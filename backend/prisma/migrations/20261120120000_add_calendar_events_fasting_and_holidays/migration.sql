-- CreateEnum
CREATE TYPE "CalendarEventType" AS ENUM ('FAST', 'HOLIDAY');

-- CreateEnum
CREATE TYPE "CalendarEventCategory" AS ENUM ('MAJOR_FAST', 'MINOR_FAST', 'MAJOR_HOLIDAY', 'MINOR_HOLIDAY', 'MONTHLY_FEAST', 'ANNUAL_FEAST');

-- CreateTable
CREATE TABLE "calendar_events" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameEn" TEXT,
    "type" "CalendarEventType" NOT NULL,
    "category" "CalendarEventCategory" NOT NULL DEFAULT 'MAJOR_HOLIDAY',
    "isRecurring" BOOLEAN NOT NULL DEFAULT true,
    "ethiopianYear" INTEGER,
    "startMonth" INTEGER NOT NULL,
    "startDay" INTEGER NOT NULL,
    "startYear" INTEGER,
    "endMonth" INTEGER NOT NULL,
    "endDay" INTEGER NOT NULL,
    "endYear" INTEGER,
    "description" TEXT,
    "spiritualMeaning" TEXT,
    "fastingRules" TEXT,
    "primaryColor" TEXT,
    "icon" TEXT,
    "isMajor" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "calendar_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "calendar_events_type_isActive_idx" ON "calendar_events"("type", "isActive");
CREATE INDEX "calendar_events_startMonth_endMonth_idx" ON "calendar_events"("startMonth", "endMonth");
CREATE INDEX "calendar_events_ethiopianYear_isActive_idx" ON "calendar_events"("ethiopianYear", "isActive");
CREATE INDEX "calendar_events_deletedAt_idx" ON "calendar_events"("deletedAt");

-- AddForeignKey
ALTER TABLE "calendar_events" ADD CONSTRAINT "calendar_events_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
