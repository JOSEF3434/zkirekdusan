-- AlterTable
ALTER TABLE "login_policies" ADD COLUMN IF NOT EXISTS "allowPasswordReset" BOOLEAN NOT NULL DEFAULT true;
