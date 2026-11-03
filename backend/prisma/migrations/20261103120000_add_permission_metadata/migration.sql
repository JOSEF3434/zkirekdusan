-- Migration: Add permission metadata fields (displayName, category, riskLevel)
-- Safe: uses IF NOT EXISTS so it can run multiple times without error

ALTER TABLE "permissions" ADD COLUMN IF NOT EXISTS "displayName" TEXT;
ALTER TABLE "permissions" ADD COLUMN IF NOT EXISTS "category" TEXT;
ALTER TABLE "permissions" ADD COLUMN IF NOT EXISTS "riskLevel" TEXT;

