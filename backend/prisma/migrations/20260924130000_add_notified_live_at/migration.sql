-- Migration: 20260924130000_add_notified_live_at
-- Purpose:
--   1. Add nullable `notifiedLiveAt` column to `live_streams`.
--      Matches Prisma camelCase column naming ("startedAt", "scheduledAt", etc.)
--   2. Add composite index on (status, startedAt) for poller efficiency.

-- Step 1 – add the new column
ALTER TABLE "live_streams"
  ADD COLUMN IF NOT EXISTS "notifiedLiveAt" TIMESTAMP(3);

-- Step 2 – composite index for the poller query
CREATE INDEX IF NOT EXISTS "live_streams_status_startedAt_idx"
  ON "live_streams" ("status", "startedAt");
