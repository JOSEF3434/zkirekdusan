-- AlterTable: Add reminder fields to calendar_notes
ALTER TABLE "calendar_notes" ADD COLUMN "hasReminder" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "calendar_notes" ADD COLUMN "reminderDateTime" TIMESTAMP(3);
ALTER TABLE "calendar_notes" ADD COLUMN "reminderNotified" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex: Index for querying upcoming reminders
CREATE INDEX "calendar_notes_reminder_idx" ON "calendar_notes"("hasReminder", "reminderDateTime", "reminderNotified") WHERE "hasReminder" = true AND "reminderNotified" = false;
