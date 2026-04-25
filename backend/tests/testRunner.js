#!/usr/bin/env node
// Comprehensive testing framework for production readiness

import { PrismaClient } from '@prisma/client';
import axios from 'axios';
import { performance } from 'perf_hooks';

const prisma = new PrismaClient();

class TestRunner {
  constructor() {
    this.baseURL = process.env.API_BASE_URL || 'http://localhost:3001';
    this.testResults = [];
    this.authToken = null;
    this.testUser = null;
    this.testOrganization = null;
  }

  async runAllTests() {
    console.log('🧪 Starting comprehensive test suite...');
    
    const testSuites = [
      { name: 'Database Tests', run: () => this.runDatabaseTests() },
      { name: 'Authentication Tests', run: () => this.runAuthTests() },
      { name: 'API Tests', run: () => this.runAPITests() },
      { name: 'Business Logic Tests', run: () => this.runBusinessLogicTests() },
      { name: 'Security Tests', run: () => this.runSecurityTests() },
      { name: 'Performance Tests', run: () => this.runPerformanceTests() },
      { name: 'Compliance Tests', run: () => this.runComplianceTests() }
    ];

    for (const suite of testSuites) {
      console.log(`\n📋 Running ${suite.name}...`);
      await this.runTestSuite(suite.name, suite.run);
    }

    this.generateReport();
  }

  async runTestSuite(suiteName, testFunction) {
    const startTime = performance.now();
    
    try {
      await testFunction();
      const duration = performance.now() - startTime;
      
      this.testResults.push({
        suite: suiteName,
        status: 'passed',
        duration,
        timestamp: new Date()
      });
      
      console.log(`✅ ${suiteName} passed (${duration.toFixed(2)}ms)`);
      
    } catch (error) {
      const duration = performance.now() - startTime;
      
      this.testResults.push({
        suite: suiteName,
        status: 'failed',
        duration,
        error: error.message,
        timestamp: new Date()
      });
      
      console.log(`❌ ${suiteName} failed: ${error.message} (${duration.toFixed(2)}ms)`);
    }
  }

  async runDatabaseTests() {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;
    
    // Test basic CRUD operations
    const testEmail = `test-${Date.now()}@example.com`;
    const user = await prisma.user.create({
      data: {
        email: testEmail,
        isVerified: true
      }
    });
    
    await prisma.user.delete({ where: { id: user.id } });
    
    // Test organization creation
    const org = await prisma.organization.create({
      data: {
        name: 'Test Organization',
        ownerUserId: user.id,
        plan: 'free'
      }
    });
    
    await prisma.organization.delete({ where: { id: org.id } });
  }

  async runAuthTests() {
    // Test user registration
    const registerResponse = await this.request('POST', '/api/auth/register', {
      email: `auth-test-${Date.now()}@example.com`
    });
    
    if (registerResponse.status !== 200) {
      throw new Error('User registration failed');
    }
    
    const { setupToken } = registerResponse.data;
    
    // Test OTP verification
    const otpResponse = await this.request('POST', '/api/auth/verify-otp', {
      email: `auth-test-${Date.now()}@example.com`,
      otp: '123456', // Test OTP
      setupToken
    });
    
    if (otpResponse.status !== 200) {
      throw new Error('OTP verification failed');
    }
    
    // Test business profile setup
    const profileResponse = await this.request('POST', '/api/auth/setup-profile', {
      setupToken: otpResponse.data.setupToken,
      fullName: 'Test User',
      businessName: 'Test Business',
      businessCategory: 'software'
    });
    
    if (profileResponse.status !== 200) {
      throw new Error('Business profile setup failed');
    }
    
    // Save auth token for subsequent tests
    this.authToken = profileResponse.data.token;
    this.testUser = profileResponse.data.user;
    this.testOrganization = profileResponse.data.user.organization;
  }

  async runAPITests() {
    if (!this.authToken) {
      throw new Error('No auth token available for API tests');
    }

    // Test organization endpoints
    const orgResponse = await this.request('GET', '/api/organization', null, this.authToken);
    if (orgResponse.status !== 200) {
      throw new Error('Organization fetch failed');
    }

    // Test invoice creation
    const invoiceResponse = await this.request('POST', '/api/invoices', {
      title: 'Test Invoice',
      clientName: 'Test Client',
      lineItems: [
        { description: 'Test Item', quantity: 1, unitPrice: 100 }
      ],
      totalAmount: 100,
      currency: 'USDC'
    }, this.authToken);
    
    if (invoiceResponse.status !== 200) {
      throw new Error('Invoice creation failed');
    }

    // Test expense creation
    const expenseResponse = await this.request('POST', '/api/expenses', {
      title: 'Test Expense',
      amount: 50,
      currency: 'NGN',
      category: 'software'
    }, this.authToken);
    
    if (expenseResponse.status !== 200) {
      throw new Error('Expense creation failed');
    }
  }

  async runBusinessLogicTests() {
    if (!this.authToken || !this.testOrganization) {
      throw new Error('No test data available for business logic tests');
    }

    // Test multi-level invoice approval
    const invoiceResponse = await this.request('POST', '/api/invoices', {
      title: 'Approval Test Invoice',
      clientName: 'Test Client',
      lineItems: [{ description: 'Test Item', quantity: 1, unitPrice: 100 }],
      totalAmount: 100,
      currency: 'USDC'
    }, this.authToken);

    const invoice = invoiceResponse.data.invoice;
    
    // Submit for approval
    const submitResponse = await this.request('POST', `/api/invoices/${invoice.id}/submit-for-approval`, {
      requiredApprovals: 2
    }, this.authToken);
    
    if (submitResponse.status !== 200) {
      throw new Error('Invoice submission for approval failed');
    }

    // Test expense approval workflow
    const expenseResponse = await this.request('POST', '/api/expenses', {
      title: 'Approval Test Expense',
      amount: 50,
      currency: 'NGN',
      category: 'software'
    }, this.authToken);

    const expense = expenseResponse.data.expense;
    
    // Submit expense
    const submitExpenseResponse = await this.request('POST', `/api/expenses/${expense.id}/submit`, null, this.authToken);
    
    if (submitExpenseResponse.status !== 200) {
      throw new Error('Expense submission failed');
    }
  }

  async runSecurityTests() {
    // Test rate limiting
    const rateLimitPromises = [];
    for (let i = 0; i < 20; i++) {
      rateLimitPromises.push(this.request('GET', '/api/organization', null, this.authToken));
    }
    
    const rateLimitResults = await Promise.all(rateLimitPromises);
    const rateLimited = rateLimitResults.some(res => res.status === 429);
    
    if (!rateLimited) {
      console.warn('⚠️  Rate limiting may not be working properly');
    }

    // Test input validation
    const invalidInvoiceResponse = await this.request('POST', '/api/invoices', {
      title: '', // Invalid empty title
      clientName: 'Test Client',
      totalAmount: -100 // Invalid negative amount
    }, this.authToken);
    
    if (invalidInvoiceResponse.status !== 400) {
      throw new Error('Input validation not working');
    }

    // Test authentication requirements
    const protectedResponse = await this.request('GET', '/api/organization');
    if (protectedResponse.status !== 401) {
      throw new Error('Protected endpoint accessible without auth');
    }
  }

  async runPerformanceTests() {
    const testRequests = 50;
    const startTime = performance.now();
    
    const promises = [];
    for (let i = 0; i < testRequests; i++) {
      promises.push(this.request('GET', '/api/organization', null, this.authToken));
    }
    
    await Promise.all(promises);
    const totalTime = performance.now() - startTime;
    const avgResponseTime = totalTime / testRequests;
    
    console.log(`📊 Performance: ${testRequests} requests in ${totalTime.toFixed(2)}ms`);
    console.log(`📊 Average response time: ${avgResponseTime.toFixed(2)}ms`);
    
    if (avgResponseTime > 1000) {
      throw new Error(`Performance issue: Average response time ${avgResponseTime.toFixed(2)}ms > 1000ms`);
    }
  }

  async runComplianceTests() {
    if (!this.authToken) {
      throw new Error('No auth token for compliance tests');
    }

    // Test audit logging
    const beforeAuditLogs = await this.request('GET', '/api/audit-logs', null, this.authToken);
    
    // Perform an action that should be logged
    await this.request('POST', '/api/invoices', {
      title: 'Compliance Test Invoice',
      clientName: 'Test Client',
      lineItems: [{ description: 'Test Item', quantity: 1, unitPrice: 100 }],
      totalAmount: 100,
      currency: 'USDC'
    }, this.authToken);
    
    // Check if action was logged
    const afterAuditLogs = await this.request('GET', '/api/audit-logs', null, this.authToken);
    
    if (afterAuditLogs.data.logs.length <= beforeAuditLogs.data.logs.length) {
      throw new Error('Audit logging not working');
    }

    // Test fraud detection
    const fraudTestResponse = await this.request('POST', '/api/fraud/test', {
      testType: 'suspicious_pattern'
    }, this.authToken);
    
    if (fraudTestResponse.status !== 200) {
      console.warn('⚠️  Fraud detection test endpoint not available');
    }
  }

  async request(method, endpoint, data = null, token = null) {
    const config = {
      method,
      url: `${this.baseURL}${endpoint}`,
      headers: {
        'Content-Type': 'application/json'
      }
    };
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    if (data) {
      config.data = data;
    }
    
    try {
      const response = await axios(config);
      return response;
    } catch (error) {
      if (error.response) {
        return error.response;
      }
      throw error;
    }
  }

  generateReport() {
    console.log('\n📊 TEST REPORT');
    console.log('='.repeat(50));
    
    const totalTests = this.testResults.length;
    const passedTests = this.testResults.filter(r => r.status === 'passed').length;
    const failedTests = this.testResults.filter(r => r.status === 'failed').length;
    const totalDuration = this.testResults.reduce((sum, r) => sum + r.duration, 0);
    
    console.log(`Total Tests: ${totalTests}`);
    console.log(`Passed: ${passedTests} ✅`);
    console.log(`Failed: ${failedTests} ${failedTests > 0 ? '❌' : '✅'}`);
    console.log(`Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
    console.log(`Total Duration: ${totalDuration.toFixed(2)}ms`);
    
    if (failedTests > 0) {
      console.log('\n❌ Failed Tests:');
      this.testResults
        .filter(r => r.status === 'failed')
        .forEach(r => {
          console.log(`  - ${r.suite}: ${r.error}`);
        });
    }
    
    console.log('\n' + '='.repeat(50));
    
    if (failedTests === 0) {
      console.log('🎉 ALL TESTS PASSED! Ready for production deployment.');
    } else {
      console.log('⚠️  Some tests failed. Please review and fix before deployment.');
    }
    
    // Exit with appropriate code
    process.exit(failedTests > 0 ? 1 : 0);
  }
}

// CLI interface
async function main() {
  const testRunner = new TestRunner();
  const command = process.argv[2] || 'all';
  
  switch (command) {
    case 'all':
      await testRunner.runAllTests();
      break;
    case 'database':
      await testRunner.runTestSuite('Database Tests', () => testRunner.runDatabaseTests());
      break;
    case 'auth':
      await testRunner.runTestSuite('Authentication Tests', () => testRunner.runAuthTests());
      break;
    case 'api':
      await testRunner.runTestSuite('API Tests', () => testRunner.runAPITests());
      break;
    case 'business':
      await testRunner.runTestSuite('Business Logic Tests', () => testRunner.runBusinessLogicTests());
      break;
    case 'security':
      await testRunner.runTestSuite('Security Tests', () => testRunner.runSecurityTests());
      break;
    case 'performance':
      await testRunner.runTestSuite('Performance Tests', () => testRunner.runPerformanceTests());
      break;
    case 'compliance':
      await testRunner.runTestSuite('Compliance Tests', () => testRunner.runComplianceTests());
      break;
    default:
      console.log('Usage: node testRunner.js [all|database|auth|api|business|security|performance|compliance]');
      process.exit(1);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

export default TestRunner;
