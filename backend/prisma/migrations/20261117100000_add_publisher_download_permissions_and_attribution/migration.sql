-- AlterTable
ALTER TABLE "posts" ADD COLUMN IF NOT EXISTS "allowDownloads" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "posts" ADD COLUMN IF NOT EXISTS "downloadPermission" "DownloadPermission" NOT NULL DEFAULT 'PUBLIC';
ALTER TABLE "posts" ADD COLUMN IF NOT EXISTS "downloadsCount" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "reels" ADD COLUMN IF NOT EXISTS "allowDownloads" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "reels" ADD COLUMN IF NOT EXISTS "downloadsCount" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "profiles" ADD COLUMN IF NOT EXISTS "allowDownloadsByDefault" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "download_records" ADD COLUMN IF NOT EXISTS "postId" TEXT;
ALTER TABLE "download_records" ADD COLUMN IF NOT EXISTS "publisherId" TEXT;
ALTER TABLE "download_records" ADD COLUMN IF NOT EXISTS "isWatermarked" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "download_records" ADD COLUMN IF NOT EXISTS "watermarkText" TEXT;
ALTER TABLE "download_records" ADD COLUMN IF NOT EXISTS "attributionJson" JSONB;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "download_records_publisherId_idx" ON "download_records"("publisherId");
CREATE INDEX IF NOT EXISTS "download_records_postId_idx" ON "download_records"("postId");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'download_records_publisherId_fkey'
  ) THEN
    ALTER TABLE "download_records" ADD CONSTRAINT "download_records_publisherId_fkey" FOREIGN KEY ("publisherId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'download_records_postId_fkey'
  ) THEN
    ALTER TABLE "download_records" ADD CONSTRAINT "download_records_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
