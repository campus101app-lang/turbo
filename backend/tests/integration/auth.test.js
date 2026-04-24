import express from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const mockDb = {
  users: [],
};

vi.mock('@prisma/client', () => {
  class PrismaClient {
    constructor() {
      this.user = {
        findUnique: vi.fn(async ({ where }) => {
          if (where.email) return mockDb.users.find((u) => u.email === where.email) || null;
          if (where.id) return mockDb.users.find((u) => u.id === where.id) || null;
          return null;
        }),
        create: vi.fn(async ({ data }) => {
          const row = { id: `u_${mockDb.users.length + 1}`, ...data, isBackedUp: false };
          mockDb.users.push(row);
          return row;
        }),
        update: vi.fn(async ({ where, data }) => {
          const idx = mockDb.users.findIndex((u) => u.email === where.email || u.id === where.id);
          if (idx < 0) return null;
          mockDb.users[idx] = { ...mockDb.users[idx], ...data };
          return mockDb.users[idx];
        }),
      };
    }
  }
  return { PrismaClient };
});

vi.mock('../../src/services/emailService.js', () => ({
  sendOTP: vi.fn(async () => {}),
  sendWelcomeEmail: vi.fn(async () => {}),
}));

vi.mock('../../src/services/walletService.js', () => ({
  createStellarWallet: vi.fn(async () => ({
    publicKey: 'GTESTPUBLICKEY',
    encryptedSecretKey: 'secret',
    encryptedMnemonic: 'mnemonic',
  })),
  getMnemonic: vi.fn(async () => 'one two three'),
  markAsBackedUp: vi.fn(async () => {}),
  fundNewUserWallet: vi.fn(async () => {}),
  addAllTrustlines: vi.fn(async () => {}),
  setupUserTrustlines: vi.fn(async () => {}),
}));

import authRoutes from '../../src/routes/auth.js';

describe('auth routes', () => {
  const app = express();
  app.use(express.json());
  app.use('/api/auth', authRoutes);

  beforeEach(() => {
    mockDb.users.length = 0;
    process.env.JWT_SECRET = 'test-secret';
    process.env.NODE_ENV = 'test';
  });

  it('sends OTP and returns success', async () => {
    const res = await request(app).post('/api/auth/send-otp').send({ email: 'test@example.com' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('rejects wrong OTP with 400', async () => {
    mockDb.users.push({
      id: 'u1',
      email: 'test@example.com',
      otpCode: '123456',
      otpAttempts: 0,
      otpExpiry: new Date(Date.now() + 600000),
      username: 'user_1',
      stellarPublicKey: null,
      isBackedUp: false,
    });
    const res = await request(app).post('/api/auth/verify-otp').send({
      email: 'test@example.com',
      otp: '654321',
    });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Invalid code.');
  });
});
