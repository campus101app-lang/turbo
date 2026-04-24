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
import { sendError, sendNotFound, sendValidationError } from '../utils/http.js';
import { sendAsset } from '../services/walletService.js';

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

const BLOCKED_ACTIONS = new Set(['createInvoice']);

function notImplemented(res, feature, expectedAvailability = 'Planned in a later release.') {
  return sendError(res, 501, 'NOT_IMPLEMENTED', `${feature} is not implemented yet.`, {
    availableNow: 'Use notifyUser, sendReminder, or flagExpense actions.',
    expectedAvailability,
  });
}

function unsupportedAction(res, actionType) {
  return sendError(
    res,
    400,
    'UNSUPPORTED_ACTION',
    `Workflow action ${actionType} is currently disabled.`,
    {
      blockedActions: Array.from(BLOCKED_ACTIONS),
      availableNow: ['notifyUser', 'sendReminder', 'flagExpense'],
    },
  );
}

function isBlockedAction(actionType) {
  return BLOCKED_ACTIONS.has(actionType);
}

// ─── Action Config Validators ─────────────────────────────────────────────────

/**
 * Validation schemas for each workflow action type.
 * Each validator defines:
 * - required: array of required field names in actionConfig
 * - optional: array of optional field names (for documentation)
 * - validate: custom validation function that throws on invalid config
 */
const ACTION_VALIDATORS = {
  sendPayment: {
    required: ['amount', 'asset'],
    optional: ['memo'],
    validate: (config) => {
      const recipient = config.recipient ?? config.to;
      if (!recipient || typeof recipient !== 'string' || recipient.trim().length < 3) {
        throw new Error('Recipient is required');
      }
      if (typeof config.amount !== 'number' || config.amount <= 0) {
        throw new Error('Amount must be a positive number');
      }
      if (!['USDC', 'NGNT'].includes(config.asset)) {
        throw new Error('Unsupported asset. Must be USDC or NGNT');
      }
    },
  },
  createInvoice: {
    required: ['title', 'amount', 'currency'],
    optional: ['description', 'dueDate', 'lineItems'],
    validate: (config) => {
      if (typeof config.amount !== 'number' || config.amount <= 0) {
        throw new Error('Amount must be a positive number');
      }
      if (!['USDC', 'NGNT'].includes(config.currency)) {
        throw new Error('Unsupported currency. Must be USDC or NGNT');
      }
      if (!config.title || config.title.trim().length === 0) {
        throw new Error('Title is required');
      }
    },
  },
  sendReminder: {
    required: [],
    optional: ['message', 'channel', 'targetType', 'targetId'],
    validate: (config) => {
      if (config.channel && !['email', 'push', 'sms'].includes(config.channel)) {
        throw new Error('Invalid channel. Must be email, push, or sms');
      }
      if (config.targetType && !['invoice', 'expense', 'request'].includes(config.targetType)) {
        throw new Error('Invalid targetType. Must be invoice, expense, or request');
      }
    },
  },
  notifyUser: {
    required: ['message'],
    optional: ['priority', 'type'],
    validate: (config) => {
      if (!config.message || config.message.trim().length === 0) {
        throw new Error('Message is required and cannot be empty');
      }
      if (config.priority && !['low', 'normal', 'high', 'urgent'].includes(config.priority)) {
        throw new Error('Invalid priority. Must be low, normal, high, or urgent');
      }
    },
  },
  flagExpense: {
    required: ['reason'],
    optional: ['severity', 'expenseId'],
    validate: (config) => {
      if (!config.reason || config.reason.trim().length === 0) {
        throw new Error('Reason is required and cannot be empty');
      }
      if (config.severity && !['low', 'medium', 'high', 'critical'].includes(config.severity)) {
        throw new Error('Invalid severity. Must be low, medium, high, or critical');
      }
    },
  },
};

/**
 * Validate action configuration against the schema for the given action type.
 * Returns { valid, error } where error contains details if validation failed.
 */
async function validateActionConfig(actionType, actionConfig, userId) {
  const validator = ACTION_VALIDATORS[actionType];
  if (!validator) {
    return {
      valid: false,
      error: { code: 'UNKNOWN_ACTION_TYPE', message: `Unknown action type: ${actionType}` },
    };
  }

  // Check required fields
  for (const field of validator.required) {
    if (actionConfig[field] === undefined || actionConfig[field] === null) {
      return {
        valid: false,
        error: {
          code: 'MISSING_REQUIRED_FIELD',
          message: `Missing required field: ${field}`,
          details: { field, actionType },
        },
      };
    }
  }

  // Ownership checks for workflows targeting existing records.
  if (actionConfig.targetType && actionConfig.targetId) {
    let exists = false;
    if (actionConfig.targetType === 'invoice') {
      const invoice = await prisma.invoice.findFirst({
        where: { id: String(actionConfig.targetId), userId },
        select: { id: true },
      });
      exists = !!invoice;
    } else if (actionConfig.targetType === 'expense') {
      const expense = await prisma.expense.findFirst({
        where: { id: String(actionConfig.targetId), submittedById: userId },
        select: { id: true },
      });
      exists = !!expense;
    } else if (actionConfig.targetType === 'request') {
      const request = await prisma.paymentRequest.findFirst({
        where: { id: String(actionConfig.targetId), userId },
        select: { id: true },
      });
      exists = !!request;
    }

    if (!exists) {
      return {
        valid: false,
        error: {
          code: 'INVALID_TARGET',
          message: 'Action target does not exist or is not owned by the current user.',
          details: { targetType: actionConfig.targetType, targetId: actionConfig.targetId },
        },
      };
    }
  }

  // Run custom validation
  try {
    validator.validate(actionConfig);
  } catch (err) {
    return {
      valid: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: err.message,
        details: { actionType, field: err.field },
      },
    };
  }

  return { valid: true, error: null };
}

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
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
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
    return sendValidationError(res, errors.array());
  }

  try {
    const { name, description, triggerType, triggerConfig, actionType, actionConfig } = req.body;
    if (isBlockedAction(actionType)) {
      return unsupportedAction(res, actionType);
    }

    // Validate action config for all action types (including blocked ones for future-proofing)
    const validation = await validateActionConfig(actionType, actionConfig, req.user.id);
    if (!validation.valid) {
      return sendError(res, 400, validation.error.code, validation.error.message, validation.error.details);
    }

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
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── GET /api/workflows/:id ───────────────────────────────────────────────────

router.get('/:id', authenticate, async (req, res) => {
  try {
    const workflow = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!workflow) return sendNotFound(res, 'Workflow');

    res.json({ workflow });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
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
    return sendValidationError(res, errors.array());
  }

  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return sendNotFound(res, 'Workflow');
    if (existing.status === 'archived') {
      return sendError(res, 400, 'INVALID_STATE', 'Cannot edit an archived workflow.');
    }

    const triggerType   = req.body.triggerType   ?? existing.triggerType;
    const triggerConfig = req.body.triggerConfig  ?? existing.triggerConfig;
    const actionType = req.body.actionType ?? existing.actionType;

    if (isBlockedAction(actionType)) {
      return unsupportedAction(res, actionType);
    }

    const actionConfig = req.body.actionConfig ?? existing.actionConfig;
    const validation = await validateActionConfig(actionType, actionConfig, req.user.id);
    if (!validation.valid) {
      return sendError(res, 400, validation.error.code, validation.error.message, validation.error.details);
    }

    const nextRunAt = computeNextRun(triggerType, triggerConfig);

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data: {
        name:          req.body.name          ?? existing.name,
        description:   req.body.description   ?? existing.description,
        triggerType,
        triggerConfig,
        actionType,
        actionConfig,
        nextRunAt,
      },
    });

    res.json({ workflow: updated });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── DELETE /api/workflows/:id ────────────────────────────────────────────────
// Soft-delete: sets status to 'archived'

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return sendNotFound(res, 'Workflow');

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'archived' },
    });

    res.json({ workflow: updated, message: 'Workflow archived' });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── POST /api/workflows/:id/pause ───────────────────────────────────────────

router.post('/:id/pause', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return sendNotFound(res, 'Workflow');
    if (existing.status === 'paused') return sendError(res, 400, 'INVALID_STATE', 'Workflow already paused.');
    if (existing.status === 'archived') return sendError(res, 400, 'INVALID_STATE', 'Cannot pause an archived workflow.');

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'paused', pausedAt: new Date() },
    });

    res.json({ workflow: updated });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── POST /api/workflows/:id/resume ──────────────────────────────────────────

router.post('/:id/resume', authenticate, async (req, res) => {
  try {
    const existing = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!existing) return sendNotFound(res, 'Workflow');
    if (existing.status === 'active') return sendError(res, 400, 'INVALID_STATE', 'Workflow is already active.');
    if (existing.status === 'archived') return sendError(res, 400, 'INVALID_STATE', 'Cannot resume an archived workflow.');

    const nextRunAt = computeNextRun(existing.triggerType, existing.triggerConfig);

    const updated = await prisma.workflow.update({
      where: { id: req.params.id },
      data:  { status: 'active', pausedAt: null, nextRunAt },
    });

    res.json({ workflow: updated });
  } catch (err) {
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

// ─── POST /api/workflows/:id/run ─────────────────────────────────────────────
// Manually trigger a workflow (respects actionType)

router.post('/:id/run', authenticate, async (req, res) => {
  try {
    const workflow = await prisma.workflow.findFirst({
      where: { id: req.params.id, userId: req.user.id },
    });

    if (!workflow) return sendNotFound(res, 'Workflow');
    if (workflow.status === 'archived') {
      return sendError(res, 400, 'INVALID_STATE', 'Cannot run an archived workflow.');
    }

    const validation = await validateActionConfig(workflow.actionType, workflow.actionConfig, req.user.id);
    if (!validation.valid) {
      return sendError(res, 400, validation.error.code, validation.error.message, validation.error.details);
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
          result = await sendAsset(
            req.user.id,
            cfg?.recipient ?? cfg?.to,
            Number(cfg?.amount),
            cfg?.asset,
            cfg?.memo ?? 'Workflow payment',
          );
          result = { action: 'sendPayment', transaction: result };
          break;

        case 'sendReminder':
          // TODO: send email/push reminder
          result = { action: 'sendReminder', status: 'queued' };
          break;

        case 'createInvoice':
          return notImplemented(res, 'Workflow action createInvoice', 'Will ship after workflow invoice template validation is completed.');

        case 'flagExpense':
          result = { action: 'flagExpense', status: 'queued' };
          break;

        default:
          return notImplemented(
            res,
            `Workflow action ${workflow.actionType}`,
            'Unsupported actions are blocked until explicit support is added.',
          );
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
    sendError(res, 500, 'INTERNAL_ERROR', err.message);
  }
});

export default router;