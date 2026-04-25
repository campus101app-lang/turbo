// src/routes/billing.js
//
// Billing and invoice management routes for DayFi
//

import express from 'express';
import { body, param, validationResult } from 'express-validator';
import { PrismaClient } from '@prisma/client';
import { authenticate } from '../middleware/auth.js';
import { sendError, sendValidationError } from '../utils/http.js';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Get Billing Overview ─────────────────────────────────────────────────────

router.get('/overview', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user's invoices
    const invoices = await prisma.invoice.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 10
    });
    
    // Get payments
    const payments = await prisma.invoicePayment.findMany({
      where: { invoice: { userId } },
      orderBy: { createdAt: 'desc' },
      take: 10
    });
    
    // Calculate totals
    const totalInvoiced = invoices.reduce((sum, inv) => sum + inv.amount, 0);
    const totalPaid = payments.reduce((sum, pay) => sum + pay.amount, 0);
    const totalOutstanding = totalInvoiced - totalPaid;
    
    res.json({
      overview: {
        totalInvoiced,
        totalPaid,
        totalOutstanding,
        invoiceCount: invoices.length,
        paymentCount: payments.length
      },
      recentInvoices: invoices,
      recentPayments: payments
    });
  } catch (error) {
    sendError(res, 500, 'BILLING_ERROR', 'Failed to fetch billing overview');
  }
});

// ─── Get Invoices ─────────────────────────────────────────────────────────────

router.get('/invoices', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const userId = req.user.id;
    
    const where = { userId };
    if (status) where.status = status;
    
    const invoices = await prisma.invoice.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: parseInt(limit)
    });
    
    const total = await prisma.invoice.count({ where });
    
    res.json({
      invoices,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    sendError(res, 500, 'BILLING_ERROR', 'Failed to fetch invoices');
  }
});

// ─── Create Invoice ───────────────────────────────────────────────────────────

router.post('/invoices', authenticate, [
  body('clientName').notEmpty().withMessage('Client name is required'),
  body('clientEmail').isEmail().withMessage('Valid client email is required'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than 0'),
  body('dueDate').isISO8601().withMessage('Valid due date is required'),
  body('description').optional().isString(),
  body('items').optional().isArray(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  
  try {
    const userId = req.user.id;
    const { clientName, clientEmail, amount, dueDate, description, items } = req.body;
    
    const invoice = await prisma.invoice.create({
      data: {
        userId,
        clientName,
        clientEmail,
        amount,
        dueDate: new Date(dueDate),
        description,
        items: items || [],
        status: 'draft',
        invoiceNumber: `INV-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`
      }
    });
    
    res.status(201).json({ invoice });
  } catch (error) {
    sendError(res, 500, 'BILLING_ERROR', 'Failed to create invoice');
  }
});

// ─── Get Invoice Details ─────────────────────────────────────────────────────

router.get('/invoices/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    const invoice = await prisma.invoice.findFirst({
      where: { id, userId },
      include: {
        payments: true
      }
    });
    
    if (!invoice) {
      return sendError(res, 404, 'INVOICE_NOT_FOUND', 'Invoice not found');
    }
    
    res.json({ invoice });
  } catch (error) {
    sendError(res, 500, 'BILLING_ERROR', 'Failed to fetch invoice');
  }
});

// ─── Update Invoice Status ─────────────────────────────────────────────────────

router.patch('/invoices/:id/status', authenticate, [
  body('status').isIn(['draft', 'sent', 'viewed', 'paid', 'overdue', 'cancelled']).withMessage('Invalid status'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { status } = req.body;
    
    const invoice = await prisma.invoice.updateMany({
      where: { id, userId },
      data: { status }
    });
    
    if (invoice.count === 0) {
      return sendError(res, 404, 'INVOICE_NOT_FOUND', 'Invoice not found');
    }
    
    res.json({ success: true });
  } catch (error) {
    sendError(res, 500, 'BILLING_ERROR', 'Failed to update invoice status');
  }
});

export default router;
