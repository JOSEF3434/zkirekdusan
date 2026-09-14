-- CreateTable
CREATE TABLE "calendar_notes" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ethiopianYear" INTEGER NOT NULL,
    "ethiopianMonth" INTEGER NOT NULL,
    "ethiopianDay" INTEGER NOT NULL,
    "gregorianDate" TIMESTAMP(3) NOT NULL,
    "title" TEXT,
    "content" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "calendar_notes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "calendar_note_media" (
    "id" TEXT NOT NULL,
    "noteId" TEXT NOT NULL,
    "fileId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "caption" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "calendar_note_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "calendar_notes_userId_idx" ON "calendar_notes"("userId");

-- CreateIndex
CREATE INDEX "calendar_notes_ethiopianYear_ethiopianMonth_idx" ON "calendar_notes"("ethiopianYear", "ethiopianMonth");

-- CreateIndex
CREATE INDEX "calendar_notes_gregorianDate_idx" ON "calendar_notes"("gregorianDate");

-- CreateIndex
CREATE INDEX "calendar_notes_deletedAt_idx" ON "calendar_notes"("deletedAt");

-- CreateIndex
CREATE INDEX "calendar_note_media_noteId_idx" ON "calendar_note_media"("noteId");

-- CreateIndex
CREATE INDEX "calendar_note_media_fileId_idx" ON "calendar_note_media"("fileId");

-- AddForeignKey
ALTER TABLE "calendar_notes" ADD CONSTRAINT "calendar_notes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_note_media" ADD CONSTRAINT "calendar_note_media_noteId_fkey" FOREIGN KEY ("noteId") REFERENCES "calendar_notes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "calendar_note_media" ADD CONSTRAINT "calendar_note_media_fileId_fkey" FOREIGN KEY ("fileId") REFERENCES "files"("id") ON DELETE CASCADE ON UPDATE CASCADE;
