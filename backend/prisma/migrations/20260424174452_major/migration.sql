-- AlterTable
ALTER TABLE "FlutterwavePayment" ADD COLUMN     "idempotencyKey" TEXT,
ADD COLUMN     "lastRetriedAt" TIMESTAMP(3),
ADD COLUMN     "providerMessage" TEXT,
ADD COLUMN     "providerStatus" TEXT,
ADD COLUMN     "retryCount" INTEGER NOT NULL DEFAULT 0;

-- CreateIndex
CREATE INDEX "FlutterwavePayment_idempotencyKey_idx" ON "FlutterwavePayment"("idempotencyKey");
