// src/routes/expenses.js
// Mounts at /api/expenses
//
// GET    /api/expenses             → list user's expenses (submitted + pending approval)
// POST   /api/expenses             → create expense
// GET    /api/expenses/:id         → get single expense
// PUT    /api/expenses/:id         → update expense (draft only)
// DELETE /api/expenses/:id         → delete expense (draft only)
// POST   /api/expenses/:id/submit  → mark as submitted for approval
// POST   /api/expenses/:id/approve → approve expense (manager only)
// POST   /api/expenses/:id/reject  → reject expense with reason (manager only)

import express from "express";
import { body, validationResult } from "express-validator";
import { authenticate } from "../middleware/auth.js";
import { PrismaClient } from "@prisma/client";

const router = express.Router();
const prisma = new PrismaClient();

// ─── GET /api/expenses ────────────────────────────────────────────────────────
// Lists: 1) My submitted expenses 2) Expenses awaiting my approval

router.get("/", authenticate, async (req, res) => {
  const { page = 1, limit = 20, status, category } = req.query;
  const skip = (parseInt(page) - 1) * parseInt(limit);

  try {
    // Get user to check if they can approve
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { isMerchant: true },
    });

    // Build WHERE clause: my expenses OR expenses awaiting my approval
    let where = {
      OR: [
        // My submitted expenses
        { submittedById: req.user.id },
        // Expenses awaiting my approval (if I'm a merchant/manager)
        ...(user?.isMerchant
          ? [{ approvedById: null, status: "pending" }]
          : []),
      ],
      ...(status ? { status } : {}),
      ...(category ? { category } : {}),
    };

    const [expenses, total] = await Promise.all([
      prisma.expense.findMany({
        where,
        include: {
          submittedBy: {
            select: { id: true, businessName: true, email: true },
          },
          approvedBy: { select: { id: true, businessName: true } },
        },
        orderBy: { createdAt: "desc" },
        take: parseInt(limit),
        skip,
      }),
      prisma.expense.count({ where }),
    ]);

    res.json({
      expenses,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/expenses ───────────────────────────────────────────────────────

router.post(
  "/",
  authenticate,
  [
    body("title").notEmpty().withMessage("Title is required"),
    body("amount").isFloat({ min: 0 }).withMessage("Amount must be positive"),
    body("category")
      .isIn([
        "travel",
        "meals",
        "accommodation",
        "equipment",
        "software",
        "marketing",
        "utilities",
        "salary",
        "other",
      ])
      .withMessage("Invalid category"),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    try {
      const expense = await prisma.expense.create({
        data: {
          submittedById: req.user.id,
          title: req.body.title,
          description: req.body.description ?? null,
          amount: parseFloat(req.body.amount),
          currency: req.body.currency ?? "NGN",
          category: req.body.category,
          receiptUrl: req.body.receiptUrl ?? null,
          status: "pending",
        },
        include: {
          submittedBy: { select: { id: true, businessName: true } },
        },
      });

      res.status(201).json({ expense });
    } catch (err) {
      console.error("Create expense error:", err.message);
      res.status(500).json({ error: err.message });
    }
  },
);

// ─── GET /api/expenses/:id ────────────────────────────────────────────────────

router.get("/:id", authenticate, async (req, res) => {
  try {
    const expense = await prisma.expense.findUnique({
      where: { id: req.params.id },
      include: {
        submittedBy: { select: { id: true, businessName: true, email: true } },
        approvedBy: { select: { id: true, businessName: true } },
      },
    });

    if (!expense) return res.status(404).json({ error: "Expense not found" });

    // Check authorization: owner or approver
    if (
      expense.submittedById !== req.user.id &&
      expense.approvedById !== req.user.id
    ) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    res.json({ expense });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT /api/expenses/:id ────────────────────────────────────────────────────
// Can only update draft expenses owned by user

router.put("/:id", authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, amount, currency, category, receiptUrl } =
      req.body;

    const existing = await prisma.expense.findUnique({
      where: { id },
    });

    if (!existing) return res.status(404).json({ error: "Expense not found" });

    // FIX: Using submittedById from your schema to check ownership
    if (existing.submittedById !== req.user.id) {
      return res
        .status(403)
        .json({ error: "Unauthorized: You did not create this expense" });
    }

    // Business Logic: Prevent editing once a manager has acted on it
    if (existing.status !== "pending") {
      return res
        .status(400)
        .json({
          error: `Cannot edit an expense that is already ${existing.status}`,
        });
    }

    const updated = await prisma.expense.update({
      where: { id },
      data: {
        title: title ?? existing.title,
        description: description ?? existing.description,
        amount: amount != null ? parseFloat(amount) : existing.amount,
        currency: currency ?? existing.currency,
        category: category ?? existing.category,
        receiptUrl: receiptUrl ?? existing.receiptUrl,
      },
      include: {
        submittedBy: { select: { id: true, businessName: true } },
      },
    });

    res.json({ expense: updated });
  } catch (err) {
    console.error("Update expense error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ─── DELETE /api/expenses/:id ─────────────────────────────────────────────────
// Can only delete draft expenses owned by user

router.delete("/:id", authenticate, async (req, res) => {
  try {
    const existing = await prisma.expense.findUnique({
      where: { id: req.params.id },
    });

    if (!existing) return res.status(404).json({ error: "Expense not found" });
    if (existing.submittedById !== req.user.id) {
      return res.status(403).json({ error: "Unauthorized" });
    }
    if (existing.status !== "pending") {
      return res
        .status(400)
        .json({ error: "Only pending expenses can be edited" });
    }

    await prisma.expense.delete({ where: { id: req.params.id } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/expenses/:id/submit ────────────────────────────────────────────
// User submits expense for approval

router.post("/:id/submit", authenticate, async (req, res) => {
  try {
    const existing = await prisma.expense.findUnique({
      where: { id: req.params.id },
    });

    if (!existing) return res.status(404).json({ error: "Expense not found" });
    if (existing.submittedById !== req.user.id) {
      return res.status(403).json({ error: "Unauthorized" });
    }
    if (existing.status !== "pending") {
      return res
        .status(400)
        .json({ error: "Only pending expenses can be submitted" });
    }

    // Expense is already in pending status, ready for approval
    res.json({ expense: existing });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/expenses/:id/approve ───────────────────────────────────────────
// Manager approves expense

router.post("/:id/approve", authenticate, async (req, res) => {
  try {
    // Check if user is merchant/manager
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { isMerchant: true },
    });

    if (!user?.isMerchant) {
      return res
        .status(403)
        .json({ error: "Only managers can approve expenses" });
    }

    const existing = await prisma.expense.findUnique({
      where: { id: req.params.id },
    });

    if (!existing) return res.status(404).json({ error: "Expense not found" });
    if (existing.status === "approved") {
      return res.status(400).json({ error: "Expense already approved" });
    }
    if (existing.status !== "pending") {
      return res
        .status(400)
        .json({ error: "Only pending expenses can be approved" });
    }

    const updated = await prisma.expense.update({
      where: { id: req.params.id },
      data: {
        status: "approved",
        approvedById: req.user.id,
        approvedAt: new Date(),
      },
      include: {
        submittedBy: { select: { id: true, businessName: true } },
        approvedBy: { select: { id: true, businessName: true } },
      },
    });

    res.json({ expense: updated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/expenses/:id/reject ────────────────────────────────────────────
// Manager rejects expense with reason

router.post(
  "/:id/reject",
  authenticate,
  [
    body("rejectionNote")
      .notEmpty()
      .withMessage("Rejection reason is required"),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg });
    }

    try {
      // Check if user is merchant/manager
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        select: { isMerchant: true },
      });

      if (!user?.isMerchant) {
        return res
          .status(403)
          .json({ error: "Only managers can reject expenses" });
      }

      const existing = await prisma.expense.findUnique({
        where: { id: req.params.id },
      });

      if (!existing)
        return res.status(404).json({ error: "Expense not found" });
      if (existing.status === "rejected") {
        return res.status(400).json({ error: "Expense already rejected" });
      }
      if (existing.status !== "pending") {
        return res
          .status(400)
          .json({ error: "Only pending expenses can be rejected" });
      }

      const updated = await prisma.expense.update({
        where: { id: req.params.id },
        data: {
          status: "rejected",
          approvedById: req.user.id,
          rejectionNote: req.body.rejectionNote,
        },
        include: {
          submittedBy: { select: { id: true, businessName: true } },
          approvedBy: { select: { id: true, businessName: true } },
        },
      });

      res.json({ expense: updated });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  },
);

export default router;
