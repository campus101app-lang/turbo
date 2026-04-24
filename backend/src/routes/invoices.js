// src/routes/invoices.js
// Mounts at /api/invoices
//
// GET    /api/invoices                → list user's invoices (paginated)
// POST   /api/invoices                → create invoice
// GET    /api/invoices/:id            → get single invoice
// PUT    /api/invoices/:id            → update invoice
// DELETE /api/invoices/:id            → delete invoice
// POST   /api/invoices/:id/send       → mark as sent + generate payment link
// GET    /api/invoices/pay/:invoiceNumber  → public payment page (no auth)

import express from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth.js';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Helpers ─────────────────────────────────────────────────────────────────

function generateInvoiceNumber(existingCount) {
  const year  = new Date().getFullYear();
  const seq   = String(existingCount + 1).padStart(4, '0');
  return `INV-${year}-${seq}`;
}

function generatePaymentLink(invoiceNumber) {
  const base = process.env.FRONTEND_URL || 'https://dayfi.me';
  return `${base}/pay/${invoiceNumber}`;
}

// ─── GET /api/invoices ────────────────────────────────────────────────────────

router.get('/', authenticate, async (req, res) => {
  const { page = 1, limit = 20, status } = req.query;
  const skip = (parseInt(page) - 1) * parseInt(limit);

  const where = {
    userId: req.user.id,
    ...(status ? { status } : {}),
  };

  try {
    const [invoices, total] = await Promise.all([
      prisma.invoice.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take:    parseInt(limit),
        skip,
      }),
      prisma.invoice.count({ where }),
    ]);

    res.json({
      invoices,
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

// ─── POST /api/invoices ───────────────────────────────────────────────────────

router.post('/', authenticate, [
  body('title').notEmpty().withMessage('Title is required'),
  body('clientName').notEmpty().withMessage('Client name is required'),
  body('lineItems').isArray({ min: 1 }).withMessage('At least one line item required'),
  body('totalAmount').isFloat({ min: 0 }).withMessage('Total amount required'),
  body('currency').isIn(['NGNT', 'USDC']).withMessage('Currency must be NGNT or USDC'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    // Count existing invoices for sequential numbering
    const count = await prisma.invoice.count({ where: { userId: req.user.id } });
    const invoiceNumber = generateInvoiceNumber(count);

    const invoice = await prisma.invoice.create({
      data: {
        userId:        req.user.id,
        invoiceNumber,
        title:         req.body.title,
        description:   req.body.description   ?? null,
        clientName:    req.body.clientName,
        clientEmail:   req.body.clientEmail   ?? null,
        clientPhone:   req.body.clientPhone   ?? null,
        clientAddress: req.body.clientAddress ?? null,
        lineItems:     req.body.lineItems,
        subtotal:      parseFloat(req.body.subtotal   ?? 0),
        vatAmount:     parseFloat(req.body.vatAmount  ?? 0),
        totalAmount:   parseFloat(req.body.totalAmount),
        currency:      req.body.currency      ?? 'NGNT',
        paymentType:   req.body.paymentType   ?? 'crypto',
        vatEnabled:    req.body.vatEnabled    ?? false,
        vatRate:       parseFloat(req.body.vatRate ?? 7.5),
        isRecurring:   req.body.isRecurring   ?? false,
        recurringInterval: req.body.recurringInterval ?? null,
        dueDate:       req.body.dueDate ? new Date(req.body.dueDate) : null,
        status:        'draft',
      },
    });

    res.status(201).json({ invoice });
  } catch (err) {
    console.error('Create invoice error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/invoices/:id ────────────────────────────────────────────────────

router.get('/:id', authenticate, async (req, res) => {
  try {
    const invoice = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });
    res.json({ invoice });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT /api/invoices/:id ────────────────────────────────────────────────────

router.put('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Invoice not found' });
    if (existing.status !== 'draft') {
      return res.status(400).json({ error: 'Only draft invoices can be edited' });
    }

    const updated = await prisma.invoice.update({
      where: { id: req.params.id },
      data: {
        title:         req.body.title         ?? existing.title,
        description:   req.body.description   ?? existing.description,
        clientName:    req.body.clientName    ?? existing.clientName,
        clientEmail:   req.body.clientEmail   ?? existing.clientEmail,
        lineItems:     req.body.lineItems     ?? existing.lineItems,
        subtotal:      req.body.subtotal      != null ? parseFloat(req.body.subtotal)    : existing.subtotal,
        vatAmount:     req.body.vatAmount     != null ? parseFloat(req.body.vatAmount)   : existing.vatAmount,
        totalAmount:   req.body.totalAmount   != null ? parseFloat(req.body.totalAmount) : existing.totalAmount,
        currency:      req.body.currency      ?? existing.currency,
        paymentType:   req.body.paymentType   ?? existing.paymentType,
        vatEnabled:    req.body.vatEnabled    ?? existing.vatEnabled,
        vatRate:       req.body.vatRate       != null ? parseFloat(req.body.vatRate) : existing.vatRate,
        isRecurring:   req.body.isRecurring   ?? existing.isRecurring,
        recurringInterval: req.body.recurringInterval ?? existing.recurringInterval,
        dueDate:       req.body.dueDate ? new Date(req.body.dueDate) : existing.dueDate,
      },
    });

    res.json({ invoice: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/invoices/:id ─────────────────────────────────────────────────

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Invoice not found' });

    await prisma.invoice.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/invoices/:id/send ──────────────────────────────────────────────
// Marks invoice as sent and generates a payment link.

router.post('/:id/send', authenticate, async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Invoice not found' });
    if (existing.status === 'paid') {
      return res.status(400).json({ error: 'Invoice is already paid' });
    }

    const paymentLink = generatePaymentLink(existing.invoiceNumber);

    const updated = await prisma.invoice.update({
      where: { id: req.params.id },
      data: {
        status:      'sent',
        sentAt:      new Date(),
        paymentLink,
      },
    });

    res.json({ invoice: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/invoices/:id/mark-paid ─────────────────────────────────────────
// Marks an invoice as paid manually (e.g. off-app settlement confirmed).
router.post('/:id/mark-paid', authenticate, async (req, res) => {
  try {
    const existing = await prisma.invoice.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return res.status(404).json({ error: 'Invoice not found' });
    if (existing.status === 'paid') {
      return res.status(400).json({ error: 'Invoice is already paid' });
    }
    if (existing.status === 'cancelled') {
      return res.status(400).json({ error: 'Cancelled invoice cannot be marked as paid' });
    }

    const updated = await prisma.invoice.update({
      where: { id: req.params.id },
      data: {
        status: 'paid',
        paidAt: new Date(),
      },
    });

    res.json({ invoice: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/invoices/pay/:invoiceNumber (public — no auth) ──────────────────
// Used by the payment page. Returns invoice details without sensitive user data.

router.get('/pay/:invoiceNumber', async (req, res) => {
  try {
    const invoice = await prisma.invoice.findUnique({
      where: { invoiceNumber: req.params.invoiceNumber },
      select: {
        id:            true,
        invoiceNumber: true,
        title:         true,
        description:   true,
        clientName:    true,
        lineItems:     true,
        subtotal:      true,
        vatAmount:     true,
        totalAmount:   true,
        currency:      true,
        paymentType:   true,
        vatEnabled:    true,
        vatRate:       true,
        status:        true,
        dueDate:       true,
        // Include the payer's Stellar address for on-chain payment
        user: {
          select: {
            stellarPublicKey: true,
            businessName:     true,
          },
        },
      },
    });

    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });

    // Mark as viewed if it was sent
    if (invoice.status === 'sent') {
      await prisma.invoice.update({
        where: { id: invoice.id },
        data:  { status: 'viewed', viewedAt: new Date() },
      });
    }

    res.json({ invoice });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;