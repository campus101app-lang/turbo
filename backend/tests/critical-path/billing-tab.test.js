// backend/tests/critical-path/billing-tab.test.js
//
// Billing Tab - Revenue Operations Testing
// Tests invoice lifecycle + payment processing for enterprise billing
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';
import InvoiceService from '../../src/services/invoiceService.js';
import PaymentService from '../../src/services/paymentService.js';
import NotificationService from '../../src/services/notificationService.js';

const prisma = new PrismaClient();

describe('Billing Tab - Revenue Operations', () => {
  let testUser;
  let testOrganization;
  let testCustomer;
  let authToken;
  let invoiceService;
  let paymentService;
  let notificationService;

  beforeEach(async () => {
    // Create test user with business profile
    testUser = await prisma.user.create({
      data: {
        email: `billing-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Test Business User',
        businessName: 'Test Business Ltd',
        phone: '+2348012345678',
        bvn: '12345678901',
        cacRegistrationNumber: 'RC123456',
      },
    });

    // Create test organization
    testOrganization = await prisma.organization.create({
      data: {
        name: 'Test Organization',
        description: 'Test billing organization',
        businessType: 'LIMITED_LIABILITY',
        ownerUserId: testUser.id,
      },
    });

    // Create test customer
    testCustomer = await prisma.user.create({
      data: {
        email: `customer-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Test Customer',
        phone: '+2348012345679',
      },
    });

    // Initialize services
    invoiceService = new InvoiceService();
    paymentService = new PaymentService();
    notificationService = new NotificationService();

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_billing_tests';
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.invoice.deleteMany({ where: { userId: testUser.id } });
    await prisma.payment.deleteMany({ where: { userId: testUser.id } });
    await prisma.organization.delete({ where: { id: testOrganization.id } });
    await prisma.user.delete({ where: { id: testCustomer.id } });
    await prisma.user.delete({ where: { id: testUser.id } });
  });

  describe('Invoice Creation', () => {
    it('should create invoice with all required fields', async () => {
      const invoiceData = {
        customerEmail: testCustomer.email,
        amount: '50000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        description: 'Professional Services - Q1 2024',
        items: [
          {
            description: 'Consulting Services',
            quantity: 40,
            unitPrice: '1250.00',
            total: '50000.00'
          }
        ],
        organizationId: testOrganization.id,
        paymentTerms: 'Net 7 days',
        notes: 'Please pay within 7 days of receipt'
      };

      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invoiceData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.invoice).toBeDefined();
      expect(response.body.invoice.invoiceNumber).toBeDefined();
      expect(response.body.invoice.status).toBe('draft');
      expect(response.body.invoice.amount).toBe('50000.00');
      expect(response.body.invoice.currency).toBe('NGN');
    });

    it('should validate invoice data completeness', async () => {
      const incompleteInvoice = {
        customerEmail: '', // Missing customer
        amount: '', // Missing amount
        currency: 'NGN',
        dueDate: new Date().toISOString(),
      };

      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send(incompleteInvoice);

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors.length).toBeGreaterThan(0);
    });

    it('should generate sequential invoice numbers', async () => {
      // Create first invoice
      const invoice1 = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '10000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      // Create second invoice
      const invoice2 = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '20000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      expect(invoice1.invoiceNumber).toBeDefined();
      expect(invoice2.invoiceNumber).toBeDefined();
      expect(invoice2.invoiceNumber).not.toBe(invoice1.invoiceNumber);

      // Verify sequential numbering
      const num1 = parseInt(invoice1.invoiceNumber.replace(/\D/g, ''));
      const num2 = parseInt(invoice2.invoiceNumber.replace(/\D/g, ''));
      expect(num2).toBe(num1 + 1);
    });

    it('should handle multiple invoice items correctly', async () => {
      const multiItemInvoice = {
        customerEmail: testCustomer.email,
        amount: '75000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        items: [
          {
            description: 'Web Development',
            quantity: 20,
            unitPrice: '2000.00',
            total: '40000.00'
          },
          {
            description: 'Mobile App Development',
            quantity: 10,
            unitPrice: '3500.00',
            total: '35000.00'
          }
        ],
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send(multiItemInvoice);

      expect(response.status).toBe(201);
      expect(response.body.invoice.items).toHaveLength(2);
      expect(response.body.invoice.items[0].description).toBe('Web Development');
      expect(response.body.invoice.items[1].description).toBe('Mobile App Development');
    });
  });

  describe('Invoice Management', () => {
    let testInvoice;

    beforeEach(async () => {
      testInvoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '30000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
        description: 'Test Invoice for Management',
      });
    });

    it('should retrieve invoice list with pagination', async () => {
      // Create additional invoices
      for (let i = 0; i < 15; i++) {
        await invoiceService.createInvoice(testUser.id, {
          customerEmail: `customer${i}@test.com`,
          amount: `${(i + 1) * 1000}.00`,
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          organizationId: testOrganization.id,
        });
      }

      const response = await request(app)
        .get('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.invoices).toHaveLength(10);
      expect(response.body.pagination).toBeDefined();
      expect(response.body.pagination.total).toBeGreaterThan(15);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(10);
    });

    it('should filter invoices by status', async () => {
      // Create invoices with different statuses
      await invoiceService.updateInvoiceStatus(testInvoice.id, 'sent');
      await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'customer2@test.com',
        amount: '25000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      const response = await request(app)
        .get('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ status: 'sent' });

      expect(response.status).toBe(200);
      expect(response.body.invoices.every(inv => inv.status === 'sent')).toBe(true);
    });

    it('should update invoice status correctly', async () => {
      const response = await request(app)
        .put(`/api/invoices/${testInvoice.id}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'sent' });

      expect(response.status).toBe(200);
      expect(response.body.invoice.status).toBe('sent');

      // Verify status change in database
      const updatedInvoice = await invoiceService.getInvoice(testInvoice.id);
      expect(updatedInvoice.status).toBe('sent');
    });

    it('should handle invalid status transitions', async () => {
      // Try to transition from draft directly to paid
      const response = await request(app)
        .put(`/api/invoices/${testInvoice.id}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'paid' });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid status transition');
    });
  });

  describe('Payment Processing', () => {
    let testInvoice;

    beforeEach(async () => {
      testInvoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '50000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
        description: 'Test Invoice for Payment',
      });

      // Set invoice to sent status
      await invoiceService.updateInvoiceStatus(testInvoice.id, 'sent');
    });

    it('should create payment link for invoice', async () => {
      const response = await request(app)
        .post(`/api/invoices/${testInvoice.id}/payment-link`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ paymentMethod: 'bank_transfer' });

      expect(response.status).toBe(201);
      expect(response.body.paymentLink).toBeDefined();
      expect(response.body.paymentLink.url).toBeDefined();
      expect(response.body.paymentLink.expiresAt).toBeDefined();
    });

    it('should process bank transfer payment', async () => {
      const paymentData = {
        invoiceId: testInvoice.id,
        amount: '50000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        bankDetails: {
          accountNumber: '1234567890',
          bankCode: '044',
          accountName: 'Test Customer',
        },
        reference: `PAY_${Date.now()}`,
      };

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send(paymentData);

      expect(response.status).toBe(201);
      expect(response.body.payment).toBeDefined();
      expect(response.body.payment.status).toBe('pending');
      expect(response.body.payment.amount).toBe('50000.00');
    });

    it('should handle partial payments correctly', async () => {
      const partialPayment = {
        invoiceId: testInvoice.id,
        amount: '25000.00', // Half of invoice amount
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        reference: `PARTIAL_${Date.now()}`,
      };

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send(partialPayment);

      expect(response.status).toBe(201);
      expect(response.body.payment.amount).toBe('25000.00');

      // Verify invoice status remains unpaid
      const updatedInvoice = await invoiceService.getInvoice(testInvoice.id);
      expect(updatedInvoice.status).toBe('partially_paid');
    });

    it('should mark invoice as paid when fully settled', async () => {
      // Create full payment
      await paymentService.createPayment({
        userId: testUser.id,
        invoiceId: testInvoice.id,
        amount: '50000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        status: 'completed',
        reference: `FULL_${Date.now()}`,
      });

      // Check invoice status
      const updatedInvoice = await invoiceService.getInvoice(testInvoice.id);
      expect(updatedInvoice.status).toBe('paid');
    });

    it('should handle overpayment scenarios', async () => {
      const overPayment = {
        invoiceId: testInvoice.id,
        amount: '60000.00', // More than invoice amount
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        reference: `OVER_${Date.now()}`,
      };

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send(overPayment);

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Payment amount exceeds invoice amount');
    });
  });

  describe('Customer Management', () => {
    it('should create and manage customer profiles', async () => {
      const customerData = {
        email: 'newcustomer@test.com',
        name: 'New Customer',
        phone: '+2348012345670',
        address: '123 Customer Street, Lagos, Nigeria',
        businessType: 'INDIVIDUAL',
      };

      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(customerData);

      expect(response.status).toBe(201);
      expect(response.body.customer).toBeDefined();
      expect(response.body.customer.email).toBe('newcustomer@test.com');
    });

    it('should retrieve customer payment history', async () => {
      // Create invoice and payment for customer
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '30000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      await paymentService.createPayment({
        userId: testUser.id,
        invoiceId: invoice.id,
        amount: '30000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        status: 'completed',
        reference: `HISTORY_${Date.now()}`,
      });

      const response = await request(app)
        .get(`/api/customers/${testCustomer.email}/payment-history`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.payments).toHaveLength(1);
      expect(response.body.payments[0].amount).toBe('30000.00');
    });

    it('should calculate customer outstanding balance', async () => {
      // Create unpaid invoice
      await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '25000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      const response = await request(app)
        .get(`/api/customers/${testCustomer.email}/balance`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.outstandingBalance).toBe('25000.00');
    });
  });

  describe('Notifications & Reminders', () => {
    let testInvoice;

    beforeEach(async () => {
      testInvoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '40000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
        description: 'Test Invoice for Notifications',
      });
    });

    it('should send invoice creation notification', async () => {
      const notification = await notificationService.sendInvoiceNotification(
        testInvoice.id,
        'created'
      );

      expect(notification).toBeDefined();
      expect(notification.type).toBe('invoice_created');
      expect(notification.recipientEmail).toBe(testCustomer.email);
    });

    it('should send payment reminder notifications', async () => {
      // Set invoice to sent status
      await invoiceService.updateInvoiceStatus(testInvoice.id, 'sent');

      const reminder = await notificationService.sendPaymentReminder(
        testInvoice.id,
        'due_soon'
      );

      expect(reminder).toBeDefined();
      expect(reminder.type).toBe('payment_reminder');
      expect(reminder.reminderType).toBe('due_soon');
    });

    it('should send payment confirmation notification', async () => {
      // Create completed payment
      await paymentService.createPayment({
        userId: testUser.id,
        invoiceId: testInvoice.id,
        amount: '40000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        status: 'completed',
        reference: `CONFIRM_${Date.now()}`,
      });

      const confirmation = await notificationService.sendPaymentConfirmation(
        testInvoice.id
      );

      expect(confirmation).toBeDefined();
      expect(confirmation.type).toBe('payment_confirmation');
    });
  });

  describe('Reporting & Analytics', () => {
    beforeEach(async () => {
      // Create test invoices with different statuses and amounts
      await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'customer1@test.com',
        amount: '10000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'customer2@test.com',
        amount: '20000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      const paidInvoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'customer3@test.com',
        amount: '15000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      await paymentService.createPayment({
        userId: testUser.id,
        invoiceId: paidInvoice.id,
        amount: '15000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        status: 'completed',
        reference: `REPORT_${Date.now()}`,
      });
    });

    it('should generate revenue summary report', async () => {
      const response = await request(app)
        .get('/api/reports/revenue-summary')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ 
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
        });

      expect(response.status).toBe(200);
      expect(response.body.summary).toBeDefined();
      expect(response.body.summary.totalInvoiced).toBe('45000.00');
      expect(response.body.summary.totalPaid).toBe('15000.00');
      expect(response.body.summary.outstanding).toBe('30000.00');
    });

    it('should generate aging report', async () => {
      const response = await request(app)
        .get('/api/reports/aging')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.aging).toBeDefined();
      expect(response.body.aging.current).toBeDefined();
      expect(response.body.aging.overdue).toBeDefined();
    });

    it('should generate customer performance report', async () => {
      const response = await request(app)
        .get('/api/reports/customer-performance')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.customers).toBeDefined();
      expect(Array.isArray(response.body.customers)).toBe(true);
    });
  });

  describe('Performance Requirements', () => {
    it('should create invoice in under 200ms', async () => {
      const startTime = Date.now();

      await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: testCustomer.email,
          amount: '10000.00',
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          organizationId: testOrganization.id,
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(200);
    });

    it('should retrieve invoice list in under 150ms', async () => {
      const startTime = Date.now();

      await request(app)
        .get('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ page: 1, limit: 10 });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(150);
    });

    it('should process payment in under 300ms', async () => {
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '10000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
      });

      const startTime = Date.now();

      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '10000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          reference: `PERF_${Date.now()}`,
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(300);
    });
  });

  describe('Error Handling & Edge Cases', () => {
    it('should handle duplicate invoice numbers gracefully', async () => {
      // Create invoice with specific number
      const invoice1 = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '10000.00',
        currency: 'NGN',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        organizationId: testOrganization.id,
        invoiceNumber: 'INV-2024-001',
      });

      // Try to create another with same number
      await expect(
        invoiceService.createInvoice(testUser.id, {
          customerEmail: 'other@test.com',
          amount: '20000.00',
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          organizationId: testOrganization.id,
          invoiceNumber: 'INV-2024-001',
        })
      ).rejects.toThrow('Invoice number already exists');
    });

    it('should handle invalid customer email', async () => {
      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: 'invalid-email',
          amount: '10000.00',
          currency: 'NGN',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          organizationId: testOrganization.id,
        });

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
    });

    it('should handle currency mismatches', async () => {
      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: testInvoice.id,
          amount: '10000.00',
          currency: 'USD', // Different from invoice currency
          paymentMethod: 'bank_transfer',
          reference: `MISMATCH_${Date.now()}`,
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Currency mismatch');
    });
  });
});
