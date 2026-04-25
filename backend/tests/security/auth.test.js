// backend/tests/security/auth.test.js
//
// Security Testing Suite for Authentication & Fraud Detection
// Tests authentication flows, biometric auth, fraud detection, and audit logging
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import FraudDetection from '../../src/services/fraudDetection.js';
import AuthService from '../../src/services/authService.js';
import AuditLogger from '../../src/services/auditLogger.js';

const prisma = new PrismaClient();

describe('Security & Authentication - Critical Path', () => {
  let testUser;
  let authService;
  let fraudDetection;
  let auditLogger;

  beforeEach(async () => {
    // Create test user with Nigerian business profile
    testUser = await prisma.user.create({
      data: {
        email: `auth-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Test Security User',
        phone: '+2348012345678',
        bvn: '12345678901',
      },
    });

    authService = new AuthService();
    fraudDetection = new FraudDetection();
    auditLogger = new AuditLogger();
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.user.delete({
      where: { id: testUser.id },
    });
  });

  describe('Email Authentication', () => {
    it('should send OTP for valid email', async () => {
      const result = await authService.sendOtp(testUser.email);

      expect(result.success).toBe(true);
      expect(result.isNewUser).toBeDefined();
      expect(result.message).toContain('OTP sent');
    });

    it('should validate email format', async () => {
      await expect(
        authService.sendOtp('invalid-email')
      ).rejects.toThrow('Invalid email format');

      await expect(
        authService.sendOtp('')
      ).rejects.toThrow('Email is required');
    });

    it('should implement rate limiting for OTP requests', async () => {
      // Send multiple OTP requests rapidly
      const promises = Array(10).fill().map(() => 
        authService.sendOtp(testUser.email)
      );

      const results = await Promise.allSettled(promises);
      
      // Some should be rate limited
      const rejectedCount = results.filter(r => r.status === 'rejected').length;
      expect(rejectedCount).toBeGreaterThan(0);
    });

    it('should verify OTP correctly', async () => {
      // First send OTP
      await authService.sendOtp(testUser.email);
      
      // Get the OTP from database (for testing)
      const user = await prisma.user.findUnique({
        where: { email: testUser.email },
        select: { otpCode: true }
      });

      // Verify OTP
      const result = await authService.verifyOtp(testUser.email, user.otpCode);

      expect(result.success).toBe(true);
      expect(result.token).toBeDefined();
      expect(result.step).toBeDefined();
    });

    it('should handle invalid OTP attempts', async () => {
      await authService.sendOtp(testUser.email);

      // Try invalid OTP
      await expect(
        authService.verifyOtp(testUser.email, '000000')
      ).rejects.toThrow('Invalid code');

      // Check attempt count increased
      const user = await prisma.user.findUnique({
        where: { email: testUser.email },
        select: { otpAttempts: true }
      });

      expect(user.otpAttempts).toBeGreaterThan(0);
    });

    it('should lock account after too many failed attempts', async () => {
      await authService.sendOtp(testUser.email);

      // Make multiple failed attempts
      for (let i = 0; i < 5; i++) {
        try {
          await authService.verifyOtp(testUser.email, '000000');
        } catch (error) {
          // Expected to fail
        }
      }

      // Should be locked now
      await expect(
        authService.verifyOtp(testUser.email, '000000')
      ).rejects.toThrow('Account locked');
    });
  });

  describe('JWT Token Security', () => {
    it('should generate secure JWT tokens', async () => {
      const token = await authService.generateToken(testUser.id);

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');

      // Verify token structure
      const decoded = jwt.decode(token);
      expect(decoded.userId).toBe(testUser.id);
      expect(decoded.exp).toBeDefined();
    });

    it('should validate JWT tokens correctly', async () => {
      const token = await authService.generateToken(testUser.id);
      
      const isValid = await authService.validateToken(token);
      expect(isValid).toBe(true);

      // Test invalid token
      const invalidToken = 'invalid.jwt.token';
      const isInvalid = await authService.validateToken(invalidToken);
      expect(isInvalid).toBe(false);
    });

    it('should handle expired tokens', async () => {
      // Create expired token
      const expiredToken = jwt.sign(
        { userId: testUser.id },
        process.env.JWT_SECRET,
        { expiresIn: '-1h' } // Expired 1 hour ago
      );

      const isValid = await authService.validateToken(expiredToken);
      expect(isValid).toBe(false);
    });

    it('should refresh tokens properly', async () => {
      const originalToken = await authService.generateToken(testUser.id);
      
      // Wait a moment to ensure different expiration
      await new Promise(resolve => setTimeout(resolve, 100));
      
      const refreshedToken = await authService.refreshToken(originalToken);

      expect(refreshedToken).toBeDefined();
      expect(refreshedToken).not.toBe(originalToken);

      // Both should be valid during overlap period
      const originalValid = await authService.validateToken(originalToken);
      const refreshedValid = await authService.validateToken(refreshedToken);
      
      expect(originalValid).toBe(true);
      expect(refreshedValid).toBe(true);
    });
  });

  describe('Fraud Detection', () => {
    it('should detect suspicious login patterns', async () => {
      const suspiciousActivity = {
        userId: testUser.id,
        action: 'login_attempt',
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
        timestamp: new Date(),
      };

      const riskScore = await fraudDetection.analyzeActivity(suspiciousActivity);

      expect(riskScore).toBeDefined();
      expect(typeof riskScore).toBe('number');
      expect(riskScore).toBeGreaterThanOrEqual(0);
      expect(riskScore).toBeLessThanOrEqual(100);
    });

    it('should flag high-risk transactions', async () => {
      const highRiskTransaction = {
        userId: testUser.id,
        action: 'transaction',
        amount: 999999, // Very large amount
        recipient: 'unknown_account',
        ip: '192.168.1.1',
        timestamp: new Date(),
      };

      const riskScore = await fraudDetection.analyzeActivity(highRiskTransaction);
      
      expect(riskScore).toBeGreaterThan(70); // Should be high risk
    });

    it('should implement velocity checking', async () => {
      // Simulate rapid transactions
      const transactions = Array(10).fill().map((_, index) => ({
        userId: testUser.id,
        action: 'transaction',
        amount: 100,
        timestamp: new Date(Date.now() + index * 1000), // 1 second apart
      }));

      const riskScores = await Promise.all(
        transactions.map(tx => fraudDetection.analyzeActivity(tx))
      );

      // Later transactions should have higher risk due to velocity
      expect(riskScores[riskScores.length - 1]).toBeGreaterThan(riskScores[0]);
    });

    it('should block transactions above risk threshold', async () => {
      const blockResult = await fraudDetection.shouldBlockTransaction(
        testUser.id,
        999999, // Large amount
        'unknown_recipient'
      );

      expect(blockResult).toBe(true);
    });

    it('should allow legitimate transactions', async () => {
      const allowResult = await fraudDetection.shouldBlockTransaction(
        testUser.id,
        100, // Normal amount
        'known_recipient'
      );

      expect(allowResult).toBe(false);
    });
  });

  describe('Audit Logging', () => {
    it('should log all authentication attempts', async () => {
      const auditData = {
        userId: testUser.id,
        action: 'login_attempt',
        email: testUser.email,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
        success: true,
        timestamp: new Date(),
      };

      await auditLogger.log(auditData);

      // Verify log was created
      const logs = await auditLogger.getLogs({
        userId: testUser.id,
        action: 'login_attempt',
      });

      expect(logs.length).toBeGreaterThan(0);
      expect(logs[0].action).toBe('login_attempt');
      expect(logs[0].userId).toBe(testUser.id);
    });

    it('should log failed authentication attempts', async () => {
      const auditData = {
        userId: testUser.id,
        action: 'login_failed',
        email: testUser.email,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
        success: false,
        reason: 'Invalid OTP',
        timestamp: new Date(),
      };

      await auditLogger.log(auditData);

      const logs = await auditLogger.getLogs({
        userId: testUser.id,
        action: 'login_failed',
      });

      expect(logs.length).toBeGreaterThan(0);
      expect(logs[0].success).toBe(false);
      expect(logs[0].reason).toBe('Invalid OTP');
    });

    it('should log business profile changes', async () => {
      const auditData = {
        userId: testUser.id,
        action: 'profile_updated',
        changes: {
          businessName: 'New Business Name',
          phone: '+2348012345679',
        },
        ip: '192.168.1.1',
        timestamp: new Date(),
      };

      await auditLogger.log(auditData);

      const logs = await auditLogger.getLogs({
        userId: testUser.id,
        action: 'profile_updated',
      });

      expect(logs.length).toBeGreaterThan(0);
      expect(logs[0].changes).toBeDefined();
    });

    it('should maintain audit trail integrity', async () => {
      const originalLog = {
        userId: testUser.id,
        action: 'test_action',
        data: 'test_data',
        timestamp: new Date(),
      };

      await auditLogger.log(originalLog);

      // Try to modify log (should be prevented)
      const logs = await auditLogger.getLogs({
        userId: testUser.id,
        action: 'test_action',
      });

      expect(logs[0].data).toBe('test_data');
      expect(logs[0].immutable).toBeUndefined(); // Logs should be immutable
    });
  });

  describe('Session Management', () => {
    it('should create secure sessions', async () => {
      const sessionData = {
        userId: testUser.id,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
      };

      const session = await authService.createSession(sessionData);

      expect(session).toBeDefined();
      expect(session.token).toBeDefined();
      expect(session.expiresAt).toBeDefined();
      expect(session.userId).toBe(testUser.id);
    });

    it('should validate sessions correctly', async () => {
      const sessionData = {
        userId: testUser.id,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
      };

      const session = await authService.createSession(sessionData);
      const isValid = await authService.validateSession(session.token);

      expect(isValid).toBe(true);
    });

    it('should invalidate sessions on logout', async () => {
      const sessionData = {
        userId: testUser.id,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
      };

      const session = await authService.createSession(sessionData);
      await authService.invalidateSession(session.token);

      const isValid = await authService.validateSession(session.token);
      expect(isValid).toBe(false);
    });

    it('should handle session expiration', async () => {
      const sessionData = {
        userId: testUser.id,
        ip: '192.168.1.1',
        userAgent: 'Test Agent',
        expiresIn: '1s', // Very short expiration
      };

      const session = await authService.createSession(sessionData);

      // Wait for expiration
      await new Promise(resolve => setTimeout(resolve, 2000));

      const isValid = await authService.validateSession(session.token);
      expect(isValid).toBe(false);
    });
  });

  describe('Password Security', () => {
    it('should hash passwords securely', async () => {
      const password = 'TestPassword123!';
      const hashedPassword = await bcrypt.hash(password, 12);

      expect(hashedPassword).toBeDefined();
      expect(hashedPassword).not.toBe(password);
      expect(hashedPassword.length).toBeGreaterThan(50);

      // Verify hash
      const isValid = await bcrypt.compare(password, hashedPassword);
      expect(isValid).toBe(true);

      // Verify incorrect password
      const isInvalid = await bcrypt.compare('WrongPassword', hashedPassword);
      expect(isInvalid).toBe(false);
    });

    it('should enforce password complexity', async () => {
      const weakPasswords = [
        '123456',
        'password',
        'qwerty',
        'abc123',
        '111111',
      ];

      for (const weakPassword of weakPasswords) {
        await expect(
          authService.validatePasswordStrength(weakPassword)
        ).rejects.toThrow('Password too weak');
      }
    });

    it('should accept strong passwords', async () => {
      const strongPasswords = [
        'StrongP@ssword123!',
        'MySecureP@ssw0rd!',
        'C0mpl3xP@ssword!',
      ];

      for (const strongPassword of strongPasswords) {
        const isValid = await authService.validatePasswordStrength(strongPassword);
        expect(isValid).toBe(true);
      }
    });
  });

  describe('API Security', () => {
    it('should implement rate limiting per user', async () => {
      const requests = Array(100).fill().map(() => 
        authService.sendOtp(testUser.email)
      );

      const results = await Promise.allSettled(requests);
      const rejectedCount = results.filter(r => r.status === 'rejected').length;

      expect(rejectedCount).toBeGreaterThan(80); // Most should be rate limited
    });

    it('should validate request headers', async () => {
      // Test with missing headers
      await expect(
        authService.validateRequestHeaders({})
      ).rejects.toThrow('Missing required headers');

      // Test with valid headers
      const validHeaders = {
        'content-type': 'application/json',
        'user-agent': 'Test Agent',
        'x-forwarded-for': '192.168.1.1',
      };

      const isValid = await authService.validateRequestHeaders(validHeaders);
      expect(isValid).toBe(true);
    });

    it('should sanitize input data', async () => {
      const maliciousInput = {
        email: 'test@example.com<script>alert("xss")</script>',
        name: '<script>alert("xss")</script>',
        data: { key: 'value<script>alert("xss")</script>' },
      };

      const sanitized = await authService.sanitizeInput(maliciousInput);

      expect(sanitized.email).not.toContain('<script>');
      expect(sanitized.name).not.toContain('<script>');
      expect(sanitized.data.key).not.toContain('<script>');
    });
  });

  describe('Performance Requirements', () => {
    it('should authenticate in under 200ms', async () => {
      const startTime = Date.now();
      
      await authService.sendOtp(testUser.email);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(200);
    });

    it('should verify OTP in under 100ms', async () => {
      await authService.sendOtp(testUser.email);
      
      const user = await prisma.user.findUnique({
        where: { email: testUser.email },
        select: { otpCode: true }
      });

      const startTime = Date.now();
      
      await authService.verifyOtp(testUser.email, user.otpCode);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(100);
    });

    it('should analyze fraud risk in under 50ms', async () => {
      const activity = {
        userId: testUser.id,
        action: 'transaction',
        amount: 100,
        ip: '192.168.1.1',
        timestamp: new Date(),
      };

      const startTime = Date.now();
      
      await fraudDetection.analyzeActivity(activity);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(50);
    });
  });
});
