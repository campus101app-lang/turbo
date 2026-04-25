// src/middleware/organizationRateLimit.js
// Per-organization rate limiting for production security

import rateLimit from 'express-rate-limit';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Store rate limit data per organization
const organizationLimits = new Map();

// Default rate limits per organization plan
const PLAN_LIMITS = {
  free: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requests per 15 minutes
    sensitiveEndpoints: {
      '/api/transactions': { max: 20, windowMs: 15 * 60 * 1000 },
      '/api/invoices': { max: 30, windowMs: 15 * 60 * 1000 },
      '/api/expenses': { max: 25, windowMs: 15 * 60 * 1000 },
      '/api/payments': { max: 15, windowMs: 15 * 60 * 1000 },
    }
  },
  starter: {
    windowMs: 15 * 60 * 1000,
    max: 300,
    sensitiveEndpoints: {
      '/api/transactions': { max: 60, windowMs: 15 * 60 * 1000 },
      '/api/invoices': { max: 80, windowMs: 15 * 60 * 1000 },
      '/api/expenses': { max: 70, windowMs: 15 * 60 * 1000 },
      '/api/payments': { max: 50, windowMs: 15 * 60 * 1000 },
    }
  },
  pro: {
    windowMs: 15 * 60 * 1000,
    max: 1000,
    sensitiveEndpoints: {
      '/api/transactions': { max: 200, windowMs: 15 * 60 * 1000 },
      '/api/invoices': { max: 250, windowMs: 15 * 60 * 1000 },
      '/api/expenses': { max: 200, windowMs: 15 * 60 * 1000 },
      '/api/payments': { max: 150, windowMs: 15 * 60 * 1000 },
    }
  },
  enterprise: {
    windowMs: 15 * 60 * 1000,
    max: 5000,
    sensitiveEndpoints: {
      '/api/transactions': { max: 1000, windowMs: 15 * 60 * 1000 },
      '/api/invoices': { max: 1200, windowMs: 15 * 60 * 1000 },
      '/api/expenses': { max: 1000, windowMs: 15 * 60 * 1000 },
      '/api/payments': { max: 800, windowMs: 15 * 60 * 1000 },
    }
  }
};

// Create organization-specific rate limiter
function createOrganizationLimiter(organization) {
  const plan = organization.plan || 'free';
  const limits = PLAN_LIMITS[plan];
  
  return rateLimit({
    windowMs: limits.windowMs,
    max: limits.max,
    message: {
      code: 'RATE_LIMITED',
      message: `Rate limit exceeded for ${plan} plan. Upgrade for higher limits.`,
      details: {
        plan,
        limit: limits.max,
        windowMs: limits.windowMs,
        organizationId: organization.id,
      },
    },
    keyGenerator: (req) => {
      // Use organization ID as key
      return `org_${organization.id}`;
    },
    skip: (req) => {
      // Skip if no organization context
      return !req.user?.currentOrganization?.id;
    },
    onLimitReached: (req, res, options) => {
      // Log rate limit violations for security monitoring
      console.warn(`Rate limit exceeded for organization ${req.user?.currentOrganization?.id} from IP ${req.ip}`);
      
      // Could trigger fraud detection here
      if (options.max < 50) { // Low limits might indicate abuse
        // Trigger additional monitoring
      }
    },
  });
}

// Create sensitive endpoint rate limiter
function createSensitiveEndpointLimiter(organization, endpoint) {
  const plan = organization.plan || 'free';
  const limits = PLAN_LIMITS[plan];
  const endpointLimits = limits.sensitiveEndpoints[endpoint] || limits;
  
  return rateLimit({
    windowMs: endpointLimits.windowMs,
    max: endpointLimits.max,
    message: {
      code: 'SENSITIVE_RATE_LIMITED',
      message: `Rate limit exceeded for ${endpoint} on ${plan} plan.`,
      details: {
        plan,
        endpoint,
        limit: endpointLimits.max,
        windowMs: endpointLimits.windowMs,
        organizationId: organization.id,
      },
    },
    keyGenerator: (req) => {
      return `org_${organization.id}_${endpoint}`;
    },
    skip: (req) => {
      return !req.user?.currentOrganization?.id || !req.path.startsWith(endpoint);
    },
  });
}

// Middleware to get organization context and apply rate limiting
export function organizationRateLimit(options = {}) {
  return async (req, res, next) => {
    try {
      // Skip rate limiting for health checks and static assets
      if (req.path.startsWith('/health') || req.path.startsWith('/static')) {
        return next();
      }

      // Get organization from authenticated user
      if (req.user?.currentOrganization?.id) {
        const organizationId = req.user.currentOrganization.id;
        
        // Get or create limiter for this organization
        let limiter = organizationLimits.get(organizationId);
        
        if (!limiter) {
          // Fetch organization details
          const organization = await prisma.organization.findUnique({
            where: { id: organizationId },
            select: { id: true, plan: true }
          });
          
          if (organization) {
            // Create limiters for this organization
            limiter = {
              general: createOrganizationLimiter(organization),
              sensitive: new Map(),
            };
            
            // Create sensitive endpoint limiters
            Object.keys(PLAN_LIMITS[organization.plan || 'free'].sensitiveEndpoints).forEach(endpoint => {
              limiter.sensitive.set(endpoint, createSensitiveEndpointLimiter(organization, endpoint));
            });
            
            organizationLimits.set(organizationId, limiter);
          }
        }
        
        if (limiter) {
          // Check if this is a sensitive endpoint
          const sensitiveEndpoint = Object.keys(PLAN_LIMITS[req.user.currentOrganization.plan || 'free'].sensitiveEndpoints)
            .find(endpoint => req.path.startsWith(endpoint));
          
          if (sensitiveEndpoint && limiter.sensitive.has(sensitiveEndpoint)) {
            return limiter.sensitive.get(sensitiveEndpoint)(req, res, next);
          } else {
            return limiter.general(req, res, next);
          }
        }
      }
      
      // Fallback to global rate limiting if no organization context
      next();
    } catch (error) {
      console.error('Organization rate limiting error:', error);
      // Don't block requests if rate limiting fails
      next();
    }
  };
}

// Function to clear rate limits for an organization (admin use)
export function clearOrganizationRateLimit(organizationId) {
  organizationLimits.delete(organizationId);
}

// Function to update rate limits when organization plan changes
export async function updateOrganizationRateLimit(organizationId) {
  // Clear existing limits
  clearOrganizationRateLimit(organizationId);
  
  // The next request will create new limits with updated plan
  console.log(`Rate limits updated for organization ${organizationId}`);
}

// Get rate limit statistics for monitoring
export function getRateLimitStats() {
  const stats = {
    totalOrganizations: organizationLimits.size,
    organizations: Array.from(organizationLimits.entries()).map(([orgId, limiters]) => ({
      organizationId: orgId,
      hasSensitiveLimiters: limiters.sensitive.size > 0,
    })),
  };
  
  return stats;
}

// Cleanup old rate limit data periodically
setInterval(() => {
  // This could be enhanced to remove inactive organizations
  console.log('Rate limit cleanup: Currently tracking', organizationLimits.size, 'organizations');
}, 60 * 60 * 1000); // Every hour

export default organizationRateLimit;
