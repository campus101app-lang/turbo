-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('draft', 'sent', 'viewed', 'paid', 'overdue', 'cancelled');

-- CreateEnum
CREATE TYPE "InvoicePaymentType" AS ENUM ('crypto', 'bankTransfer', 'both');

-- CreateEnum
CREATE TYPE "RecurringInterval" AS ENUM ('weekly', 'monthly', 'quarterly', 'annually');

-- CreateEnum
CREATE TYPE "ExpenseCategory" AS ENUM ('travel', 'meals', 'accommodation', 'equipment', 'software', 'marketing', 'utilities', 'salary', 'other');

-- CreateEnum
CREATE TYPE "ExpenseStatus" AS ENUM ('pending', 'approved', 'rejected', 'reimbursed');

-- CreateEnum
CREATE TYPE "FwPaymentType" AS ENUM ('deposit', 'withdrawal');

-- CreateEnum
CREATE TYPE "FwPaymentStatus" AS ENUM ('initiated', 'pending', 'successful', 'failed');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "TransactionType" ADD VALUE 'fiatDeposit';
ALTER TYPE "TransactionType" ADD VALUE 'fiatWithdrawal';
ALTER TYPE "TransactionType" ADD VALUE 'invoicePayment';
ALTER TYPE "TransactionType" ADD VALUE 'expenseReimbursement';

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "expenseId" TEXT,
ADD COLUMN     "fiatAmount" DOUBLE PRECISION,
ADD COLUMN     "fiatCurrency" TEXT,
ADD COLUMN     "flutterwaveRef" TEXT,
ADD COLUMN     "flutterwaveStatus" TEXT,
ADD COLUMN     "invoiceId" TEXT,
ADD COLUMN     "swapId" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "businessCategory" TEXT,
ADD COLUMN     "businessEmail" TEXT,
ADD COLUMN     "businessName" TEXT,
ADD COLUMN     "fullName" TEXT,
ADD COLUMN     "isMerchant" BOOLEAN NOT NULL DEFAULT false,
ALTER COLUMN "username" DROP NOT NULL;

-- CreateTable
CREATE TABLE "Invoice" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "invoiceNumber" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "clientName" TEXT NOT NULL,
    "clientEmail" TEXT,
    "clientPhone" TEXT,
    "clientAddress" TEXT,
    "lineItems" JSONB NOT NULL,
    "subtotal" DOUBLE PRECISION NOT NULL,
    "vatAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'NGNT',
    "paymentType" "InvoicePaymentType" NOT NULL DEFAULT 'crypto',
    "bankAccountDetails" JSONB,
    "paymentLink" TEXT,
    "status" "InvoiceStatus" NOT NULL DEFAULT 'draft',
    "dueDate" TIMESTAMP(3),
    "sentAt" TIMESTAMP(3),
    "viewedAt" TIMESTAMP(3),
    "paidAt" TIMESTAMP(3),
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "recurringInterval" "RecurringInterval",
    "nextDueDate" TIMESTAMP(3),
    "vatEnabled" BOOLEAN NOT NULL DEFAULT false,
    "vatRate" DOUBLE PRECISION NOT NULL DEFAULT 7.5,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Invoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Expense" (
    "id" TEXT NOT NULL,
    "submittedById" TEXT NOT NULL,
    "approvedById" TEXT,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'NGN',
    "onChainAsset" TEXT DEFAULT 'NGNT',
    "category" "ExpenseCategory" NOT NULL,
    "receiptUrl" TEXT,
    "status" "ExpenseStatus" NOT NULL DEFAULT 'pending',
    "rejectionNote" TEXT,
    "reimbursedAt" TIMESTAMP(3),
    "notes" TEXT,
    "approvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Expense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FlutterwavePayment" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "txRef" TEXT NOT NULL,
    "flwRef" TEXT,
    "type" "FwPaymentType" NOT NULL,
    "fiatAmount" DOUBLE PRECISION NOT NULL,
    "onChainAmount" DOUBLE PRECISION,
    "currency" TEXT NOT NULL DEFAULT 'NGN',
    "status" "FwPaymentStatus" NOT NULL DEFAULT 'initiated',
    "bankCode" TEXT,
    "accountNumber" TEXT,
    "accountName" TEXT,
    "customerEmail" TEXT,
    "customerName" TEXT,
    "redirectUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FlutterwavePayment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InventoryItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sku" TEXT,
    "priceUsdc" DOUBLE PRECISION NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "threshold" INTEGER NOT NULL DEFAULT 5,
    "barcode" TEXT,
    "imageUrl" TEXT,
    "category" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InventoryItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_invoiceNumber_key" ON "Invoice"("invoiceNumber");

-- CreateIndex
CREATE INDEX "Invoice_userId_idx" ON "Invoice"("userId");

-- CreateIndex
CREATE INDEX "Invoice_status_idx" ON "Invoice"("status");

-- CreateIndex
CREATE INDEX "Invoice_invoiceNumber_idx" ON "Invoice"("invoiceNumber");

-- CreateIndex
CREATE INDEX "Expense_submittedById_idx" ON "Expense"("submittedById");

-- CreateIndex
CREATE INDEX "Expense_status_idx" ON "Expense"("status");

-- CreateIndex
CREATE UNIQUE INDEX "FlutterwavePayment_txRef_key" ON "FlutterwavePayment"("txRef");

-- CreateIndex
CREATE INDEX "FlutterwavePayment_userId_idx" ON "FlutterwavePayment"("userId");

-- CreateIndex
CREATE INDEX "FlutterwavePayment_txRef_idx" ON "FlutterwavePayment"("txRef");

-- CreateIndex
CREATE INDEX "FlutterwavePayment_flwRef_idx" ON "FlutterwavePayment"("flwRef");

-- CreateIndex
CREATE INDEX "InventoryItem_userId_idx" ON "InventoryItem"("userId");

-- CreateIndex
CREATE INDEX "InventoryItem_sku_idx" ON "InventoryItem"("sku");

-- CreateIndex
CREATE INDEX "Transaction_flutterwaveRef_idx" ON "Transaction"("flutterwaveRef");

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_expenseId_fkey" FOREIGN KEY ("expenseId") REFERENCES "Expense"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_approvedById_fkey" FOREIGN KEY ("approvedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FlutterwavePayment" ADD CONSTRAINT "FlutterwavePayment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InventoryItem" ADD CONSTRAINT "InventoryItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
