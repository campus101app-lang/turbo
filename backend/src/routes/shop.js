// src/routes/shop.js
//
// Shop and product management routes for DayFi
//

import express from 'express';
import { body, param, validationResult } from 'express-validator';
import { PrismaClient } from '@prisma/client';
import { authenticate, requireMerchant } from '../middleware/auth.js';
import { sendError, sendValidationError } from '../utils/http.js';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Get Shop Overview ─────────────────────────────────────────────────────

router.get('/overview', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user's products (inventory)
    const products = await prisma.inventoryItem.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 10
    });
    
    // Get orders
    const orders = await prisma.order?.findMany({
      where: { sellerId: userId },
      orderBy: { createdAt: 'desc' },
      take: 10
    }) || [];
    
    // Calculate totals
    const totalProducts = await prisma.inventoryItem.count({ where: { userId } });
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + (order.total || 0), 0);
    
    res.json({
      overview: {
        totalProducts,
        totalOrders,
        totalRevenue,
        activeProducts: products.filter(p => p.stock > 0).length
      },
      recentProducts: products,
      recentOrders: orders
    });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to fetch shop overview');
  }
});

// ─── Get Products ───────────────────────────────────────────────────────────

router.get('/products', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, category } = req.query;
    const userId = req.user.id;
    
    const where = { userId };
    if (category) where.category = category;
    
    const products = await prisma.inventoryItem.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: parseInt(limit)
    });
    
    const total = await prisma.inventoryItem.count({ where });
    
    res.json({
      products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to fetch products');
  }
});

// ─── Create Product ───────────────────────────────────────────────────────────

router.post('/products', authenticate, requireMerchant, [
  body('name').notEmpty().withMessage('Product name is required'),
  body('description').optional().isString(),
  body('priceUsdc').isFloat({ min: 0.01 }).withMessage('Price must be greater than 0'),
  body('category').optional().isString(),
  body('stock').optional().isInt({ min: 0 }).withMessage('Stock must be non-negative'),
  body('images').optional().isArray(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  
  try {
    const userId = req.user.id;
    const { name, description, priceUsdc, category, stock, images } = req.body;
    
    const product = await prisma.inventoryItem.create({
      data: {
        userId,
        name,
        description,
        priceUsdc,
        category: category || 'general',
        stock: stock || 0,
        images: images || [],
        isActive: true
      }
    });
    
    res.status(201).json({ product });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to create product');
  }
});

// ─── Update Product ───────────────────────────────────────────────────────────

router.patch('/products/:id', authenticate, requireMerchant, [
  body('name').optional().notEmpty().withMessage('Product name cannot be empty'),
  body('priceUsdc').optional().isFloat({ min: 0.01 }).withMessage('Price must be greater than 0'),
  body('stock').optional().isInt({ min: 0 }).withMessage('Stock must be non-negative'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updates = req.body;
    
    const product = await prisma.inventoryItem.updateMany({
      where: { id, userId },
      data: updates
    });
    
    if (product.count === 0) {
      return sendError(res, 404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }
    
    res.json({ success: true });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to update product');
  }
});

// ─── Delete Product ───────────────────────────────────────────────────────────

router.delete('/products/:id', authenticate, requireMerchant, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    const product = await prisma.inventoryItem.deleteMany({
      where: { id, userId }
    });
    
    if (product.count === 0) {
      return sendError(res, 404, 'PRODUCT_NOT_FOUND', 'Product not found');
    }
    
    res.json({ success: true });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to delete product');
  }
});

// ─── Get Orders ─────────────────────────────────────────────────────────────

router.get('/orders', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const userId = req.user.id;
    
    const where = { sellerId: userId };
    if (status) where.status = status;
    
    const orders = await prisma.order?.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: parseInt(limit)
    }) || [];
    
    const total = await prisma.order?.count({ where }) || 0;
    
    res.json({
      orders,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    sendError(res, 500, 'SHOP_ERROR', 'Failed to fetch orders');
  }
});

export default router;
