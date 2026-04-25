// src/middleware/auth.js
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { sendForbidden, sendUnauthorized } from '../utils/http.js';

const prisma = new PrismaClient();

export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendUnauthorized(res, 'Authorization token required.');
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    if (decoded.setupMode) {
      return sendUnauthorized(res, 'Setup token cannot be used here.');
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        username: true,
        stellarPublicKey: true,
        isVerified: true,
        isMerchant: true,
      }
    });

    if (!user) {
      return sendUnauthorized(res, 'User not found.');
    }

    const adminEmails = (process.env.ADMIN_EMAILS || '')
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean);
    const isAdmin = adminEmails.includes((user.email || '').toLowerCase());

    req.user = { ...user, isAdmin };
    next();
  } catch (err) {
    return sendUnauthorized(res, 'Invalid or expired token.');
  }
}

export function requireMerchant(req, res, next) {
  if (!req.user?.isMerchant) {
    return sendForbidden(res, 'Merchant permission is required.');
  }
  return next();
}

export function requireManager(req, res, next) {
  if (!(req.user?.isMerchant || req.user?.isAdmin)) {
    return sendForbidden(res, 'Manager permission is required.');
  }
  return next();
}

// Role-based permission system
export const ROLE_PERMISSIONS = {
  owner: {
    can: ['invite_members', 'remove_members', 'manage_billing', 'approve_expenses', 'create_invoices', 'view_all_reports', 'manage_settings'],
    level: 100
  },
  admin: {
    can: ['invite_members', 'approve_expenses', 'create_invoices', 'view_reports', 'manage_inventory'],
    level: 80
  },
  manager: {
    can: ['approve_expenses', 'create_invoices', 'view_team_reports'],
    level: 60
  },
  staff: {
    can: ['submit_expenses', 'view_own_reports'],
    level: 40
  }
};

export function hasPermission(user, permission, organizationId) {
  if (!user || !permission) return false;
  
  // Check if user is owner of the organization
  if (user.currentOrganization?.ownerUserId === user.id) {
    return ROLE_PERMISSIONS.owner.can.includes(permission);
  }
  
  // Check organization membership role
  const membership = user.currentOrganization?.members?.find(m => m.userId === user.id);
  if (!membership) return false;
  
  const rolePermissions = ROLE_PERMISSIONS[membership.role];
  return rolePermissions?.can.includes(permission) || false;
}

export function requirePermission(permission) {
  return (req, res, next) => {
    const organizationId = req.body.organizationId || req.query.organizationId || req.params.organizationId;
    
    if (!hasPermission(req.user, permission, organizationId)) {
      return sendForbidden(res, `Permission required: ${permission}`);
    }
    
    next();
  };
}

export function requireOrganizationRole(minLevel = 40) {
  return (req, res, next) => {
    const membership = req.user?.currentOrganization?.members?.find(m => m.userId === req.user.id);
    
    if (!membership) {
      return sendForbidden(res, 'Organization membership required.');
    }
    
    const roleLevel = ROLE_PERMISSIONS[membership.role]?.level || 0;
    if (roleLevel < minLevel) {
      return sendForbidden(res, 'Higher role level required.');
    }
    
    next();
  };
}
