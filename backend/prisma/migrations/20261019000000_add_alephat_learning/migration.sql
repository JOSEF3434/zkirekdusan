-- Drop existing if any partial creation occurred
DROP TABLE IF EXISTS "alephat_family_members" CASCADE;
DROP TABLE IF EXISTS "alephat_letters" CASCADE;
DROP TABLE IF EXISTS "alephat_22_entries" CASCADE;

-- CreateTable
CREATE TABLE "alephat_letters" (
    "id" TEXT NOT NULL,
    "letter" TEXT NOT NULL,
    "name" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "defaultNote" TEXT,
    "pronunciationGuide" TEXT,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdById" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "alephat_letters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alephat_family_members" (
    "id" TEXT NOT NULL,
    "baseLetterId" TEXT NOT NULL,
    "glyph" TEXT NOT NULL,
    "orderIndex" INTEGER NOT NULL,
    "orderName" TEXT,
    "note" TEXT,
    "pronunciation" TEXT,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "alephat_family_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alephat_22_entries" (
    "id" TEXT NOT NULL,
    "letter" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "meaning" TEXT,
    "order" INTEGER NOT NULL DEFAULT 0,
    "note" TEXT NOT NULL,
    "supplementaryInfo" TEXT,
    "isPublished" BOOLEAN NOT NULL DEFAULT true,
    "createdById" TEXT,
    "updatedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "alephat_22_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "alephat_letters_letter_key" ON "alephat_letters"("letter");

-- CreateIndex
CREATE INDEX "alephat_letters_order_idx" ON "alephat_letters"("order");

-- CreateIndex
CREATE INDEX "alephat_letters_isPublished_idx" ON "alephat_letters"("isPublished");

-- CreateIndex
CREATE INDEX "alephat_letters_createdById_idx" ON "alephat_letters"("createdById");

-- CreateIndex
CREATE INDEX "alephat_family_members_baseLetterId_idx" ON "alephat_family_members"("baseLetterId");

-- CreateIndex
CREATE INDEX "alephat_family_members_orderIndex_idx" ON "alephat_family_members"("orderIndex");

-- CreateIndex
CREATE UNIQUE INDEX "alephat_family_members_baseLetterId_orderIndex_key" ON "alephat_family_members"("baseLetterId", "orderIndex");

-- CreateIndex
CREATE INDEX "alephat_22_entries_order_idx" ON "alephat_22_entries"("order");

-- CreateIndex
CREATE INDEX "alephat_22_entries_isPublished_idx" ON "alephat_22_entries"("isPublished");

-- CreateIndex
CREATE INDEX "alephat_22_entries_createdById_idx" ON "alephat_22_entries"("createdById");

-- AddForeignKey
ALTER TABLE "alephat_letters" ADD CONSTRAINT "alephat_letters_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alephat_letters" ADD CONSTRAINT "alephat_letters_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alephat_family_members" ADD CONSTRAINT "alephat_family_members_baseLetterId_fkey" FOREIGN KEY ("baseLetterId") REFERENCES "alephat_letters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alephat_22_entries" ADD CONSTRAINT "alephat_22_entries_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alephat_22_entries" ADD CONSTRAINT "alephat_22_entries_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
