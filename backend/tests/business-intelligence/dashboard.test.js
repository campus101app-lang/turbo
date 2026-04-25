// backend/tests/business-intelligence/dashboard.test.js
//
// Business Intelligence Dashboard Testing
// Tests dashboard performance + KPI accuracy + real-time updates
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';
import DashboardService from '../../src/services/dashboardService.js';
import AnalyticsService from '../../src/services/analyticsService.js';
import ReportService from '../../src/services/reportService.js';

const prisma = new PrismaClient();

describe('Business Intelligence Dashboard', () => {
  let testUser;
  let testOrganization;
  let authToken;
  let dashboardService;
  let analyticsService;
  let reportService;

  beforeEach(async () => {
    // Create test user with business profile
    testUser = await prisma.user.create({
      data: {
        email: `dashboard-test-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Dashboard Test User',
        businessName: 'Dashboard Business Ltd',
        phone: '+2348012345678',
        bvn: '12345678901',
      },
    });

    // Create test organization
    testOrganization = await prisma.organization.create({
      data: {
        name: 'Dashboard Test Organization',
        description: 'Organization for dashboard testing',
        businessType: 'LIMITED_LIABILITY',
        ownerUserId: testUser.id,
      },
    });

    // Initialize services
    dashboardService = new DashboardService();
    analyticsService = new AnalyticsService();
    reportService = new ReportService();

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_dashboard_tests';

    // Create test data for dashboard
    await createTestDashboardData();
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.analyticsCache.deleteMany({ where: { userId: testUser.id } });
    await prisma.dashboardWidget.deleteMany({ where: { userId: testUser.id } });
    await prisma.kpiMetric.deleteMany({ where: { organizationId: testOrganization.id } });
    await prisma.transaction.deleteMany({ where: { userId: testUser.id } });
    await prisma.invoice.deleteMany({ where: { userId: testUser.id } });
    await prisma.expense.deleteMany({ where: { userId: testUser.id } });
    await prisma.organization.delete({ where: { id: testOrganization.id } });
    await prisma.user.delete({ where: { id: testUser.id } });
  });

  async function createTestDashboardData() {
    // Create transactions
    await prisma.transaction.createMany({
      data: [
        {
          userId: testUser.id,
          type: 'payment',
          amount: '50000.00',
          currency: 'NGN',
          status: 'completed',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
        },
        {
          userId: testUser.id,
          type: 'payment',
          amount: '75000.00',
          currency: 'NGN',
          status: 'completed',
          createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        },
        {
          userId: testUser.id,
          type: 'payment',
          amount: '25000.00',
          currency: 'NGN',
          status: 'pending',
          createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        },
      ],
    });

    // Create invoices
    await prisma.invoice.createMany({
      data: [
        {
          userId: testUser.id,
          organizationId: testOrganization.id,
          customerEmail: 'customer1@test.com',
          amount: '100000.00',
          currency: 'NGN',
          status: 'paid',
          createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
        },
        {
          userId: testUser.id,
          organizationId: testOrganization.id,
          customerEmail: 'customer2@test.com',
          amount: '60000.00',
          currency: 'NGN',
          status: 'pending',
          createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        },
      ],
    });

    // Create expenses
    await prisma.expense.createMany({
      data: [
        {
          userId: testUser.id,
          organizationId: testOrganization.id,
          amount: '30000.00',
          currency: 'NGN',
          category: 'Office Supplies',
          status: 'approved',
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        },
        {
          userId: testUser.id,
          organizationId: testOrganization.id,
          amount: '20000.00',
          currency: 'NGN',
          category: 'Travel',
          status: 'pending',
          createdAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
        },
      ],
    });

    // Create KPI metrics
    await prisma.kpiMetric.createMany({
      data: [
        {
          organizationId: testOrganization.id,
          name: 'Monthly Revenue',
          value: '160000.00',
          target: '200000.00',
          unit: 'NGN',
          category: 'financial',
          period: 'monthly',
          calculatedAt: new Date(),
        },
        {
          organizationId: testOrganization.id,
          name: 'Customer Acquisition',
          value: '25',
          target: '30',
          unit: 'count',
          category: 'growth',
          period: 'monthly',
          calculatedAt: new Date(),
        },
        {
          organizationId: testOrganization.id,
          name: 'Profit Margin',
          value: '65.5',
          target: '70.0',
          unit: 'percentage',
          category: 'financial',
          period: 'monthly',
          calculatedAt: new Date(),
        },
      ],
    });
  }

  describe('Dashboard Loading', () => {
    it('should load dashboard with all widgets', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      expect(response.status).toBe(200);
      expect(response.body.dashboard).toBeDefined();
      expect(response.body.dashboard.widgets).toBeDefined();
      expect(Array.isArray(response.body.dashboard.widgets)).toBe(true);
      expect(response.body.dashboard.widgets.length).toBeGreaterThan(0);
    });

    it('should load dashboard widgets in correct order', async () => {
      // Create custom widget order
      await prisma.dashboardWidget.createMany({
        data: [
          {
            userId: testUser.id,
            widgetType: 'revenue_chart',
            position: 1,
            config: { timeframe: 'monthly' },
          },
          {
            userId: testUser.id,
            widgetType: 'kpi_cards',
            position: 2,
            config: { metrics: ['revenue', 'profit'] },
          },
          {
            userId: testUser.id,
            widgetType: 'recent_transactions',
            position: 3,
            config: { limit: 10 },
          },
        ],
      });

      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      const widgets = response.body.dashboard.widgets;
      
      expect(widgets[0].widgetType).toBe('revenue_chart');
      expect(widgets[1].widgetType).toBe('kpi_cards');
      expect(widgets[2].widgetType).toBe('recent_transactions');
      
      // Verify position ordering
      expect(widgets[0].position).toBe(1);
      expect(widgets[1].position).toBe(2);
      expect(widgets[2].position).toBe(3);
    });

    it('should handle dashboard loading errors gracefully', async () => {
      // Simulate database error by using invalid organization
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: 'invalid-org-id' });

      expect(response.status).toBe(404);
      expect(response.body.error).toBeDefined();
    });
  });

  describe('KPI Calculation', () => {
    it('should calculate KPI metrics accurately', async () => {
      const response = await request(app)
        .get('/api/dashboard/kpis')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ 
          organizationId: testOrganization.id,
          period: 'monthly',
        });

      expect(response.status).toBe(200);
      expect(response.body.kpis).toBeDefined();
      expect(Array.isArray(response.body.kpis)).toBe(true);

      // Check specific KPI calculations
      const revenueKPI = response.body.kpis.find(kpi => kpi.name === 'Monthly Revenue');
      expect(revenueKPI).toBeDefined();
      expect(revenueKPI.value).toBe('160000.00');
      expect(revenueKPI.target).toBe('200000.00');
      expect(revenueKPI.achievementRate).toBe(80); // 160000/200000 * 100

      const profitKPI = response.body.kpis.find(kpi => kpi.name === 'Profit Margin');
      expect(profitKPI).toBeDefined();
      expect(profitKPI.value).toBe('65.5');
      expect(profitKPI.target).toBe('70.0');
    });

    it('should calculate KPI trends correctly', async () => {
      // Create historical KPI data
      const historicalData = [
        { period: '2024-01', value: '120000.00' },
        { period: '2024-02', value: '140000.00' },
        { period: '2024-03', value: '160000.00' },
      ];

      for (const data of historicalData) {
        await prisma.kpiMetric.create({
          data: {
            organizationId: testOrganization.id,
            name: 'Monthly Revenue',
            value: data.value,
            target: '200000.00',
            unit: 'NGN',
            category: 'financial',
            period: 'monthly',
            calculatedAt: new Date(data.period + '-01'),
          },
        });
      }

      const response = await request(app)
        .get('/api/dashboard/kpis/trends')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          kpiName: 'Monthly Revenue',
          periods: 3,
        });

      expect(response.status).toBe(200);
      expect(response.body.trend).toBeDefined();
      expect(response.body.trend.data).toHaveLength(3);
      expect(response.body.trend.trend).toBe('increasing'); // 120k -> 140k -> 160k
      expect(response.body.trend.growthRate).toBeCloseTo(33.33, 1); // (160-120)/120 * 100
    });

    it('should handle KPI target achievements', async () => {
      const response = await request(app)
        .get('/api/dashboard/kpis/achievements')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      expect(response.status).toBe(200);
      expect(response.body.achievements).toBeDefined();

      // Check achievement status
      const achievements = response.body.achievements;
      expect(achievements.total).toBe(3);
      expect(achievements.achieved).toBe(1); // Only Customer Acquisition (25/30) is close to target
      expect(achievements.missed).toBe(2); // Revenue and Profit Margin below target
    });
  });

  describe('Real-time Updates', () => {
    it('should provide real-time dashboard updates', async () => {
      // Get initial dashboard state
      const initialResponse = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      const initialRevenue = initialResponse.body.dashboard.widgets
        .find(w => w.widgetType === 'revenue_chart')
        ?.data?.totalRevenue || '0';

      // Create new transaction
      await prisma.transaction.create({
        data: {
          userId: testUser.id,
          type: 'payment',
          amount: '30000.00',
          currency: 'NGN',
          status: 'completed',
          createdAt: new Date(),
        },
      });

      // Get updated dashboard
      const updatedResponse = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ 
          organizationId: testOrganization.id,
          refresh: true, // Force refresh
        });

      const updatedRevenue = updatedResponse.body.dashboard.widgets
        .find(w => w.widgetType === 'revenue_chart')
        ?.data?.totalRevenue || '0';

      expect(parseFloat(updatedRevenue)).toBeGreaterThan(parseFloat(initialRevenue));
    });

    it('should handle WebSocket real-time updates', async () => {
      // Test WebSocket connection for real-time updates
      const wsUrl = `ws://localhost:3001/dashboard/updates?token=${authToken}&organizationId=${testOrganization.id}`;
      
      // This would typically test WebSocket connection
      // For now, we'll test the endpoint that would send updates
      const response = await request(app)
        .post('/api/dashboard/subscribe')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          organizationId: testOrganization.id,
          events: ['transaction_created', 'invoice_paid', 'expense_approved'],
        });

      expect(response.status).toBe(200);
      expect(response.body.subscriptionId).toBeDefined();
      expect(response.body.events).toHaveLength(3);
    });

    it('should cache dashboard data for performance', async () => {
      // First request - should cache data
      const startTime1 = Date.now();
      const response1 = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });
      const duration1 = Date.now() - startTime1;

      // Second request - should use cache
      const startTime2 = Date.now();
      const response2 = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });
      const duration2 = Date.now() - startTime2;

      expect(response1.status).toBe(200);
      expect(response2.status).toBe(200);
      expect(duration2).toBeLessThan(duration1); // Cached request should be faster

      // Verify cache entry exists
      const cacheEntry = await prisma.analyticsCache.findFirst({
        where: { 
          userId: testUser.id,
          key: `dashboard_${testOrganization.id}`,
        },
      });

      expect(cacheEntry).toBeDefined();
      expect(cacheEntry.data).toBeDefined();
    });
  });

  describe('Chart Rendering', () => {
    it('should render revenue charts correctly', async () => {
      const response = await request(app)
        .get('/api/dashboard/charts/revenue')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          period: 'monthly',
          chartType: 'line',
        });

      expect(response.status).toBe(200);
      expect(response.body.chart).toBeDefined();
      expect(response.body.chart.type).toBe('line');
      expect(response.body.chart.data).toBeDefined();
      expect(response.body.chart.data.labels).toBeDefined();
      expect(response.body.chart.data.datasets).toBeDefined();
      expect(Array.isArray(response.body.chart.data.datasets)).toBe(true);
    });

    it('should render multi-dataset charts', async () => {
      const response = await request(app)
        .get('/api/dashboard/charts/comparison')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          metrics: ['revenue', 'expenses', 'profit'],
          period: 'monthly',
        });

      expect(response.status).toBe(200);
      expect(response.body.chart).toBeDefined();
      expect(response.body.chart.data.datasets).toHaveLength(3); // revenue, expenses, profit
      
      const datasets = response.body.chart.data.datasets;
      expect(datasets[0].label).toBe('Revenue');
      expect(datasets[1].label).toBe('Expenses');
      expect(datasets[2].label).toBe('Profit');
    });

    it('should handle different chart types', async () => {
      const chartTypes = ['line', 'bar', 'pie', 'doughnut', 'area'];
      
      for (const chartType of chartTypes) {
        const response = await request(app)
          .get('/api/dashboard/charts/revenue')
          .set('Authorization', `Bearer ${authToken}`)
          .query({
            organizationId: testOrganization.id,
            chartType,
          });

        expect(response.status).toBe(200);
        expect(response.body.chart.type).toBe(chartType);
      }
    });

    it('should provide chart export functionality', async () => {
      const response = await request(app)
        .get('/api/dashboard/charts/revenue/export')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          format: 'png',
          period: 'monthly',
        });

      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toContain('image/');
    });
  });

  describe('Data Aggregation', () => {
    it('should aggregate data across different time periods', async () => {
      const periods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];
      
      for (const period of periods) {
        const response = await request(app)
          .get('/api/dashboard/aggregated-data')
          .set('Authorization', `Bearer ${authToken}`)
          .query({
            organizationId: testOrganization.id,
            period,
            metrics: ['revenue', 'transactions', 'customers'],
          });

        expect(response.status).toBe(200);
        expect(response.body.data).toBeDefined();
        expect(response.body.data.period).toBe(period);
        expect(response.body.data.aggregations).toBeDefined();
      }
    });

    it('should handle complex data aggregations', async () => {
      const response = await request(app)
        .get('/api/dashboard/advanced-analytics')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          dimensions: ['customer_segment', 'product_category', 'payment_method'],
          metrics: ['revenue', 'profit_margin', 'customer_lifetime_value'],
        });

      expect(response.status).toBe(200);
      expect(response.body.analytics).toBeDefined();
      expect(response.body.analytics.dimensions).toHaveLength(3);
      expect(response.body.analytics.metrics).toHaveLength(3);
    });

    it('should calculate rolling averages and trends', async () => {
      const response = await request(app)
        .get('/api/dashboard/trends/rolling-average')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          metric: 'revenue',
          window: 7, // 7-day rolling average
        });

      expect(response.status).toBe(200);
      expect(response.body.trend).toBeDefined();
      expect(response.body.trend.rollingAverage).toBeDefined();
      expect(Array.isArray(response.body.trend.rollingAverage)).toBe(true);
    });
  });

  describe('Performance Requirements', () => {
    it('should load dashboard in under 2 seconds', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(response.status).toBe(200);
      expect(duration).toBeLessThan(2000);
    });

    it('should calculate KPIs in under 500ms', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/dashboard/kpis')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: testOrganization.id });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(response.status).toBe(200);
      expect(duration).toBeLessThan(500);
    });

    it('should render charts in under 1 second', async () => {
      const startTime = Date.now();

      const response = await request(app)
        .get('/api/dashboard/charts/revenue')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          chartType: 'line',
          period: 'monthly',
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(response.status).toBe(200);
      expect(duration).toBeLessThan(1000);
    });

    it('should handle concurrent dashboard requests', async () => {
      const concurrentRequests = Array(20).fill().map(() =>
        request(app)
          .get('/api/dashboard')
          .set('Authorization', `Bearer ${authToken}`)
          .query({ organizationId: testOrganization.id })
      );

      const startTime = Date.now();
      const responses = await Promise.allSettled(concurrentRequests);
      const endTime = Date.now();

      const successfulRequests = responses.filter(r => 
        r.status === 'fulfilled' && r.value.status === 200
      ).length;

      expect(successfulRequests).toBeGreaterThan(18); // At least 90% success
      expect(endTime - startTime).toBeLessThan(3000); // Under 3 seconds total
    });
  });

  describe('Error Handling', () => {
    it('should handle missing organization data gracefully', async () => {
      const response = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ organizationId: 'non-existent-org' });

      expect(response.status).toBe(404);
      expect(response.body.error).toContain('Organization not found');
    });

    it('should handle invalid KPI calculations', async () => {
      const response = await request(app)
        .get('/api/dashboard/kpis')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          period: 'invalid_period',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBeDefined();
    });

    it('should handle chart rendering errors', async () => {
      const response = await request(app)
        .get('/api/dashboard/charts/revenue')
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          organizationId: testOrganization.id,
          chartType: 'invalid_chart_type',
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid chart type');
    });
  });

  describe('Dashboard Customization', () => {
    it('should allow widget customization', async () => {
      const widgetConfig = {
        widgets: [
          {
            widgetType: 'custom_kpi',
            position: 1,
            config: {
              title: 'Custom Revenue KPI',
              metric: 'revenue',
              format: 'currency',
              comparison: 'previous_period',
            },
          },
          {
            widgetType: 'custom_chart',
            position: 2,
            config: {
              title: 'Sales Trend',
              chartType: 'area',
              dataSource: 'transactions',
            },
          },
        ],
      };

      const response = await request(app)
        .post('/api/dashboard/customize')
        .set('Authorization', `Bearer ${authToken}`)
        .send(widgetConfig);

      expect(response.status).toBe(200);
      expect(response.body.dashboard.widgets).toHaveLength(2);
      expect(response.body.dashboard.widgets[0].widgetType).toBe('custom_kpi');
    });

    it('should save dashboard preferences', async () => {
      const preferences = {
        defaultPeriod: 'monthly',
        theme: 'dark',
        autoRefresh: true,
        refreshInterval: 300, // 5 minutes
        layout: 'grid',
      };

      const response = await request(app)
        .put('/api/dashboard/preferences')
        .set('Authorization', `Bearer ${authToken}`)
        .send(preferences);

      expect(response.status).toBe(200);
      expect(response.body.preferences.defaultPeriod).toBe('monthly');
      expect(response.body.preferences.theme).toBe('dark');
    });

    it('should support dashboard templates', async () => {
      const response = await request(app)
        .get('/api/dashboard/templates')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.templates).toBeDefined();
      expect(Array.isArray(response.body.templates)).toBe(true);

      // Apply template
      const templateResponse = await request(app)
        .post('/api/dashboard/apply-template')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          templateId: response.body.templates[0].id,
          organizationId: testOrganization.id,
        });

      expect(templateResponse.status).toBe(200);
      expect(templateResponse.dashboard).toBeDefined();
    });
  });
});
