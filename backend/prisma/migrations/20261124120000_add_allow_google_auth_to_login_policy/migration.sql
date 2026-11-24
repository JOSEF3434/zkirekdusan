-- AlterTable
ALTER TABLE "login_policies" ADD COLUMN IF NOT EXISTS "allowGoogleAuth" BOOLEAN NOT NULL DEFAULT true;
