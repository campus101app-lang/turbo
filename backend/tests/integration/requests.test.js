import express from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const state = {
  requests: [],
};

vi.mock('@prisma/client', () => {
  class PrismaClient {
    constructor() {
      this.paymentRequest = {
        count: vi.fn(async ({ where }) => state.requests.filter((r) => r.userId === where.userId).length),
        create: vi.fn(async ({ data }) => {
          const row = { id: `r_${state.requests.length + 1}`, createdAt: new Date().toISOString(), ...data };
          state.requests.push(row);
          return row;
        }),
        findUnique: vi.fn(async ({ where }) => {
          return state.requests.find((r) => r.requestNumber === where.requestNumber) || null;
        }),
        findFirst: vi.fn(async ({ where }) => {
          return state.requests.find((r) => r.id === where.id && r.userId === where.userId) || null;
        }),
        update: vi.fn(async ({ where, data }) => {
          const idx = state.requests.findIndex((r) => r.id === where.id);
          if (idx < 0) return null;
          state.requests[idx] = { ...state.requests[idx], ...data };
          return state.requests[idx];
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

import requestsRoutes from '../../src/routes/requests.js';

describe('requests routes', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/requests', requestsRoutes);

  beforeEach(() => {
    state.requests.length = 0;
  });

  it('creates payment request', async () => {
    const res = await request(app).post('/api/requests').send({
      amount: 10,
      asset: 'USDC',
      note: 'consulting',
    });
    expect(res.status).toBe(201);
    expect(res.body.request.requestNumber).toMatch(/^REQ-/);
  });

  it('returns public pay request', async () => {
    state.requests.push({
      id: 'r1',
      userId: 'u1',
      requestNumber: 'REQ-2026-0001',
      amount: 10,
      asset: 'USDC',
      note: 'x',
      payerName: null,
      status: 'pending',
      expiresAt: null,
      createdAt: new Date().toISOString(),
      user: { stellarPublicKey: 'GXXX', businessName: 'ACME', username: 'acme' },
    });

    const res = await request(app).get('/api/requests/pay/REQ-2026-0001');
    expect(res.status).toBe(200);
    expect(res.body.request.requestNumber).toBe('REQ-2026-0001');
  });

  it('edits pending request', async () => {
    state.requests.push({
      id: 'r1',
      userId: 'u1',
      requestNumber: 'REQ-2026-0001',
      amount: 10,
      asset: 'USDC',
      status: 'pending',
      createdAt: new Date().toISOString(),
    });
    const res = await request(app).put('/api/requests/r1').send({
      amount: 15,
      asset: 'NGNT',
      note: 'updated',
    });
    expect(res.status).toBe(200);
    expect(res.body.request.amount).toBe(15);
    expect(res.body.request.asset).toBe('NGNT');
  });
});
