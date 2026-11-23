-- AlterTable
ALTER TABLE "stories" ADD COLUMN IF NOT EXISTS "isArchived" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "stories_authorId_isArchived_idx" ON "stories"("authorId", "isArchived");
