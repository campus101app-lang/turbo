// src/routes/payments.js
//
// Mounts at /api/payments
//
// GET  /api/payments/virtual-account       → fetch existing virtual account
// POST /api/payments/virtual-account       → create virtual account (BVN required)
// POST /api/payments/flutterwave/init      → initiate Flutterwave deposit (future)
// POST /api/payments/flutterwave/verify    → verify Flutterwave deposit (future)
// POST /api/payments/flutterwave/withdraw  → withdraw to bank (future)

import express from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth.js';
import { PrismaClient } from '@prisma/client';
import { sendError, sendNotFound, sendValidationError } from '../utils/http.js';
import { sendAssetFromMasterWallet } from '../services/walletService.js';

const router  = express.Router();
const prisma  = new PrismaClient();

// ─── Helpers ─────────────────────────────────────────────────────────────────

const FLW_SECRET = process.env.FLUTTERWAVE_SECRET_KEY || '';
const FLW_WEBHOOK_HASH = process.env.FLUTTERWAVE_WEBHOOK_HASH || process.env.FLUTTERWAVE_WEBHOOK_SECRET_HASH || '';

const RETRYABLE_STATUSES = new Set([408, 429, 500, 502, 503, 504]);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function flwRequest(path, method = 'GET', body = null, retries = 2) {
  let attempt = 0;
  let lastErr = null;

  while (attempt <= retries) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);

    try {
      const res = await fetch(`https://api.flutterwave.com/v3${path}`, {
        method,
        headers: {
          Authorization: `Bearer ${FLW_SECRET}`,
          'Content-Type': 'application/json',
        },
        ...(body ? { body: JSON.stringify(body) } : {}),
        signal: controller.signal,
      });

      clearTimeout(timeout);
      const payload = await res.json();

      if (!res.ok || payload?.status !== 'success') {
        const err = new Error(payload?.message || `Flutterwave request failed (${res.status})`);
        err.status = res.status;
        throw err;
      }

      return payload.data;
    } catch (err) {
      clearTimeout(timeout);
      lastErr = err;
      const status = err?.status;
      const retryable = status ? RETRYABLE_STATUSES.has(status) : true;
      if (attempt === retries || !retryable) break;
      await sleep(300 * (attempt + 1));
      attempt += 1;
    }
  }

  throw lastErr || new Error('Flutterwave request failed');
}

function ensureFlutterwaveConfigured(res) {
  if (!FLW_SECRET) {
    sendError(
      res,
      503,
      'PAYMENT_PROVIDER_UNAVAILABLE',
      'Flutterwave is not configured.',
      { requiredEnv: 'FLUTTERWAVE_SECRET_KEY' },
    );
    return false;
  }
  return true;
}

function isSuccessfulProviderStatus(status) {
  const s = String(status || '').toLowerCase();
  return s === 'successful' || s === 'completed' || s === 'success';
}

async function processDepositSuccess({
  userId,
  txRef,
  flwRef,
  amount,
  currency = 'NGN',
  providerStatus = 'successful',
  providerMessage = null,
}) {
  const amountNum = Number(amount || 0);
  if (!amountNum || amountNum <= 0) return { processed: false, reason: 'invalid_amount' };

  await prisma.flutterwavePayment.upsert({
    where: { txRef },
    create: {
      userId,
      txRef,
      flwRef: flwRef ? String(flwRef) : null,
      type: 'deposit',
      fiatAmount: amountNum,
      currency: String(currency || 'NGN').toUpperCase(),
      status: 'successful',
      providerStatus: String(providerStatus || 'successful').toLowerCase(),
      providerMessage: providerMessage || null,
    },
    update: {
      flwRef: flwRef ? String(flwRef) : undefined,
      fiatAmount: amountNum,
      currency: String(currency || 'NGN').toUpperCase(),
      status: 'successful',
      providerStatus: String(providerStatus || 'successful').toLowerCase(),
      providerMessage: providerMessage || null,
    },
  });

  const existingFiatTx = await prisma.transaction.findFirst({
    where: { userId, type: 'fiatDeposit', flutterwaveRef: txRef },
  });
  let fiatTxId = existingFiatTx?.id || null;
  if (!existingFiatTx) {
    const created = await prisma.transaction.create({
      data: {
        userId,
        type: 'fiatDeposit',
        status: 'confirmed',
        amount: amountNum,
        asset: 'NGNT',
        network: 'flutterwave',
        flutterwaveRef: txRef,
        fiatAmount: amountNum,
        fiatCurrency: String(currency || 'NGN').toUpperCase(),
        flutterwaveStatus: String(providerStatus || 'successful').toLowerCase(),
        memo: 'Flutterwave top-up confirmed',
      },
    });
    fiatTxId = created.id;
  }

  let settlement = null;
  const autoSettle = String(process.env.AUTO_SETTLE_NGNT_TOPUPS || 'true').toLowerCase() === 'true';
  if (autoSettle) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { stellarPublicKey: true },
    });
    if (user?.stellarPublicKey) {
      const memo = `Top-up settlement ${txRef}`.slice(0, 28);
      const settledAlready = await prisma.transaction.findFirst({
        where: {
          userId,
          type: 'receive',
          network: 'stellar',
          flutterwaveRef: txRef,
          asset: 'NGNT',
        },
      });
      if (!settledAlready) {
        try {
          const sent = await sendAssetFromMasterWallet(
            user.stellarPublicKey,
            amountNum,
            'NGNT',
            memo,
          );
          await prisma.transaction.create({
            data: {
              userId,
              type: 'receive',
              status: 'confirmed',
              amount: amountNum,
              asset: 'NGNT',
              network: 'stellar',
              fromAddress: process.env.MASTER_WALLET_PUBLIC_KEY || null,
              toAddress: user.stellarPublicKey,
              stellarTxHash: sent.hash,
              flutterwaveRef: txRef,
              memo: 'NGNT settlement from top-up',
            },
          });
          settlement = { status: 'settled', hash: sent.hash, asset: 'NGNT', amount: amountNum };
        } catch (err) {
          settlement = { status: 'settlement_failed', error: err.message };
        }
      } else {
        settlement = { status: 'already_settled' };
      }
    } else {
      settlement = { status: 'wallet_not_ready' };
    }
  } else {
    settlement = { status: 'disabled' };
  }

  if (fiatTxId) {
    const settlementStatus =
      settlement?.status === 'settled' || settlement?.status === 'already_settled'
        ? 'settled'
        : 'pending_settlement';
    await prisma.transaction.update({
      where: { id: fiatTxId },
      data: { flutterwaveStatus: settlementStatus },
    });
  }

  return { processed: true, settlement };
}

// ─── GET /api/payments/virtual-account ───────────────────────────────────────
// Returns the user's existing virtual account details, or { exists: false }

router.get('/virtual-account', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where:  { id: req.user.id },
      select: {
        virtualAccountNumber: true,
        virtualAccountBank:   true,
        virtualAccountName:   true,
      },
    });

    if (!user) return sendNotFound(res, 'User');

    if (!user.virtualAccountNumber) {
      return res.json({ exists: false });
    }

    return res.json({
      exists:        true,
      accountNumber: user.virtualAccountNumber,
      bankName:      user.virtualAccountBank,
      accountName:   user.virtualAccountName,
    });
  } catch (err) {
    console.error('GET /virtual-account error:', err.message);
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── POST /api/payments/virtual-account ──────────────────────────────────────
// Creates a Flutterwave virtual account for the user (BVN required).
// Idempotent: if one already exists, returns it without creating a new one.

router.post(
  '/virtual-account',
  authenticate,
  [
    body('bvn')
      .isLength({ min: 11, max: 11 })
      .withMessage('BVN must be 11 digits')
      .matches(/^\d{11}$/)
      .withMessage('BVN must be numeric'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendValidationError(res, errors.array());
    }

    const { bvn } = req.body;

    try {
      // ── Idempotency: return existing account without hitting Flutterwave again
      const existing = await prisma.user.findUnique({
        where:  { id: req.user.id },
        select: {
          virtualAccountNumber: true,
          virtualAccountBank:   true,
          virtualAccountName:   true,
          email:                true,
          fullName:             true,
          businessName:         true,
        },
      });

      if (!existing) return sendNotFound(res, 'User');

      if (existing.virtualAccountNumber) {
        return res.json({
          accountNumber: existing.virtualAccountNumber,
          bankName:      existing.virtualAccountBank,
          accountName:   existing.virtualAccountName,
        });
      }

      if (!FLW_SECRET) {
        // Dev mode: return a mock account so the UI works without live keys
        console.warn('⚠️  FLUTTERWAVE_SECRET_KEY not set — returning mock virtual account');
        const mock = {
          accountNumber: '1234567890',
          bankName:      'Wema Bank',
          accountName:   existing.fullName || existing.email,
        };
        await prisma.user.update({
          where: { id: req.user.id },
          data: {
            virtualAccountNumber: mock.accountNumber,
            virtualAccountBank:   mock.bankName,
            virtualAccountName:   mock.accountName,
          },
        });
        return res.json(mock);
      }

      // ── Call Flutterwave to create a permanent virtual account ──────────────
      // Docs: https://developer.flutterwave.com/docs/collecting-payments/virtual-account-numbers
      const accountName = existing.businessName || existing.fullName || existing.email;
      const txRef       = `dayfi-va-${req.user.id}-${Date.now()}`;

      const flwData = await flwRequest('/virtual-account-numbers', 'POST', {
        email:      existing.email,
        is_permanent: true,
        bvn,
        tx_ref:     txRef,
        phonenumber: '',          // optional — add if you collect phone
        firstname:  accountName.split(' ')[0] || accountName,
        lastname:   accountName.split(' ').slice(1).join(' ') || '',
        narration:  `DayFi — ${accountName}`,
      });

      // flwData shape: { account_number, bank_name, ... }
      const result = {
        accountNumber: flwData.account_number,
        bankName:      flwData.bank_name,
        accountName:   flwData.account_name || accountName,
      };

      // ── Persist to DB ────────────────────────────────────────────────────────
      await prisma.user.update({
        where: { id: req.user.id },
        data: {
          virtualAccountNumber: result.accountNumber,
          virtualAccountBank:   result.bankName,
          virtualAccountName:   result.accountName,
        },
      });

      console.log(`✅ Virtual account created for user ${req.user.id}: ${result.accountNumber}`);
      return res.json(result);
    } catch (err) {
      console.error('POST /virtual-account error:', err.message);
      sendError(res, 500, 'INTERNAL_ERROR', err.message);
    }
  },
);

// ─── POST /api/payments/flutterwave/init ─────────────────────────────────────
// Kept for future WebView-based deposit flow.

router.post('/flutterwave/init', authenticate, [
  body('amount').isFloat({ min: 100 }).withMessage('Minimum deposit is ₦100'),
  body('currency').optional().isString(),
  body('txRef').optional().isString().isLength({ min: 8, max: 120 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());
  if (!ensureFlutterwaveConfigured(res)) return;

  try {
    const amount = Number(req.body.amount);
    const currency = (req.body.currency || 'NGN').toUpperCase();
    const txRef = req.body.txRef || `dayfi-dep-${req.user.id}-${Date.now()}`;
    const redirectUrl = process.env.FRONTEND_URL || 'https://dayfi.me';

    const existing = await prisma.flutterwavePayment.findUnique({ where: { txRef } });
    if (existing && existing.userId === req.user.id) {
      return res.json({
        txRef: existing.txRef,
        paymentLink: existing.redirectUrl,
        status: existing.status,
      });
    }

    const linkData = await flwRequest('/payments', 'POST', {
      tx_ref: txRef,
      amount,
      currency,
      redirect_url: redirectUrl,
      customer: {
        email: req.user.email,
        name: req.user.username || req.user.email,
      },
      customizations: {
        title: 'DayFi Deposit',
        description: 'Top up your account',
      },
    });

    const payment = await prisma.flutterwavePayment.create({
      data: {
        userId: req.user.id,
        txRef,
        flwRef: linkData?.id ? String(linkData.id) : null,
        type: 'deposit',
        fiatAmount: amount,
        currency,
        status: 'initiated',
        providerStatus: 'initiated',
        customerEmail: req.user.email,
        customerName: req.user.username || req.user.email,
        redirectUrl: linkData?.link || redirectUrl,
      },
    });

    return res.json({
      txRef: payment.txRef,
      paymentLink: linkData?.link || payment.redirectUrl,
      status: payment.status,
    });
  } catch (err) {
    return sendError(res, 502, 'PAYMENT_PROVIDER_ERROR', err.message);
  }
});

// ─── POST /api/payments/flutterwave/verify ────────────────────────────────────

router.post('/flutterwave/verify', authenticate, [
  body('txRef').notEmpty().withMessage('txRef is required'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());
  if (!ensureFlutterwaveConfigured(res)) return;

  try {
    const { txRef } = req.body;
    const payment = await prisma.flutterwavePayment.findUnique({ where: { txRef } });
    if (!payment || payment.userId !== req.user.id) return sendNotFound(res, 'Payment');

    const verify = await flwRequest(`/transactions/verify_by_reference?tx_ref=${encodeURIComponent(txRef)}`);
    const providerStatus = String(verify?.status || '').toLowerCase();
    const nextStatus = providerStatus === 'successful' ? 'successful' : providerStatus === 'failed' ? 'failed' : 'pending';

    const updated = await prisma.flutterwavePayment.update({
      where: { txRef },
      data: {
        status: nextStatus,
        providerStatus,
        providerMessage: verify?.processor_response || null,
        flwRef: verify?.flw_ref || payment.flwRef,
      },
    });

    let settlement = null;
    if (nextStatus === 'successful' && payment.type === 'deposit') {
      const processed = await processDepositSuccess({
        userId: req.user.id,
        txRef,
        flwRef: verify?.flw_ref || payment.flwRef,
        amount: Number(verify?.amount || payment.fiatAmount),
        currency: payment.currency,
        providerStatus,
        providerMessage: verify?.processor_response || null,
      });
      settlement = processed.settlement;
    }

    return res.json({
      txRef: updated.txRef,
      status: updated.status,
      providerStatus,
      amount: verify?.amount || payment.fiatAmount,
      currency: payment.currency,
      settlement,
    });
  } catch (err) {
    return sendError(res, 502, 'PAYMENT_PROVIDER_ERROR', err.message);
  }
});

// ─── POST /api/payments/flutterwave/webhook ───────────────────────────────────
// Handles asynchronous Flutterwave events (including virtual account transfers).
router.post('/flutterwave/webhook', async (req, res) => {
  try {
    if (!FLW_WEBHOOK_HASH) {
      return res.status(503).json({ ok: false, message: 'Webhook hash not configured' });
    }
    const signature = req.header('verif-hash') || req.header('x-flw-signature') || '';
    if (!signature || signature !== FLW_WEBHOOK_HASH) {
      return res.status(401).json({ ok: false, message: 'Invalid webhook signature' });
    }

    const event = req.body?.event || '';
    const data = req.body?.data || {};
    const txRef = data?.tx_ref || data?.txRef || data?.reference || data?.flw_ref;
    const providerStatus = String(data?.status || '').toLowerCase();
    const amount = Number(data?.amount || 0);
    const currency = data?.currency || 'NGN';
    const flwRef = data?.flw_ref || data?.id || null;
    const accountNumber = data?.account_number || data?.meta?.account_number || null;
    const providerMessage = data?.processor_response || data?.narration || null;

    if (!txRef) return res.status(200).json({ ok: true, ignored: 'missing_reference' });
    if (!(event === 'charge.completed' || event === 'charge.successful' || event === 'transfer.completed')) {
      return res.status(200).json({ ok: true, ignored: 'unsupported_event' });
    }
    if (!isSuccessfulProviderStatus(providerStatus)) {
      return res.status(200).json({ ok: true, ignored: 'non_success_status' });
    }

    let payment = await prisma.flutterwavePayment.findUnique({ where: { txRef } });
    let userId = payment?.userId || null;
    if (!userId && accountNumber) {
      const user = await prisma.user.findFirst({
        where: { virtualAccountNumber: String(accountNumber) },
        select: { id: true },
      });
      userId = user?.id || null;
    }
    if (!userId) return res.status(200).json({ ok: true, ignored: 'user_not_found' });

    const processed = await processDepositSuccess({
      userId,
      txRef,
      flwRef,
      amount,
      currency,
      providerStatus,
      providerMessage,
    });

    return res.status(200).json({
      ok: true,
      txRef,
      processed: processed.processed,
      settlement: processed.settlement || null,
    });
  } catch (err) {
    console.error('Flutterwave webhook error:', err.message);
    return res.status(500).json({ ok: false, message: err.message });
  }
});

// ─── POST /api/payments/flutterwave/withdraw ──────────────────────────────────

router.post('/flutterwave/withdraw', authenticate, [
  body('ngntAmount').isFloat({ min: 1 }),
  body('bankCode').notEmpty(),
  body('accountNumber').notEmpty(),
  body('accountName').notEmpty(),
  body('idempotencyKey').optional().isString().isLength({ min: 8, max: 120 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());
  if (!ensureFlutterwaveConfigured(res)) return;

  try {
    const { ngntAmount, bankCode, accountNumber, accountName, idempotencyKey } = req.body;
    const txRef = idempotencyKey
      ? `dayfi-wd-${req.user.id}-${idempotencyKey}`
      : `dayfi-wd-${req.user.id}-${Date.now()}`;

    const existing = await prisma.flutterwavePayment.findUnique({ where: { txRef } });
    if (existing && existing.userId === req.user.id) {
      return res.json({
        txRef: existing.txRef,
        status: existing.status,
      });
    }

    const transfer = await flwRequest('/transfers', 'POST', {
      account_bank: bankCode,
      account_number: accountNumber,
      amount: Number(ngntAmount),
      currency: 'NGN',
      reference: txRef,
      narration: 'DayFi withdrawal',
      beneficiary_name: accountName,
      debit_currency: 'NGN',
    });

    const providerStatus = String(transfer?.status || 'pending').toLowerCase();
    const status = providerStatus === 'successful' ? 'successful' : providerStatus === 'failed' ? 'failed' : 'pending';

    const payment = await prisma.flutterwavePayment.create({
      data: {
        userId: req.user.id,
        txRef,
        flwRef: transfer?.id ? String(transfer.id) : null,
        type: 'withdrawal',
        fiatAmount: Number(ngntAmount),
        currency: 'NGN',
        status,
        providerStatus,
        idempotencyKey: idempotencyKey || null,
        bankCode,
        accountNumber,
        accountName,
        customerEmail: req.user.email,
        customerName: req.user.username || req.user.email,
      },
    });

    return res.json({
      txRef: payment.txRef,
      status: payment.status,
      providerReference: payment.flwRef,
    });
  } catch (err) {
    return sendError(res, 502, 'PAYMENT_PROVIDER_ERROR', err.message);
  }
});

// ─── GET /api/payments/flutterwave/banks ──────────────────────────────────────
router.get('/flutterwave/banks', authenticate, async (_req, res) => {
  if (!ensureFlutterwaveConfigured(res)) return;
  try {
    const banks = await flwRequest('/banks/NG');
    const normalized = (banks || []).map((b) => ({
      code: String(b.code || ''),
      name: String(b.name || ''),
    }));
    return res.json({ banks: normalized });
  } catch (err) {
    return sendError(res, 502, 'PAYMENT_PROVIDER_ERROR', err.message);
  }
});

// ─── POST /api/payments/flutterwave/resolve-account ───────────────────────────
router.post('/flutterwave/resolve-account', authenticate, [
  body('bankCode').notEmpty(),
  body('accountNumber').isLength({ min: 10, max: 10 }).withMessage('Account number must be 10 digits'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());
  if (!ensureFlutterwaveConfigured(res)) return;
  try {
    const { bankCode, accountNumber } = req.body;
    const resolved = await flwRequest(
      `/accounts/resolve?account_number=${encodeURIComponent(accountNumber)}&account_bank=${encodeURIComponent(bankCode)}`
    );
    return res.json({
      accountNumber,
      bankCode,
      accountName: resolved?.account_name || null,
    });
  } catch (err) {
    return sendError(res, 400, 'ACCOUNT_RESOLVE_FAILED', err.message);
  }
});

export default router;