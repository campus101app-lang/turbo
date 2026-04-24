-- CreateEnum
CREATE TYPE "CardType" AS ENUM ('virtual', 'physical');

-- CreateEnum
CREATE TYPE "CardCurrency" AS ENUM ('USDC', 'NGN');

-- CreateEnum
CREATE TYPE "CardStatus" AS ENUM ('active', 'frozen', 'cancelled');

-- CreateEnum
CREATE TYPE "WorkflowTrigger" AS ENUM ('scheduled', 'balanceThreshold', 'invoicePaid', 'expenseApproved', 'manualRun');

-- CreateEnum
CREATE TYPE "WorkflowAction" AS ENUM ('sendPayment', 'createInvoice', 'sendReminder', 'notifyUser', 'flagExpense');

-- CreateEnum
CREATE TYPE "WorkflowStatus" AS ENUM ('active', 'paused', 'archived');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('pending', 'paid', 'expired', 'cancelled');

-- AlterEnum
ALTER TYPE "TransactionType" ADD VALUE 'requestPayment';

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "paymentRequestId" TEXT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "virtualAccountBank" TEXT,
ADD COLUMN     "virtualAccountName" TEXT,
ADD COLUMN     "virtualAccountNumber" TEXT;

-- CreateTable
CREATE TABLE "Card" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "cardNumber" TEXT NOT NULL,
    "last4" TEXT NOT NULL,
    "cardholderName" TEXT NOT NULL,
    "expiryMonth" INTEGER NOT NULL,
    "expiryYear" INTEGER NOT NULL,
    "cvvHash" TEXT,
    "type" "CardType" NOT NULL DEFAULT 'virtual',
    "currency" "CardCurrency" NOT NULL DEFAULT 'USDC',
    "status" "CardStatus" NOT NULL DEFAULT 'active',
    "frozenAt" TIMESTAMP(3),
    "cancelledAt" TIMESTAMP(3),
    "spendingLimit" DOUBLE PRECISION,
    "spendingLimitPeriod" TEXT DEFAULT 'daily',
    "provider" TEXT DEFAULT 'internal',
    "providerCardId" TEXT,
    "label" TEXT,
    "color" TEXT DEFAULT '#6C47FF',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Card_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Workflow" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "triggerType" "WorkflowTrigger" NOT NULL,
    "triggerConfig" JSONB NOT NULL,
    "actionType" "WorkflowAction" NOT NULL,
    "actionConfig" JSONB NOT NULL,
    "status" "WorkflowStatus" NOT NULL DEFAULT 'active',
    "pausedAt" TIMESTAMP(3),
    "lastRunAt" TIMESTAMP(3),
    "nextRunAt" TIMESTAMP(3),
    "runCount" INTEGER NOT NULL DEFAULT 0,
    "failCount" INTEGER NOT NULL DEFAULT 0,
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Workflow_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PaymentRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "requestNumber" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "asset" TEXT NOT NULL DEFAULT 'USDC',
    "note" TEXT,
    "payerName" TEXT,
    "payerEmail" TEXT,
    "paymentLink" TEXT,
    "status" "RequestStatus" NOT NULL DEFAULT 'pending',
    "paidAt" TIMESTAMP(3),
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PaymentRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Card_cardNumber_key" ON "Card"("cardNumber");

-- CreateIndex
CREATE INDEX "Card_userId_idx" ON "Card"("userId");

-- CreateIndex
CREATE INDEX "Card_status_idx" ON "Card"("status");

-- CreateIndex
CREATE INDEX "Workflow_userId_idx" ON "Workflow"("userId");

-- CreateIndex
CREATE INDEX "Workflow_status_idx" ON "Workflow"("status");

-- CreateIndex
CREATE INDEX "Workflow_nextRunAt_idx" ON "Workflow"("nextRunAt");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentRequest_requestNumber_key" ON "PaymentRequest"("requestNumber");

-- CreateIndex
CREATE INDEX "PaymentRequest_userId_idx" ON "PaymentRequest"("userId");

-- CreateIndex
CREATE INDEX "PaymentRequest_status_idx" ON "PaymentRequest"("status");

-- CreateIndex
CREATE INDEX "PaymentRequest_requestNumber_idx" ON "PaymentRequest"("requestNumber");

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_paymentRequestId_fkey" FOREIGN KEY ("paymentRequestId") REFERENCES "PaymentRequest"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Card" ADD CONSTRAINT "Card_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Workflow" ADD CONSTRAINT "Workflow_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PaymentRequest" ADD CONSTRAINT "PaymentRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
