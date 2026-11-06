-- AlterTable
ALTER TABLE "alephat_letters" ADD COLUMN IF NOT EXISTS "mediaUrls" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable
ALTER TABLE "alephat_family_members" ADD COLUMN IF NOT EXISTS "mediaUrls" TEXT[] DEFAULT ARRAY[]::TEXT[];

