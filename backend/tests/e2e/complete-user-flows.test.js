// backend/tests/e2e/complete-user-flows.test.js
//
// End-to-End Testing for Complete User Flows
// Tests complete user journeys from registration to complex business operations
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';

const prisma = new PrismaClient();

describe('Complete User Flows - End-to-End Testing', () => {
  let testUser;
  let testOrganization;
  let authToken;
  let testData;

  beforeEach(async () => {
    // Generate unique test data
    testData = {
      email: `e2e-${Date.now()}@test.com`,
      businessName: `E2E Test Business ${Date.now()}`,
      phone: '+2348012345678',
      bvn: '12345678901',
    };

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_e2e_tests';
  });

  afterEach(async () => {
    // Comprehensive cleanup
    await cleanupTestData();
  });

  async function cleanupTestData() {
    if (testUser) {
      await prisma.workflow.deleteMany({ where: { organizationId: testOrganization?.id } });
      await prisma.order.deleteMany({ where: { userId: testUser.id } });
      await prisma.invoice.deleteMany({ where: { userId: testUser.id } });
      await prisma.transaction.deleteMany({ where: { userId: testUser.id } });
      await prisma.expense.deleteMany({ where: { userId: testUser.id } });
      await prisma.organizationMember.deleteMany({ where: { organizationId: testOrganization?.id } });
      await prisma.organization.delete({ where: { id: testOrganization?.id } });
      await prisma.user.delete({ where: { id: testUser.id } });
    }
  }

  describe('Complete Nigerian Business Onboarding Flow', () => {
    it('should complete full business registration and first transaction', async () => {
      // Step 1: Email Registration
      const emailResponse = await request(app)
        .post('/api/auth/send-otp')
        .send({ email: testData.email });

      expect(emailResponse.status).toBe(200);
      expect(emailResponse.body.success).toBe(true);
      expect(emailResponse.body.isNewUser).toBe(true);

      // Step 2: OTP Verification (mocked)
      const otpResponse = await request(app)
        .post('/api/auth/verify-otp')
        .send({ 
          email: testData.email, 
          otp: '123456' 
        });

      expect(otpResponse.status).toBe(200);
      expect(otpResponse.body.success).toBe(true);
      expect(otpResponse.body.token).toBeDefined();

      // Step 3: Business Profile Setup
      const businessProfileResponse = await request(app)
        .post('/auth/setup-business-profile')
        .set('Authorization', `Bearer ${otpResponse.body.token}`)
        .send({
          accountType: 'REGISTERED_BUSINESS',
          fullName: 'Test Business Owner',
          businessName: testData.businessName,
          phone: testData.phone,
          homeAddress: '123 Business Avenue, Lagos, Nigeria',
          bvn: testData.bvn,
          businessAddress: '456 Corporate Plaza, Victoria Island, Lagos',
          businessType: 'LIMITED_LIABILITY',
          cacRegistrationNumber: 'RC123456789',
          taxIdentificationNumber: 'TIN123456789',
          businessCategory: 'Technology Services',
        });

      expect(businessProfileResponse.status).toBe(200);
      expect(businessProfileResponse.body.success).toBe(true);

      // Store user and organization for subsequent steps
      testUser = await prisma.user.findUnique({ where: { email: testData.email } });
      testOrganization = await prisma.organization.findFirst({ where: { ownerUserId: testUser.id } });

      // Step 4: Stellar Wallet Creation
      const walletResponse = await request(app)
        .post('/api/wallet/create')
        .set('Authorization', `Bearer ${otpResponse.body.token}`);

      expect(walletResponse.status).toBe(200);
      expect(walletResponse.body.wallet).toBeDefined();
      expect(walletResponse.body.wallet.publicKey).toMatch(/^G[A-Z0-9]{55}$/);

      // Step 5: Virtual Account Creation
      const virtualAccountResponse = await request(app)
        .post('/api/virtual-accounts')
        .set('Authorization', `Bearer ${otpResponse.body.token}`)
        .send({
          bvn: testData.bvn,
          phoneNumber: testData.phone,
          firstName: 'Test',
          lastName: 'Owner',
          dateOfBirth: '1990-01-01',
        });

      expect(virtualAccountResponse.status).toBe(200);
      expect(virtualAccountResponse.body.accountNumber).toMatch(/^\d{10}$/);

      // Step 6: First Invoice Creation
      const invoiceResponse = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${otpResponse.body.token}`)
        .send({
          customerEmail: 'first-customer@test.com',
          amount: '75000.00',
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          description: 'Professional Services - Initial Project',
          organizationId: testOrganization.id,
        });

      expect(invoiceResponse.status).toBe(201);
      expect(invoiceResponse.body.invoice.status).toBe('draft');

      // Step 7: Invoice Payment Processing
      const paymentResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${otpResponse.body.token}`)
        .send({
          invoiceId: invoiceResponse.body.invoice.id,
          amount: '75000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          reference: `E2E_PAYMENT_${Date.now()}`,
        });

      expect(paymentResponse.status).toBe(201);
      expect(paymentResponse.body.payment.status).toBe('pending');

      // Verify complete flow success
      const finalUser = await prisma.user.findUnique({ 
        where: { id: testUser.id },
        include: { organization: true }
      });

      expect(finalUser.accountType).toBe('REGISTERED_BUSINESS');
      expect(finalUser.businessName).toBe(testData.businessName);
      expect(finalUser.stellarPublicKey).toBeDefined();
      expect(finalUser.organization).toBeDefined();
      expect(finalUser.organization.name).toBe(testData.businessName);
    });
  });

  describe('Complete E-commerce Business Flow', () => {
    beforeEach(async () => {
      // Setup complete business user
      testUser = await prisma.user.create({
        data: {
          email: testData.email,
          isVerified: true,
          accountType: 'REGISTERED_BUSINESS',
          fullName: 'E-commerce Business Owner',
          businessName: testData.businessName,
          phone: testData.phone,
          bvn: testData.bvn,
          stellarPublicKey: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        },
      });

      testOrganization = await prisma.organization.create({
        data: {
          name: testData.businessName,
          description: 'E-commerce test organization',
          businessType: 'LIMITED_LIABILITY',
          ownerUserId: testUser.id,
        },
      });
    });

    it('should complete full e-commerce cycle from product to payment', async () => {
      // Step 1: Product Creation
      const productResponse = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Premium Wireless Headphones',
          description: 'High-quality wireless headphones with noise cancellation',
          price: '45000.00',
          currency: 'NGN',
          category: 'Electronics',
          sku: 'HEADPHONES-001',
          inventory: {
            quantity: 100,
            reorderLevel: 20,
            trackInventory: true,
          },
          organizationId: testOrganization.id,
          status: 'active',
        });

      expect(productResponse.status).toBe(201);
      const productId = productResponse.body.product.id;

      // Step 2: Customer Places Order
      const orderResponse = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: 'shopper@test.com',
          items: [
            {
              productId: productId,
              quantity: 2,
              unitPrice: '45000.00',
              total: '90000.00',
            },
          ],
          shippingAddress: {
            street: '123 Shopper Street',
            city: 'Lagos',
            state: 'Lagos',
            postalCode: '100001',
            country: 'Nigeria',
          },
          paymentMethod: 'bank_transfer',
          organizationId: testOrganization.id,
        });

      expect(orderResponse.status).toBe(201);
      expect(orderResponse.body.order.status).toBe('pending');
      const orderId = orderResponse.body.order.id;

      // Step 3: Order Confirmation and Inventory Update
      const confirmResponse = await request(app)
        .put(`/api/orders/${orderId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'confirmed' });

      expect(confirmResponse.status).toBe(200);
      expect(confirmResponse.body.order.status).toBe('confirmed');

      // Verify inventory decreased
      const updatedProduct = await request(app)
        .get(`/api/products/${productId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(updatedProduct.body.inventory.quantity).toBe(98); // 100 - 2

      // Step 4: Payment Processing
      const paymentResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          orderId: orderId,
          amount: '90000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `E2E_SHOP_PAYMENT_${Date.now()}`,
        });

      expect(paymentResponse.status).toBe(201);

      // Step 5: Order Fulfillment
      const fulfillResponse = await request(app)
        .put(`/api/orders/${orderId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ 
          status: 'shipped',
          trackingNumber: 'TRK123456789',
          shippingCarrier: 'DHL',
        });

      expect(fulfillResponse.status).toBe(200);
      expect(fulfillResponse.body.order.status).toBe('shipped');

      // Step 6: Order Completion
      const completeResponse = await request(app)
        .put(`/api/orders/${orderId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'delivered' });

      expect(completeResponse.status).toBe(200);
      expect(completeResponse.body.order.status).toBe('delivered');

      // Verify complete e-commerce flow
      const finalOrder = await request(app)
        .get(`/api/orders/${orderId}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(finalOrder.body.order.status).toBe('delivered');
      expect(finalOrder.body.order.totalAmount).toBe('90000.00');
      expect(finalOrder.body.order.paymentStatus).toBe('paid');
    });
  });

  describe('Complete Multi-tenant Team Workflow', () => {
    let teamAdmin, teamManager, teamStaff;

    beforeEach(async () => {
      // Setup organization owner
      testUser = await prisma.user.create({
        data: {
          email: testData.email,
          isVerified: true,
          accountType: 'REGISTERED_BUSINESS',
          fullName: 'Organization Owner',
          businessName: testData.businessName,
          phone: testData.phone,
          bvn: testData.bvn,
        },
      });

      testOrganization = await prisma.organization.create({
        data: {
          name: testData.businessName,
          description: 'Multi-tenant test organization',
          businessType: 'LIMITED_LIABILITY',
          ownerUserId: testUser.id,
          settings: {
            requireApprovalForInvoices: true,
            requireApprovalForExpenses: true,
          },
        },
      });

      // Create team members
      teamAdmin = await prisma.user.create({
        data: {
          email: `admin-${Date.now()}@test.com`,
          isVerified: true,
          accountType: 'INDIVIDUAL',
          fullName: 'Team Admin',
          phone: '+2348012345679',
        },
      });

      teamManager = await prisma.user.create({
        data: {
          email: `manager-${Date.now()}@test.com`,
          isVerified: true,
          accountType: 'INDIVIDUAL',
          fullName: 'Team Manager',
          phone: '+2348012345680',
        },
      });

      teamStaff = await prisma.user.create({
        data: {
          email: `staff-${Date.now()}@test.com`,
          isVerified: true,
          accountType: 'INDIVIDUAL',
          fullName: 'Team Staff',
          phone: '+2348012345681',
        },
      });
    });

    it('should complete full team collaboration workflow', async () => {
      // Step 1: Team Setup and Role Assignment
      await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: teamAdmin.email,
          role: 'Admin',
          permissions: ['manage_invoices', 'manage_expenses', 'view_reports'],
        });

      await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: teamManager.email,
          role: 'Manager',
          permissions: ['create_invoices', 'create_expenses', 'view_team_reports'],
        });

      await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: teamStaff.email,
          role: 'Staff',
          permissions: ['view_own_data', 'create_expenses'],
        });

      // Accept invitations (mocked)
      await prisma.organizationMember.createMany({
        data: [
          { organizationId: testOrganization.id, userId: teamAdmin.id, role: 'Admin' },
          { organizationId: testOrganization.id, userId: teamManager.id, role: 'Manager' },
          { organizationId: testOrganization.id, userId: teamStaff.id, role: 'Staff' },
        ],
      });

      // Step 2: Staff Creates Expense (Requires Approval)
      const expenseResponse = await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer staff_token_${teamStaff.id}`)
        .send({
          amount: '25000.00',
          currency: 'NGN',
          category: 'Travel',
          description: 'Business trip to Abuja',
          organizationId: testOrganization.id,
        });

      expect(expenseResponse.status).toBe(201);
      expect(expenseResponse.body.expense.status).toBe('pending_approval');

      // Step 3: Manager Reviews and Approves Expense
      const approveResponse = await request(app)
        .put(`/api/expenses/${expenseResponse.body.expense.id}/approve`)
        .set('Authorization', `Bearer manager_token_${teamManager.id}`)
        .send({
          approved: true,
          comments: 'Approved for client meeting',
        });

      expect(approveResponse.status).toBe(200);
      expect(approveResponse.body.expense.status).toBe('approved');

      // Step 4: Admin Creates High-Value Invoice (Triggers Workflow)
      const invoiceResponse = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer admin_token_${teamAdmin.id}`)
        .send({
          customerEmail: 'corporate-client@test.com',
          amount: '500000.00', // High value - triggers approval
          currency: 'NGN',
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString(),
          description: 'Enterprise Software License',
          organizationId: testOrganization.id,
        });

      expect(invoiceResponse.status).toBe(201);
      expect(invoiceResponse.body.invoice.workflowStatus).toBe('pending_approval');

      // Step 5: Owner Approves High-Value Invoice
      const ownerApproveResponse = await request(app)
        .put(`/api/invoices/${invoiceResponse.body.invoice.id}/approve`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          approved: true,
          comments: 'Approved for enterprise client',
        });

      expect(ownerApproveResponse.status).toBe(200);
      expect(ownerApproveResponse.body.invoice.status).toBe('sent');

      // Step 6: Client Pays Invoice
      const paymentResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer admin_token_${teamAdmin.id}`)
        .send({
          invoiceId: invoiceResponse.body.invoice.id,
          amount: '500000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `TEAM_WORKFLOW_PAYMENT_${Date.now()}`,
        });

      expect(paymentResponse.status).toBe(201);

      // Step 7: Generate Team Performance Report
      const reportResponse = await request(app)
        .get(`/api/organization/${testOrganization.id}/team-performance`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
        });

      expect(reportResponse.status).toBe(200);
      expect(reportResponse.body.performance).toBeDefined();
      expect(reportResponse.body.performance.members).toHaveLength(4); // Owner + 3 team members

      // Verify complete team workflow
      const organizationOverview = await request(app)
        .get(`/api/organization/${testOrganization.id}/overview`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(organizationOverview.body.overview.totalMembers).toBe(4);
      expect(organizationOverview.body.overview.totalInvoices).toBeGreaterThan(0);
      expect(organizationOverview.body.overview.totalExpenses).toBeGreaterThan(0);
      expect(organizationOverview.body.overview.totalRevenue).toBe('500000.00');
    });
  });

  describe('Complete Financial Operations Flow', () => {
    beforeEach(async () => {
      // Setup business with financial infrastructure
      testUser = await prisma.user.create({
        data: {
          email: testData.email,
          isVerified: true,
          accountType: 'REGISTERED_BUSINESS',
          fullName: 'Financial Operations User',
          businessName: testData.businessName,
          phone: testData.phone,
          bvn: testData.bvn,
          stellarPublicKey: 'GD5QJZQJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5QJQ5Q',
        },
      });

      testOrganization = await prisma.organization.create({
        data: {
          name: testData.businessName,
          description: 'Financial operations test organization',
          businessType: 'LIMITED_LIABILITY',
          ownerUserId: testUser.id,
        },
      });
    });

    it('should complete full financial cycle from revenue to profit', async () => {
      // Step 1: Generate Revenue (Multiple Invoices)
      const invoices = [];
      for (let i = 1; i <= 3; i++) {
        const invoiceResponse = await request(app)
          .post('/api/invoices')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            customerEmail: `client${i}@test.com`,
            amount: `${i * 50000}.00`, // 50k, 100k, 150k
            currency: 'NGN',
            dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            description: `Service Package ${i}`,
            organizationId: testOrganization.id,
          });

        invoices.push(invoiceResponse.body.invoice);
      }

      // Step 2: Process All Payments
      for (const invoice of invoices) {
        await request(app)
          .post('/api/payments')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            invoiceId: invoice.id,
            amount: invoice.amount,
            currency: 'NGN',
            paymentMethod: 'bank_transfer',
            status: 'completed',
            reference: `FINANCIAL_FLOW_${invoice.id}`,
          });
      }

      // Step 3: Record Business Expenses
      const expenses = [];
      const expenseData = [
        { amount: '30000.00', category: 'Office Rent' },
        { amount: '20000.00', category: 'Utilities' },
        { amount: '15000.00', category: 'Software Licenses' },
        { amount: '25000.00', category: 'Marketing' },
      ];

      for (const expense of expenseData) {
        const expenseResponse = await request(app)
          .post('/api/expenses')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            ...expense,
            currency: 'NGN',
            description: `Monthly ${expense.category}`,
            organizationId: testOrganization.id,
          });

        expenses.push(expenseResponse.body.expense);
      }

      // Step 4: Process NGN to NGNT Conversion
      const conversionResponse = await request(app)
        .post('/api/convert/ngn-to-ngnt')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: '300000.00', // Total revenue
          convertToWallet: true,
        });

      expect(conversionResponse.status).toBe(200);
      expect(conversionResponse.body.conversion.ngntAmount).toBeDefined();

      // Step 5: Check Wallet Balances
      const balanceResponse = await request(app)
        .get('/api/balances')
        .set('Authorization', `Bearer ${authToken}`);

      expect(balanceResponse.status).toBe(200);
      const ngnBalance = balanceResponse.body.balances.find(b => b.currency === 'NGN');
      const ngntBalance = balanceResponse.body.balances.find(b => b.currency === 'NGNT');

      expect(parseFloat(ngntBalance.balance)).toBeGreaterThan(0);

      // Step 6: Generate Financial Reports
      const profitLossResponse = await request(app)
        .get('/api/reports/profit-loss')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
          organizationId: testOrganization.id,
        });

      expect(profitLossResponse.status).toBe(200);
      expect(profitLossResponse.body.report).toBeDefined();
      expect(profitLossResponse.body.report.totalRevenue).toBe('300000.00');
      expect(profitLossResponse.body.report.totalExpenses).toBe('90000.00');
      expect(profitLossResponse.body.report.netProfit).toBe('210000.00');

      // Step 7: Business Intelligence Dashboard
      const dashboardResponse = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      expect(dashboardResponse.status).toBe(200);
      expect(dashboardResponse.body.dashboard.widgets).toBeDefined();

      // Verify complete financial flow
      const finalReport = await request(app)
        .get('/api/reports/financial-summary')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      expect(finalReport.body.summary.totalRevenue).toBe('300000.00');
      expect(finalReport.body.summary.totalExpenses).toBe('90000.00');
      expect(finalReport.body.summary.profitMargin).toBeCloseTo(70.0, 1);
    });
  });

  describe('Error Recovery and Resilience', () => {
    it('should handle and recover from various failure scenarios', async () => {
      // Setup user
      testUser = await prisma.user.create({
        data: {
          email: testData.email,
          isVerified: true,
          accountType: 'INDIVIDUAL',
          fullName: 'Resilience Test User',
          phone: testData.phone,
        },
      });

      // Test 1: Failed Transaction Recovery
      const failedPaymentResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: '10000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          reference: 'FAILED_TRANSACTION',
          simulateFailure: true,
        });

      expect(failedPaymentResponse.status).toBe(400);
      expect(failedPaymentResponse.body.error).toBeDefined();

      // Test 2: Retry Mechanism
      const retryResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          amount: '10000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          reference: 'RETRY_TRANSACTION',
          retryCount: 3,
        });

      expect(retryResponse.status).toBe(201);

      // Test 3: Data Consistency Check
      const consistencyResponse = await request(app)
        .get('/api/data-consistency/check')
        .set('Authorization', `Bearer ${authToken}`);

      expect(consistencyResponse.status).toBe(200);
      expect(consistencyResponse.body.consistent).toBe(true);

      // Test 4: System Health Check
      const healthResponse = await request(app)
        .get('/api/system/health')
        .set('Authorization', `Bearer ${authToken}`);

      expect(healthResponse.status).toBe(200);
      expect(healthResponse.body.status).toBe('healthy');
    });
  });

  describe('Performance Under Load', () => {
    it('should handle concurrent user operations without degradation', async () => {
      // Setup multiple users
      const users = [];
      for (let i = 0; i < 5; i++) {
        const user = await prisma.user.create({
          data: {
            email: `load-test-${i}-${Date.now()}@test.com`,
            isVerified: true,
            accountType: 'INDIVIDUAL',
            fullName: `Load Test User ${i}`,
            phone: `+234801234567${i}`,
          },
        });
        users.push(user);
      }

      // Concurrent operations
      const concurrentOperations = [];
      
      for (const user of users) {
        // Each user creates invoice, processes payment, checks balance
        concurrentOperations.push(
          request(app)
            .post('/api/invoices')
            .set('Authorization', `Bearer user_token_${user.id}`)
            .send({
              customerEmail: `customer-${user.id}@test.com`,
              amount: '25000.00',
              currency: 'NGN',
              dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            })
        );

        concurrentOperations.push(
          request(app)
            .get('/api/balances')
            .set('Authorization', `Bearer user_token_${user.id}`)
        );
      }

      const startTime = Date.now();
      const results = await Promise.allSettled(concurrentOperations);
      const endTime = Date.now();

      const successfulOperations = results.filter(r => 
        r.status === 'fulfilled' && (r.value.status === 200 || r.value.status === 201)
      ).length;

      expect(successfulOperations).toBeGreaterThan(8); // At least 80% success
      expect(endTime - startTime).toBeLessThan(5000); // Under 5 seconds

      // Cleanup
      for (const user of users) {
        await prisma.user.delete({ where: { id: user.id } });
      }
    });
  });
});
