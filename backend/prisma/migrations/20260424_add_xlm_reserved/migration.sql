-- AddColumn xlmReserved to User table
ALTER TABLE "User" ADD COLUMN "xlmReserved" DOUBLE PRECISION NOT NULL DEFAULT 0;
