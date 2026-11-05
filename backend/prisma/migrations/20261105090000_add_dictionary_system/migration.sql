-- CreateEnum with IF NOT EXISTS guard
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DictionaryProcessingStatus') THEN
        CREATE TYPE "DictionaryProcessingStatus" AS ENUM ('PENDING', 'VALIDATING', 'EXTRACTING', 'PARSING', 'INDEXING', 'READY', 'FAILED', 'RETRYING');
    END IF;
END $$;

-- AlterTable books
ALTER TABLE "books" ADD COLUMN IF NOT EXISTS "isDictionary" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable dictionary_languages
CREATE TABLE IF NOT EXISTS "dictionary_languages" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nativeName" TEXT NOT NULL,
    "direction" TEXT NOT NULL DEFAULT 'ltr',
    "localizedNames" JSONB,
    "isEnabled" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "dictionary_languages_pkey" PRIMARY KEY ("id")
);

-- CreateTable dictionary_book_configs
CREATE TABLE IF NOT EXISTS "dictionary_book_configs" (
    "id" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "dictionaryName" TEXT NOT NULL,
    "description" TEXT,
    "sourceLanguageId" TEXT NOT NULL,
    "targetLanguageId" TEXT NOT NULL,
    "processingStatus" "DictionaryProcessingStatus" NOT NULL DEFAULT 'PENDING',
    "totalEntries" INTEGER NOT NULL DEFAULT 0,
    "errorMessage" TEXT,
    "processedAt" TIMESTAMP(3),
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "dictionary_book_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable dictionary_entries
CREATE TABLE IF NOT EXISTS "dictionary_entries" (
    "id" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "configId" TEXT NOT NULL,
    "headword" TEXT NOT NULL,
    "normalizedHeadword" TEXT NOT NULL,
    "sourceLanguageCode" TEXT NOT NULL,
    "targetLanguageCode" TEXT NOT NULL,
    "definition" TEXT NOT NULL,
    "definitions" JSONB,
    "entryNumber" INTEGER NOT NULL DEFAULT 0,
    "pageNumber" INTEGER,
    "chapterTitle" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "dictionary_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable user_translation_histories
CREATE TABLE IF NOT EXISTS "user_translation_histories" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "word" TEXT NOT NULL,
    "sourceLanguage" TEXT NOT NULL,
    "targetLanguage" TEXT NOT NULL,
    "definition" TEXT NOT NULL,
    "dictionaryBookId" TEXT,
    "dictionaryEntryId" TEXT,
    "dictionaryNameSnapshot" TEXT NOT NULL,
    "pageNumber" INTEGER,
    "chapter" TEXT,
    "surroundingSentence" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_translation_histories_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "dictionary_languages_code_key" ON "dictionary_languages"("code");
CREATE INDEX IF NOT EXISTS "dictionary_languages_code_idx" ON "dictionary_languages"("code");
CREATE INDEX IF NOT EXISTS "dictionary_languages_isEnabled_idx" ON "dictionary_languages"("isEnabled");
CREATE INDEX IF NOT EXISTS "dictionary_languages_sortOrder_idx" ON "dictionary_languages"("sortOrder");
CREATE INDEX IF NOT EXISTS "dictionary_languages_deletedAt_idx" ON "dictionary_languages"("deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "dictionary_book_configs_bookId_key" ON "dictionary_book_configs"("bookId");
CREATE INDEX IF NOT EXISTS "dictionary_book_configs_bookId_idx" ON "dictionary_book_configs"("bookId");
CREATE INDEX IF NOT EXISTS "dictionary_book_configs_sourceLanguageId_idx" ON "dictionary_book_configs"("sourceLanguageId");
CREATE INDEX IF NOT EXISTS "dictionary_book_configs_targetLanguageId_idx" ON "dictionary_book_configs"("targetLanguageId");
CREATE INDEX IF NOT EXISTS "dictionary_book_configs_processingStatus_idx" ON "dictionary_book_configs"("processingStatus");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "dictionary_entries_bookId_idx" ON "dictionary_entries"("bookId");
CREATE INDEX IF NOT EXISTS "dictionary_entries_configId_idx" ON "dictionary_entries"("configId");
CREATE INDEX IF NOT EXISTS "dictionary_entries_normalizedHeadword_idx" ON "dictionary_entries"("normalizedHeadword");
CREATE INDEX IF NOT EXISTS "dictionary_entries_sourceLanguageCode_targetLanguageCode_idx" ON "dictionary_entries"("sourceLanguageCode", "targetLanguageCode");
CREATE INDEX IF NOT EXISTS "dictionary_entries_sourceLanguageCode_normalizedHeadword_idx" ON "dictionary_entries"("sourceLanguageCode", "normalizedHeadword");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "user_translation_histories_userId_idx" ON "user_translation_histories"("userId");
CREATE INDEX IF NOT EXISTS "user_translation_histories_userId_createdAt_idx" ON "user_translation_histories"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "user_translation_histories_userId_word_idx" ON "user_translation_histories"("userId", "word");
CREATE INDEX IF NOT EXISTS "user_translation_histories_userId_sourceLanguage_targetLanguage_idx" ON "user_translation_histories"("userId", "sourceLanguage", "targetLanguage");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "books_isDictionary_idx" ON "books"("isDictionary");

-- AddForeignKey with IF NOT EXISTS guards
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_languages_createdById_fkey') THEN
        ALTER TABLE "dictionary_languages" ADD CONSTRAINT "dictionary_languages_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_book_configs_bookId_fkey') THEN
        ALTER TABLE "dictionary_book_configs" ADD CONSTRAINT "dictionary_book_configs_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_book_configs_sourceLanguageId_fkey') THEN
        ALTER TABLE "dictionary_book_configs" ADD CONSTRAINT "dictionary_book_configs_sourceLanguageId_fkey" FOREIGN KEY ("sourceLanguageId") REFERENCES "dictionary_languages"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_book_configs_targetLanguageId_fkey') THEN
        ALTER TABLE "dictionary_book_configs" ADD CONSTRAINT "dictionary_book_configs_targetLanguageId_fkey" FOREIGN KEY ("targetLanguageId") REFERENCES "dictionary_languages"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_entries_bookId_fkey') THEN
        ALTER TABLE "dictionary_entries" ADD CONSTRAINT "dictionary_entries_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'dictionary_entries_configId_fkey') THEN
        ALTER TABLE "dictionary_entries" ADD CONSTRAINT "dictionary_entries_configId_fkey" FOREIGN KEY ("configId") REFERENCES "dictionary_book_configs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_translation_histories_userId_fkey') THEN
        ALTER TABLE "user_translation_histories" ADD CONSTRAINT "user_translation_histories_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_translation_histories_dictionaryBookId_fkey') THEN
        ALTER TABLE "user_translation_histories" ADD CONSTRAINT "user_translation_histories_dictionaryBookId_fkey" FOREIGN KEY ("dictionaryBookId") REFERENCES "books"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_translation_histories_dictionaryEntryId_fkey') THEN
        ALTER TABLE "user_translation_histories" ADD CONSTRAINT "user_translation_histories_dictionaryEntryId_fkey" FOREIGN KEY ("dictionaryEntryId") REFERENCES "dictionary_entries"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;
