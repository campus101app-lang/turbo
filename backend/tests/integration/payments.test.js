import express from 'express';
import request from 'supertest';
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

process.env.FLUTTERWAVE_WEBHOOK_HASH = 'secret-hash';
process.env.AUTO_SETTLE_NGNT_TOPUPS = 'true';

const state = {
  users: [{ id: 'u1', virtualAccountNumber: '1234567890', stellarPublicKey: 'GUSER' }],
  flwPayments: [],
  transactions: [],
  settled: [],
};

vi.mock('@prisma/client', () => {
  class PrismaClient {
    constructor() {
      this.user = {
        findUnique: vi.fn(async ({ where, select }) => {
          const user = state.users.find((u) => u.id === where.id) || null;
          if (!user) return null;
          if (!select) return user;
          const out = {};
          for (const key of Object.keys(select)) out[key] = user[key] ?? null;
          return out;
        }),
        findFirst: vi.fn(async ({ where, select }) => {
          const user = state.users.find((u) => u.virtualAccountNumber === where.virtualAccountNumber) || null;
          if (!user) return null;
          if (!select) return user;
          const out = {};
          for (const key of Object.keys(select)) out[key] = user[key] ?? null;
          return out;
        }),
      };
      this.flutterwavePayment = {
        findUnique: vi.fn(async ({ where }) => state.flwPayments.find((p) => p.txRef === where.txRef) || null),
        upsert: vi.fn(async ({ where, create, update }) => {
          const idx = state.flwPayments.findIndex((p) => p.txRef === where.txRef);
          if (idx < 0) {
            const row = { id: `flw_${state.flwPayments.length + 1}`, ...create };
            state.flwPayments.push(row);
            return row;
          }
          state.flwPayments[idx] = { ...state.flwPayments[idx], ...update };
          return state.flwPayments[idx];
        }),
      };
      this.transaction = {
        findFirst: vi.fn(async ({ where }) => {
          return (
            state.transactions.find((t) =>
              Object.entries(where).every(([k, v]) => t[k] === v),
            ) || null
          );
        }),
        create: vi.fn(async ({ data }) => {
          const row = { id: `tx_${state.transactions.length + 1}`, ...data };
          state.transactions.push(row);
          return row;
        }),
        update: vi.fn(async ({ where, data }) => {
          const idx = state.transactions.findIndex((t) => t.id === where.id);
          if (idx < 0) return null;
          state.transactions[idx] = { ...state.transactions[idx], ...data };
          return state.transactions[idx];
        }),
      };
    }
  }
  return { PrismaClient };
});

vi.mock('../../src/middleware/auth.js', () => ({
  authenticate: (req, _res, next) => {
    req.user = { id: 'u1', email: 'u1@example.com', username: 'u1' };
    next();
  },
}));

vi.mock('../../src/services/walletService.js', () => ({
  sendAssetFromMasterWallet: vi.fn(async (address, amount, asset) => {
    state.settled.push({ address, amount, asset });
    return { hash: `h_${state.settled.length}`, amount, asset };
  }),
}));

let paymentsRoutes;

describe('payments webhook', () => {
  const app = express();
  app.use(express.json());

  beforeAll(async () => {
    const mod = await import('../../src/routes/payments.js');
    paymentsRoutes = mod.default;
    app.use('/api/payments', paymentsRoutes);
  });

  beforeEach(() => {
    state.flwPayments.length = 0;
    state.transactions.length = 0;
    state.settled.length = 0;
  });

  it('processes webhook idempotently and settles once', async () => {
    const payload = {
      event: 'charge.completed',
      data: {
        tx_ref: 'txr_123',
        status: 'successful',
        amount: 1500,
        currency: 'NGN',
        account_number: '1234567890',
      },
    };
    const call1 = await request(app)
      .post('/api/payments/flutterwave/webhook')
      .set('verif-hash', 'secret-hash')
      .send(payload);
    const call2 = await request(app)
      .post('/api/payments/flutterwave/webhook')
      .set('verif-hash', 'secret-hash')
      .send(payload);

    expect(call1.status).toBe(200);
    expect(call2.status).toBe(200);
    expect(state.flwPayments.length).toBe(1);
    expect(
      state.transactions.filter((t) => t.type === 'fiatDeposit' && t.flutterwaveRef === 'txr_123').length,
    ).toBe(1);
    expect(state.settled.length).toBe(1);
  });
});
