// src/routes/organization.js
// Mounts at /api/organization
//
// GET    /api/organization             → get user's organization
// POST   /api/organization             → create organization
// PUT    /api/organization/:id         → update organization
// POST   /api/organization/invite      → invite team member
// PUT    /api/organization/:id/members/:memberId → update member role
// DELETE /api/organization/:id/members/:memberId → remove member

import express from "express";
import { body, validationResult } from "express-validator";
import { authenticate, requirePermission, hasPermission } from "../middleware/auth.js";
import { PrismaClient } from "@prisma/client";
import { sendError, sendNotFound, sendValidationError } from "../utils/http.js";
import jwt from "jsonwebtoken";

const router = express.Router();
const prisma = new PrismaClient();

// ─── GET /api/organization ─────────────────────────────────────────────────────
// Get user's organization with members

router.get("/", authenticate, async (req, res) => {
  try {
    // Get user's organization (as owner or member)
    const organization = await prisma.organization.findFirst({
      where: {
        OR: [
          { ownerUserId: req.user.id },
          { members: { some: { userId: req.user.id } } }
        ]
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                fullName: true,
                businessName: true,
                isMerchant: true,
              }
            }
          }
        },
        owner: {
          select: {
            id: true,
            email: true,
            fullName: true,
            businessName: true,
          }
        }
      }
    });

    if (!organization) {
      return res.json({ organization: null, members: [] });
    }

    // Determine user's role in this organization
    const userMembership = organization.members.find(m => m.userId === req.user.id);
    const userRole = organization.ownerUserId === req.user.id ? 'owner' : userMembership?.role || 'staff';

    res.json({
      organization: {
        ...organization,
        userRole,
      },
      members: organization.members,
    });
  } catch (err) {
    console.error("Get organization error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── POST /api/organization ────────────────────────────────────────────────────
// Create new organization

router.post("/", authenticate, [
  body('name').notEmpty().withMessage('Organization name is required'),
  body('domain').optional().isString().withMessage('Domain must be a string'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  const { name, domain } = req.body;

  try {
    // Check if user already has an organization
    const existingOrg = await prisma.organization.findFirst({
      where: {
        OR: [
          { ownerUserId: req.user.id },
          { members: { some: { userId: req.user.id } } }
        ]
      }
    });

    if (existingOrg) {
      return sendError(res, 400, "ALREADY_EXISTS", "User already belongs to an organization.");
    }

    // Check domain uniqueness if provided
    if (domain) {
      const domainExists = await prisma.organization.findUnique({
        where: { domain }
      });

      if (domainExists) {
        return sendError(res, 400, "DOMAIN_TAKEN", "Domain is already taken.");
      }
    }

    // Create organization
    const organization = await prisma.organization.create({
      data: {
        name,
        domain,
        ownerUserId: req.user.id,
        plan: 'free',
        maxMembers: 5,
      },
      include: {
        members: true,
        owner: {
          select: {
            id: true,
            email: true,
            fullName: true,
            businessName: true,
          }
        }
      }
    });

    // Add user as organization owner
    await prisma.organizationMember.create({
      data: {
        organizationId: organization.id,
        userId: req.user.id,
        role: 'owner',
      },
    });

    res.status(201).json({
      organization: {
        ...organization,
        userRole: 'owner',
      },
      members: organization.members,
    });
  } catch (err) {
    console.error("Create organization error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── PUT /api/organization/:id ───────────────────────────────────────────────────
// Update organization (owner only)

router.put("/:id", authenticate, [
  body('name').optional().notEmpty().withMessage('Name cannot be empty'),
  body('domain').optional().isString().withMessage('Domain must be a string'),
  body('plan').optional().isIn(['free', 'starter', 'pro', 'enterprise']).withMessage('Invalid plan'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  const { name, domain, plan } = req.body;

  try {
    const organization = await prisma.organization.findUnique({
      where: { id: req.params.id },
    });

    if (!organization) return sendNotFound(res, "Organization");

    // Check if user is owner
    if (organization.ownerUserId !== req.user.id) {
      return sendError(res, 403, "FORBIDDEN", "Only organization owner can update organization.");
    }

    // Check domain uniqueness if updating
    if (domain && domain !== organization.domain) {
      const domainExists = await prisma.organization.findUnique({
        where: { domain }
      });

      if (domainExists) {
        return sendError(res, 400, "DOMAIN_TAKEN", "Domain is already taken.");
      }
    }

    const updated = await prisma.organization.update({
      where: { id: req.params.id },
      data: {
        ...(name && { name }),
        ...(domain !== undefined && { domain }),
        ...(plan && { plan }),
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                fullName: true,
                businessName: true,
              }
            }
          }
        }
      }
    });

    res.json({ organization: updated });
  } catch (err) {
    console.error("Update organization error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── POST /api/organization/invite ───────────────────────────────────────────────
// Invite team member to organization

router.post("/invite", authenticate, [
  body('organizationId').notEmpty().withMessage('Organization ID is required'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('role').isIn(['staff', 'manager', 'admin']).withMessage('Invalid role'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  const { organizationId, email, role } = req.body;

  try {
    const organization = await prisma.organization.findUnique({
      where: { id: organizationId },
      include: {
        members: true,
      }
    });

    if (!organization) return sendNotFound(res, "Organization");

    // Check if user has permission to invite (owner, admin)
    const canInvite = hasPermission(req.user, 'invite_members', organizationId);
    if (!canInvite) {
      return sendError(res, 403, "FORBIDDEN", "Insufficient permissions to invite members.");
    }

    // Check member limit
    if (organization.members.length >= organization.maxMembers) {
      return sendError(res, 400, "LIMIT_REACHED", "Organization member limit reached.");
    }

    // Check if user exists
    const userToInvite = await prisma.user.findUnique({
      where: { email: email.toLowerCase() }
    });

    if (!userToInvite) {
      return sendError(res, 404, "USER_NOT_FOUND", "User with this email not found.");
    }

    // Check if user is already a member
    const existingMember = organization.members.find(m => m.userId === userToInvite.id);
    if (existingMember) {
      return sendError(res, 400, "ALREADY_MEMBER", "User is already a member of this organization.");
    }

    // Check if user is already in another organization
    const existingMembership = await prisma.organizationMember.findFirst({
      where: { userId: userToInvite.id }
    });

    if (existingMembership) {
      return sendError(res, 400, "ALREADY_IN_ORG", "User is already a member of another organization.");
    }

    // Create invitation token (valid for 7 days)
    const invitationToken = jwt.sign(
      {
        organizationId,
        userId: userToInvite.id,
        email: userToInvite.email,
        role,
        type: 'organization_invite'
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Create membership record
    await prisma.organizationMember.create({
      data: {
        organizationId,
        userId: userToInvite.id,
        role,
        invitedBy: req.user.id,
      },
    });

    // TODO: Send invitation email with token
    console.log(`📧 Invitation sent to ${email} for organization ${organization.name}`);
    console.log(`🔗 Invitation token: ${invitationToken}`);

    res.json({
      success: true,
      message: 'Invitation sent successfully',
      invitationToken,
    });
  } catch (err) {
    console.error("Invite member error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── PUT /api/organization/:id/members/:memberId ────────────────────────────────
// Update member role

router.put("/:id/members/:memberId", authenticate, [
  body('role').isIn(['staff', 'manager', 'admin']).withMessage('Invalid role'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  const { role } = req.body;

  try {
    const organization = await prisma.organization.findUnique({
      where: { id: req.params.id },
      include: {
        members: {
          include: { user: true }
        }
      }
    });

    if (!organization) return sendNotFound(res, "Organization");

    // Check if user has permission to manage members
    const canManage = hasPermission(req.user, 'remove_members', req.params.id);
    if (!canManage) {
      return sendError(res, 403, "FORBIDDEN", "Insufficient permissions to manage members.");
    }

    const memberToUpdate = organization.members.find(m => m.id === req.params.memberId);
    if (!memberToUpdate) {
      return sendNotFound(res, "Member");
    }

    // Cannot change owner role
    if (memberToUpdate.role === 'owner') {
      return sendError(res, 400, "CANNOT_CHANGE_OWNER", "Cannot change owner role.");
    }

    // Cannot modify owner's role
    if (memberToUpdate.userId === organization.ownerUserId) {
      return sendError(res, 400, "CANNOT_MODIFY_OWNER", "Cannot modify organization owner.");
    }

    const updated = await prisma.organizationMember.update({
      where: { id: req.params.memberId },
      data: { role },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            fullName: true,
            businessName: true,
          }
        }
      }
    });

    res.json({ member: updated });
  } catch (err) {
    console.error("Update member error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── DELETE /api/organization/:id/members/:memberId ─────────────────────────────
// Remove member from organization

router.delete("/:id/members/:memberId", authenticate, async (req, res) => {
  try {
    const organization = await prisma.organization.findUnique({
      where: { id: req.params.id },
      include: {
        members: {
          include: { user: true }
        }
      }
    });

    if (!organization) return sendNotFound(res, "Organization");

    // Check if user has permission to remove members
    const canRemove = hasPermission(req.user, 'remove_members', req.params.id);
    if (!canRemove) {
      return sendError(res, 403, "FORBIDDEN", "Insufficient permissions to remove members.");
    }

    const memberToRemove = organization.members.find(m => m.id === req.params.memberId);
    if (!memberToRemove) {
      return sendNotFound(res, "Member");
    }

    // Cannot remove owner
    if (memberToRemove.role === 'owner' || memberToRemove.userId === organization.ownerUserId) {
      return sendError(res, 400, "CANNOT_REMOVE_OWNER", "Cannot remove organization owner.");
    }

    await prisma.organizationMember.delete({
      where: { id: req.params.memberId }
    });

    res.json({ success: true, message: 'Member removed successfully' });
  } catch (err) {
    console.error("Remove member error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

// ─── POST /api/organization/accept-invitation ───────────────────────────────────
// Accept organization invitation

router.post("/accept-invitation", [
  body('token').isJWT().withMessage('Valid invitation token is required'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  const { token } = req.body;

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.type !== 'organization_invite') {
      return sendError(res, 400, "INVALID_TOKEN", "Invalid invitation token.");
    }

    // Verify user matches the invitation
    if (req.user.id !== decoded.userId) {
      return sendError(res, 403, "FORBIDDEN", "This invitation is for a different user.");
    }

    // Check if membership exists and is pending
    const membership = await prisma.organizationMember.findFirst({
      where: {
        organizationId: decoded.organizationId,
        userId: decoded.userId,
      },
      include: {
        organization: true,
      }
    });

    if (!membership) {
      return sendError(res, 404, "INVITATION_NOT_FOUND", "Invitation not found.");
    }

    // Update joinedAt to accept invitation
    await prisma.organizationMember.update({
      where: { id: membership.id },
      data: { joinedAt: new Date() }
    });

    res.json({
      success: true,
      organization: membership.organization,
      role: membership.role,
    });
  } catch (err) {
    if (err.name === 'JsonWebTokenError') {
      return sendError(res, 400, "INVALID_TOKEN", "Invalid or expired invitation token.");
    }
    console.error("Accept invitation error:", err);
    sendError(res, 500, "INTERNAL_ERROR", "Internal server error.");
  }
});

export default router;
