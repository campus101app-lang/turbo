import express from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const state = {
  workflows: [],
  invoices: [{ id: 'inv_1', userId: 'u1' }],
  expenses: [{ id: 'exp_1', submittedById: 'u1' }],
  requests: [{ id: 'req_1', userId: 'u1' }],
};

vi.mock('@prisma/client', () => {
  class PrismaClient {
    constructor() {
      this.workflow = {
        create: vi.fn(async ({ data }) => {
          const row = { id: `w_${state.workflows.length + 1}`, ...data };
          state.workflows.push(row);
          return row;
        }),
        findMany: vi.fn(async ({ where }) => state.workflows.filter((w) => w.userId === where.userId)),
        findFirst: vi.fn(async ({ where }) => state.workflows.find((w) => w.id === where.id && w.userId === where.userId) || null),
        update: vi.fn(async ({ where, data }) => {
          const idx = state.workflows.findIndex((w) => w.id === where.id);
          if (idx < 0) return null;
          state.workflows[idx] = { ...state.workflows[idx], ...data };
          return state.workflows[idx];
        }),
      };
      this.invoice = {
        findFirst: vi.fn(async ({ where }) => state.invoices.find((i) => i.id === where.id && i.userId === where.userId) || null),
      };
      this.expense = {
        findFirst: vi.fn(async ({ where }) => state.expenses.find((e) => e.id === where.id && e.submittedById === where.submittedById) || null),
      };
      this.paymentRequest = {
        findFirst: vi.fn(async ({ where }) => state.requests.find((r) => r.id === where.id && r.userId === where.userId) || null),
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

vi.mock('../../src/services/walletService.js', () => ({
  sendAsset: vi.fn(async (_fromUserId, _to, amount, asset) => ({
    hash: 'workflow_send_hash',
    amount,
    asset,
  })),
}));

import workflowsRoutes from '../../src/routes/workflows.js';

describe('workflows routes', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/workflows', workflowsRoutes);

  beforeEach(() => {
    state.workflows.length = 0;
  });

  it('rejects still-blocked action on create', async () => {
    const res = await request(app).post('/api/workflows').send({
      name: 'auto invoice',
      triggerType: 'manualRun',
      triggerConfig: {},
      actionType: 'createInvoice',
      actionConfig: { title: 'x', amount: 10, currency: 'USDC' },
    });
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('UNSUPPORTED_ACTION');
  });

  it('creates supported workflow with valid action config', async () => {
    const res = await request(app).post('/api/workflows').send({
      name: 'notify',
      triggerType: 'manualRun',
      triggerConfig: {},
      actionType: 'notifyUser',
      actionConfig: { message: 'hello' },
    });
    expect(res.status).toBe(201);
    expect(res.body.workflow.actionType).toBe('notifyUser');
  });

  it('runs sendPayment workflow successfully', async () => {
    state.workflows.push({
      id: 'w1',
      userId: 'u1',
      name: 'auto pay',
      status: 'active',
      triggerType: 'manualRun',
      triggerConfig: {},
      actionType: 'sendPayment',
      actionConfig: { to: 'alice', amount: 12.5, asset: 'USDC' },
    });
    const res = await request(app).post('/api/workflows/w1/run').send({});
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.result.action).toBe('sendPayment');
  });
});
