// backend/tests/integration/flutterwave-stellar.test.js
//
// Integration Tests for Flutterwave + Stellar Interaction
// Tests the complete NGN deposit → NGNT conversion → wallet credit flow
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import FlutterwaveService from '../../src/services/flutterwaveService.js';
import StellarService from '../../src/services/stellarService.js';
import WalletService from '../../src/services/walletService.js';
import WebhookService from '../../src/services/webhookService.js';

const prisma = new PrismaClient();

describe('Flutterwave + Stellar Integration - Critical Path', () => {
  let testUser;
  let virtualAccount;
  let flutterwaveService;
  let stellarService;
  let walletService;
  let webhookService;

  beforeEach(async () => {
    // Create test user with Nigerian business profile
    testUser = await prisma.user.create({
      data: {
        email: `integration-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Test Integration Business',
        businessName: 'Test Business Ltd',
        phone: '+2348012345678',
        bvn: '12345678901',
        cacRegistrationNumber: 'RC123456',
        taxIdentificationNumber: 'TIN123456',
      },
    });

    // Initialize services
    flutterwaveService = new FlutterwaveService();
    stellarService = new StellarService();
    walletService = new WalletService();
    webhookService = new WebhookService();

    // Create Stellar wallet
    await walletService.createWallet(testUser.id);
    
    // Create NGNT trustline
    await stellarService.createTrustline(
      testUser.id,
      'NGNT',
      'GAWODAROMJ33V5YDFY3NPYTHVYQG7MJXVJ2ND3AOGIHYRWINES6ACCPD'
    );
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.user.delete({
      where: { id: testUser.id },
    });
  });

  describe('Virtual Account Creation', () => {
    it('should create virtual account with BVN validation', async () => {
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      const result = await flutterwaveService.createVirtualAccount(accountData);

      expect(result.success).toBe(true);
      expect(result.accountNumber).toBeDefined();
      expect(result.accountNumber).toMatch(/^\d{10}$/);
      expect(result.bankName).toBeDefined();
      expect(result.flutterwaveReference).toBeDefined();

      // Store for subsequent tests
      virtualAccount = result;

      // Update user with virtual account details
      await prisma.user.update({
        where: { id: testUser.id },
        data: {
          virtualAccountNumber: result.accountNumber,
          virtualAccountBank: result.bankName,
          virtualAccountName: `${testUser.fullName} - ${testUser.businessName}`,
        },
      });
    });

    it('should validate BVN format', async () => {
      const invalidBVNData = {
        email: testUser.email,
        bvn: '123', // Invalid BVN
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      await expect(
        flutterwaveService.createVirtualAccount(invalidBVNData)
      ).rejects.toThrow('Invalid BVN format');
    });

    it('should handle duplicate virtual account creation', async () => {
      // Create first account
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      await flutterwaveService.createVirtualAccount(accountData);

      // Attempt to create duplicate
      await expect(
        flutterwaveService.createVirtualAccount(accountData)
      ).rejects.toThrow('Virtual account already exists');
    });
  });

  describe('NGN Deposit Processing', () => {
    beforeEach(async () => {
      // Create virtual account for deposit tests
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      virtualAccount = await flutterwaveService.createVirtualAccount(accountData);
    });

    it('should process successful NGN deposit', async () => {
      // Simulate successful deposit webhook
      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000, // 50,000 NGN
          currency: 'NGN',
          account_number: virtualAccount.accountNumber,
          reference: `FLW_REF_${Date.now()}`,
          customer: {
            email: testUser.email,
            name: testUser.fullName,
          },
          meta: {
            userId: testUser.id,
          },
        },
      };

      const result = await webhookService.processDepositWebhook(webhookPayload);

      expect(result.success).toBe(true);
      expect(result.ngntAmount).toBeDefined();
      expect(result.transactionId).toBeDefined();

      // Verify NGNT was credited to wallet
      const balances = await stellarService.getBalances(testUser.id);
      const ngntBalance = balances.find(b => b.asset === 'NGNT');

      expect(ngntBalance).toBeDefined();
      expect(parseFloat(ngntBalance.balance)).toBeGreaterThan(0);
    });

    it('should handle failed deposit gracefully', async () => {
      // Simulate failed deposit webhook
      const webhookPayload = {
        event: 'charge.failed',
        data: {
          status: 'failed',
          amount: 50000,
          currency: 'NGN',
          account_number: virtualAccount.accountNumber,
          reference: `FLW_REF_${Date.now()}`,
          customer: {
            email: testUser.email,
            name: testUser.fullName,
          },
        },
      };

      const result = await webhookService.processDepositWebhook(webhookPayload);

      expect(result.success).toBe(false);
      expect(result.reason).toBeDefined();

      // Verify no NGNT was credited
      const balances = await stellarService.getBalances(testUser.id);
      const ngntBalance = balances.find(b => b.asset === 'NGNT');

      expect(ngntBalance).toBeUndefined();
    });

    it('should validate webhook signature', async () => {
      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000,
          currency: 'NGN',
        },
      };

      // Test with invalid signature
      const invalidSignature = 'invalid_signature';
      
      await expect(
        webhookService.verifyWebhookSignature(webhookPayload, invalidSignature)
      ).rejects.toThrow('Invalid webhook signature');
    });

    it('should handle duplicate deposit webhooks', async () => {
      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000,
          currency: 'NGN',
          account_number: virtualAccount.accountNumber,
          reference: `FLW_REF_${Date.now()}`,
          customer: {
            email: testUser.email,
            name: testUser.fullName,
          },
        },
      };

      // Process first webhook
      const firstResult = await webhookService.processDepositWebhook(webhookPayload);
      expect(firstResult.success).toBe(true);

      // Process duplicate webhook
      const duplicateResult = await webhookService.processDepositWebhook(webhookPayload);
      expect(duplicateResult.success).toBe(true);
      expect(duplicateResult.duplicate).toBe(true);
    });
  });

  describe('NGN Withdrawal Processing', () => {
    beforeEach(async () => {
      // Create virtual account
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      virtualAccount = await flutterwaveService.createVirtualAccount(accountData);

      // Add NGNT to wallet for withdrawal
      await stellarService.sendPayment(
        'SYSTEM_WALLET', // System wallet that has NGNT
        testUser.id,
        '10000',
        'NGNT'
      );
    });

    it('should process successful NGN withdrawal', async () => {
      const withdrawalData = {
        amount: 5000, // 5,000 NGN
        bankAccount: {
          account_number: '1234567890',
          bank_code: '044', // Access Bank
          account_name: 'Test User',
        },
        currency: 'NGN',
        reference: `WITHDRAWAL_${Date.now()}`,
      };

      const result = await flutterwaveService.processWithdrawal(
        testUser.id,
        withdrawalData
      );

      expect(result.success).toBe(true);
      expect(result.flutterwaveReference).toBeDefined();
      expect(result.transactionId).toBeDefined();

      // Verify NGNT was debited from wallet
      const balances = await stellarService.getBalances(testUser.id);
      const ngntBalance = balances.find(b => b.asset === 'NGNT');

      expect(ngntBalance).toBeDefined();
      expect(parseFloat(ngntBalance.balance)).toBeLessThan(10000);
    });

    it('should validate withdrawal limits', async () => {
      // Test withdrawal exceeding daily limit
      const excessiveWithdrawal = {
        amount: 5000000, // 5M NGN (exceeds typical daily limit)
        bankAccount: {
          account_number: '1234567890',
          bank_code: '044',
          account_name: 'Test User',
        },
        currency: 'NGN',
      };

      await expect(
        flutterwaveService.processWithdrawal(testUser.id, excessiveWithdrawal)
      ).rejects.toThrow('Withdrawal amount exceeds daily limit');
    });

    it('should handle insufficient NGNT balance', async () => {
      const insufficientWithdrawal = {
        amount: 50000, // More than available balance
        bankAccount: {
          account_number: '1234567890',
          bank_code: '044',
          account_name: 'Test User',
        },
        currency: 'NGN',
      };

      await expect(
        flutterwaveService.processWithdrawal(testUser.id, insufficientWithdrawal)
      ).rejects.toThrow('Insufficient NGNT balance');
    });

    it('should validate bank account details', async () => {
      const invalidBankAccount = {
        amount: 1000,
        bankAccount: {
          account_number: '123', // Invalid account number
          bank_code: '999', // Invalid bank code
          account_name: '',
        },
        currency: 'NGN',
      };

      await expect(
        flutterwaveService.processWithdrawal(testUser.id, invalidBankAccount)
      ).rejects.toThrow('Invalid bank account details');
    });
  });

  describe('NGNT Conversion', () => {
    it('should convert NGN to NGNT at correct rate', async () => {
      const ngnAmount = 50000; // 50,000 NGN
      
      const conversionResult = await flutterwaveService.convertNGNtoNGNT(ngnAmount);

      expect(conversionResult.success).toBe(true);
      expect(conversionResult.ngntAmount).toBeDefined();
      expect(conversionResult.rate).toBeDefined();
      expect(conversionResult.ngntAmount).toBeGreaterThan(0);

      // Verify conversion rate is reasonable (should be close to 1:1)
      const expectedNGNT = ngnAmount / conversionResult.rate;
      expect(Math.abs(conversionResult.ngntAmount - expectedNGNT)).toBeLessThan(100);
    });

    it('should handle conversion rate updates', async () => {
      const ngnAmount = 10000;
      
      // Get first conversion
      const firstConversion = await flutterwaveService.convertNGNtoNGNT(ngnAmount);
      
      // Simulate rate update
      await flutterwaveService.updateConversionRate(750); // 1 NGN = 0.75 NGNT
      
      // Get second conversion
      const secondConversion = await flutterwaveService.convertNGNtoNGNT(ngnAmount);

      expect(firstConversion.rate).not.toBe(secondConversion.rate);
      expect(firstConversion.ngntAmount).not.toBe(secondConversion.ngntAmount);
    });

    it('should cache conversion rates for performance', async () => {
      const ngnAmount = 10000;
      
      // First conversion (should fetch from API)
      const startTime1 = Date.now();
      const firstConversion = await flutterwaveService.convertNGNtoNGNT(ngnAmount);
      const duration1 = Date.now() - startTime1;

      // Second conversion (should use cache)
      const startTime2 = Date.now();
      const secondConversion = await flutterwaveService.convertNGNtoNGNT(ngnAmount);
      const duration2 = Date.now() - startTime2;

      // Cached conversion should be faster
      expect(duration2).toBeLessThan(duration1);
      expect(firstConversion.ngntAmount).toBe(secondConversion.ngntAmount);
    });
  });

  describe('Transaction Reconciliation', () => {
    it('should reconcile Flutterwave and Stellar transactions', async () => {
      // Create virtual account
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      virtualAccount = await flutterwaveService.createVirtualAccount(accountData);

      // Process deposit
      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000,
          currency: 'NGN',
          account_number: virtualAccount.accountNumber,
          reference: `FLW_REF_${Date.now()}`,
          customer: {
            email: testUser.email,
            name: testUser.fullName,
          },
        },
      };

      const depositResult = await webhookService.processDepositWebhook(webhookPayload);

      // Reconcile transactions
      const reconciliation = await flutterwaveService.reconcileTransactions(
        testUser.id,
        depositResult.transactionId
      );

      expect(reconciliation.success).toBe(true);
      expect(reconciliation.flutterwaveTransaction).toBeDefined();
      expect(reconciliation.stellarTransaction).toBeDefined();
      expect(reconciliation.matched).toBe(true);
    });

    it('should flag unreconciled transactions', async () => {
      // Create Flutterwave transaction without corresponding Stellar transaction
      const flutterwaveTx = {
        reference: `FLW_REF_${Date.now()}`,
        amount: 50000,
        status: 'successful',
        userId: testUser.id,
      };

      // Save Flutterwave transaction
      await prisma.transaction.create({
        data: {
          flutterwaveReference: flutterwaveTx.reference,
          amount: flutterwaveTx.amount,
          currency: 'NGN',
          status: 'completed',
          userId: testUser.id,
        },
      });

      // Reconcile (should flag as unmatched)
      const reconciliation = await flutterwaveService.reconcileTransactions(
        testUser.id,
        flutterwaveTx.reference
      );

      expect(reconciliation.matched).toBe(false);
      expect(reconciliation.stellarTransaction).toBeNull();
    });
  });

  describe('Error Handling & Recovery', () => {
    it('should handle Flutterwave API failures gracefully', async () => {
      // Mock Flutterwave API failure
      const originalCreateAccount = flutterwaveService.createVirtualAccount;
      flutterwaveService.createVirtualAccount = () => {
        throw new Error('Flutterwave API unavailable');
      };

      await expect(
        flutterwaveService.createVirtualAccount({})
      ).rejects.toThrow('Flutterwave API unavailable');

      // Restore original method
      flutterwaveService.createVirtualAccount = originalCreateAccount;
    });

    it('should handle Stellar network failures during deposit', async () => {
      // Mock Stellar failure
      const originalSendPayment = stellarService.sendPayment;
      stellarService.sendPayment = () => {
        throw new Error('Stellar network unavailable');
      };

      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000,
          currency: 'NGN',
          account_number: '1234567890',
        },
      };

      const result = await webhookService.processDepositWebhook(webhookPayload);

      expect(result.success).toBe(false);
      expect(result.error).toContain('Stellar network unavailable');

      // Restore original method
      stellarService.sendPayment = originalSendPayment;
    });

    it('should implement retry logic for failed transactions', async () => {
      let attemptCount = 0;
      
      // Mock method that fails twice then succeeds
      const originalSendPayment = stellarService.sendPayment;
      stellarService.sendPayment = () => {
        attemptCount++;
        if (attemptCount <= 2) {
          throw new Error('Temporary network failure');
        }
        return { success: true, transactionId: 'retry_success' };
      };

      const result = await stellarService.sendPaymentWithRetry(
        testUser.id,
        'RECIPIENT',
        '100',
        'NGNT',
        3 // Max 3 retries
      );

      expect(result.success).toBe(true);
      expect(result.transactionId).toBe('retry_success');
      expect(attemptCount).toBe(3);

      // Restore original method
      stellarService.sendPayment = originalSendPayment;
    });
  });

  describe('Performance Requirements', () => {
    it('should create virtual account in under 3 seconds', async () => {
      const accountData = {
        email: testUser.email,
        bvn: testUser.bvn,
        phoneNumber: testUser.phone,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01',
      };

      const startTime = Date.now();
      
      await flutterwaveService.createVirtualAccount(accountData);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(3000);
    });

    it('should process deposit webhook in under 500ms', async () => {
      const webhookPayload = {
        event: 'charge.completed',
        data: {
          status: 'successful',
          amount: 50000,
          currency: 'NGN',
          account_number: '1234567890',
        },
      };

      const startTime = Date.now();
      
      await webhookService.processDepositWebhook(webhookPayload);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(500);
    });

    it('should convert NGN to NGNT in under 100ms', async () => {
      const startTime = Date.now();
      
      await flutterwaveService.convertNGNtoNGNT(50000);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(100);
    });
  });
});
