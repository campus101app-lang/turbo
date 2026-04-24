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
