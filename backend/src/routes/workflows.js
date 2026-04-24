// src/routes/workflows.js
// Mounts at /api/workflows
//
// GET    /api/workflows           → list user's workflows
// POST   /api/workflows           → create workflow
// GET    /api/workflows/:id       → get single workflow
// PUT    /api/workflows/:id       → update workflow
// DELETE /api/workflows/:id       → delete (archive) workflow
// POST   /api/workflows/:id/pause → pause workflow
// POST   /api/workflows/:id/resume → resume workflow
// POST   /api/workflows/:id/run   → manually trigger a workflow

import express from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth.js';
import { PrismaClient } from '@prisma/client';

const router = express.Router();
const prisma = new PrismaClient();

// ─── Valid enums (mirrors Prisma schema) ──────────────────────────────────────

const VALID_TRIGGERS = [
  'scheduled',
  'balanceThreshold',
  'invoicePaid',
  'expenseApproved',
  'manualRun',
];

const VALID_ACTIONS = [
  'sendPayment',
  'createInvoice',
  'sendReminder',
  'notifyUser',
  'flagExpense',
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Compute the next run time for a scheduled workflow.
 * triggerConfig shape: { interval: 'daily' | 'weekly' | 'monthly', hour?: number }
 */
function computeNextRun(triggerType, triggerConfig) {
  if (triggerType !== 'scheduled') return null;

  const now      = new Date();
  const interval = triggerConfig?.interval ?? 'monthly';
  const hour     = triggerConfig?.hour     ?? 9; // default 9 AM

  const next = new Date(now);
  next.setHours(hour, 0, 0, 0);

  switch (interval) {
    case 'daily':
      next.setDate(now.getDate() + 1);
      break;
    case 'weekly':
      next.setDate(now.getDate() + 7);
      break;
    case 'monthly':
      next.setMonth(now.getMonth() + 1, triggerConfig?.day ?? 1);
      break;
    default:
      next.setMonth(now.getMonth() + 1);
  }

  return next;
}

// ─── GET /api/workflows ───────────────────────────────────────────────────────

router.get('/', authenticate, async (req, res) => {
  const { status } = req.query;

  try {
    const workflows = await prisma.workflow.findMany({
      where: {
        userId: req.user.id,
        status: status
          ? status
          : { not: 'archived' }, // hide archived by default
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ workflows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/workflows ──────────────────────────────────────────────────────

router.post('/', authenticate, [
  body('name').notEmpty().withMessage('Name is required'),
  body('triggerType').isIn(VALID_TRIGGERS).withMessage('Invalid trigger type'),
  body('triggerConfig').isObject().withMessage('triggerConfig must be an object'),
  body('actionType').isIn(VALID_ACTIONS).withMessage('Invalid action type'),
  body('actionConfig').isObject().withMessage('actionConfig must be an object'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    const { name, description, triggerType, triggerConfig, actionType, actionConfig } = req.body;

    const nextRunAt = computeNextRun(triggerType, triggerConfig);

    const workflow = await prisma.workflow.create({
      data: {
        userId:        req.user.id,
        name,
        description:   description ?? null,
        triggerType,
        triggerConfig,
        actionType,
        actionConfig,
        status:        'active',
        nextRunAt,
      },
    });

    res.status(201).json({ workflow });
  } catch (err) {
    console.error('Create workflow error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/workflows/:id ───────────────────────────────────────────────────

router.get('/:id', authenticate, async (req, res) => {
  try {
    const workflow = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!workflow) return res.status(404).json({ error: 'Workflow not found' });

    res.json({ workflow });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT /api/workflows/:id ───────────────────────────────────────────────────

router.put('/:id', authenticate, [
  body('triggerType').optional().isIn(VALID_TRIGGERS),
  body('triggerConfig').optional().isObject(),
  body('actionType').optional().isIn(VALID_ACTIONS),
  body('actionConfig').optional().isObject(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Workflow not found' });
    if (existing.status === 'archived') {
      return res.status(400).json({ error: 'Cannot edit an archived workflow' });
    }

    const triggerType   = req.body.triggerType   ?? existing.triggerType;
    const triggerConfig = req.body.triggerConfig  ?? existing.triggerConfig;

    const nextRunAt = computeNextRun(triggerType, triggerConfig);

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data: {
        name:          req.body.name          ?? existing.name,
        description:   req.body.description   ?? existing.description,
        triggerType,
        triggerConfig,
        actionType:    req.body.actionType    ?? existing.actionType,
        actionConfig:  req.body.actionConfig  ?? existing.actionConfig,
        nextRunAt,
      },
    });

    res.json({ workflow: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/workflows/:id ────────────────────────────────────────────────
// Soft-delete: sets status to 'archived'

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Workflow not found' });

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'archived' },
    });

    res.json({ workflow: updated, message: 'Workflow archived' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/workflows/:id/pause ───────────────────────────────────────────

router.post('/:id/pause', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Workflow not found' });
    if (existing.status === 'paused')   return res.status(400).json({ error: 'Workflow already paused' });
    if (existing.status === 'archived') return res.status(400).json({ error: 'Cannot pause an archived workflow' });

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'paused', pausedAt: new Date() },
    });

    res.json({ workflow: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/workflows/:id/resume ──────────────────────────────────────────

router.post('/:id/resume', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return res.status(404).json({ error: 'Workflow not found' });
    if (existing.status === 'active')   return res.status(400).json({ error: 'Workflow is already active' });
    if (existing.status === 'archived') return res.status(400).json({ error: 'Cannot resume an archived workflow' });

    const nextRunAt = computeNextRun(existing.triggerType, existing.triggerConfig);

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'active', pausedAt: null, nextRunAt },
    });

    res.json({ workflow: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/workflows/:id/run ─────────────────────────────────────────────
// Manually trigger a workflow (respects actionType)

router.post('/:id/run', authenticate, async (req, res) => {
  try {
    const workflow = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!workflow) return res.status(404).json({ error: 'Workflow not found' });
    if (workflow.status === 'archived') {
      return res.status(400).json({ error: 'Cannot run an archived workflow' });
    }

    // ── Execute action ────────────────────────────────────────────────────────
    let result = null;
    const cfg  = workflow.actionConfig;

    try {
      switch (workflow.actionType) {
        case 'notifyUser':
          // TODO: fire push notification
          result = { action: 'notifyUser', message: cfg?.message ?? 'Workflow triggered' };
          break;

        case 'sendPayment':
          // TODO: call walletService.sendAsset when ready
          result = { action: 'sendPayment', status: 'queued', to: cfg?.to, amount: cfg?.amount };
          break;

        case 'sendReminder':
          // TODO: send email/push reminder
          result = { action: 'sendReminder', status: 'queued' };
          break;

        case 'createInvoice':
          // TODO: auto-create invoice from template
          result = { action: 'createInvoice', status: 'queued' };
          break;

        case 'flagExpense':
          result = { action: 'flagExpense', status: 'queued' };
          break;

        default:
          result = { action: workflow.actionType, status: 'unsupported' };
      }

      // Update run stats
      await prisma.workflow.update({
        where: { id: workflow.id },
        data: {
          lastRunAt: new Date(),
          runCount:  { increment: 1 },
          nextRunAt: computeNextRun(workflow.triggerType, workflow.triggerConfig),
          lastError: null,
        },
      });

      res.json({ success: true, result });
    } catch (execErr) {
      // Log the failure
      await prisma.workflow.update({
        where: { id: workflow.id },
        data: {
          failCount: { increment: 1 },
          lastError: execErr.message,
          lastRunAt: new Date(),
        },
      });
      throw execErr;
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;