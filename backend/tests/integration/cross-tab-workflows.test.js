// backend/tests/integration/cross-tab-workflows.test.js
//
// Cross-Tab Workflow Integration Testing
// Tests seamless integration between different tabs and workflows
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';
import InvoiceService from '../../src/services/invoiceService.js';
import OrderService from '../../src/services/orderService.js';
import OrganizationService from '../../src/services/organizationService.js';
import WorkflowService from '../../src/services/workflowService.js';
import NotificationService from '../../src/services/notificationService.js';

const prisma = new PrismaClient();

describe('Cross-Tab Workflow Integration', () => {
  let testUser;
  let testOrganization;
  let testCustomer;
  let authToken;
  let invoiceService;
  let orderService;
  let organizationService;
  let workflowService;
  let notificationService;

  beforeEach(async () => {
    // Create test user with business profile
    testUser = await prisma.user.create({
      data: {
        email: `cross-tab-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Cross Tab Test User',
        businessName: 'Cross Tab Business Ltd',
        phone: '+2348012345678',
        bvn: '12345678901',
      },
    });

    // Create test organization
    testOrganization = await prisma.organization.create({
      data: {
        name: 'Cross Tab Test Organization',
        description: 'Organization for cross-tab testing',
        businessType: 'LIMITED_LIABILITY',
        ownerUserId: testUser.id,
        settings: {
          requireApprovalForInvoices: true,
          requireApprovalForExpenses: true,
          autoCreateOrdersFromInvoices: true,
          syncInventoryWithSales: true,
        },
      },
    });

    // Create test customer
    testCustomer = await prisma.user.create({
      data: {
        email: `customer-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Cross Tab Customer',
        phone: '+2348012345679',
      },
    });

    // Initialize services
    invoiceService = new InvoiceService();
    orderService = new OrderService();
    organizationService = new OrganizationService();
    workflowService = new WorkflowService();
    notificationService = new NotificationService();

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_cross_tab_tests';
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.workflow.deleteMany({ where: { organizationId: testOrganization.id } });
    await prisma.order.deleteMany({ where: { userId: testUser.id } });
    await prisma.invoice.deleteMany({ where: { userId: testUser.id } });
    await prisma.transaction.deleteMany({ where: { userId: testUser.id } });
    await prisma.organization.delete({ where: { id: testOrganization.id } });
    await prisma.user.delete({ where: { id: testCustomer.id } });
    await prisma.user.delete({ where: { id: testUser.id } });
  });

  describe('Billing to Shop Integration', () => {
    it('should auto-create shop orders from invoice payments', async () => {
      // Create invoice with product items
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '75000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
        items: [
          {
            description: 'Premium Laptop',
            quantity: 1,
            unitPrice: '50000.00',
            total: '50000.00',
            productId: 'PROD-LAPTOP-001',
            sku: 'LAPTOP-001'
          },
          {
            description: 'Wireless Mouse',
            quantity: 1,
            unitPrice: '25000.00',
            total: '25000.00',
            productId: 'PROD-MOUSE-001',
            sku: 'MOUSE-001'
          }
        ],
      });

      // Process payment for invoice
      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '75000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `BILLING_SHOP_${Date.now()}`,
        });

      // Check if order was automatically created
      const orders = await orderService.getOrders(testUser.id, {
        invoiceId: invoice.id,
      });

      expect(orders).toHaveLength(1);
      expect(orders[0].customerEmail).toBe(testCustomer.email);
      expect(orders[0].totalAmount).toBe('75000.00');
      expect(orders[0].items).toHaveLength(2);
      expect(orders[0].items[0].productId).toBe('PROD-LAPTOP-001');
    });

    it('should sync inventory when invoice creates order', async () => {
      // Create product with inventory
      const product = await prisma.product.create({
        data: {
          userId: testUser.id,
          organizationId: testOrganization.id,
          name: 'Test Product',
          sku: 'TEST-001',
          price: '25000.00',
          currency: 'NGN',
          category: 'Electronics',
          inventory: {
            quantity: 100,
            trackInventory: true,
          },
        },
      });

      // Create invoice with product
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '25000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
        items: [
          {
            description: 'Test Product',
            quantity: 2,
            unitPrice: '12500.00',
            total: '25000.00',
            productId: product.id,
            sku: 'TEST-001'
          }
        ],
      });

      // Process payment
      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '25000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `INVENTORY_SYNC_${Date.now()}`,
        });

      // Check inventory was updated
      const updatedProduct = await prisma.product.findUnique({
        where: { id: product.id },
        include: { inventory: true },
      });

      expect(updatedProduct.inventory.quantity).toBe(98); // 100 - 2
    });

    it('should handle billing to shop customer data sync', async () => {
      // Create invoice with new customer
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'newcustomer@test.com',
        amount: '50000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
        customerInfo: {
          name: 'New Customer',
          phone: '+2348012345670',
          address: '123 Customer Street, Lagos',
        },
      });

      // Process payment
      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '50000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `CUSTOMER_SYNC_${Date.now()}`,
        });

      // Check customer was created in shop system
      const customer = await prisma.customer.findFirst({
        where: { email: 'newcustomer@test.com' },
      });

      expect(customer).toBeDefined();
      expect(customer.name).toBe('New Customer');
      expect(customer.phone).toBe('+2348012345670');
    });
  });

  describe('Shop to Billing Integration', () => {
    it('should auto-create invoices from shop orders', async () => {
      // Create shop order
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 2,
            unitPrice: '15000.00',
            total: '30000.00',
            description: 'Test Product'
          }
        ],
        organizationId: testOrganization.id,
        autoGenerateInvoice: true,
      });

      // Check if invoice was automatically created
      const invoices = await invoiceService.getInvoices(testUser.id, {
        orderId: order.id,
      });

      expect(invoices).toHaveLength(1);
      expect(invoices[0].customerEmail).toBe(testCustomer.email);
      expect(invoices[0].amount).toBe('30000.00');
      expect(invoices[0].status).toBe('sent');
    });

    it('should sync order status with invoice status', async () => {
      // Create order with auto-invoice
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '25000.00',
            total: '25000.00',
          }
        ],
        organizationId: testOrganization.id,
        autoGenerateInvoice: true,
      });

      const invoice = await invoiceService.getInvoices(testUser.id, { orderId: order.id });
      const invoiceId = invoice[0].id;

      // Update order status to completed
      await orderService.updateOrderStatus(order.id, 'completed');

      // Check invoice status was updated
      const updatedInvoice = await invoiceService.getInvoice(invoiceId);
      expect(updatedInvoice.status).toBe('paid');
    });

    it('should handle shop returns to billing credits', async () => {
      // Create and complete order
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '30000.00',
            total: '30000.00',
          }
        ],
        organizationId: testOrganization.id,
      });

      await orderService.updateOrderStatus(order.id, 'completed');

      // Process return
      const returnData = {
        orderId: order.id,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            reason: 'Defective product',
            refundAmount: '30000.00',
          }
        ],
        refundMethod: 'credit',
      };

      const response = await request(app)
        .post('/api/shop/returns')
        .set('Authorization', `Bearer ${authToken}`)
        .send(returnData);

      expect(response.status).toBe(201);
      expect(response.body.return.refundType).toBe('credit');

      // Check customer credit was created
      const credit = await prisma.customerCredit.findFirst({
        where: { 
          customerId: testCustomer.id,
          organizationId: testOrganization.id,
        },
      });

      expect(credit).toBeDefined();
      expect(credit.amount).toBe('30000.00');
    });
  });

  describe('Organization Workflow Integration', () => {
    it('should trigger organization workflows for billing approvals', async () => {
      // Create approval workflow for invoices
      await workflowService.createWorkflow(testOrganization.id, {
        name: 'Invoice Approval Workflow',
        trigger: 'invoice_created',
        conditions: {
          amount: { operator: '>', value: '100000' },
        },
        steps: [
          {
            type: 'approval',
            role: 'Admin',
            required: true,
          },
        ],
      });

      // Create high-value invoice
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '150000.00', // Above threshold
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      // Check workflow was triggered
      const workflowInstances = await workflowService.getWorkflowInstances(
        testOrganization.id,
        { invoiceId: invoice.id }
      );

      expect(workflowInstances).toHaveLength(1);
      expect(workflowInstances[0].status).toBe('pending');
      expect(invoice.workflowStatus).toBe('pending_approval');
    });

    it('should sync organization permissions across tabs', async () => {
      // Add team member with specific permissions
      const teamMember = await prisma.user.create({
        data: {
          email: `team-member-${Date.now()}@test.com`,
          isVerified: true,
          accountType: 'INDIVIDUAL',
          fullName: 'Team Member',
        },
      });

      await organizationService.addMember(testOrganization.id, teamMember.id, 'Manager');

      // Test billing tab access
      const billingResponse = await request(app)
        .get('/api/invoices')
        .set('Authorization', `Bearer team_member_token_${teamMember.id}`)
        .query({ organizationId: testOrganization.id });

      expect(billingResponse.status).toBe(200);

      // Test shop tab access
      const shopResponse = await request(app)
        .get('/api/shop/products')
        .set('Authorization', `Bearer team_member_token_${teamMember.id}`)
        .query({ organizationId: testOrganization.id });

      expect(shopResponse.status).toBe(200);

      // Cleanup
      await prisma.user.delete({ where: { id: teamMember.id } });
    });

    it('should handle organization-level reporting across tabs', async () => {
      // Create data across different tabs
      await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'customer1@test.com',
        amount: '50000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
        status: 'paid',
      });

      await orderService.createOrder(testUser.id, {
        customerEmail: 'customer2@test.com',
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '30000.00',
            total: '30000.00',
          }
        ],
        organizationId: testOrganization.id,
        status: 'completed',
      });

      // Generate cross-tab report
      const response = await request(app)
        .get(`/api/organization/${testOrganization.id}/cross-tab-report`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
        });

      expect(response.status).toBe(200);
      expect(response.body.report).toBeDefined();
      expect(response.body.report.billing).toBeDefined();
      expect(response.body.report.shop).toBeDefined();
      expect(response.body.report.totalRevenue).toBe('80000.00');
    });
  });

  describe('Transaction Flow Integration', () => {
    it('should create unified transaction records across tabs', async () => {
      // Create invoice payment
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '40000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      const paymentResponse = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '40000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `UNIFIED_TX_${Date.now()}`,
        });

      // Check unified transaction record
      const transaction = await prisma.transaction.findFirst({
        where: { 
          userId: testUser.id,
          reference: `UNIFIED_TX_${Date.now()}`,
        },
      });

      expect(transaction).toBeDefined();
      expect(transaction.type).toBe('invoice_payment');
      expect(transaction.amount).toBe('40000.00');
      expect(transaction.sourceTab).toBe('billing');
    });

    it('should sync financial data across tabs in real-time', async () => {
      // Create initial balance
      await prisma.userBalance.create({
        data: {
          userId: testUser.id,
          currency: 'NGN',
          amount: '100000.00',
        },
      });

      // Process invoice payment
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '25000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '25000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `REALTIME_SYNC_${Date.now()}`,
        });

      // Check updated balance across tabs
      const balanceResponse = await request(app)
        .get('/api/balances')
        .set('Authorization', `Bearer ${authToken}`);

      const ngnBalance = balanceResponse.body.balances.find(b => b.currency === 'NGN');
      expect(ngnBalance.amount).toBe('125000.00'); // 100000 + 25000
    });
  });

  describe('Notification Integration', () => {
    it('should send cross-tab notifications for workflow events', async () => {
      // Create workflow for order approvals
      await workflowService.createWorkflow(testOrganization.id, {
        name: 'Order Approval Workflow',
        trigger: 'order_created',
        conditions: {
          amount: { operator: '>', value: '100000' },
        },
        steps: [
          {
            type: 'approval',
            role: 'Admin',
            required: true,
          },
        ],
      });

      // Create high-value order
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '150000.00',
            total: '150000.00',
          }
        ],
        organizationId: testOrganization.id,
      });

      // Check notifications were sent
      const notifications = await notificationService.getNotifications(testUser.id, {
        type: 'workflow_pending',
      });

      expect(notifications.length).toBeGreaterThan(0);
      expect(notifications[0].sourceTab).toBe('shop');
      expect(notifications[0].relatedEntity).toBe(order.id);
    });

    it('should aggregate notifications from multiple tabs', async () => {
      // Create invoice
      await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '30000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      // Create order
      await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '25000.00',
            total: '25000.00',
          }
        ],
        organizationId: testOrganization.id,
      });

      // Get aggregated notifications
      const response = await request(app)
        .get('/api/notifications')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ aggregate: true });

      expect(response.status).toBe(200);
      expect(response.body.notifications).toBeDefined();
      expect(response.body.notifications.length).toBeGreaterThan(0);

      // Check notifications from different tabs
      const billingNotifications = response.body.notifications.filter(n => n.sourceTab === 'billing');
      const shopNotifications = response.body.notifications.filter(n => n.sourceTab === 'shop');

      expect(billingNotifications.length).toBeGreaterThan(0);
      expect(shopNotifications.length).toBeGreaterThan(0);
    });
  });

  describe('Data Consistency', () => {
    it('should maintain data consistency across tab operations', async () => {
      // Create customer in billing
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: 'consistency@test.com',
        amount: '35000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
        customerInfo: {
          name: 'Consistency Test',
          phone: '+2348012345670',
        },
      });

      // Create order for same customer
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: 'consistency@test.com',
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '25000.00',
            total: '25000.00',
          }
        ],
        organizationId: testOrganization.id,
      });

      // Verify customer data consistency
      const customer = await prisma.customer.findFirst({
        where: { email: 'consistency@test.com' },
      });

      expect(customer).toBeDefined();
      expect(customer.name).toBe('Consistency Test');
      expect(customer.phone).toBe('+2348012345670');

      // Verify related records
      const relatedInvoices = await invoiceService.getInvoices(testUser.id, {
        customerId: customer.id,
      });

      const relatedOrders = await orderService.getOrders(testUser.id, {
        customerId: customer.id,
      });

      expect(relatedInvoices).toHaveLength(1);
      expect(relatedOrders).toHaveLength(1);
    });

    it('should handle concurrent operations across tabs', async () => {
      // Simultaneous operations
      const invoicePromise = invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '20000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      const orderPromise = orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: 'PROD-001',
            quantity: 1,
            unitPrice: '15000.00',
            total: '15000.00',
          }
        ],
        organizationId: testOrganization.id,
      });

      const [invoice, order] = await Promise.all([invoicePromise, orderPromise]);

      // Verify both operations completed successfully
      expect(invoice).toBeDefined();
      expect(order).toBeDefined();

      // Verify data integrity
      const customerRecord = await prisma.customer.findFirst({
        where: { email: testCustomer.email },
      });

      expect(customerRecord).toBeDefined();
      expect(customerRecord.totalInvoiced).toBe('20000.00');
      expect(customerRecord.totalOrders).toBe('15000.00');
    });
  });

  describe('Performance Integration', () => {
    it('should handle cross-tab operations efficiently', async () => {
      const startTime = Date.now();

      // Create invoice
      const invoice = await invoiceService.createInvoice(testUser.id, {
        customerEmail: testCustomer.email,
        amount: '30000.00',
        currency: 'NGN',
        organizationId: testOrganization.id,
      });

      // Process payment
      await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          invoiceId: invoice.id,
          amount: '30000.00',
          currency: 'NGN',
          paymentMethod: 'bank_transfer',
          status: 'completed',
          reference: `PERF_INTEGRATION_${Date.now()}`,
        });

      // Check auto-created order
      const orders = await orderService.getOrders(testUser.id, {
        invoiceId: invoice.id,
      });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(500); // Cross-tab operation under 500ms
      expect(orders).toHaveLength(1);
    });

    it('should maintain performance under concurrent cross-tab load', async () => {
      const concurrentOperations = Array(10).fill().map((_, index) => 
        request(app)
          .post('/api/invoices')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            customerEmail: `customer${index}@test.com`,
            amount: `${(index + 1) * 1000}.00`,
            currency: 'NGN',
            organizationId: testOrganization.id,
          })
      );

      const startTime = Date.now();
      const responses = await Promise.allSettled(concurrentOperations);
      const endTime = Date.now();

      const successfulOperations = responses.filter(r => 
        r.status === 'fulfilled' && r.value.status === 201
      ).length;

      expect(successfulOperations).toBeGreaterThan(8); // At least 80% success
      expect(endTime - startTime).toBeLessThan(2000); // Under 2 seconds total
    });
  });
});
