-- Add Ethiopian-calendar recurrence metadata without changing existing notes.
CREATE TYPE "CalendarReminderRepeat" AS ENUM ('NONE', 'MONTHLY', 'YEARLY');

ALTER TABLE "calendar_notes"
  ADD COLUMN "reminderRepeat" "CalendarReminderRepeat" NOT NULL DEFAULT 'NONE',
  ADD COLUMN "reminderEthiopianMonth" INTEGER,
  ADD COLUMN "reminderEthiopianDay" INTEGER,
  ADD COLUMN "reminderHour" INTEGER,
  ADD COLUMN "reminderMinute" INTEGER,
  ADD COLUMN "reminderTimezone" TEXT NOT NULL DEFAULT 'Africa/Addis_Ababa',
  ADD COLUMN "reminderNextOccurrence" TIMESTAMP(3);

CREATE INDEX "calendar_notes_userId_hasReminder_reminderNextOccurrence_idx"
  ON "calendar_notes"("userId", "hasReminder", "reminderNextOccurrence");