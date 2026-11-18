-- CreateEnum
CREATE TYPE "CalendarPublicationStatus" AS ENUM ('PENDING', 'SCHEDULED', 'PUBLISHED', 'FAILED', 'CANCELLED');

-- AlterTable
ALTER TABLE "calendar_notes" ADD COLUMN "recurrenceType" "CalendarReminderRepeat" NOT NULL DEFAULT 'NONE';
ALTER TABLE "calendar_notes" ADD COLUMN "isAutoPublishEnabled" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "calendar_notes" ADD COLUMN "autoPublishTime" TEXT DEFAULT '12:00';

-- AlterTable
ALTER TABLE "posts" ADD COLUMN "calendarNoteId" TEXT;

-- CreateTable
CREATE TABLE "calendar_publication_occurrences" (
    "id" TEXT NOT NULL,
    "calendarNoteId" TEXT NOT NULL,
    "recurrenceType" "CalendarReminderRepeat" NOT NULL,
    "occurrenceEthiopianDate" TEXT NOT NULL,
    "occurrenceYear" INTEGER NOT NULL,
    "occurrenceMonth" INTEGER NOT NULL,
    "occurrenceDay" INTEGER NOT NULL,
    "scheduledAt" TIMESTAMP(3) NOT NULL,
    "publishedAt" TIMESTAMP(3),
    "generatedPostId" TEXT,
    "publicationStatus" "CalendarPublicationStatus" NOT NULL DEFAULT 'PENDING',
    "lastError" TEXT,
    "retryCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "calendar_publication_occurrences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calendar_sync_metadata" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "activeWindowStart" TEXT NOT NULL,
    "activeWindowEnd" TEXT NOT NULL,
    "lastSuccessfulSyncAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSyncCursor" TEXT,
    "schemaVersion" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "calendar_sync_metadata_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "calendar_note_recurrence_occurrence_unique" ON "calendar_publication_occurrences"("calendarNoteId", "recurrenceType", "occurrenceEthiopianDate");
CREATE INDEX "calendar_publication_occurrences_publicationStatus_scheduledAt_idx" ON "calendar_publication_occurrences"("publicationStatus", "scheduledAt");
CREATE INDEX "calendar_publication_occurrences_occurrenceEthiopianDate_idx" ON "calendar_publication_occurrences"("occurrenceEthiopianDate");
CREATE INDEX "calendar_publication_occurrences_generatedPostId_idx" ON "calendar_publication_occurrences"("generatedPostId");

-- CreateIndex
CREATE INDEX "calendar_sync_metadata_userId_idx" ON "calendar_sync_metadata"("userId");
CREATE INDEX "posts_calendarNoteId_idx" ON "posts"("calendarNoteId");

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_calendarNoteId_fkey" FOREIGN KEY ("calendarNoteId") REFERENCES "calendar_notes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_publication_occurrences" ADD CONSTRAINT "calendar_publication_occurrences_calendarNoteId_fkey" FOREIGN KEY ("calendarNoteId") REFERENCES "calendar_notes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_publication_occurrences" ADD CONSTRAINT "calendar_publication_occurrences_generatedPostId_fkey" FOREIGN KEY ("generatedPostId") REFERENCES "posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
