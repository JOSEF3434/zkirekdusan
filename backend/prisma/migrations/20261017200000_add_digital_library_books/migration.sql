-- CreateEnum
CREATE TYPE "BookStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED', 'DELETED');

-- CreateEnum
CREATE TYPE "BookFormat" AS ENUM ('PDF', 'EPUB', 'TEXT', 'AUDIO', 'EXTERNAL_LINK');

-- CreateEnum
CREATE TYPE "BookLanguage" AS ENUM ('AMHARIC', 'GEEZ', 'ENGLISH', 'OTHER');

-- CreateTable
CREATE TABLE "book_categories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAm" TEXT,
    "nameGez" TEXT,
    "description" TEXT,
    "slug" TEXT NOT NULL,
    "parentId" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isVisible" BOOLEAN NOT NULL DEFAULT true,
    "isArchived" BOOLEAN NOT NULL DEFAULT false,
    "iconName" TEXT,
    "coverUrl" TEXT,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "book_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "books" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "titleAm" TEXT,
    "titleGez" TEXT,
    "subtitle" TEXT,
    "author" TEXT,
    "translator" TEXT,
    "description" TEXT,
    "categoryId" TEXT,
    "language" "BookLanguage" NOT NULL DEFAULT 'AMHARIC',
    "format" "BookFormat" NOT NULL DEFAULT 'PDF',
    "publisher" TEXT,
    "publishedYear" INTEGER,
    "edition" TEXT,
    "isbn" TEXT,
    "pageCount" INTEGER,
    "tags" TEXT[],
    "status" "BookStatus" NOT NULL DEFAULT 'DRAFT',
    "coverFileId" TEXT,
    "contentFileId" TEXT,
    "externalUrl" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "viewsCount" INTEGER NOT NULL DEFAULT 0,
    "bookmarksCount" INTEGER NOT NULL DEFAULT 0,
    "createdById" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "books_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "book_chapters" (
    "id" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "titleAm" TEXT,
    "titleGez" TEXT,
    "content" TEXT,
    "contentFileId" TEXT,
    "durationSeconds" INTEGER,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "book_chapters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_book_progress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "currentPage" INTEGER,
    "currentChapter" INTEGER,
    "scrollOffset" DOUBLE PRECISION,
    "percentComplete" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "isCompleted" BOOLEAN NOT NULL DEFAULT false,
    "lastReadAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_book_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_book_bookmarks" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "page" INTEGER,
    "chapter" INTEGER,
    "label" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_book_bookmarks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_book_annotations" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "page" INTEGER,
    "chapter" INTEGER,
    "startOffset" INTEGER,
    "endOffset" INTEGER,
    "selectedText" TEXT,
    "note" TEXT,
    "highlightColor" TEXT,
    "annotationType" TEXT NOT NULL DEFAULT 'highlight',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "user_book_annotations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_reading_prefs" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "fontSize" DOUBLE PRECISION NOT NULL DEFAULT 16,
    "lineSpacing" DOUBLE PRECISION NOT NULL DEFAULT 1.5,
    "fontFamily" TEXT NOT NULL DEFAULT 'default',
    "textAlign" TEXT NOT NULL DEFAULT 'left',
    "themeMode" TEXT NOT NULL DEFAULT 'system',
    "pageMargin" DOUBLE PRECISION NOT NULL DEFAULT 16,
    "scrollMode" TEXT NOT NULL DEFAULT 'paginated',
    "gridView" BOOLEAN NOT NULL DEFAULT true,
    "sortBy" TEXT NOT NULL DEFAULT 'title',
    "sortAsc" BOOLEAN NOT NULL DEFAULT true,
    "defaultCategoryId" TEXT,
    "defaultHighlightColor" TEXT NOT NULL DEFAULT '#FFEB3B',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_reading_prefs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "book_categories_slug_key" ON "book_categories"("slug");
CREATE INDEX "book_categories_parentId_idx" ON "book_categories"("parentId");
CREATE INDEX "book_categories_sortOrder_idx" ON "book_categories"("sortOrder");
CREATE INDEX "book_categories_isVisible_idx" ON "book_categories"("isVisible");
CREATE INDEX "book_categories_deletedAt_idx" ON "book_categories"("deletedAt");

-- CreateIndex
CREATE INDEX "books_categoryId_idx" ON "books"("categoryId");
CREATE INDEX "books_status_idx" ON "books"("status");
CREATE INDEX "books_language_idx" ON "books"("language");
CREATE INDEX "books_format_idx" ON "books"("format");
CREATE INDEX "books_sortOrder_idx" ON "books"("sortOrder");
CREATE INDEX "books_deletedAt_idx" ON "books"("deletedAt");
CREATE INDEX "books_createdAt_idx" ON "books"("createdAt");

-- CreateIndex
CREATE INDEX "book_chapters_bookId_idx" ON "book_chapters"("bookId");
CREATE INDEX "book_chapters_bookId_order_idx" ON "book_chapters"("bookId", "order");
CREATE UNIQUE INDEX "book_chapters_bookId_order_key" ON "book_chapters"("bookId", "order");

-- CreateIndex
CREATE INDEX "user_book_progress_userId_idx" ON "user_book_progress"("userId");
CREATE INDEX "user_book_progress_bookId_idx" ON "user_book_progress"("bookId");
CREATE INDEX "user_book_progress_lastReadAt_idx" ON "user_book_progress"("lastReadAt");
CREATE UNIQUE INDEX "user_book_progress_userId_bookId_key" ON "user_book_progress"("userId", "bookId");

-- CreateIndex
CREATE INDEX "user_book_bookmarks_userId_idx" ON "user_book_bookmarks"("userId");
CREATE INDEX "user_book_bookmarks_bookId_idx" ON "user_book_bookmarks"("bookId");
CREATE INDEX "user_book_bookmarks_userId_bookId_idx" ON "user_book_bookmarks"("userId", "bookId");

-- CreateIndex
CREATE INDEX "user_book_annotations_userId_idx" ON "user_book_annotations"("userId");
CREATE INDEX "user_book_annotations_bookId_idx" ON "user_book_annotations"("bookId");
CREATE INDEX "user_book_annotations_userId_bookId_idx" ON "user_book_annotations"("userId", "bookId");
CREATE INDEX "user_book_annotations_deletedAt_idx" ON "user_book_annotations"("deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX "user_reading_prefs_userId_key" ON "user_reading_prefs"("userId");

-- AddForeignKey
ALTER TABLE "book_categories" ADD CONSTRAINT "book_categories_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "book_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "book_categories" ADD CONSTRAINT "book_categories_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "books" ADD CONSTRAINT "books_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "book_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "books" ADD CONSTRAINT "books_coverFileId_fkey" FOREIGN KEY ("coverFileId") REFERENCES "files"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "books" ADD CONSTRAINT "books_contentFileId_fkey" FOREIGN KEY ("contentFileId") REFERENCES "files"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "books" ADD CONSTRAINT "books_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "books" ADD CONSTRAINT "books_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_chapters" ADD CONSTRAINT "book_chapters_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "book_chapters" ADD CONSTRAINT "book_chapters_contentFileId_fkey" FOREIGN KEY ("contentFileId") REFERENCES "files"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_book_progress" ADD CONSTRAINT "user_book_progress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_book_progress" ADD CONSTRAINT "user_book_progress_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_book_bookmarks" ADD CONSTRAINT "user_book_bookmarks_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_book_bookmarks" ADD CONSTRAINT "user_book_bookmarks_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_book_annotations" ADD CONSTRAINT "user_book_annotations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "user_book_annotations" ADD CONSTRAINT "user_book_annotations_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_reading_prefs" ADD CONSTRAINT "user_reading_prefs_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
