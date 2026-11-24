-- AlterTable: Make passwordHash nullable for federated authentication providers
ALTER TABLE "users" ALTER COLUMN "passwordHash" DROP NOT NULL;

-- CreateTable: federated_identities for OAuth and external identity providers
CREATE TABLE IF NOT EXISTS "federated_identities" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "email" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "federated_identities_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "federated_identities_provider_providerId_key" ON "federated_identities"("provider", "providerId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "federated_identities_userId_idx" ON "federated_identities"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "federated_identities_provider_email_idx" ON "federated_identities"("provider", "email");

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'federated_identities_userId_fkey'
    ) THEN
        ALTER TABLE "federated_identities" ADD CONSTRAINT "federated_identities_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
