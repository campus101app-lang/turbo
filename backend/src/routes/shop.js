// src/routes/shop.js
import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { PrismaClient } from '@prisma/client';
import { authenticate, requireMerchant } from '../middleware/auth.js';
import { sendError, sendValidationError, sendNotFound } from '../utils/http.js';
import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import { Readable } from 'stream';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Multer (memory storage — stream to Cloudinary) ───────────────────────────
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (_, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Images only'));
  },
});

// ─── Cloudinary config ────────────────────────────────────────────────────────
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function uploadToCloudinary(buffer, folder = 'dayfi/products') {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'image' },
      (err, result) => err ? reject(err) : resolve(result),
    );
    Readable.from(buffer).pipe(stream);
  });
}

// ─── Order number generator ───────────────────────────────────────────────────
async function generateOrderNumber(userId) {
  const count = await prisma.order.count({ where: { userId } });
  const pad   = String(count + 1).padStart(4, '0');
  return `ORD-${Date.now().toString(36).toUpperCase()}-${pad}`;
}

// ══════════════════════════════════════════════════════════════════════════════
// PRODUCTS
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/shop/products
router.get('/products', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 50, category, search, lowStock } = req.query;
    const userId = req.user.id;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = { userId };
    if (category)           where.category = category;
    if (lowStock === 'true') where.stock    = { lte: prisma.inventoryItem.fields.threshold };
    if (search) {
      where.OR = [
        { name:     { contains: search, mode: 'insensitive' } },
        { sku:      { contains: search, mode: 'insensitive' } },
        { category: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [products, total] = await Promise.all([
      prisma.inventoryItem.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit),
      }),
      prisma.inventoryItem.count({ where }),
    ]);

    res.json({ products, pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / parseInt(limit)) } });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// GET /api/shop/products/:id
router.get('/products/:id', authenticate, async (req, res) => {
  try {
    const product = await prisma.inventoryItem.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!product) return sendNotFound(res, 'Product');
    res.json({ product });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// POST /api/shop/products
router.post('/products', authenticate, requireMerchant, [
  body('name').notEmpty().trim(),
  body('priceUsdc').isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('threshold').optional().isInt({ min: 0 }),
  body('description').optional().isString(),
  body('category').optional().trim(),
  body('sku').optional().trim(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  try {
    await prisma.user.update({ where: { id: req.user.id }, data: { isMerchant: true } });

    const product = await prisma.inventoryItem.create({
      data: {
        userId:      req.user.id,
        name:        req.body.name,
        description: req.body.description ?? null,
        priceUsdc:   parseFloat(req.body.priceUsdc),
        stock:       parseInt(req.body.stock ?? 0),
        threshold:   parseInt(req.body.threshold ?? 5),
        sku:         req.body.sku ?? null,
        category:    req.body.category ?? null,
        isActive:    true,
      },
    });
    res.status(201).json({ product });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// PATCH /api/shop/products/:id
router.patch('/products/:id', authenticate, requireMerchant, [
  body('priceUsdc').optional().isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('threshold').optional().isInt({ min: 0 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  try {
    const existing = await prisma.inventoryItem.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return sendNotFound(res, 'Product');

    const { name, description, priceUsdc, stock, threshold, sku, category, isActive } = req.body;
    const product = await prisma.inventoryItem.update({
      where: { id: req.params.id },
      data: {
        ...(name        !== undefined && { name }),
        ...(description !== undefined && { description }),
        ...(priceUsdc   !== undefined && { priceUsdc: parseFloat(priceUsdc) }),
        ...(stock       !== undefined && { stock:     parseInt(stock) }),
        ...(threshold   !== undefined && { threshold: parseInt(threshold) }),
        ...(sku         !== undefined && { sku }),
        ...(category    !== undefined && { category }),
        ...(isActive    !== undefined && { isActive }),
      },
    });
    res.json({ product });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// DELETE /api/shop/products/:id
router.delete('/products/:id', authenticate, requireMerchant, async (req, res) => {
  try {
    const existing = await prisma.inventoryItem.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return sendNotFound(res, 'Product');
    await prisma.inventoryItem.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// IMAGE UPLOAD
// ══════════════════════════════════════════════════════════════════════════════

// POST /api/shop/products/:id/image
router.post('/products/:id/image', authenticate, requireMerchant, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, 'NO_FILE', 'Image file required.');

    const existing = await prisma.inventoryItem.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!existing) return sendNotFound(res, 'Product');

    const result   = await uploadToCloudinary(req.file.buffer);
    const product  = await prisma.inventoryItem.update({
      where: { id: req.params.id },
      data:  { imageUrl: result.secure_url },
    });
    res.json({ product, imageUrl: result.secure_url });
  } catch (err) {
    sendError(res, 500, 'UPLOAD_ERROR', err.message);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// IMPORT / EXPORT
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/shop/products/export/csv
router.get('/products/export/csv', authenticate, async (req, res) => {
  try {
    const products = await prisma.inventoryItem.findMany({
      where:   { userId: req.user.id },
      orderBy: { createdAt: 'asc' },
    });

    const header = 'name,description,priceUsdc,stock,threshold,sku,category';
    const rows   = products.map(p =>
      [p.name, p.description ?? '', p.priceUsdc, p.stock, p.threshold, p.sku ?? '', p.category ?? '']
        .map(v => `"${String(v).replace(/"/g, '""')}"`)
        .join(','),
    );

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="products.csv"');
    res.send([header, ...rows].join('\n'));
  } catch (err) {
    sendError(res, 500, 'EXPORT_ERROR', err.message);
  }
});

// POST /api/shop/products/import/csv
const csvUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024 } });

router.post('/products/import/csv', authenticate, requireMerchant, csvUpload.single('file'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, 'NO_FILE', 'CSV file required.');

    const text  = req.file.buffer.toString('utf-8');
    const lines = text.split('\n').map(l => l.trim()).filter(Boolean);
    if (lines.length < 2) return sendError(res, 400, 'EMPTY_CSV', 'CSV has no data rows.');

    // Parse header
    const header = lines[0].split(',').map(h => h.replace(/"/g, '').trim());
    const nameIdx  = header.indexOf('name');
    const priceIdx = header.indexOf('priceUsdc');
    if (nameIdx === -1 || priceIdx === -1) {
      return sendError(res, 400, 'INVALID_CSV', 'CSV must have name and priceUsdc columns.');
    }

    const parseCell = (row, i) => {
      const cells = row.match(/(".*?"|[^,]+)(?=,|$)/g) ?? [];
      return (cells[i] ?? '').replace(/^"|"$/g, '').replace(/""/g, '"').trim();
    };

    const created = [];
    const errors  = [];

    await prisma.user.update({ where: { id: req.user.id }, data: { isMerchant: true } });

    for (let i = 1; i < lines.length; i++) {
      const row   = lines[i];
      const name  = parseCell(row, nameIdx);
      const price = parseFloat(parseCell(row, priceIdx));

      if (!name || isNaN(price)) {
        errors.push({ row: i + 1, reason: 'Missing name or invalid price' });
        continue;
      }

      const stockIdx     = header.indexOf('stock');
      const threshIdx    = header.indexOf('threshold');
      const skuIdx       = header.indexOf('sku');
      const catIdx       = header.indexOf('category');
      const descIdx      = header.indexOf('description');

      try {
        const item = await prisma.inventoryItem.create({
          data: {
            userId:      req.user.id,
            name,
            priceUsdc:   price,
            stock:       stockIdx !== -1 ? parseInt(parseCell(row, stockIdx)) || 0 : 0,
            threshold:   threshIdx !== -1 ? parseInt(parseCell(row, threshIdx)) || 5 : 5,
            sku:         skuIdx !== -1 ? parseCell(row, skuIdx) || null : null,
            category:    catIdx !== -1 ? parseCell(row, catIdx) || null : null,
            description: descIdx !== -1 ? parseCell(row, descIdx) || null : null,
            isActive:    true,
          },
        });
        created.push(item);
      } catch (e) {
        errors.push({ row: i + 1, reason: e.message });
      }
    }

    res.json({ imported: created.length, errors, products: created });
  } catch (err) {
    sendError(res, 500, 'IMPORT_ERROR', err.message);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// ORDERS
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/shop/orders
router.get('/orders', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const where = { userId: req.user.id };
    if (status) where.status = status;

    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where,
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        skip:  (parseInt(page) - 1) * parseInt(limit),
        take:  parseInt(limit),
      }),
      prisma.order.count({ where }),
    ]);

    res.json({ orders, pagination: { page: parseInt(page), total, pages: Math.ceil(total / parseInt(limit)) } });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// POST /api/shop/orders  — create order from checkout
router.post('/orders', authenticate, [
  body('items').isArray({ min: 1 }),
  body('items.*.inventoryItemId').notEmpty(),
  body('items.*.quantity').isInt({ min: 1 }),
  body('customerName').optional().isString(),
  body('customerEmail').optional().isEmail(),
  body('stellarTxHash').optional().isString(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  try {
    const { items, customerName, customerEmail, customerPhone, notes, stellarTxHash } = req.body;

    // Validate items belong to this user
    const ids       = items.map(i => i.inventoryItemId);
    const dbItems   = await prisma.inventoryItem.findMany({ where: { id: { in: ids }, userId: req.user.id } });
    if (dbItems.length !== ids.length) return sendError(res, 400, 'INVALID_ITEMS', 'Some items not found.');

    const itemMap   = Object.fromEntries(dbItems.map(i => [i.id, i]));
    let totalUsdc   = 0;
    const orderItems = items.map(i => {
      const db = itemMap[i.inventoryItemId];
      totalUsdc += db.priceUsdc * i.quantity;
      return { inventoryItemId: i.inventoryItemId, name: db.name, priceUsdc: db.priceUsdc, quantity: i.quantity };
    });

    const orderNumber = await generateOrderNumber(req.user.id);

    const order = await prisma.order.create({
      data: {
        userId:        req.user.id,
        orderNumber,
        totalUsdc,
        customerName:  customerName  ?? null,
        customerEmail: customerEmail ?? null,
        customerPhone: customerPhone ?? null,
        notes:         notes         ?? null,
        stellarTxHash: stellarTxHash ?? null,
        status:        stellarTxHash ? 'confirmed' : 'pending',
        paidAt:        stellarTxHash ? new Date() : null,
        items: { create: orderItems },
      },
      include: { items: true },
    });

    // Deduct stock
    for (const i of items) {
      await prisma.inventoryItem.update({
        where: { id: i.inventoryItemId },
        data:  { stock: { decrement: i.quantity } },
      });
    }

    res.status(201).json({ order });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// PATCH /api/shop/orders/:id/status
router.patch('/orders/:id/status', authenticate, requireMerchant, [
  body('status').isIn(['pending', 'confirmed', 'fulfilled', 'cancelled', 'refunded']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  try {
    const existing = await prisma.order.findFirst({ where: { id: req.params.id, userId: req.user.id } });
    if (!existing) return sendNotFound(res, 'Order');

    const order = await prisma.order.update({
      where: { id: req.params.id },
      data:  { status: req.body.status },
      include: { items: true },
    });
    res.json({ order });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// OVERVIEW
// ══════════════════════════════════════════════════════════════════════════════

router.get('/overview', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;

    const [totalProducts, products, orders] = await Promise.all([
      prisma.inventoryItem.count({ where: { userId } }),
      prisma.inventoryItem.findMany({ where: { userId } }),
      prisma.order.findMany({
        where:   { userId },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
        take:    10,
      }),
    ]);

    const totalRevenue  = orders.reduce((s, o) => s + (o.totalUsdc ?? 0), 0);
    const lowStockCount = products.filter(p => p.stock <= p.threshold).length;
    const outOfStock    = products.filter(p => p.stock === 0).length;
    const totalStock    = products.reduce((s, p) => s + p.stock, 0);
    const totalValue    = products.reduce((s, p) => s + p.priceUsdc * p.stock, 0);

    res.json({
      overview: {
        totalProducts,
        activeProducts: products.filter(p => p.isActive).length,
        lowStockCount,
        outOfStock,
        totalStock,
        totalValue,
        totalOrders:   orders.length,
        totalRevenue,
        pendingOrders: orders.filter(o => o.status === 'pending').length,
      },
      recentOrders:   orders,
      lowStockItems:  products.filter(p => p.stock <= p.threshold),
    });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// PAYMENT LINK
// ══════════════════════════════════════════════════════════════════════════════

router.post('/payment-link', authenticate, requireMerchant, [
  body('items').isArray({ min: 1 }),
  body('totalUsdc').isFloat({ min: 0.000001 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return sendValidationError(res, errors.array());

  try {
    const { items, totalUsdc } = req.body;
    const destination = req.user.stellarPublicKey;
    if (!destination) return sendError(res, 400, 'WALLET_NOT_READY', 'Merchant wallet not set up.');

    const { generateMemoReceipt, buildStellarPayUri } = await import('../services/inventoryService.js');
    const memo = generateMemoReceipt(items, totalUsdc);
    const uri  = buildStellarPayUri({ destination, amountUsdc: totalUsdc, memo });

    res.json({ uri, memo, destination, totalUsdc });
  } catch (err) {
    sendError(res, 500, 'SHOP_ERROR', err.message);
  }
});

export default router;