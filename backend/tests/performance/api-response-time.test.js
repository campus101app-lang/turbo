// backend/tests/performance/api-response-time.test.js
//
// Performance Testing for API Response Times (<200ms requirement)
// Tests all critical endpoints to ensure they meet performance targets
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';

const prisma = new PrismaClient();

describe('API Performance - Response Time Tests', () => {
  let testUser;
  let authToken;
  let server;

  beforeAll(async () => {
    // Start test server
    server = app.listen(0); // Random port
  });

  afterAll(async () => {
    if (server) {
      await new Promise(resolve => server.close(resolve));
    }
  });

  beforeEach(async () => {
    // Create test user
    testUser = await prisma.user.create({
      data: {
        email: `perf-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Performance Test User',
        phone: '+2348012345678',
        bvn: '12345678901',
      },
    });

    // Get auth token
    const loginResponse = await request(app)
      .post('/api/auth/send-otp')
      .send({ email: testUser.email });

    // For testing purposes, we'll use a mock token
    authToken = 'mock_jwt_token_for_testing';
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.user.delete({
      where: { id: testUser.id },
    });
  });

  describe('Authentication Endpoints', () => {
    it('POST /api/auth/send-otp should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/api/auth/send-otp')
        .send({ email: `new-user-${Date.now()}@test.com` });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(response.status).toBe(200);
      expect(responseTime).toBeLessThan(150);
      expect(response.body.success).toBe(true);
    });

    it('POST /api/auth/verify-otp should respond in <100ms', async () => {
      // First send OTP
      await request(app)
        .post('/api/auth/send-otp')
        .send({ email: testUser.email });

      const startTime = Date.now();

      const response = await request(app)
        .post('/api/auth/verify-otp')
        .send({ 
          email: testUser.email, 
          otp: '123456' // Mock OTP for testing
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Even with invalid OTP, response should be fast
      expect(responseTime).toBeLessThan(100);
    });

    it('POST /auth/setup-business-profile should respond in <200ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/auth/setup-business-profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          accountType: 'INDIVIDUAL',
          fullName: 'Test User',
          phone: '+2348012345678',
          homeAddress: '123 Test Street, Lagos, Nigeria',
          bvn: '12345678901',
          businessCategory: 'Software Development'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
    });
  });

  describe('User Management Endpoints', () => {
    it('GET /api/user/profile should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/user/profile')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });

    it('PUT /api/user/profile should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .put('/api/user/profile')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          fullName: 'Updated Name',
          phone: '+2348012345679'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(150);
    });

    it('GET /api/user/wallet should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/user/wallet')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });
  });

  describe('Transaction Endpoints', () => {
    it('GET /api/transactions should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(150);
    });

    it('POST /api/transactions should respond in <200ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          recipient: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
          amount: '10.50',
          asset: 'USDC'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
    });

    it('GET /api/transactions/:id should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/transactions/123')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });
  });

  describe('Balance Endpoints', () => {
    it('GET /api/balances should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/balances')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });

    it('GET /api/balances/:asset should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/balances/USDC')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });
  });

  describe('Organization Endpoints', () => {
    it('GET /api/organization should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/organization')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(150);
    });

    it('POST /api/organization should respond in <200ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/api/organization')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Test Organization',
          description: 'Test Description',
          businessType: 'LIMITED_LIABILITY'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
    });
  });

  describe('Invoice Endpoints', () => {
    it('GET /api/invoices should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(150);
    });

    it('POST /api/invoices should respond in <200ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: 'customer@test.com',
          amount: '50000',
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          description: 'Test Invoice'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
    });
  });

  describe('Payment Endpoints', () => {
    it('GET /api/payments should respond in <150ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(150);
    });

    it('POST /api/payments should respond in <200ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: '10000',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          recipientAccount: '1234567890',
          recipientBank: '044'
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
    });
  });

  describe('Health Check Endpoints', () => {
    it('GET /health should respond in <50ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/health');

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(response.status).toBe(200);
      expect(responseTime).toBeLessThan(50);
      expect(response.body.status).toBe('ok');
    });

    it('GET /monitoring/metrics should respond in <100ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/monitoring/metrics')
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(100);
    });
  });

  describe('Concurrent Request Performance', () => {
    it('should handle 10 concurrent requests without performance degradation', async () => {
      const concurrentRequests = Array(10).fill().map(() =>
        request(app)
          .get('/api/balances')
          .set('Authorization', `Bearer ${authToken}`)
      );

      const startTime = Date.now();
      const responses = await Promise.all(concurrentRequests);
      const endTime = Date.now();

      const averageResponseTime = (endTime - startTime) / 10;

      // Each request should still be fast even under load
      expect(averageResponseTime).toBeLessThan(150);
      
      // All requests should succeed
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });
    });

    it('should handle 50 concurrent requests without crashing', async () => {
      const concurrentRequests = Array(50).fill().map(() =>
        request(app)
          .get('/health')
      );

      const startTime = Date.now();
      const responses = await Promise.allSettled(concurrentRequests);
      const endTime = Date.now();

      const successfulRequests = responses.filter(r => 
        r.status === 'fulfilled' && r.value.status === 200
      ).length;

      expect(successfulRequests).toBeGreaterThan(45); // At least 90% success rate
      expect(endTime - startTime).toBeLessThan(1000); // Total time under 1 second
    });
  });

  describe('Database Performance', () => {
    it('should handle database queries efficiently', async () => {
      const startTime = Date.now();

      // Test complex query with joins
      const response = await request(app)
        .get('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ 
          page: 1, 
          limit: 50,
          include: 'user,organization',
          filters: JSON.stringify({
            status: 'completed',
            dateRange: 'last_30_days'
          })
        });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(200);
      expect(response.status).toBe(200);
    });

    it('should handle bulk operations efficiently', async () => {
      const startTime = Date.now();

      // Test bulk data retrieval
      const response = await request(app)
        .get('/api/transactions')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 100 });

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      expect(responseTime).toBeLessThan(300); // Slightly higher for bulk operations
      expect(response.status).toBe(200);
    });
  });

  describe('Memory Usage', () => {
    it('should not leak memory during repeated requests', async () => {
      const initialMemory = process.memoryUsage();

      // Make 100 requests
      for (let i = 0; i < 100; i++) {
        await request(app)
          .get('/api/balances')
          .set('Authorization', `Bearer ${authToken}`);
      }

      // Force garbage collection if available
      if (global.gc) {
        global.gc();
      }

      const finalMemory = process.memoryUsage();
      const memoryIncrease = finalMemory.heapUsed - initialMemory.heapUsed;

      // Memory increase should be minimal (less than 10MB)
      expect(memoryIncrease).toBeLessThan(10 * 1024 * 1024);
    });
  });

  describe('Stress Testing', () => {
    it('should maintain performance under sustained load', async () => {
      const requestCount = 100;
      const responseTimes = [];

      for (let i = 0; i < requestCount; i++) {
        const startTime = Date.now();
        
        await request(app)
          .get('/api/balances')
          .set('Authorization', `Bearer ${authToken}`);
        
        const endTime = Date.now();
        responseTimes.push(endTime - startTime);
      }

      // Calculate statistics
      const averageResponseTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
      const maxResponseTime = Math.max(...responseTimes);
      const p95ResponseTime = responseTimes.sort((a, b) => a - b)[Math.floor(responseTimes.length * 0.95)];

      expect(averageResponseTime).toBeLessThan(150);
      expect(maxResponseTime).toBeLessThan(500);
      expect(p95ResponseTime).toBeLessThan(200);
    });
  });

  describe('Performance Regression Tests', () => {
    it('should maintain baseline performance for critical endpoints', async () => {
      const baselineResponseTimes = {
        '/health': 50,
        '/api/auth/send-otp': 150,
        '/api/balances': 100,
        '/api/transactions': 150,
      };

      for (const [endpoint, baselineTime] of Object.entries(baselineResponseTimes)) {
        const startTime = Date.now();

        const response = endpoint === '/health' 
          ? await request(app).get(endpoint)
          : await request(app)
              .get(endpoint)
              .set('Authorization', `Bearer ${authToken}`);

        const endTime = Date.now();
        const responseTime = endTime - startTime;

        // Allow 20% tolerance over baseline
        const acceptableTime = baselineTime * 1.2;
        
        expect(responseTime).toBeLessThan(acceptableTime);
        expect(response.status).toBe(200);
      }
    });
  });
});
