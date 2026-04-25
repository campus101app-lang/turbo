// backend/tests/critical-path/organization-tab.test.js
//
// Organization Tab - Multi-tenant Team Collaboration Testing
// Tests team management + permissions + workflows for enterprise organizations
//

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import app from '../../src/index.js';
import OrganizationService from '../../src/services/organizationService.js';
import UserService from '../../src/services/userService.js';
import RoleService from '../../src/services/roleService.js';
import WorkflowService from '../../src/services/workflowService.js';

const prisma = new PrismaClient();

describe('Organization Tab - Multi-tenant Operations', () => {
  let testOwner;
  let testOrganization;
  let testAdmin;
  let testManager;
  let testStaff;
  let authToken;
  let organizationService;
  let userService;
  let roleService;
  let workflowService;

  beforeEach(async () => {
    // Create organization owner
    testOwner = await prisma.user.create({
      data: {
        email: `owner-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'REGISTERED_BUSINESS',
        fullName: 'Organization Owner',
        businessName: 'Owner Business',
        phone: '+2348012345678',
        bvn: '12345678901',
      },
    });

    // Create test organization
    testOrganization = await prisma.organization.create({
      data: {
        name: 'Test Multi-tenant Organization',
        description: 'Test organization for team collaboration',
        businessType: 'LIMITED_LIABILITY',
        ownerUserId: testOwner.id,
        settings: {
          requireApprovalForInvoices: true,
          requireApprovalForExpenses: true,
          maxInvoiceAmount: '1000000.00',
          maxExpenseAmount: '500000.00',
        },
      },
    });

    // Create team members with different roles
    testAdmin = await prisma.user.create({
      data: {
        email: `admin-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Team Admin',
        phone: '+2348012345679',
      },
    });

    testManager = await prisma.user.create({
      data: {
        email: `manager-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Team Manager',
        phone: '+2348012345680',
      },
    });

    testStaff = await prisma.user.create({
      data: {
        email: `staff-${Date.now()}@test.com`,
        isVerified: true,
        accountType: 'INDIVIDUAL',
        fullName: 'Team Staff',
        phone: '+2348012345681',
      },
    });

    // Initialize services
    organizationService = new OrganizationService();
    userService = new UserService();
    roleService = new RoleService();
    workflowService = new WorkflowService();

    // Mock auth token for testing
    authToken = 'mock_jwt_token_for_org_tests';
  });

  afterEach(async () => {
    // Cleanup test data
    await prisma.organizationMember.deleteMany({ where: { organizationId: testOrganization.id } });
    await prisma.role.deleteMany({ where: { organizationId: testOrganization.id } });
    await prisma.workflow.deleteMany({ where: { organizationId: testOrganization.id } });
    await prisma.organization.delete({ where: { id: testOrganization.id } });
    await prisma.user.deleteMany({ where: { id: { in: [testOwner.id, testAdmin.id, testManager.id, testStaff.id] } } });
  });

  describe('Organization Setup', () => {
    it('should create organization with proper structure', async () => {
      const orgData = {
        name: 'New Test Organization',
        description: 'New organization for testing',
        businessType: 'SOLE_PROPRIETORSHIP',
        settings: {
          requireApprovalForInvoices: false,
          requireApprovalForExpenses: true,
          defaultCurrency: 'NGN',
          fiscalYearStart: '01-01',
        },
      };

      const response = await request(app)
        .post('/api/organization')
        .set('Authorization', `Bearer ${authToken}`)
        .send(orgData);

      expect(response.status).toBe(201);
      expect(response.body.organization).toBeDefined();
      expect(response.body.organization.name).toBe('New Test Organization');
      expect(response.body.organization.ownerUserId).toBe(testOwner.id);
      expect(response.body.organization.settings).toBeDefined();
    });

    it('should validate organization data completeness', async () => {
      const incompleteOrg = {
        name: '', // Missing name
        description: 'Test description',
        businessType: 'INVALID_TYPE', // Invalid business type
      };

      const response = await request(app)
        .post('/api/organization')
        .set('Authorization', `Bearer ${authToken}`)
        .send(incompleteOrg);

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors.length).toBeGreaterThan(0);
    });

    it('should create default roles for new organization', async () => {
      const newOrg = await organizationService.createOrganization(testOwner.id, {
        name: 'Default Roles Test Org',
        businessType: 'LIMITED_LIABILITY',
      });

      const defaultRoles = await roleService.getOrganizationRoles(newOrg.id);

      expect(defaultRoles).toHaveLength(4); // Owner, Admin, Manager, Staff
      expect(defaultRoles.some(r => r.name === 'Owner')).toBe(true);
      expect(defaultRoles.some(r => r.name === 'Admin')).toBe(true);
      expect(defaultRoles.some(r => r.name === 'Manager')).toBe(true);
      expect(defaultRoles.some(r => r.name === 'Staff')).toBe(true);
    });
  });

  describe('Team Member Management', () => {
    it('should invite team members with proper roles', async () => {
      const invitationData = {
        email: testAdmin.email,
        role: 'Admin',
        permissions: ['manage_invoices', 'manage_expenses', 'view_reports'],
        message: 'Join our team as an administrator',
      };

      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(invitationData);

      expect(response.status).toBe(201);
      expect(response.body.invitation).toBeDefined();
      expect(response.body.invitation.email).toBe(testAdmin.email);
      expect(response.body.invitation.role).toBe('Admin');
      expect(response.body.invitation.token).toBeDefined();
    });

    it('should handle team member invitations correctly', async () => {
      // Create invitation
      const invitation = await organizationService.inviteMember(testOrganization.id, {
        email: testManager.email,
        role: 'Manager',
        invitedBy: testOwner.id,
      });

      // Accept invitation
      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/accept-invitation`)
        .send({
          token: invitation.token,
          userId: testManager.id,
        });

      expect(response.status).toBe(200);
      expect(response.body.membership).toBeDefined();
      expect(response.body.membership.userId).toBe(testManager.id);
      expect(response.body.membership.role).toBe('Manager');

      // Verify member is added to organization
      const members = await organizationService.getOrganizationMembers(testOrganization.id);
      expect(members.some(m => m.userId === testManager.id)).toBe(true);
    });

    it('should validate role assignments', async () => {
      const invalidRoleData = {
        email: testStaff.email,
        role: 'InvalidRole', // Non-existent role
      };

      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidRoleData);

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Invalid role');
    });

    it('should handle member role changes', async () => {
      // Add member as Staff
      await organizationService.addMember(testOrganization.id, testStaff.id, 'Staff');

      // Promote to Manager
      const response = await request(app)
        .put(`/api/organization/${testOrganization.id}/members/${testStaff.id}/role`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ role: 'Manager' });

      expect(response.status).toBe(200);
      expect(response.body.membership.role).toBe('Manager');

      // Verify permissions updated
      const updatedMember = await organizationService.getMember(testOrganization.id, testStaff.id);
      expect(updatedMember.role).toBe('Manager');
    });

    it('should remove team members correctly', async () => {
      // Add member
      await organizationService.addMember(testOrganization.id, testStaff.id, 'Staff');

      // Remove member
      const response = await request(app)
        .delete(`/api/organization/${testOrganization.id}/members/${testStaff.id}`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);

      // Verify member removed
      const members = await organizationService.getOrganizationMembers(testOrganization.id);
      expect(members.some(m => m.userId === testStaff.id)).toBe(false);
    });
  });

  describe('Role-Based Permissions', () => {
    beforeEach(async () => {
      // Add members with different roles
      await organizationService.addMember(testOrganization.id, testAdmin.id, 'Admin');
      await organizationService.addMember(testOrganization.id, testManager.id, 'Manager');
      await organizationService.addMember(testOrganization.id, testStaff.id, 'Staff');
    });

    it('should enforce owner permissions', async () => {
      const ownerPermissions = await roleService.getUserPermissions(testOwner.id, testOrganization.id);

      expect(ownerPermissions).toContain('manage_organization');
      expect(ownerPermissions).toContain('manage_members');
      expect(ownerPermissions).toContain('manage_settings');
      expect(ownerPermissions).toContain('view_all_data');
    });

    it('should enforce admin permissions', async () => {
      const adminPermissions = await roleService.getUserPermissions(testAdmin.id, testOrganization.id);

      expect(adminPermissions).toContain('manage_invoices');
      expect(adminPermissions).toContain('manage_expenses');
      expect(adminPermissions).toContain('view_reports');
      expect(adminPermissions).not.toContain('manage_organization'); // Owner only
    });

    it('should enforce manager permissions', async () => {
      const managerPermissions = await roleService.getUserPermissions(testManager.id, testOrganization.id);

      expect(managerPermissions).toContain('create_invoices');
      expect(managerPermissions).toContain('create_expenses');
      expect(managerPermissions).toContain('view_team_reports');
      expect(managerPermissions).not.toContain('manage_members'); // Admin/Owner only
    });

    it('should enforce staff permissions', async () => {
      const staffPermissions = await roleService.getUserPermissions(testStaff.id, testOrganization.id);

      expect(staffPermissions).toContain('view_own_data');
      expect(staffPermissions).toContain('create_expenses');
      expect(staffPermissions).not.toContain('view_team_reports'); // Manager+ only
    });

    it('should validate permission-based access', async () => {
      // Test staff trying to access admin-only feature
      const hasPermission = await roleService.checkPermission(
        testStaff.id,
        testOrganization.id,
        'manage_members'
      );

      expect(hasPermission).toBe(false);

      // Test admin accessing allowed feature
      const adminHasPermission = await roleService.checkPermission(
        testAdmin.id,
        testOrganization.id,
        'manage_invoices'
      );

      expect(adminHasPermission).toBe(true);
    });

    it('should handle custom role creation', async () => {
      const customRoleData = {
        name: 'Accountant',
        description: 'Handles financial reporting and analysis',
        permissions: [
          'view_all_invoices',
          'view_all_expenses',
          'create_reports',
          'export_data'
        ],
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/roles`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(customRoleData);

      expect(response.status).toBe(201);
      expect(response.body.role).toBeDefined();
      expect(response.body.role.name).toBe('Accountant');
      expect(response.body.role.permissions).toHaveLength(4);
    });
  });

  describe('Workflow Management', () => {
    beforeEach(async () => {
      // Add members for workflow testing
      await organizationService.addMember(testOrganization.id, testAdmin.id, 'Admin');
      await organizationService.addMember(testOrganization.id, testManager.id, 'Manager');
    });

    it('should create approval workflows', async () => {
      const workflowData = {
        name: 'Invoice Approval Workflow',
        description: 'Multi-level approval for invoices over 100k',
        trigger: 'invoice_created',
        conditions: {
          amount: { operator: '>', value: '100000' },
          currency: 'NGN',
        },
        steps: [
          {
            type: 'approval',
            role: 'Manager',
            required: true,
            timeout: 72, // hours
          },
          {
            type: 'approval',
            role: 'Admin',
            required: true,
            timeout: 48,
          },
        ],
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/workflows`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(workflowData);

      expect(response.status).toBe(201);
      expect(response.body.workflow).toBeDefined();
      expect(response.body.workflow.steps).toHaveLength(2);
      expect(response.body.workflow.steps[0].role).toBe('Manager');
    });

    it('should trigger workflows based on conditions', async () => {
      // Create workflow for high-value invoices
      await workflowService.createWorkflow(testOrganization.id, {
        name: 'High Value Invoice Approval',
        trigger: 'invoice_created',
        conditions: { amount: { operator: '>', value: '500000' } },
        steps: [
          {
            type: 'approval',
            role: 'Admin',
            required: true,
          },
        ],
      });

      // Create invoice that triggers workflow
      const invoiceData = {
        customerEmail: 'customer@test.com',
        amount: '600000.00', // Above threshold
        currency: 'NGN',
        organizationId: testOrganization.id,
      };

      const response = await request(app)
        .post('/api/invoices')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invoiceData);

      expect(response.status).toBe(201);
      expect(response.body.invoice.workflowStatus).toBe('pending_approval');

      // Verify workflow instance created
      const workflowInstances = await workflowService.getWorkflowInstances(
        testOrganization.id,
        { invoiceId: response.body.invoice.id }
      );

      expect(workflowInstances).toHaveLength(1);
      expect(workflowInstances[0].status).toBe('pending');
    });

    it('should process workflow steps correctly', async () => {
      // Create and trigger workflow
      const workflow = await workflowService.createWorkflow(testOrganization.id, {
        name: 'Test Approval Workflow',
        trigger: 'manual',
        steps: [
          {
            type: 'approval',
            role: 'Manager',
            required: true,
          },
        ],
      });

      const instance = await workflowService.createWorkflowInstance(workflow.id, {
        triggerData: { type: 'manual', userId: testOwner.id },
      });

      // Process approval step
      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/workflows/${instance.id}/approve`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          stepId: instance.steps[0].id,
          approved: true,
          comments: 'Approved for processing',
        });

      expect(response.status).toBe(200);
      expect(response.body.instance.status).toBe('completed');
    });

    it('should handle workflow rejections', async () => {
      const workflow = await workflowService.createWorkflow(testOrganization.id, {
        name: 'Rejection Test Workflow',
        trigger: 'manual',
        steps: [
          {
            type: 'approval',
            role: 'Manager',
            required: true,
          },
        ],
      });

      const instance = await workflowService.createWorkflowInstance(workflow.id, {
        triggerData: { type: 'manual', userId: testOwner.id },
      });

      // Reject workflow step
      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/workflows/${instance.id}/reject`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          stepId: instance.steps[0].id,
          rejected: true,
          reason: 'Insufficient documentation',
        });

      expect(response.status).toBe(200);
      expect(response.body.instance.status).toBe('rejected');
    });
  });

  describe('Organization Analytics', () => {
    beforeEach(async () => {
      // Add members for analytics
      await organizationService.addMember(testOrganization.id, testAdmin.id, 'Admin');
      await organizationService.addMember(testOrganization.id, testManager.id, 'Manager');
      await organizationService.addMember(testOrganization.id, testStaff.id, 'Staff');

      // Create test data for analytics
      await prisma.invoice.createMany({
        data: [
          {
            userId: testOwner.id,
            organizationId: testOrganization.id,
            customerEmail: 'customer1@test.com',
            amount: '100000.00',
            currency: 'NGN',
            status: 'paid',
            createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
          },
          {
            userId: testAdmin.id,
            organizationId: testOrganization.id,
            customerEmail: 'customer2@test.com',
            amount: '50000.00',
            currency: 'NGN',
            status: 'pending',
            createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
          },
        ],
      });

      await prisma.expense.createMany({
        data: [
          {
            userId: testManager.id,
            organizationId: testOrganization.id,
            amount: '25000.00',
            currency: 'NGN',
            category: 'Office Supplies',
            status: 'approved',
            createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
          },
          {
            userId: testStaff.id,
            organizationId: testOrganization.id,
            amount: '15000.00',
            currency: 'NGN',
            category: 'Travel',
            status: 'pending',
            createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
          },
        ],
      });
    });

    it('should generate organization overview report', async () => {
      const response = await request(app)
        .get(`/api/organization/${testOrganization.id}/overview`)
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.overview).toBeDefined();
      expect(response.body.overview.totalMembers).toBe(4); // Owner + 3 members
      expect(response.body.overview.totalInvoices).toBe(2);
      expect(response.body.overview.totalExpenses).toBe(2);
      expect(response.body.overview.totalRevenue).toBe('100000.00');
      expect(response.body.overview.totalExpensesAmount).toBe('40000.00');
    });

    it('should generate team performance report', async () => {
      const response = await request(app)
        .get(`/api/organization/${testOrganization.id}/team-performance`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
          endDate: new Date().toISOString(),
        });

      expect(response.status).toBe(200);
      expect(response.body.performance).toBeDefined();
      expect(Array.isArray(response.body.performance.members)).toBe(true);
      expect(response.body.performance.members.length).toBeGreaterThan(0);
    });

    it('should generate financial summary report', async () => {
      const response = await request(app)
        .get(`/api/organization/${testOrganization.id}/financial-summary`)
        .set('Authorization', `Bearer ${authToken}`)
        .query({
          period: 'monthly',
          year: new Date().getFullYear(),
        });

      expect(response.status).toBe(200);
      expect(response.body.summary).toBeDefined();
      expect(response.body.summary.revenue).toBeDefined();
      expect(response.body.summary.expenses).toBeDefined();
      expect(response.body.summary.profit).toBeDefined();
    });
  });

  describe('Organization Settings', () => {
    it('should update organization settings', async () => {
      const settingsData = {
        requireApprovalForInvoices: false,
        requireApprovalForExpenses: true,
        maxInvoiceAmount: '2000000.00',
        maxExpenseAmount: '750000.00',
        workingHours: {
          start: '09:00',
          end: '17:00',
          timezone: 'Africa/Lagos',
        },
      };

      const response = await request(app)
        .put(`/api/organization/${testOrganization.id}/settings`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(settingsData);

      expect(response.status).toBe(200);
      expect(response.body.settings.requireApprovalForInvoices).toBe(false);
      expect(response.body.settings.maxInvoiceAmount).toBe('2000000.00');
    });

    it('should validate setting constraints', async () => {
      const invalidSettings = {
        maxInvoiceAmount: '-1000', // Negative amount
        maxExpenseAmount: '0', // Zero amount
        workingHours: {
          start: '17:00',
          end: '09:00', // End before start
        },
      };

      const response = await request(app)
        .put(`/api/organization/${testOrganization.id}/settings`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidSettings);

      expect(response.status).toBe(400);
      expect(response.body.errors).toBeDefined();
    });

    it('should handle organization branding', async () => {
      const brandingData = {
        logo: 'https://example.com/logo.png',
        primaryColor: '#1e40af',
        secondaryColor: '#64748b',
        customDomain: 'business.dayfi.me',
      };

      const response = await request(app)
        .put(`/api/organization/${testOrganization.id}/branding`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(brandingData);

      expect(response.status).toBe(200);
      expect(response.body.branding.logo).toBe('https://example.com/logo.png');
      expect(response.body.branding.primaryColor).toBe('#1e40af');
    });
  });

  describe('Performance Requirements', () => {
    it('should create organization in under 300ms', async () => {
      const startTime = Date.now();

      await request(app)
        .post('/api/organization')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Performance Test Org',
          businessType: 'LIMITED_LIABILITY',
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(300);
    });

    it('should invite team member in under 200ms', async () => {
      const startTime = Date.now();

      await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'newmember@test.com',
          role: 'Staff',
        });

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(200);
    });

    it('should retrieve organization overview in under 150ms', async () => {
      const startTime = Date.now();

      await request(app)
        .get(`/api/organization/${testOrganization.id}/overview`)
        .set('Authorization', `Bearer ${authToken}`);

      const endTime = Date.now();
      const duration = endTime - startTime;

      expect(duration).toBeLessThan(150);
    });
  });

  describe('Security & Access Control', () => {
    it('should prevent unauthorized organization access', async () => {
      const response = await request(app)
        .get(`/api/organization/${testOrganization.id}/members`)
        .set('Authorization', 'Bearer unauthorized_token');

      expect(response.status).toBe(401);
    });

    it('should enforce role-based feature access', async () => {
      // Add staff member
      await organizationService.addMember(testOrganization.id, testStaff.id, 'Staff');

      // Staff trying to access admin-only feature
      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/invite`)
        .set('Authorization', `Bearer staff_token_for_${testStaff.id}`)
        .send({
          email: 'new@test.com',
          role: 'Admin',
        });

      expect(response.status).toBe(403);
      expect(response.body.error).toContain('Insufficient permissions');
    });

    it('should handle organization ownership transfer', async () => {
      const response = await request(app)
        .post(`/api/organization/${testOrganization.id}/transfer-ownership`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          newOwnerId: testAdmin.id,
          confirmation: true,
        });

      expect(response.status).toBe(200);
      expect(response.body.organization.ownerUserId).toBe(testAdmin.id);

      // Verify old owner becomes admin
      const oldOwnerMembership = await organizationService.getMember(testOrganization.id, testOwner.id);
      expect(oldOwnerMembership.role).toBe('Admin');
    });
  });
});
