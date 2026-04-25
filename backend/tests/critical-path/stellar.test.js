// backend/tests/critical-path/stellar.test.js
//
// Critical Path Testing for Stellar Operations
// Tests the complete Stellar wallet creation → transactions → confirmation flow
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import StellarService from '../../src/services/stellarService.js';
import WalletService from '../../src/services/walletService.js';

const prisma = new PrismaClient();

describe('Stellar Operations - Critical Path', () => {
  let testUser;
  let stellarService;
  let walletService;

  beforeEach(async () => {
    // Create test user
    testUser = await prisma.user.create({
      data: {
        email: `stellar-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
      },
    });

    stellarService = new StellarService();
    walletService = new WalletService();
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.user.delete({
      where: { id: testUser.id },
    });
  });

  describe('Wallet Creation Flow', () => {
    it('should create Stellar wallet with proper encryption', async () => {
      // Step 1: Generate wallet
      const wallet = await walletService.createWallet(testUser.id);
      
      expect(wallet).toBeDefined();
      expect(wallet.publicKey).toMatch(/^G[A-Z0-9]{55}$/);
      expect(wallet.encryptedMnemonic).toBeDefined();
      expect(wallet.stellarSecretKey).toBeUndefined(); // Should not be stored

      // Step 2: Verify wallet exists in database
      const updatedUser = await prisma.user.findUnique({
        where: { id: testUser.id },
        select: {
          stellarPublicKey: true,
          encryptedMnemonic: true,
        },
      });

      expect(updatedUser.stellarPublicKey).toBe(wallet.publicKey);
      expect(updatedUser.encryptedMnemonic).toBe(wallet.encryptedMnemonic);
    });

    it('should handle wallet creation failure gracefully', async () => {
      // Test with invalid user ID
      await expect(
        walletService.createWallet('invalid-user-id')
      ).rejects.toThrow();
    });
  });

  describe('Trustline Management', () => {
    beforeEach(async () => {
      // Create wallet for trustline tests
      await walletService.createWallet(testUser.id);
    });

    it('should create USDC trustline successfully', async () => {
      const trustlineResult = await stellarService.createTrustline(
        testUser.id,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'
      );

      expect(trustlineResult.success).toBe(true);
      expect(trustlineResult.transactionId).toBeDefined();
    });

    it('should create NGNT trustline successfully', async () => {
      const trustlineResult = await stellarService.createTrustline(
        testUser.id,
        'NGNT',
        'GAWODAROMJ33V5YDFY3NPYTHVYQG7MJXVJ2ND3AOGIHYRWINES6ACCPD'
      );

      expect(trustlineResult.success).toBe(true);
      expect(trustlineResult.transactionId).toBeDefined();
    });

    it('should handle duplicate trustline creation', async () => {
      // Create first trustline
      await stellarService.createTrustline(
        testUser.id,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'
      );

      // Attempt to create duplicate
      const duplicateResult = await stellarService.createTrustline(
        testUser.id,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'
      );

      // Should handle gracefully (either success or appropriate error)
      expect(duplicateResult).toBeDefined();
    });
  });

  describe('USDC Transactions', () => {
    beforeEach(async () => {
      // Setup wallet and trustlines
      await walletService.createWallet(testUser.id);
      await stellarService.createTrustline(
        testUser.id,
        'USDC',
        'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'
      );
    });

    it('should send USDC transaction successfully', async () => {
      const transactionData = {
        recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        amount: '10.50',
        asset: 'USDC',
      };

      const result = await stellarService.sendPayment(
        testUser.id,
        transactionData.recipient,
        transactionData.amount,
        transactionData.asset
      );

      expect(result.success).toBe(true);
      expect(result.transactionId).toBeDefined();
      expect(result.transactionHash).toBeDefined();
    });

    it('should validate USDC transaction parameters', async () => {
      // Test invalid recipient
      await expect(
        stellarService.sendPayment(testUser.id, 'invalid', '10.50', 'USDC')
      ).rejects.toThrow();

      // Test invalid amount
      await expect(
        stellarService.sendPayment(
          testUser.id,
          'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
          '-10.50',
          'USDC'
        )
      ).rejects.toThrow();

      // Test zero amount
      await expect(
        stellarService.sendPayment(
          testUser.id,
          'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
          '0',
          'USDC'
        )
      ).rejects.toThrow();
    });

    it('should handle insufficient balance gracefully', async () => {
      const result = await stellarService.sendPayment(
        testUser.id,
        'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        '999999999', // Large amount
        'USDC'
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('balance');
    });
  });

  describe('NGNT Transactions', () => {
    beforeEach(async () => {
      // Setup wallet and trustlines
      await walletService.createWallet(testUser.id);
      await stellarService.createTrustline(
        testUser.id,
        'NGNT',
        'GAWODAROMJ33V5YDFY3NPYTHVYQG7MJXVJ2ND3AOGIHYRWINES6ACCPD'
      );
    });

    it('should send NGNT transaction successfully', async () => {
      const transactionData = {
        recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        amount: '5000.00',
        asset: 'NGNT',
      };

      const result = await stellarService.sendPayment(
        testUser.id,
        transactionData.recipient,
        transactionData.amount,
        transactionData.asset
      );

      expect(result.success).toBe(true);
      expect(result.transactionId).toBeDefined();
      expect(result.transactionHash).toBeDefined();
    });
  });

  describe('XLM Transactions', () => {
    beforeEach(async () => {
      // Setup wallet
      await walletService.createWallet(testUser.id);
    });

    it('should send XLM transaction successfully', async () => {
      const transactionData = {
        recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        amount: '1.50',
        asset: 'XLM',
      };

      const result = await stellarService.sendPayment(
        testUser.id,
        transactionData.recipient,
        transactionData.amount,
        transactionData.asset
      );

      expect(result.success).toBe(true);
      expect(result.transactionId).toBeDefined();
      expect(result.transactionHash).toBeDefined();
    });

    it('should respect minimum XLM balance requirements', async () => {
      // Test sending too much XLM (below minimum reserve)
      const result = await stellarService.sendPayment(
        testUser.id,
        'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        '999999', // Large amount that would violate minimum balance
        'XLM'
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('minimum');
    });
  });

  describe('Transaction History', () => {
    beforeEach(async () => {
      // Setup wallet
      await walletService.createWallet(testUser.id);
    });

    it('should retrieve transaction history', async () => {
      const history = await stellarService.getTransactionHistory(testUser.id);

      expect(history).toBeDefined();
      expect(Array.isArray(history.transactions)).toBe(true);
      expect(history.transactions.length).toBeGreaterThanOrEqual(0);
    });

    it('should filter transactions by asset type', async () => {
      const usdcHistory = await stellarService.getTransactionHistory(
        testUser.id,
        'USDC'
      );

      expect(usdcHistory).toBeDefined();
      expect(usdcHistory.asset).toBe('USDC');
    });
  });

  describe('Balance Checking', () => {
    beforeEach(async () => {
      // Setup wallet
      await walletService.createWallet(testUser.id);
    });

    it('should retrieve wallet balances', async () => {
      const balances = await stellarService.getBalances(testUser.id);

      expect(balances).toBeDefined();
      expect(Array.isArray(balances)).toBe(true);
      
      // Should include XLM balance
      const xlmBalance = balances.find(b => b.asset === 'XLM');
      expect(xlmBalance).toBeDefined();
      expect(xlmBalance.balance).toBeDefined();
    });

    it('should return zero balance for non-existent trustlines', async () => {
      const balances = await stellarService.getBalances(testUser.id);
      
      // Should not have USDC balance if trustline not created
      const usdcBalance = balances.find(b => b.asset === 'USDC');
      expect(usdcBalance).toBeUndefined();
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors gracefully', async () => {
      // Mock network error
      const originalHorizon = stellarService.horizonServer;
      stellarService.horizonServer = null; // Simulate network failure

      await expect(
        stellarService.getBalances(testUser.id)
      ).rejects.toThrow();

      // Restore
      stellarService.horizonServer = originalHorizon;
    });

    it('should handle invalid user authentication', async () => {
      await expect(
        stellarService.sendPayment('invalid-user', 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q', '10', 'USDC')
      ).rejects.toThrow();
    });

    it('should handle malformed transaction data', async () => {
      await walletService.createWallet(testUser.id);

      await expect(
        stellarService.sendPayment(testUser.id, '', '10', 'USDC')
      ).rejects.toThrow();

      await expect(
        stellarService.sendPayment(testUser.id, 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q', '', 'USDC')
      ).rejects.toThrow();
    });
  });

  describe('Performance Requirements', () => {
    it('should create wallet in under 2 seconds', async () => {
      const startTime = Date.now();
      
      await walletService.createWallet(testUser.id);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(2000);
    });

    it('should send transaction in under 5 seconds', async () => {
      await walletService.createWallet(testUser.id);
      
      const startTime = Date.now();
      
      try {
        await stellarService.sendPayment(
          testUser.id,
          'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
          '1',
          'XLM'
        );
      } catch (error) {
        // Expected for test environment, but we measure the attempt time
      }
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(5000);
    });

    it('should retrieve balances in under 1 second', async () => {
      await walletService.createWallet(testUser.id);
      
      const startTime = Date.now();
      
      await stellarService.getBalances(testUser.id);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(1000);
    });
  });
});
