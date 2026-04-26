import express from 'express';
import { body, validationResult } from 'express-validator';
import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import { sendOTP, sendWelcomeEmail } from '../services/emailService.js';
import {
  createStellarWallet,
  getMnemonic,
  markAsBackedUp,
  fundNewUserWallet,
  addAllTrustlines,
  setupUserTrustlines,
} from '../services/walletService.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
const prisma = new PrismaClient();

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// POST /api/auth/send-otp
router.post('/send-otp', [
  body('email').isEmail().normalizeEmail(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { email } = req.body;
  try {
    let user = await prisma.user.findUnique({ where: { email } });
    const isNewUser = !user;
    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    if (!user) {
      user = await prisma.user.create({
        data: { email, username: `user_${Date.now()}`, otpCode: otp, otpExpiry, otpAttempts: 0 },
      });
    } else {
      await prisma.user.update({
        where: { email },
        data: { otpCode: otp, otpExpiry, otpAttempts: 0 },
      });
    }

    try { await sendOTP(email, otp, isNewUser); }
    catch (err) { console.warn('Email delivery failed:', err.message); }

    console.log(`\n🔑 OTP for ${email}: ${otp}\n`);

    res.json({
      success: true, isNewUser,
      message: `OTP sent to ${email}`,
      ...(process.env.NODE_ENV === 'development' && { devOtp: otp }),
    });
  } catch (err) {
    console.error('Send OTP error:', err);
    res.status(500).json({ error: 'Failed to send OTP.' });
  }
});

// POST /api/auth/verify-otp
router.post('/verify-otp', [
  body('email').isEmail().normalizeEmail(),
  body('otp').isLength({ min: 6, max: 6 }).isNumeric(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { email, otp } = req.body;
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (user.otpAttempts >= 5)
      return res.status(429).json({ error: 'Too many attempts. Request a new code.' });
    if (!user.otpExpiry || new Date() > user.otpExpiry)
      return res.status(400).json({ error: 'OTP expired.' });
    if (user.otpCode !== otp) {
      await prisma.user.update({ where: { email }, data: { otpAttempts: { increment: 1 } } });
      return res.status(400).json({ error: 'Invalid code.', attemptsLeft: 5 - (user.otpAttempts + 1) });
    }

    // Determine what setup steps are needed
    const hasBusinessProfile = !!(user.fullName && user.businessName && user.businessCategory);
    const hasOnboarding = !!(user.stellarPublicKey);
    const isNewUser = !hasBusinessProfile && !hasOnboarding;

    await prisma.user.update({
      where: { email },
      data: { otpCode: null, otpExpiry: null, otpAttempts: 0, isVerified: true },
    });

    // Fully complete — go straight to shell
    if (hasBusinessProfile && hasOnboarding) {
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
      );
      return res.json({
        success: true, step: 'complete', token,
        user: {
          id: user.id, email: user.email,
          username: user.username,
          fullName: user.fullName,
          businessName: user.businessName,
          stellarPublicKey: user.stellarPublicKey,
          isBackedUp: user.isBackedUp,
          isMerchant: user.isMerchant,
        },
      });
    }

    // Generate setupToken for all incomplete flows
    const setupToken = jwt.sign(
      { userId: user.id, email: user.email, setupMode: true },
      process.env.JWT_SECRET,
      { expiresIn: '30m' }
    );

    // Missing business profile — go here first
    if (!hasBusinessProfile) {
      return res.json({
        success: true,
        step: 'setup_business_profile',
        setupToken,
        isNewUser,
        completedSteps: { businessProfile: false, businessOnboarding: hasOnboarding },
        existingData: {
          fullName: user.fullName,
          businessName: user.businessName,
          businessCategory: user.businessCategory,
          businessEmail: user.businessEmail,
        },
      });
    }

    // Has profile but missing onboarding
    return res.json({
      success: true,
      step: 'setup_business_onboarding',
      setupToken,
      isNewUser: false,
      completedSteps: { businessProfile: true, businessOnboarding: false },
    });

  } catch (err) {
    console.error('Verify OTP error:', err);
    res.status(500).json({ error: 'Verification failed.' });
  }
});

// POST /api/auth/setup-username
router.post('/setup-username', [
  body('username').trim().isLength({ min: 3, max: 30 }).matches(/^[a-zA-Z0-9_]+$/),
  body('setupToken').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { username, setupToken } = req.body;
  try {
    let decoded;
    try { decoded = jwt.verify(setupToken, process.env.JWT_SECRET); }
    catch { return res.status(401).json({ error: 'Invalid or expired setup token' }); }

    if (!decoded.setupMode) return res.status(401).json({ error: 'Invalid token' });

    const lowerUsername = username.toLowerCase();
    const existing = await prisma.user.findUnique({ where: { username: lowerUsername } });
    if (existing && existing.id !== decoded.userId)
      return res.status(409).json({ error: 'Username already taken.' });

    await prisma.user.update({
      where: { id: decoded.userId },
      data: { username: lowerUsername },
    });

    console.log(`\n⚙️  Creating Stellar wallet for @${lowerUsername}...`);
    const { publicKey, encryptedSecretKey, encryptedMnemonic } = await createStellarWallet();

    await prisma.user.update({
      where: { id: decoded.userId },
      data: { stellarPublicKey: publicKey, stellarSecretKey: encryptedSecretKey, encryptedMnemonic },
    });

    console.log(`✅ Wallet ready: ${publicKey}`);

    // ✅ decoded.userId exists here — no 'user' needed yet
    await fundNewUserWallet(publicKey, decoded.userId);

    // ✅ single DB fetch at the end, used for everything below
    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });

    // trustlines already handled inside createStellarWallet() for testnet
    // only needed if you want to re-run it explicitly on mainnet
    await setupUserTrustlines(user);

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    try { await sendWelcomeEmail(user.email, user.username); }
    catch (err) { console.warn('⚠️  Welcome email failed:', err.message); }

    res.json({
      success: true, token,
      user: {
        id: user.id, email: user.email,
        username: user.username,
        dayfiUsername: `${user.username}@dayfi.me`,
        stellarPublicKey: user.stellarPublicKey,
        isBackedUp: user.isBackedUp,
      },
    });
  } catch (err) {
    console.error('Setup username error:', err);
    res.status(500).json({ error: 'Setup failed.' });
  }
});

// POST /api/auth/setup-onboarding
router.post('/setup-onboarding', [
  body('setupToken').isJWT(),
  body('accountType').isIn(['individual', 'registeredBusiness', 'otherEntity']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { setupToken, accountType, ...fields } = req.body;

  try {
    let decoded;
    try { decoded = jwt.verify(setupToken, process.env.JWT_SECRET); }
    catch { return res.status(401).json({ error: 'Invalid or expired setup token' }); }

    if (!decoded.setupMode) return res.status(401).json({ error: 'Invalid token' });

    // ─ Save KYC / compliance data ───────────────────────────────────────
    await prisma.user.update({
      where: { id: decoded.userId },
      data: {
        accountType: accountType === 'individual'
          ? 'INDIVIDUAL'
          : accountType === 'registeredBusiness'
            ? 'REGISTERED_BUSINESS'
            : 'OTHER_ENTITY',
        phone: fields.phone || null,
        homeAddress: fields.homeAddress || null,
        bvn: fields.bvn || null,
        businessAddress: fields.businessAddress || null,
        businessType: fields.businessType?.toUpperCase() || null,
        cacRegistrationNumber: fields.cacRegistrationNumber || null,
        taxIdentificationNumber: fields.taxIdentificationNumber || null,
      },
    });

    // ─ Create Stellar wallet (now that KYC is complete) ─────────────────
    let user = await prisma.user.findUnique({ where: { id: decoded.userId } });

    if (!user.stellarPublicKey) {
      console.log(`\n⚙️  Creating Stellar wallet for ${user.fullName}...`);
      const { publicKey, encryptedSecretKey, encryptedMnemonic } = await createStellarWallet();

      await prisma.user.update({
        where: { id: decoded.userId },
        data: { stellarPublicKey: publicKey, stellarSecretKey: encryptedSecretKey, encryptedMnemonic },
      });

      console.log(`✅ Wallet ready: ${publicKey}`);
      await fundNewUserWallet(publicKey, decoded.userId);


      // Re-fetch with updated stellarPublicKey for trustlines
      user = await prisma.user.findUnique({ where: { id: decoded.userId } });
      await setupUserTrustlines(user);
      console.log(`✅ Trustlines set up for ${user.fullName}`);

      // ─ Auto-create virtual account if BVN provided ──────────────────────
      if (fields.bvn) {
        try {
          const { createVirtualAccount } = await import('../services/flutterwaveService.js');
          await createVirtualAccount({ userId: decoded.userId, bvn: fields.bvn });
          console.log(`✅ Virtual account created for ${user.fullName}`);
        } catch (err) {
          // Non-fatal — user can create it manually from receive screen
          console.warn('⚠️  Virtual account creation failed:', err.message);
        }
      }
    }

    // ─ Generate full auth token ─────────────────────────────────────────
    const token = jwt.sign(
      { userId: decoded.userId, email: decoded.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        businessName: user.businessName,
        stellarPublicKey: user.stellarPublicKey,
        isBackedUp: user.isBackedUp,
        isMerchant: user.isMerchant,
      },
    });
  } catch (err) {
    console.error('Setup onboarding error:', err);
    res.status(500).json({ error: err.message || 'Onboarding failed' });
  }
});

// GET /api/auth/check-username/:username
router.get('/check-username/:username', async (req, res) => {
  const lower = req.params.username.toLowerCase().trim();
  if (!/^[a-zA-Z0-9_]{3,30}$/.test(lower))
    return res.json({ available: false, reason: 'Invalid format' });

  const reserved = ['admin', 'support', 'dayfi', 'help', 'system', 'api',
    'app', 'wallet', 'pay', 'send', 'receive', 'swap', 'buy', 'sell'];
  if (reserved.includes(lower))
    return res.json({ available: false, reason: 'Reserved username' });

  const existing = await prisma.user.findUnique({ where: { username: lower } });
  res.json({ available: !existing, username: lower });
});

// GET /api/auth/mnemonic — returns 12 words (Face ID verified on client)
router.get('/mnemonic', authenticate, async (req, res) => {
  try {
    const mnemonic = await getMnemonic(req.user.id);
    const words = mnemonic.split(' ');
    res.json({ words });
  } catch (err) {
    res.status(404).json({ error: 'Recovery phrase not found' });
  }
});

// POST /api/auth/mark-backed-up
router.post('/mark-backed-up', authenticate, async (req, res) => {
  try {
    await markAsBackedUp(req.user.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/setup-profile
router.post('/setup-profile', [
  body('setupToken').isJWT().withMessage('Invalid setup token'),
  body('fullName').notEmpty().withMessage('Full name is required'),
  body('businessName').notEmpty().withMessage('Business name is required'),
  body('businessCategory').isIn([
    'Retail & E-commerce', 'Food & Beverages', 'Professional Services',
    'Technology', 'Healthcare', 'Education', 'Logistics & Delivery',
    'Construction & Real Estate', 'Agriculture', 'Media & Entertainment',
    'Finance & Fintech', 'Other',
  ]).withMessage('Invalid category'),
  body('businessEmail').optional().isEmail().withMessage('Invalid email'),
  body('organizationName').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { setupToken, fullName, businessName, businessCategory, businessEmail, organizationName } = req.body;

  try {
    let decoded;
    try { decoded = jwt.verify(setupToken, process.env.JWT_SECRET); }
    catch { return res.status(401).json({ error: 'Invalid or expired setup token' }); }

    if (!decoded.setupMode) return res.status(401).json({ error: 'Invalid token' });

    // ─ Create organization (if not already exists) ─────────────────────
    const orgName = organizationName || businessName;
    let organization = await prisma.organization.findFirst({
      where: { ownerUserId: decoded.userId },
    });

    if (!organization) {
      organization = await prisma.organization.create({
        data: { name: orgName, ownerUserId: decoded.userId, plan: 'free', maxMembers: 5 },
      });
      await prisma.organizationMember.create({
        data: { organizationId: organization.id, userId: decoded.userId, role: 'owner' },
      });
      console.log(`✅ Organization created: ${organization.name}`);
    }

    // ─ Save business profile ────────────────────────────────────────────
    const user = await prisma.user.update({
      where: { id: decoded.userId },
      data: {
        fullName,
        businessName,
        businessCategory,
        businessEmail: businessEmail || null,
        isMerchant: true,
        isVerified: true,
      },
    });

    // ─ Generate tokens ──────────────────────────────────────────────────
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    const onboardingSetupToken = jwt.sign(
      { userId: user.id, email: user.email, setupMode: true },
      process.env.JWT_SECRET,
      { expiresIn: '30m' }
    );

    try { await sendWelcomeEmail(user.email, user.businessName); }
    catch (err) { console.warn('⚠️  Welcome email failed:', err.message); }

    res.json({
      success: true,
      token,
      setupToken: onboardingSetupToken,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        businessName: user.businessName,
        businessCategory: user.businessCategory,
        stellarPublicKey: user.stellarPublicKey,
        isBackedUp: user.isBackedUp,
        isMerchant: user.isMerchant,
        organization: {
          id: organization.id,
          name: organization.name,
          plan: organization.plan,
          maxMembers: organization.maxMembers,
          role: 'owner',
        },
      },
    });
  } catch (err) {
    console.error('Setup profile error:', err);
    res.status(500).json({ error: err.message || 'Setup failed' });
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  const { token } = req.body;
  if (!token) return res.status(401).json({ error: 'Token required' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const newToken = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );
    res.json({ token: newToken });
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export default router;