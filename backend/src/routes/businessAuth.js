// src/routes/businessAuth.js
//
// Business authentication routes for Nigerian businesses
//
// POST /auth/setup-business-profile → Setup business profile for new users

import express from 'express';
import { body, validationResult } from 'express-validator';
import { PrismaClient } from '@prisma/client';
import { sendError, sendValidationError } from '../utils/http.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Business Onboarding ─────────────────────────────────────────────────────

router.post('/business-onboarding', authenticate, [
  body('accountType').isIn(['INDIVIDUAL', 'REGISTERED_BUSINESS', 'OTHER_ENTITY']).withMessage('Invalid account type'),
  body('fullName').optional().isLength({ min: 2 }).withMessage('Full name must be at least 2 characters'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('homeAddress').optional().isLength({ min: 5 }).withMessage('Address must be at least 5 characters'),
  body('bvn').optional().isLength({ min: 11, max: 11 }).withMessage('BVN must be 11 digits'),
  body('businessName').optional().isLength({ min: 2 }).withMessage('Business name must be at least 2 characters'),
  body('businessAddress').optional().isLength({ min: 5 }).withMessage('Business address must be at least 5 characters'),
  body('businessType').optional().isIn(['SOLE_PROPRIETORSHIP', 'LIMITED_LIABILITY', 'PUBLIC_LIMITED', 'PARTNERSHIP', 'NGO', 'RELIGIOUS_ORG', 'TRUST', 'OTHER']),
  body('cacRegistrationNumber').optional().isLength({ min: 5 }).withMessage('CAC registration number is required'),
  body('taxIdentificationNumber').optional().isLength({ min: 5 }).withMessage('TIN is required'),
  body('businessCategory').optional().isLength({ min: 2 }).withMessage('Business category is required'),
], async (req, res) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendValidationError(res, errors);
    }

    const {
      accountType,
      fullName,
      phone,
      homeAddress,
      bvn,
      businessName,
      businessAddress,
      businessType,
      cacRegistrationNumber,
      taxIdentificationNumber,
      businessCategory,
    } = req.body;

    // Get user from token (assuming auth middleware is applied)
    const userId = req.user?.id;
    if (!userId) {
      return sendError(res, 401, 'UNAUTHORIZED', 'User not authenticated');
    }

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return sendError(res, 404, 'NOT_FOUND', 'User not found');
    }

    // Update user with business profile
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        accountType,
        fullName: fullName || user.fullName,
        phone,
        homeAddress,
        bvn,
        businessName,
        businessAddress,
        businessType,
        cacRegistrationNumber,
        taxIdentificationNumber,
        businessCategory: businessCategory || user.businessCategory,
      },
    });

    // Create organization if it's a business account
    if (accountType !== 'INDIVIDUAL' && businessName) {
      const existingOrg = await prisma.organization.findFirst({
        where: { ownerUserId: userId },
      });

      if (!existingOrg) {
        await prisma.organization.create({
          data: {
            name: businessName,
            description: `${accountType} - ${businessType || 'General Business'}`,
            businessType,
            cacRegistrationNumber,
            taxIdentificationNumber,
            businessAddress: businessAddress || homeAddress,
            ownerUserId: userId,
          },
        });
      }
    }

    res.json({
      success: true,
      message: 'Business profile setup completed',
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        accountType: updatedUser.accountType,
        fullName: updatedUser.fullName,
        businessName: updatedUser.businessName,
        isVerified: updatedUser.isVerified,
      },
    });

  } catch (error) {
    console.error('Business profile setup error:', error);
    sendError(res, 500, 'INTERNAL_ERROR', 'Failed to setup business profile');
  }
});

// ─── Business Onboarding (Initial Setup) ─────────────────────────────────────────────

router.post('/business-onboarding', authenticate, [
  body('accountType').isIn(['INDIVIDUAL', 'REGISTERED_BUSINESS', 'OTHER_ENTITY']).withMessage('Invalid account type'),
  body('fullName').optional().isLength({ min: 2 }).withMessage('Full name must be at least 2 characters'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('homeAddress').optional().isLength({ min: 5 }).withMessage('Address must be at least 5 characters'),
  body('bvn').optional().isLength({ min: 11, max: 11 }).withMessage('BVN must be 11 digits'),
  body('businessName').optional().isLength({ min: 2 }).withMessage('Business name must be at least 2 characters'),
  body('businessAddress').optional().isLength({ min: 5 }).withMessage('Business address must be at least 5 characters'),
  body('businessType').optional().isIn(['SOLE_PROPRIETORSHIP', 'LIMITED_LIABILITY', 'PUBLIC_LIMITED', 'PARTNERSHIP', 'NGO', 'RELIGIOUS_ORG', 'TRUST', 'OTHER']),
  body('cacRegistrationNumber').optional().isLength({ min: 5 }).withMessage('CAC registration number is required'),
  body('taxIdentificationNumber').optional().isLength({ min: 5 }).withMessage('TIN is required'),
  body('businessCategory').optional().isLength({ min: 2 }).withMessage('Business category is required'),
], async (req, res) => {
  try {
    // Validate request
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return sendValidationError(res, errors);
    }

    const {
      accountType,
      fullName,
      phone,
      homeAddress,
      bvn,
      businessName,
      businessAddress,
      businessType,
      cacRegistrationNumber,
      taxIdentificationNumber,
      businessCategory,
    } = req.body;

    // Get user from token (assuming auth middleware is applied)
    const userId = req.user?.id;
    if (!userId) {
      return sendError(res, 401, 'UNAUTHORIZED', 'User not authenticated');
    }

    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      return sendError(res, 404, 'NOT_FOUND', 'User not found');
    }

    // Update user with initial business onboarding data
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        accountType,
        fullName: fullName || user.fullName,
        phone,
        homeAddress,
        bvn,
        businessName,
        businessAddress,
        businessType,
        cacRegistrationNumber,
        taxIdentificationNumber,
        businessCategory: businessCategory || user.businessCategory,
      },
    });

    res.json({
      success: true,
      message: 'Business onboarding initiated',
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        accountType: updatedUser.accountType,
        fullName: updatedUser.fullName,
        businessName: updatedUser.businessName,
        isVerified: updatedUser.isVerified,
      },
    });

  } catch (error) {
    console.error('Business onboarding error:', error);
    sendError(res, 500, 'INTERNAL_ERROR', 'Failed to process business onboarding');
  }
});

export default router;
