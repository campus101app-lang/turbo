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

const router  = express.Router();
const prisma  = new PrismaClient();

// ─── Helpers ─────────────────────────────────────────────────────────────────

const FLW_SECRET = process.env.FLUTTERWAVE_SECRET_KEY;

async function flwRequest(path, method = 'GET', body = null) {
  const res = await fetch(`https://api.flutterwave.com/v3${path}`, {
    method,
    headers: {
      'Authorization': `Bearer ${FLW_SECRET}`,
      'Content-Type':  'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const data = await res.json();
  if (data.status !== 'success') {
    throw new Error(data.message || 'Flutterwave error');
  }
  return data.data;
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

    if (!user) return res.status(404).json({ error: 'User not found' });

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
    res.status(500).json({ error: err.message });
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
      return res.status(400).json({ error: errors.array()[0].msg });
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

      if (!existing) return res.status(404).json({ error: 'User not found' });

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
      res.status(500).json({ error: err.message });
    }
  },
);

// ─── POST /api/payments/flutterwave/init ─────────────────────────────────────
// Kept for future WebView-based deposit flow.

router.post('/flutterwave/init', authenticate, [
  body('amount').isFloat({ min: 100 }).withMessage('Minimum deposit is ₦100'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ error: errors.array()[0].msg });

  // TODO: implement hosted payment link flow when needed
  res.status(501).json({ error: 'WebView deposit not yet implemented. Use virtual account.' });
});

// ─── POST /api/payments/flutterwave/verify ────────────────────────────────────

router.post('/flutterwave/verify', authenticate, async (req, res) => {
  // TODO: verify webhook or txRef and credit NGNT
  res.status(501).json({ error: 'Not yet implemented' });
});

// ─── POST /api/payments/flutterwave/withdraw ──────────────────────────────────

router.post('/flutterwave/withdraw', authenticate, [
  body('ngntAmount').isFloat({ min: 1 }),
  body('bankCode').notEmpty(),
  body('accountNumber').notEmpty(),
  body('accountName').notEmpty(),
], async (req, res) => {
  // TODO: burn NGNT on Stellar, send NGN via Flutterwave transfer
  res.status(501).json({ error: 'Withdrawals not yet implemented' });
});

export default router;