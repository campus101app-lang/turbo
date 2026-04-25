-- Safe Migration: Add Nigeria Business Fields
-- This migration adds new fields without affecting existing data
-- Run this manually in your database before updating the schema

-- Step 1: Add new enums (if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'accounttype') THEN
        CREATE TYPE "AccountType" AS ENUM ('INDIVIDUAL', 'REGISTERED_BUSINESS', 'OTHER_ENTITY');
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'businesstype') THEN
        CREATE TYPE "BusinessType" AS ENUM ('SOLE_PROPRIETORSHIP', 'LIMITED_LIABILITY', 'PUBLIC_LIMITED', 'PARTNERSHIP', 'NGO', 'RELIGIOUS_ORG', 'TRUST', 'OTHER');
    END IF;
END $$;

-- Step 2: Add new columns with safe defaults
ALTER TABLE "User" 
ADD COLUMN IF NOT EXISTS "accountType" "AccountType" DEFAULT 'INDIVIDUAL',
ADD COLUMN IF NOT EXISTS "phone" TEXT,
ADD COLUMN IF NOT EXISTS "homeAddress" TEXT,
ADD COLUMN IF NOT EXISTS "businessAddress" TEXT,
ADD COLUMN IF NOT EXISTS "businessType" "BusinessType",
ADD COLUMN IF NOT EXISTS "cacRegistrationNumber" TEXT,
ADD COLUMN IF NOT EXISTS "taxIdentificationNumber" TEXT,
ADD COLUMN IF NOT EXISTS "bvn" TEXT,
ADD COLUMN IF NOT EXISTS "nin" TEXT,
ADD COLUMN IF NOT EXISTS "idType" TEXT,
ADD COLUMN IF NOT EXISTS "idNumber" TEXT;

-- Step 3: Update existing users to have default account type
UPDATE "User" 
SET "accountType" = 'INDIVIDUAL' 
WHERE "accountType" IS NULL;

-- Step 4: Set fullName from existing businessName for users who have it
UPDATE "User" 
SET "fullName" = "businessName" 
WHERE "fullName" IS NULL AND "businessName" IS NOT NULL;

-- Step 5: Create indexes for performance
CREATE INDEX IF NOT EXISTS "User_accountType_idx" ON "User"("accountType");
CREATE INDEX IF NOT EXISTS "User_bvn_idx" ON "User"("bvn");
CREATE INDEX IF NOT EXISTS "User_phone_idx" ON "User"("phone");

-- Step 6: Verify migration success
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN "accountType" = 'INDIVIDUAL' THEN 1 END) as individual_users,
    COUNT(CASE WHEN "accountType" = 'REGISTERED_BUSINESS' THEN 1 END) as business_users,
    COUNT(CASE WHEN "accountType" = 'OTHER_ENTITY' THEN 1 END) as other_users,
    COUNT(CASE WHEN "bvn" IS NOT NULL THEN 1 END) as users_with_bvn,
    COUNT(CASE WHEN "phone" IS NOT NULL THEN 1 END) as users_with_phone
FROM "User";

-- Migration completed successfully!
-- Now you can safely run: npx prisma generate
