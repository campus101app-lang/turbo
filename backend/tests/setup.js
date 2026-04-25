// backend/tests/setup.js
//
// Test Setup Configuration
// Configures test environment, database connections, and global test utilities
//

import { beforeAll, afterAll, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';

// Test database configuration
const TEST_DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgresql://test:test@localhost:5433/dayfi_test';

// Global test database instance
let testPrisma;

// Setup test environment
beforeAll(async () => {
  // Set test database URL
  process.env.DATABASE_URL = TEST_DATABASE_URL;
  
  // Initialize test database client
  testPrisma = new PrismaClient({
    datasources: {
      db: {
        url: TEST_DATABASE_URL,
      },
    },
  });

  // Reset test database
  try {
    // Drop and recreate test database schema
    execSync('npx prisma db push --force-reset', {
      env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
      stdio: 'inherit',
    });
  } catch (error) {
    console.warn('Database reset failed, continuing with existing schema:', error.message);
  }

  // Run migrations
  try {
    execSync('npx prisma db push', {
      env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
      stdio: 'inherit',
    });
  } catch (error) {
    console.warn('Migration failed:', error.message);
  }

  // Seed test data
  await seedTestData();
});

// Cleanup after all tests
afterAll(async () => {
  await testPrisma.$disconnect();
});

// Cleanup before each test
beforeEach(async () => {
  // Clear test data between tests
  await clearTestData();
});

// Global test utilities
export const createTestUser = async (overrides = {}) => {
  const defaultUser = {
    email: `test-${Date.now()}@example.com`,
    isVerified: true,
    accountType: 'INDIVIDUAL',
    fullName: 'Test User',
    phone: '+2348012345678',
    bvn: '12345678901',
    ...overrides,
  };

  return await testPrisma.user.create({
    data: defaultUser,
  });
};

export const createTestOrganization = async (userId, overrides = {}) => {
  const defaultOrg = {
    name: 'Test Organization',
    description: 'Test Description',
    businessType: 'LIMITED_LIABILITY',
    ownerUserId: userId,
    ...overrides,
  };

  return await testPrisma.organization.create({
    data: defaultOrg,
  });
};

export const createTestTransaction = async (userId, overrides = {}) => {
  const defaultTransaction = {
    userId,
    type: 'payment',
    amount: '100.00',
    currency: 'NGN',
    status: 'pending',
    ...overrides,
  };

  return await testPrisma.transaction.create({
    data: defaultTransaction,
  });
};

export const createTestInvoice = async (userId, overrides = {}) => {
  const defaultInvoice = {
    userId,
    customerEmail: 'customer@example.com',
    amount: '50000.00',
    currency: 'NGN',
    dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    status: 'pending',
    ...overrides,
  };

  return await testPrisma.invoice.create({
    data: defaultInvoice,
  });
};

// Helper functions
async function seedTestData() {
  // Create test system data
  try {
    // Create system wallet if it doesn't exist
    const systemWallet = await testPrisma.user.findFirst({
      where: { email: 'system@dayfi.com' },
    });

    if (!systemWallet) {
      await testPrisma.user.create({
        data: {
          email: 'system@dayfi.com',
          isVerified: true,
          accountType: 'OTHER_ENTITY',
          fullName: 'DayFi System',
          stellarPublicKey: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        },
      });
    }
  } catch (error) {
    console.warn('Failed to seed test data:', error.message);
  }
}

async function clearTestData() {
  // Clear all test data while preserving system data
  const tablesToClear = [
    'Transaction',
    'Invoice',
    'Payment',
    'Expense',
    'Organization',
    'AuditLog',
    'User',
  ];

  for (const table of tablesToClear) {
    try {
      await testPrisma.$executeRawUnsafe(
        `DELETE FROM "${table}" WHERE email NOT LIKE '%@dayfi.com'`
      );
    } catch (error) {
      // Table might not exist or be empty
      console.warn(`Failed to clear table ${table}:`, error.message);
    }
  }
}

// Mock external services
export const mockStellarService = {
  createWallet: jest.fn(() => ({
    publicKey: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
    encryptedMnemonic: 'encrypted_mnemonic',
  })),
  sendPayment: jest.fn(() => ({
    success: true,
    transactionId: 'tx_123',
    transactionHash: 'hash_123',
  })),
  getBalances: jest.fn(() => [
    { asset: 'XLM', balance: '1000.0000000' },
    { asset: 'USDC', balance: '500.0000000' },
    { asset: 'NGNT', balance: '100000.0000000' },
  ]),
  createTrustline: jest.fn(() => ({
    success: true,
    transactionId: 'trustline_123',
  })),
};

export const mockFlutterwaveService = {
  createVirtualAccount: jest.fn(() => ({
    success: true,
    accountNumber: '1234567890',
    bankName: 'Test Bank',
    flutterwaveReference: 'FLW_REF_123',
  })),
  processWithdrawal: jest.fn(() => ({
    success: true,
    flutterwaveReference: 'FLW_WITHDRAW_123',
    transactionId: 'withdraw_123',
  })),
  convertNGNtoNGNT: jest.fn(() => ({
    success: true,
    ngntAmount: '50000.00',
    rate: 1.0,
  })),
};

export const mockFraudDetection = {
  analyzeActivity: jest.fn(() => 25), // Low risk score
  shouldBlockTransaction: jest.fn(() => false),
};

export const mockAuthService = {
  sendOtp: jest.fn(() => ({
    success: true,
    isNewUser: true,
    message: 'OTP sent',
  })),
  verifyOtp: jest.fn(() => ({
    success: true,
    token: 'jwt_token',
    step: 'complete',
  })),
  generateToken: jest.fn(() => 'jwt_token'),
  validateToken: jest.fn(() => true),
};

export const mockAuditLogger = {
  log: jest.fn(),
  getLogs: jest.fn(() => []),
};

// Test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_jwt_secret_key_for_testing_only';
process.env.STELLAR_NETWORK = 'testnet';
process.env.FLUTTERWAVE_SECRET_KEY = 'test_flutterwave_secret';
process.env.FLUTTERWAVE_PUBLIC_KEY = 'test_flutterwave_public';

// Global test timeout
process.env.TEST_TIMEOUT = '30000';

// Export test database client for use in tests
export { testPrisma as prisma };
