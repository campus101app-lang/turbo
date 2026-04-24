import express from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const state = {
  invoices: [],
};

vi.mock('@prisma/client', () => {
  class PrismaClient {
    constructor() {
      this.invoice = {
        count: vi.fn(async ({ where }) => state.invoices.filter((i) => i.userId === where.userId).length),
        create: vi.fn(async ({ data }) => {
          const row = { id: `i_${state.invoices.length + 1}`, createdAt: new Date().toISOString(), ...data };
          state.invoices.push(row);
          return row;
        }),
        findUnique: vi.fn(async ({ where }) => {
          return state.invoices.find((i) => i.invoiceNumber === where.invoiceNumber) || null;
        }),
        update: vi.fn(async ({ where, data }) => {
          const idx = state.invoices.findIndex((i) => i.id === where.id);
          if (idx < 0) return null;
          state.invoices[idx] = { ...state.invoices[idx], ...data };
          return state.invoices[idx];
        }),
      };
    }
  }
  return { PrismaClient };
});

vi.mock('../../src/middleware/auth.js', () => ({
  authenticate: (req, _res, next) => {
    req.user = { id: 'u1' };
    next();
  },
}));

import invoicesRoutes from '../../src/routes/invoices.js';

describe('invoices routes', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/invoices', invoicesRoutes);

  beforeEach(() => {
    state.invoices.length = 0;
  });

  it('creates invoice draft', async () => {
    const res = await request(app).post('/api/invoices').send({
      title: 'Design',
      clientName: 'Client',
      lineItems: [{ description: 'Design', quantity: 1, unitPrice: 100, total: 100 }],
      totalAmount: 100,
      currency: 'USDC',
    });
    expect(res.status).toBe(201);
    expect(res.body.invoice.invoiceNumber).toMatch(/^INV-/);
  });

  it('returns public invoice pay payload', async () => {
    state.invoices.push({
      id: 'i1',
      invoiceNumber: 'INV-2026-0001',
      title: 'Design',
      lineItems: [],
      subtotal: 100,
      vatAmount: 0,
      totalAmount: 100,
      currency: 'USDC',
      paymentType: 'crypto',
      vatEnabled: false,
      vatRate: 7.5,
      status: 'sent',
      dueDate: null,
      user: { stellarPublicKey: 'GXXX', businessName: 'ACME' },
    });
    const res = await request(app).get('/api/invoices/pay/INV-2026-0001');
    expect(res.status).toBe(200);
    expect(res.body.invoice.invoiceNumber).toBe('INV-2026-0001');
  });
});
