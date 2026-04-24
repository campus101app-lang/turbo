// src/routes/cards.js
// Mounts at /api/cards
//
// GET    /api/cards              → list user's cards
// POST   /api/cards              → create virtual card
// GET    /api/cards/:id          → get single card
// PATCH  /api/cards/:id          → update card label/color/limit
// POST   /api/cards/:id/freeze   → freeze card
// POST   /api/cards/:id/unfreeze → unfreeze card
// DELETE /api/cards/:id          → cancel card

import express from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth.js';
import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Generate a masked card number — we never store the full PAN */
function generateCardNumber() {
  const last4 = String(Math.floor(1000 + Math.random() * 9000));
  // Fake BIN prefix for virtual cards (not a real network BIN)
  const masked = `4539 **** **** ${last4}`;
  return { masked, last4 };
}

function generateExpiry() {
  const now = new Date();
  const expiryYear  = now.getFullYear() + 3;
  const expiryMonth = now.getMonth() + 1; // 1-based
  return { expiryMonth, expiryYear };
}

function hashCvv(cvv) {
  return crypto.createHash('sha256').update(cvv + process.env.CVV_SALT || 'dayfi_cvv_salt').digest('hex');
}

function generateCvv() {
  return String(Math.floor(100 + Math.random() * 900));
}

function sanitizeCard(card) {
  // Never return cvvHash to the client
  const { cvvHash, ...safe } = card;
  return safe;
}

// ─── GET /api/cards ───────────────────────────────────────────────────────────

router.get('/', authenticate, async (req, res) => {
  try {
    const cards = await prisma.card.findMany({
      where:   { userId: req.user.id, status: { not: 'cancelled' } },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ cards: cards.map(sanitizeCard) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/cards ──────────────────────────────────────────────────────────

router.post('/', authenticate, [
  body('cardholderName').notEmpty().withMessage('Cardholder name is required'),
  body('currency').isIn(['USDC', 'NGN']).withMessage('Currency must be USDC or NGN'),
  body('label').optional().isString().isLength({ max: 40 }),
  body('color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Color must be a valid hex color'),
  body('spendingLimit').optional().isFloat({ min: 1 }).withMessage('Spending limit must be positive'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    // Limit: max 5 active cards per user
    const activeCount = await prisma.card.count({
      where: { userId: req.user.id, status: { in: ['active', 'frozen'] } },
    });
    if (activeCount >= 5) {
      return res.status(400).json({ error: 'Maximum of 5 cards allowed per account' });
    }

    const { masked, last4 }       = generateCardNumber();
    const { expiryMonth, expiryYear } = generateExpiry();
    const cvv                     = generateCvv();

    const card = await prisma.card.create({
      data: {
        userId:         req.user.id,
        cardNumber:     masked,
        last4,
        cardholderName: req.body.cardholderName,
        expiryMonth,
        expiryYear,
        cvvHash:        hashCvv(cvv),
        type:           'virtual',
        currency:       req.body.currency ?? 'USDC',
        status:         'active',
        label:          req.body.label          ?? null,
        color:          req.body.color          ?? '#6C47FF',
        spendingLimit:  req.body.spendingLimit   != null
                          ? parseFloat(req.body.spendingLimit)
                          : null,
        spendingLimitPeriod: req.body.spendingLimitPeriod ?? 'daily',
        provider:       'internal',
      },
    });

    // Return CVV once — never stored in plain text again
    res.status(201).json({
      card: sanitizeCard(card),
      cvv,  // shown once at creation
      message: 'Save your CVV — it will not be shown again',
    });
  } catch (err) {
    console.error('Create card error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/cards/:id ───────────────────────────────────────────────────────

router.get('/:id', authenticate, async (req, res) => {
  try {
    const card = await prisma.card.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!card) return res.status(404).json({ error: 'Card not found' });

    res.json({ card: sanitizeCard(card) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PATCH /api/cards/:id ─────────────────────────────────────────────────────

router.patch('/:id', authenticate, [
  body('label').optional().isString().isLength({ max: 40 }),
  body('color').optional().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Invalid hex color'),
  body('spendingLimit').optional().isFloat({ min: 1 }),
  body('spendingLimitPeriod').optional().isIn(['daily', 'monthly']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    const existing = await prisma.card.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Card not found' });
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Cannot update a cancelled card' });
    }

    const updated = await prisma.card.update({
      where: { id: req.params.id },
      data: {
        label:               req.body.label               ?? existing.label,
        color:               req.body.color               ?? existing.color,
        spendingLimit:       req.body.spendingLimit        != null
                               ? parseFloat(req.body.spendingLimit)
                               : existing.spendingLimit,
        spendingLimitPeriod: req.body.spendingLimitPeriod ?? existing.spendingLimitPeriod,
      },
    });

    res.json({ card: sanitizeCard(updated) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/cards/:id/freeze ───────────────────────────────────────────────

router.post('/:id/freeze', authenticate, async (req, res) => {
  try {
    const existing = await prisma.card.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Card not found' });
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Cannot freeze a cancelled card' });
    }
    if (existing.status === 'frozen') {
      return res.status(400).json({ error: 'Card is already frozen' });
    }

    const updated = await prisma.card.update({
      where: { id: req.params.id },
      data:  { status: 'frozen', frozenAt: new Date() },
    });

    res.json({ card: sanitizeCard(updated) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/cards/:id/unfreeze ─────────────────────────────────────────────

router.post('/:id/unfreeze', authenticate, async (req, res) => {
  try {
    const existing = await prisma.card.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Card not found' });
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Cannot unfreeze a cancelled card' });
    }
    if (existing.status === 'active') {
      return res.status(400).json({ error: 'Card is already active' });
    }

    const updated = await prisma.card.update({
      where: { id: req.params.id },
      data:  { status: 'active', frozenAt: null },
    });

    res.json({ card: sanitizeCard(updated) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/cards/:id ────────────────────────────────────────────────────

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.card.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Card not found' });
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Card is already cancelled' });
    }

    const updated = await prisma.card.update({
      where: { id: req.params.id },
      data:  { status: 'cancelled', cancelledAt: new Date() },
    });

    res.json({ card: sanitizeCard(updated), message: 'Card cancelled successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;