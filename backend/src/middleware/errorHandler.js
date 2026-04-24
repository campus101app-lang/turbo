// src/middleware/auth.js
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization token required' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Don't allow setup tokens for regular routes
    if (decoded.setupMode) {
      return res.status(401).json({ error: 'Setup token cannot be used here' });
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        username: true,
        stellarPublicKey: true,
        isVerified: true,
      }
    });

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// src/middleware/errorHandler.js
import { sendError } from '../utils/http.js';

export function errorHandler(err, req, res, next) {
  console.error('[api_error]', {
    requestId: req.requestId || null,
    method: req.method,
    path: req.originalUrl || req.url,
    code: err.code || 'INTERNAL_ERROR',
    message: err.message,
  });

  if (err.code === 'P2002') {
    return sendError(res, 409, 'CONFLICT', 'Record already exists.', {
      requestId: req.requestId || null,
    });
  }

  const status = err.status || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal server error.'
    : (err.message || 'Internal server error.');

  return sendError(res, status, err.code || 'INTERNAL_ERROR', message, {
    ...(err.details || {}),
    requestId: req.requestId || null,
  });
}
