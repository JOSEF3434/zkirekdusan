-- AlterEnum
ALTER TYPE "CalendarEventType" ADD VALUE IF NOT EXISTS 'SPECIAL_EVENT';

-- AlterTable
ALTER TABLE "calendar_events" ADD COLUMN IF NOT EXISTS "importance" TEXT DEFAULT 'NORMAL';
