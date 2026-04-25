// src/middleware/auditLogger.js
// Automatic audit logging middleware for API endpoints

import AuditLog from '../models/AuditLog.js';

export function auditLogger(options = {}) {
  return async (req, res, next) => {
    // Skip audit logging for health checks and static assets
    if (req.path.startsWith('/health') || req.path.startsWith('/static')) {
      return next();
    }

    // Store original res.json method to intercept responses
    const originalJson = res.json;
    
    res.json = function(data) {
      // Log the API call after response is sent
      setImmediate(() => {
        logApiCall(req, res, data, options);
      });
      
      return originalJson.call(this, data);
    };

    // Also log errors
    const originalSend = res.send;
    res.send = function(data) {
      setImmediate(() => {
        logApiCall(req, res, data, options);
      });
      
      return originalSend.call(this, data);
    };

    next();
  };
}

async function logApiCall(req, res, responseData, options) {
  try {
    // Skip logging if audit is explicitly disabled
    if (options.enabled === false) {
      return;
    }

    // Get user and organization info from authenticated request
    const userId = req.user?.id;
    const organizationId = req.user?.currentOrganization?.id || 
                         extractOrganizationIdFromRequest(req);

    // Skip logging for non-authenticated endpoints unless specified
    if (!userId && !options.logUnauthenticated) {
      return;
    }

    // Determine action based on HTTP method and path
    const action = determineAction(req.method, req.path, res.statusCode);
    const resourceType = determineResourceType(req.path);
    const resourceId = extractResourceId(req, responseData);

    // Skip logging for certain low-value actions
    if (options.skipActions?.includes(action)) {
      return;
    }

    // Log the audit entry
    await AuditLog.log({
      userId,
      organizationId,
      action,
      resourceType,
      resourceId,
      details: {
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        requestBody: sanitizeRequestBody(req.body),
        responseSummary: sanitizeResponseData(responseData),
        duration: Date.now() - req.startTime,
      },
      ipAddress: getClientIP(req),
      userAgent: req.get('User-Agent'),
    });

  } catch (error) {
    console.error('Audit logging failed:', error);
    // Don't throw - audit logging failure shouldn't break the main flow
  }
}

function determineAction(method, path, statusCode) {
  const pathParts = path.split('/').filter(part => part && part !== 'api');
  const resource = pathParts[0] || 'unknown';
  const subResource = pathParts[1];
  
  // Determine action based on HTTP method and status code
  let action = method.toLowerCase();
  
  if (statusCode >= 400) {
    action += '_failed';
  }
  
  // Add specific action context
  switch (resource) {
    case 'auth':
      if (path.includes('/login')) action = 'auth_login';
      else if (path.includes('/logout')) action = 'auth_logout';
      else if (path.includes('/register')) action = 'auth_register';
      else action = `auth_${subResource || 'unknown'}`;
      break;
      
    case 'invoices':
      if (subResource && subResource.match(/^[0-9a-f]{24}$/i)) {
        if (method === 'POST' && path.includes('/approve')) action = 'invoice_approved';
        else if (method === 'POST' && path.includes('/reject')) action = 'invoice_rejected';
        else if (method === 'POST' && path.includes('/send')) action = 'invoice_sent';
        else if (method === 'POST' && path.includes('/submit-for-approval')) action = 'invoice_submitted_for_approval';
        else action = `invoice_${method.toLowerCase()}`;
      } else {
        action = method === 'POST' ? 'invoice_created' : `invoice_${method.toLowerCase()}`;
      }
      break;
      
    case 'expenses':
      if (subResource && subResource.match(/^[0-9a-f]{24}$/i)) {
        if (method === 'POST' && path.includes('/approve')) action = 'expense_approved';
        else if (method === 'POST' && path.includes('/reject')) action = 'expense_rejected';
        else if (method === 'POST' && path.includes('/submit')) action = 'expense_submitted';
        else action = `expense_${method.toLowerCase()}`;
      } else {
        action = method === 'POST' ? 'expense_created' : `expense_${method.toLowerCase()}`;
      }
      break;
      
    case 'organization':
      if (subResource === 'invite') action = 'organization_member_invited';
      else if (path.includes('/members/') && method === 'PUT') action = 'permission_role_changed';
      else if (path.includes('/members/') && method === 'DELETE') action = 'permission_member_removed';
      else action = `organization_${method.toLowerCase()}`;
      break;
      
    case 'transactions':
      action = `transaction_${method.toLowerCase()}`;
      break;
      
    default:
      action = `${resource}_${action}`;
  }
  
  return action;
}

function determineResourceType(path) {
  const pathParts = path.split('/').filter(part => part && part !== 'api');
  const resource = pathParts[0] || 'unknown';
  
  switch (resource) {
    case 'invoices': return 'invoice';
    case 'expenses': return 'expense';
    case 'transactions': return 'transaction';
    case 'organization': return 'organization';
    case 'auth': return 'user';
    case 'users': return 'user';
    case 'workflows': return 'workflow';
    case 'cards': return 'card';
    default: return resource;
  }
}

function extractResourceId(req, responseData) {
  // Try to extract resource ID from response data
  if (responseData?.invoice?.id) return responseData.invoice.id;
  if (responseData?.expense?.id) return responseData.expense.id;
  if (responseData?.transaction?.id) return responseData.transaction.id;
  if (responseData?.organization?.id) return responseData.organization.id;
  if (responseData?.workflow?.id) return responseData.workflow.id;
  if (responseData?.card?.id) return responseData.card.id;
  
  // Try to extract from URL parameters
  const urlParts = req.path.split('/');
  const idIndex = urlParts.findIndex(part => part.match(/^[0-9a-f]{24}$/i));
  if (idIndex !== -1) return urlParts[idIndex];
  
  return null;
}

function extractOrganizationIdFromRequest(req) {
  // Try to extract organization ID from request body, query params, or URL
  return req.body?.organizationId || 
         req.query?.organizationId || 
         req.params?.organizationId ||
         req.params?.id; // For organization endpoints
}

function sanitizeRequestBody(body) {
  if (!body) return null;
  
  // Remove sensitive data from audit logs
  const sanitized = { ...body };
  
  // Remove passwords, tokens, and other sensitive fields
  delete sanitized.password;
  delete sanitized.currentPassword;
  delete sanitized.newPassword;
  delete sanitized.token;
  delete sanitized.setupToken;
  delete sanitized.stellarSecretKey;
  delete sanitized.encryptedMnemonic;
  delete sanitized.otpCode;
  
  return sanitized;
}

function sanitizeResponseData(data) {
  if (!data) return null;
  
  // Create a summary of response data for audit purposes
  const summary = {};
  
  if (data.invoice) {
    summary.invoiceId = data.invoice.id;
    summary.invoiceNumber = data.invoice.invoiceNumber;
    summary.status = data.invoice.status;
  }
  
  if (data.expense) {
    summary.expenseId = data.expense.id;
    summary.status = data.expense.status;
    summary.amount = data.expense.amount;
  }
  
  if (data.transaction) {
    summary.transactionId = data.transaction.id;
    summary.status = data.transaction.status;
    summary.amount = data.transaction.amount;
  }
  
  if (data.organization) {
    summary.organizationId = data.organization.id;
    summary.name = data.organization.name;
  }
  
  if (data.success !== undefined) {
    summary.success = data.success;
  }
  
  return Object.keys(summary).length > 0 ? summary : null;
}

function getClientIP(req) {
  return req.ip || 
         req.connection.remoteAddress || 
         req.socket.remoteAddress ||
         (req.connection.socket ? req.connection.socket.remoteAddress : null) ||
         req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
         req.headers['x-client-ip'] ||
         req.headers['x-real-ip'] ||
         'unknown';
}

// Helper middleware to add start time to request
export function addRequestStartTime(req, res, next) {
  req.startTime = Date.now();
  next();
}

// Specific audit logging functions for important business events
export const auditLoggers = {
  // Transaction logging
  logTransaction: (transaction, userId, organizationId) => {
    return AuditLog.logTransaction({
      userId,
      organizationId,
      transactionId: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      asset: transaction.asset,
      fromAddress: transaction.fromAddress,
      toAddress: transaction.toAddress,
      status: transaction.status,
    });
  },

  // Permission change logging
  logPermissionChange: (userId, organizationId, targetUserId, action, previousRole, newRole) => {
    return AuditLog.logPermissionChange({
      userId,
      organizationId,
      targetUserId,
      action,
      previousRole,
      newRole,
    });
  },

  // Invoice action logging
  logInvoiceAction: (userId, organizationId, invoiceId, action, details) => {
    return AuditLog.logInvoiceAction({
      userId,
      organizationId,
      invoiceId,
      action,
      ...details,
    });
  },

  // Expense action logging
  logExpenseAction: (userId, organizationId, expenseId, action, details) => {
    return AuditLog.logExpenseAction({
      userId,
      organizationId,
      expenseId,
      action,
      ...details,
    });
  },

  // Authentication logging
  logAuth: (userId, action, req) => {
    return AuditLog.logAuthentication({
      userId,
      action,
      ipAddress: getClientIP(req),
      userAgent: req.get('User-Agent'),
    });
  },
};
