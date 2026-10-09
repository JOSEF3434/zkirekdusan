-- Migration: 20261009160000_add_auth_login_policy
-- Purpose:
--   1. Create LoginPolicyType and DualIdentifierCombination enums
--   2. Create login_policies singleton settings table
--   3. Create login_policy_audit_logs audit table for compliance tracking

-- Step 1: Create Enums (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'LoginPolicyType') THEN
    CREATE TYPE "LoginPolicyType" AS ENUM ('SINGLE_IDENTIFIER', 'DUAL_IDENTIFIER', 'ALL_IDENTIFIERS');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DualIdentifierCombination') THEN
    CREATE TYPE "DualIdentifierCombination" AS ENUM ('EMAIL_PHONE', 'EMAIL_USERNAME', 'PHONE_USERNAME');
  END IF;
END$$;

-- Step 2: Create login_policies table
CREATE TABLE IF NOT EXISTS "login_policies" (
  "id" TEXT NOT NULL,
  "activePolicy" "LoginPolicyType" NOT NULL DEFAULT 'SINGLE_IDENTIFIER',
  "allowEmail" BOOLEAN NOT NULL DEFAULT true,
  "allowPhone" BOOLEAN NOT NULL DEFAULT true,
  "allowUsername" BOOLEAN NOT NULL DEFAULT true,
  "dualCombination" "DualIdentifierCombination",
  "isLocked" BOOLEAN NOT NULL DEFAULT false,
  "description" TEXT,
  "lastModifiedById" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "login_policies_pkey" PRIMARY KEY ("id")
);

-- Step 3: Create login_policy_audit_logs table
CREATE TABLE IF NOT EXISTS "login_policy_audit_logs" (
  "id" TEXT NOT NULL,
  "actorId" TEXT,
  "before" JSONB,
  "after" JSONB,
  "reason" TEXT,
  "ipAddress" TEXT,
  "userAgent" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "login_policy_audit_logs_pkey" PRIMARY KEY ("id")
);

-- Step 4: Indices and Foreign Keys
CREATE INDEX IF NOT EXISTS "login_policy_audit_logs_actorId_idx" ON "login_policy_audit_logs"("actorId");
CREATE INDEX IF NOT EXISTS "login_policy_audit_logs_createdAt_idx" ON "login_policy_audit_logs"("createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'login_policies_lastModifiedById_fkey'
  ) THEN
    ALTER TABLE "login_policies"
      ADD CONSTRAINT "login_policies_lastModifiedById_fkey"
      FOREIGN KEY ("lastModifiedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'login_policy_audit_logs_actorId_fkey'
  ) THEN
    ALTER TABLE "login_policy_audit_logs"
      ADD CONSTRAINT "login_policy_audit_logs_actorId_fkey"
      FOREIGN KEY ("actorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END$$;
