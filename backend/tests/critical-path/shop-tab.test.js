// backend/tests/critical-path/shop-tab.test.js
//
// Shop Tab - E-commerce Flow Testing
// Tests e-commerce flow + inventory management for enterprise shop operations
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';
import ShopService from '../../src/services/shopService.js';
import InventoryService from '../../src/services/inventoryService.js';
import OrderService from '../../src/services/orderService.js';
import ProductService from '../../src/services/productService.js';

const prisma = new PrismaClient();

describe('Shop Tab - E-commerce Operations', () => {
  let testUser;
  let testOrganization;
  let testCustomer;
  let authToken;
  let shopService;
  let inventoryService;
  let orderService;
  let productService;

  beforeEach(async () => {
    // Create test user with business profile
    testUser = await prisma.user.create({
      data: {
        email: `shop-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Test Shop Owner',
        businessName: 'Test Shop Ltd',
        phone: '+2348012345678',
        bvn: '12345678901',
        cacRegistrationNumber: 'RC123456',
      },
    });

    // Create test organization
    testOrganization = await prisma.organization.create({
      data: {
        name: 'Test Shop Organization',
        description: 'Test e-commerce organization',
        businessType: 'LIMITED_LIABILITY',
        ownerUserId: testUser.id,
      },
    });

    // Create test customer
    testCustomer = await prisma.user.create({
      data: {
        email: `shop-customer-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Test Shop Customer',
        phone: '+2348012345679',
      },
    });

    // Initialize services
    shopService = new ShopService();
    inventoryService = new InventoryService();
    orderService = new OrderService();
    productService = new ProductService();

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_shop_tests';
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.order.deleteMany({ where: { userId: testUser.id } });
    await prisma.product.deleteMany({ where: { userId: testUser.id } });
    await prisma.inventory.deleteMany({ where: { userId: testUser.id } });
    await prisma.organization.delete({ where: { id: testOrganization.id } });
    await prisma.user.delete({ where: { id: testCustomer.id } });
    await prisma.user.delete({ where: { id: testUser.id } });
  });

  describe('Product Management', () => {
    it('should create product with complete details', async () => {
      const productData = {
        name: 'Premium Laptop',
        description: 'High-performance laptop for professionals',
        sku: 'LAPTOP-001',
        price: '250000.00',
        currency: 'NGN',
        category: 'Electronics',
        images: [
          'https://example.com/laptop-1.jpg',
          'https://example.com/laptop-2.jpg'
        ],
        specifications: {
          brand: 'TestBrand',
          model: 'X1-Pro',
          ram: '16GB',
          storage: '512GB SSD',
          processor: 'Intel i7'
        },
        inventory: {
          quantity: 50,
          reorderLevel: 10,
          trackInventory: true
        },
        organizationId: testOrganization.id,
        status: 'active'
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send(productData);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.product).toBeDefined();
      expect(response.body.product.name).toBe('Premium Laptop');
      expect(response.body.product.price).toBe('250000.00');
      expect(response.body.product.inventory.quantity).toBe(50);
    });

    it('should validate product data completeness', async () => {
      const incompleteProduct = {
        name: '', // Missing name
        price: '', // Missing price
        currency: 'NGN',
        category: 'Electronics',
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send(incompleteProduct);

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors.length).toBeGreaterThan(0);
    });

    it('should generate unique SKU automatically', async () => {
      const product1Data = {
        name: 'Product 1',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
      };

      const product2Data = {
        name: 'Product 2',
        price: '20000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
      };

      const product1 = await productService.createProduct(testUser.id, product1Data);
      const product2 = await productService.createProduct(testUser.id, product2Data);

      expect(product1.sku).toBeDefined();
      expect(product2.sku).toBeDefined();
      expect(product1.sku).not.toBe(product2.sku);
    });

    it('should handle product variants correctly', async () => {
      const productWithVariants = {
        name: 'T-Shirt',
        description: 'Comfortable cotton t-shirt',
        price: '5000.00',
        currency: 'NGN',
        category: 'Clothing',
        variants: [
          {
            name: 'T-Shirt - Small - Red',
            sku: 'TSHIRT-S-RED',
            price: '5000.00',
            attributes: { size: 'S', color: 'Red' },
            inventory: { quantity: 20 }
          },
          {
            name: 'T-Shirt - Medium - Blue',
            sku: 'TSHIRT-M-BLU',
            price: '5000.00',
            attributes: { size: 'M', color: 'Blue' },
            inventory: { quantity: 15 }
          }
        ],
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send(productWithVariants);

      expect(response.status).toBe(201);
      expect(response.body.product.variants).toHaveLength(2);
      expect(response.body.product.variants[0].attributes.size).toBe('S');
      expect(response.body.product.variants[1].attributes.color).toBe('Blue');
    });
  });

  describe('Inventory Management', () => {
    let testProduct;

    beforeEach(async () => {
      testProduct = await productService.createProduct(testUser.id, {
        name: 'Test Product',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: {
          quantity: 100,
          reorderLevel: 20,
          trackInventory: true
        }
      });
    });

    it('should update inventory levels correctly', async () => {
      const updateData = {
        quantity: 85, // Decrease by 15
        reason: 'sale',
        reference: 'ORDER-001'
      };

      const response = await request(app)
        .put(`/api/inventory/${testProduct.inventory.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expect(response.body.inventory.quantity).toBe(85);

      // Verify inventory record
      const updatedInventory = await inventoryService.getInventory(testProduct.inventory.id);
      expect(updatedInventory.quantity).toBe(85);
    });

    it('should prevent negative inventory', async () => {
      const response = await request(app)
        .put(`/api/inventory/${testProduct.inventory.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          quantity: -10, // Negative quantity
          reason: 'error',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Negative inventory not allowed');
    });

    it('should trigger low stock alerts', async () => {
      // Update inventory below reorder level
      await inventoryService.updateInventory(testProduct.inventory.id, {
        quantity: 15, // Below reorder level of 20
        reason: 'sale',
        reference: 'ORDER-002'
      });

      // Check for low stock alert
      const alerts = await inventoryService.getLowStockAlerts(testUser.id);
      expect(alerts.length).toBeGreaterThan(0);
      expect(alerts[0].productId).toBe(testProduct.id);
      expect(alerts[0].currentStock).toBe(15);
    });

    it('should handle bulk inventory updates', async () => {
      // Create additional products
      const product2 = await productService.createProduct(testUser.id, {
        name: 'Product 2',
        price: '20000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 50, trackInventory: true }
      });

      const bulkUpdate = {
        updates: [
          { productId: testProduct.id, quantity: 90, reason: 'adjustment' },
          { productId: product2.id, quantity: 45, reason: 'adjustment' }
        ]
      };

      const response = await request(app)
        .post('/api/inventory/bulk-update')
        .set('Authorization', `Bearer ${authToken}`)
        .send(bulkUpdate);

      expect(response.status).toBe(200);
      expect(response.body.updated).toBe(2);

      // Verify updates
      const updatedProduct1 = await productService.getProduct(testProduct.id);
      const updatedProduct2 = await productService.getProduct(product2.id);
      expect(updatedProduct1.inventory.quantity).toBe(90);
      expect(updatedProduct2.inventory.quantity).toBe(45);
    });
  });

  describe('Order Processing', () => {
    let testProduct;

    beforeEach(async () => {
      testProduct = await productService.createProduct(testUser.id, {
        name: 'Test Product for Order',
        price: '15000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: {
          quantity: 100,
          trackInventory: true
        }
      });
    });

    it('should create order with multiple items', async () => {
      const orderData = {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: testProduct.id,
            quantity: 2,
            unitPrice: '15000.00',
            total: '30000.00'
          }
        ],
        shippingAddress: {
          street: '123 Customer Street',
          city: 'Lagos',
          state: 'Lagos',
          postalCode: '100001',
          country: 'Nigeria'
        },
        paymentMethod: 'bank_transfer',
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send(orderData);

      expect(response.status).toBe(201);
      expect(response.body.order).toBeDefined();
      expect(response.body.order.status).toBe('pending');
      expect(response.body.order.totalAmount).toBe('30000.00');
      expect(response.body.order.items).toHaveLength(1);
    });

    it('should validate order data and inventory availability', async () => {
      const invalidOrder = {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: testProduct.id,
            quantity: 150, // More than available inventory
            unitPrice: '15000.00',
            total: '2250000.00'
          }
        ],
        paymentMethod: 'bank_transfer',
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidOrder);

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Insufficient inventory');
    });

    it('should update order status correctly', async () => {
      // Create order
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: testProduct.id,
            quantity: 1,
            unitPrice: '15000.00',
            total: '15000.00'
          }
        ],
        organizationId: testOrganization.id,
      });

      // Update status to confirmed
      const response = await request(app)
        .put(`/api/orders/${order.id}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'confirmed' });

      expect(response.status).toBe(200);
      expect(response.body.order.status).toBe('confirmed');

      // Verify inventory was updated
      const updatedProduct = await productService.getProduct(testProduct.id);
      expect(updatedProduct.inventory.quantity).toBe(99); // Decreased by 1
    });

    it('should handle order cancellation and inventory restoration', async () => {
      // Create and confirm order
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: testProduct.id,
            quantity: 3,
            unitPrice: '15000.00',
            total: '45000.00'
          }
        ],
        organizationId: testOrganization.id,
      });

      await orderService.updateOrderStatus(order.id, 'confirmed');

      // Cancel order
      const response = await request(app)
        .put(`/api/orders/${order.id}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'cancelled', reason: 'Customer request' });

      expect(response.status).toBe(200);
      expect(response.body.order.status).toBe('cancelled');

      // Verify inventory was restored
      const updatedProduct = await productService.getProduct(testProduct.id);
      expect(updatedProduct.inventory.quantity).toBe(100); // Restored to original
    });

    it('should process order payments correctly', async () => {
      const order = await orderService.createOrder(testUser.id, {
        customerEmail: testCustomer.email,
        items: [
          {
            productId: testProduct.id,
            quantity: 1,
            unitPrice: '15000.00',
            total: '15000.00'
          }
        ],
        organizationId: testOrganization.id,
      });

      const paymentData = {
        orderId: order.id,
        amount: '15000.00',
        currency: 'NGN',
        paymentMethod: 'bank_transfer',
        reference: `ORDER_PAY_${Date.now()}`,
      };

      const response = await request(app)
        .post('/api/payments')
        .set('Authorization', `Bearer ${authToken}`)
        .send(paymentData);

      expect(response.status).toBe(201);
      expect(response.body.payment.orderId).toBe(order.id);
      expect(response.body.payment.amount).toBe('15000.00');
    });
  });

  describe('Customer Experience', () => {
    let testProduct;

    beforeEach(async () => {
      testProduct = await productService.createProduct(testUser.id, {
        name: 'Public Test Product',
        price: '25000.00',
        currency: 'NGN',
        category: 'Electronics',
        organizationId: testOrganization.id,
        status: 'active',
        inventory: { quantity: 50, trackInventory: true }
      });
    });

    it('should allow customers to browse products', async () => {
      const response = await request(app)
        .get('/api/shop/products')
        .query({ 
          organizationId: testOrganization.id,
          status: 'active',
          page: 1,
          limit: 10
        });

      expect(response.status).toBe(200);
      expect(response.body.products).toBeDefined();
      expect(Array.isArray(response.body.products)).toBe(true);
      expect(response.body.products.length).toBeGreaterThan(0);
    });

    it('should provide product search functionality', async () => {
      const response = await request(app)
        .get('/api/shop/products/search')
        .query({ 
          q: 'Test Product',
          organizationId: testOrganization.id
        });

      expect(response.status).toBe(200);
      expect(response.body.products).toBeDefined();
      expect(response.body.products.some(p => p.name.includes('Test Product'))).toBe(true);
    });

    it('should filter products by category', async () => {
      // Create products in different categories
      await productService.createProduct(testUser.id, {
        name: 'Electronics Item',
        price: '30000.00',
        currency: 'NGN',
        category: 'Electronics',
        organizationId: testOrganization.id,
        status: 'active'
      });

      await productService.createProduct(testUser.id, {
        name: 'Clothing Item',
        price: '15000.00',
        currency: 'NGN',
        category: 'Clothing',
        organizationId: testOrganization.id,
        status: 'active'
      });

      const response = await request(app)
        .get('/api/shop/products')
        .query({ 
          category: 'Electronics',
          organizationId: testOrganization.id
        });

      expect(response.status).toBe(200);
      expect(response.body.products.every(p => p.category === 'Electronics')).toBe(true);
    });

    it('should show product availability', async () => {
      const response = await request(app)
        .get(`/api/shop/products/${testProduct.id}`)
        .query({ organizationId: testOrganization.id });

      expect(response.status).toBe(200);
      expect(response.body.product).toBeDefined();
      expect(response.body.product.inventory).toBeDefined();
      expect(response.body.product.inventory.quantity).toBe(50);
      expect(response.body.product.inventory.inStock).toBe(true);
    });
  });

  describe('Shop Analytics & Reporting', () => {
    beforeEach(async () => {
      // Create test products and orders for analytics
      const product1 = await productService.createProduct(testUser.id, {
        name: 'Analytics Product 1',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 100, trackInventory: true }
      });

      const product2 = await productService.createProduct(testUser.id, {
        name: 'Analytics Product 2',
        price: '20000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 50, trackInventory: true }
      });

      // Create orders
      await orderService.createOrder(testUser.id, {
        customerEmail: 'customer1@test.com',
        items: [
          {
            productId: product1.id,
            quantity: 2,
            unitPrice: '10000.00',
            total: '20000.00'
          }
        ],
        organizationId: testOrganization.id,
        status: 'completed'
      });

      await orderService.createOrder(testUser.id, {
        customerEmail: 'customer2@test.com',
        items: [
          {
            productId: product2.id,
            quantity: 1,
            unitPrice: '20000.00',
            total: '20000.00'
          }
        ],
        organizationId: testOrganization.id,
        status: 'completed'
      });
    });

    it('should generate sales summary report', async () => {
      const response = await request(app)
        .get('/api/shop/reports/sales-summary')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
          organizationId: testOrganization.id
        });

      expect(response.status).toBe(200);
      expect(response.body.summary).toBeDefined();
      expect(response.body.summary.totalSales).toBe('40000.00');
      expect(response.body.summary.totalOrders).toBe(2);
      expect(response.body.summary.averageOrderValue).toBe('20000.00');
    });

    it('should generate top-selling products report', async () => {
      const response = await request(app)
        .get('/api/shop/reports/top-products')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          limit: 10
        });

      expect(response.status).toBe(200);
      expect(response.body.products).toBeDefined();
      expect(Array.isArray(response.body.products)).toBe(true);
      expect(response.body.products.length).toBeGreaterThan(0);
    });

    it('should generate inventory valuation report', async () => {
      const response = await request(app)
        .get('/api/shop/reports/inventory-valuation')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      expect(response.status).toBe(200);
      expect(response.body.valuation).toBeDefined();
      expect(response.body.valuation.totalValue).toBeDefined();
      expect(response.body.valuation.totalProducts).toBeDefined();
    });
  });

  describe('Performance Requirements', () => {
    it('should create product in under 200ms', async () => {
      const startTime = Date.now();

      await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Performance Test Product',
          price: '10000.00',
          currency: 'NGN',
          category: 'Test',
          organizationId: testOrganization.id,
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(200);
    });

    it('should retrieve product list in under 150ms', async () => {
      const startTime = Date.now();

      await request(app)
        .get('/api/shop/products')
        .query({ organizationId: testOrganization.id, page: 1, limit: 10 });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(150);
    });

    it('should create order in under 300ms', async () => {
      const product = await productService.createProduct(testUser.id, {
        name: 'Order Test Product',
        price: '15000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 100, trackInventory: true }
      });

      const startTime = Date.now();

      await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: testCustomer.email,
          items: [
            {
              productId: product.id,
              quantity: 1,
              unitPrice: '15000.00',
              total: '15000.00'
            }
          ],
          organizationId: testOrganization.id,
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(300);
    });
  });

  describe('Error Handling & Edge Cases', () => {
    it('should handle duplicate SKUs gracefully', async () => {
      await productService.createProduct(testUser.id, {
        name: 'Product 1',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        sku: 'DUPLICATE-SKU',
        organizationId: testOrganization.id,
      });

      await expect(
        productService.createProduct(testUser.id, {
          name: 'Product 2',
          price: '20000.00',
          currency: 'NGN',
          category: 'Test',
          sku: 'DUPLICATE-SKU',
          organizationId: testOrganization.id,
        })
      ).rejects.toThrow('SKU already exists');
    });

    it('should handle invalid order quantities', async () => {
      const product = await productService.createProduct(testUser.id, {
        name: 'Order Test Product',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 10, trackInventory: true }
      });

      const response = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          customerEmail: testCustomer.email,
          items: [
            {
              productId: product.id,
              quantity: 0, // Invalid quantity
              unitPrice: '10000.00',
              total: '0.00'
            }
          ],
          organizationId: testOrganization.id,
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid quantity');
    });

    it('should handle concurrent inventory updates', async () => {
      const product = await productService.createProduct(testUser.id, {
        name: 'Concurrent Test Product',
        price: '10000.00',
        currency: 'NGN',
        category: 'Test',
        organizationId: testOrganization.id,
        inventory: { quantity: 100, trackInventory: true }
      });

      // Simulate concurrent updates
      const update1 = inventoryService.updateInventory(product.inventory.id, {
        quantity: 90,
        reason: 'sale',
        reference: 'ORDER-001'
      });

      const update2 = inventoryService.updateInventory(product.inventory.id, {
        quantity: 85,
        reason: 'sale',
        reference: 'ORDER-002'
      });

      await Promise.all([update1, update2]);

      // Verify final state is consistent
      const finalProduct = await productService.getProduct(product.id);
      expect(finalProduct.inventory.quantity).toBe(85);
    });
  });
});
