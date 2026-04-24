import express from 'express';
import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';

vi.mock('../../src/services/walletService.js', () => ({
  ISSUERS: { USDC: 'GUSDC', NGNT: 'GNGNT', XLM: 'native' },
  SUPPORTED_ASSETS: ['USDC', 'NGNT', 'XLM'],
  getWalletBalances: vi.fn(async () => ({ USDC: 10, XLM: 2, NGNT: 0 })),
  sendAsset: vi.fn(async () => ({ hash: 'tx_hash' })),
  swapAssets: vi.fn(async () => ({ hash: 'swap_hash' })),
  getStellarTransactions: vi.fn(async () => []),
  resolveUsername: vi.fn(async () => null),
  sendFromMasterWallet: vi.fn(async () => ({ hash: 'master_hash' })),
  syncBlockchainTransactions: vi.fn(async () => ({ synced: 0 })),
}));

vi.mock('../../src/middleware/auth.js', () => ({
  authenticate: (req, _res, next) => {
    req.user = { id: 'u1', email: 'u1@example.com', username: 'u1', stellarPublicKey: 'GUSER' };
    next();
  },
  requireManager: (_req, _res, next) => next(),
}));

import walletRoutes from '../../src/routes/wallet.js';

describe('wallet routes', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/wallet', walletRoutes);

  it('rejects missing swap quote params', async () => {
    const res = await request(app).get('/api/wallet/swap-quote');
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('VALIDATION_ERROR');
  });

  it('sends funds with valid payload', async () => {
    const res = await request(app).post('/api/wallet/send').send({
      to: 'alice',
      amount: 1.25,
      asset: 'USDC',
    });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
