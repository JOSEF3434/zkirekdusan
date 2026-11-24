-- CreateEnum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'RecoveryMethod') THEN
        CREATE TYPE "RecoveryMethod" AS ENUM ('EMAIL', 'PHONE');
    END IF;
END $$;

-- CreateTable
CREATE TABLE IF NOT EXISTS "password_recovery_challenges" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "method" "RecoveryMethod" NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "consumedAt" TIMESTAMP(3),
    "failedAttempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 5,
    "resendAvailableAt" TIMESTAMP(3),
    "requestIp" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "password_recovery_challenges_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "password_recovery_challenges_userId_idx" ON "password_recovery_challenges"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "password_recovery_challenges_destination_method_idx" ON "password_recovery_challenges"("destination", "method");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "password_recovery_challenges_tokenHash_idx" ON "password_recovery_challenges"("tokenHash");

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'password_recovery_challenges_userId_fkey'
    ) THEN
        ALTER TABLE "password_recovery_challenges" ADD CONSTRAINT "password_recovery_challenges_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
