-- Migration: 20260924130000_add_notified_live_at
-- Purpose:
--   1. Add nullable `notified_live_at` column to `live_streams`.
--      This column is written once by StreamReminderService when the
--      "stream still live after 2 minutes" notification is dispatched.
--      NULL = not yet notified. Non-null = already notified.
--      It is the idempotency guard that prevents duplicate dispatches
--      across Render dyno restarts.
--
--   2. Add a composite index on (status, started_at) so the poller's
--      WHERE clause  (status='LIVE' AND started_at BETWEEN ... AND
--      notified_live_at IS NULL)  can use an index seek.

-- Step 1 – add the new column
ALTER TABLE "live_streams"
  ADD COLUMN "notified_live_at" TIMESTAMP(3);

-- Step 2 – composite index for the poller query
CREATE INDEX "live_streams_status_started_at_idx"
  ON "live_streams" ("status", "started_at");
