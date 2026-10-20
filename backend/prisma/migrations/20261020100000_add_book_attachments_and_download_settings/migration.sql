-- CreateEnum
CREATE TYPE "BookDownloadDestination" AS ENUM ('IN_APP', 'DEVICE_FILE_MANAGER', 'BOTH');

-- CreateTable
CREATE TABLE "book_download_settings" (
    "id" TEXT NOT NULL,
    "destination" "BookDownloadDestination" NOT NULL DEFAULT 'IN_APP',
    "description" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "book_download_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "book_attachments" (
    "id" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "fileId" TEXT NOT NULL,
    "title" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "book_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "book_attachments_bookId_idx" ON "book_attachments"("bookId");

-- CreateIndex
CREATE INDEX "book_attachments_fileId_idx" ON "book_attachments"("fileId");

-- AddForeignKey
ALTER TABLE "book_download_settings" ADD CONSTRAINT "book_download_settings_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_attachments" ADD CONSTRAINT "book_attachments_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_attachments" ADD CONSTRAINT "book_attachments_fileId_fkey" FOREIGN KEY ("fileId") REFERENCES "files"("id") ON DELETE CASCADE ON UPDATE CASCADE;
