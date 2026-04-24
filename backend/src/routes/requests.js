// src/routes/requests.js
// Mounts at /api/requests
//
// GET    /api/requests                      → list user's payment requests
// POST   /api/requests                      → create payment request
// GET    /api/requests/:id                  → get single request
// DELETE /api/requests/:id                  → cancel request
// POST   /api/requests/:id/mark-paid        → manually mark as paid
// GET    /api/requests/pay/:requestNumber   → public payment page (no auth)

import express from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth.js';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function generateRequestNumber(count) {
  const year = new Date().getFullYear();
  const seq  = String(count + 1).padStart(4, '0');
  return `REQ-${year}-${seq}`;
}

function generatePaymentLink(requestNumber) {
  const base = process.env.FRONTEND_URL || 'https://dayfi.me';
  return `${base}/pay/request/${requestNumber}`;
}

// ─── GET /api/requests ────────────────────────────────────────────────────────

router.get('/', authenticate, async (req, res) => {
  const { page = 1, limit = 20, status } = req.query;
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const where = {
    userId: req.user.id,
    ...(status ? { status } : {}),
  };

  try {
    const [requests, total] = await Promise.all([
      prisma.paymentRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take:    parseInt(limit),
        skip,
      }),
      prisma.paymentRequest.count({ where }),
    ]);

    res.json({
      requests,
      pagination: {
        total,
        page:  parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/requests ───────────────────────────────────────────────────────

router.post('/', authenticate, [
  body('amount').isFloat({ min: 0.000001 }).withMessage('Amount must be positive'),
  body('asset').isIn(['USDC', 'NGNT', 'XLM']).withMessage('Asset must be USDC, NGNT, or XLM'),
  body('note').optional().isString().isLength({ max: 200 }),
  body('payerName').optional().isString().isLength({ max: 80 }),
  body('payerEmail').optional().isEmail().withMessage('Invalid payer email'),
  body('expiresAt').optional().isISO8601().withMessage('expiresAt must be a valid date'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    const count         = await prisma.paymentRequest.count({ where: { userId: req.user.id } });
    const requestNumber = generateRequestNumber(count);
    const paymentLink   = generatePaymentLink(requestNumber);

    const request = await prisma.paymentRequest.create({
      data: {
        userId:        req.user.id,
        requestNumber,
        amount:        parseFloat(req.body.amount),
        asset:         req.body.asset,
        note:          req.body.note       ?? null,
        payerName:     req.body.payerName  ?? null,
        payerEmail:    req.body.payerEmail ?? null,
        paymentLink,
        status:        'pending',
        expiresAt:     req.body.expiresAt ? new Date(req.body.expiresAt) : null,
      },
    });

    res.status(201).json({ request });
  } catch (err) {
    console.error('Create request error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/requests/:id ────────────────────────────────────────────────────

router.get('/:id', authenticate, async (req, res) => {
  try {
    const request = await prisma.paymentRequest.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!request) return res.status(404).json({ error: 'Payment request not found' });

    res.json({ request });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/requests/:id ─────────────────────────────────────────────────
// Cancels a pending request

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.paymentRequest.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Payment request not found' });
    if (existing.status === 'paid') {
      return res.status(400).json({ error: 'Cannot cancel a paid request' });
    }
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Request is already cancelled' });
    }

    const updated = await prisma.paymentRequest.update({
      where: { id: req.params.id },
      data:  { status: 'cancelled' },
    });

    res.json({ request: updated, message: 'Request cancelled' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/requests/:id/mark-paid ────────────────────────────────────────
// Manually mark a request as paid (e.g. off-chain payment confirmed)

router.post('/:id/mark-paid', authenticate, async (req, res) => {
  try {
    const existing = await prisma.paymentRequest.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Payment request not found' });
    if (existing.status === 'paid') {
      return res.status(400).json({ error: 'Request is already marked as paid' });
    }
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Cannot mark a cancelled request as paid' });
    }

    const updated = await prisma.paymentRequest.update({
      where: { id: req.params.id },
      data:  { status: 'paid', paidAt: new Date() },
    });

    res.json({ request: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/requests/pay/:requestNumber (public — no auth) ─────────────────
// Used by the public payment page. Returns safe request details + payee info.

router.get('/pay/:requestNumber', async (req, res) => {
  try {
    const request = await prisma.paymentRequest.findUnique({
      where: { requestNumber: req.params.requestNumber },
      select: {
        id:            true,
        requestNumber: true,
        amount:        true,
        asset:         true,
        note:          true,
        payerName:     true,
        status:        true,
        expiresAt:     true,
        createdAt:     true,
        user: {
          select: {
            stellarPublicKey: true,
            businessName:     true,
            username:         true,
          },
        },
      },
    });

    if (!request) return res.status(404).json({ error: 'Payment request not found' });

    // Auto-expire if past expiresAt
    if (
      request.status === 'pending' &&
      request.expiresAt &&
      new Date() > new Date(request.expiresAt)
    ) {
      await prisma.paymentRequest.update({
        where: { id: request.id },
        data:  { status: 'expired' },
      });
      request.status = 'expired';
    }

    res.json({ request });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;