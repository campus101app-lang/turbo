// src/models/AuditLog.js
// Audit logging system for compliance and security

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class AuditLog {
  static async log({
    userId,
    organizationId,
    action,
    resourceType,
    resourceId,
    details,
    ipAddress,
    userAgent,
  }) {
    try {
      await prisma.auditLog.create({
        data: {
          userId,
          organizationId,
          action,
          resourceType,
          resourceId,
          details: details ? JSON.stringify(details) : null,
          ipAddress,
          userAgent,
          timestamp: new Date(),
        },
      });
    } catch (error) {
      console.error('Failed to create audit log:', error);
      // Don't throw - audit logging failure shouldn't break the main flow
    }
  }

  static async logTransaction({
    userId,
    organizationId,
    transactionId,
    type,
    amount,
    asset,
    fromAddress,
    toAddress,
    status,
    details,
    ipAddress,
    userAgent,
  }) {
    return this.log({
      userId,
      organizationId,
      action: `transaction_${type}`,
      resourceType: 'transaction',
      resourceId: transactionId,
      details: {
        amount,
        asset,
        fromAddress,
        toAddress,
        status,
        ...details,
      },
      ipAddress,
      userAgent,
    });
  }

  static async logPermissionChange({
    userId,
    organizationId,
    targetUserId,
    action, // 'role_changed', 'member_added', 'member_removed'
    previousRole,
    newRole,
    ipAddress,
    userAgent,
  }) {
    return this.log({
      userId,
      organizationId,
      action: `permission_${action}`,
      resourceType: 'organization_member',
      resourceId: targetUserId,
      details: {
        targetUserId,
        previousRole,
        newRole,
      },
      ipAddress,
      userAgent,
    });
  }

  static async logInvoiceAction({
    userId,
    organizationId,
    invoiceId,
    action, // 'created', 'submitted_for_approval', 'approved', 'rejected', 'sent', 'paid'
    approvalLevel,
    requiredApprovals,
    details,
    ipAddress,
    userAgent,
  }) {
    return this.log({
      userId,
      organizationId,
      action: `invoice_${action}`,
      resourceType: 'invoice',
      resourceId: invoiceId,
      details: {
        approvalLevel,
        requiredApprovals,
        ...details,
      },
      ipAddress,
      userAgent,
    });
  }

  static async logExpenseAction({
    userId,
    organizationId,
    expenseId,
    action, // 'created', 'submitted', 'approved', 'rejected', 'reimbursed'
    amount,
    currency,
    category,
    details,
    ipAddress,
    userAgent,
  }) {
    return this.log({
      userId,
      organizationId,
      action: `expense_${action}`,
      resourceType: 'expense',
      resourceId: expenseId,
      details: {
        amount,
        currency,
        category,
        ...details,
      },
      ipAddress,
      userAgent,
    });
  }

  static async logAuthentication({
    userId,
    action, // 'login', 'logout', 'login_failed', 'password_changed', '2fa_enabled'
    ipAddress,
    userAgent,
    details,
  }) {
    return this.log({
      userId,
      action: `auth_${action}`,
      resourceType: 'user',
      resourceId: userId,
      details,
      ipAddress,
      userAgent,
    });
  }

  static async logOrganizationChange({
    userId,
    organizationId,
    action, // 'created', 'updated', 'plan_changed', 'settings_updated'
    previousValues,
    newValues,
    ipAddress,
    userAgent,
  }) {
    return this.log({
      userId,
      organizationId,
      action: `organization_${action}`,
      resourceType: 'organization',
      resourceId: organizationId,
      details: {
        previousValues,
        newValues,
      },
      ipAddress,
      userAgent,
    });
  }

  static async getAuditLogs({
    organizationId,
    userId,
    resourceType,
    resourceId,
    action,
    startDate,
    endDate,
    page = 1,
    limit = 50,
  }) {
    const where = {};
    
    if (organizationId) where.organizationId = organizationId;
    if (userId) where.userId = userId;
    if (resourceType) where.resourceType = resourceType;
    if (resourceId) where.resourceId = resourceId;
    if (action) where.action = { contains: action };
    
    if (startDate || endDate) {
      where.timestamp = {};
      if (startDate) where.timestamp.gte = startDate;
      if (endDate) where.timestamp.lte = endDate;
    }

    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        orderBy: { timestamp: 'desc' },
        skip,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              email: true,
              fullName: true,
              businessName: true,
            },
          },
        },
      }),
      prisma.auditLog.count({ where }),
    ]);

    return {
      logs,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async getComplianceReport({
    organizationId,
    startDate,
    endDate,
  }) {
    const where = {
      organizationId,
    };
    
    if (startDate || endDate) {
      where.timestamp = {};
      if (startDate) where.timestamp.gte = startDate;
      if (endDate) where.timestamp.lte = endDate;
    }

    const [
      totalLogs,
      transactionLogs,
      authLogs,
      permissionLogs,
      invoiceLogs,
      expenseLogs,
    ] = await Promise.all([
      prisma.auditLog.count({ where }),
      prisma.auditLog.count({
        where: { ...where, action: { startsWith: 'transaction_' } },
      }),
      prisma.auditLog.count({
        where: { ...where, action: { startsWith: 'auth_' } },
      }),
      prisma.auditLog.count({
        where: { ...where, action: { startsWith: 'permission_' } },
      }),
      prisma.auditLog.count({
        where: { ...where, action: { startsWith: 'invoice_' } },
      }),
      prisma.auditLog.count({
        where: { ...where, action: { startsWith: 'expense_' } },
      }),
    ]);

    return {
      summary: {
        totalActivities: totalLogs,
        transactionCount: transactionLogs,
        authenticationEvents: authLogs,
        permissionChanges: permissionLogs,
        invoiceActions: invoiceLogs,
        expenseActions: expenseLogs,
        period: { startDate, endDate },
      },
    };
  }
}

export default AuditLog;
