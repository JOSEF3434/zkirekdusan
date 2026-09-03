-- AlterTable
ALTER TABLE "messages" ADD COLUMN IF NOT EXISTS "clientId" TEXT;

-- CreateIndex
CREATE INDEX IF NOT EXISTS "messages_clientId_idx" ON "messages"("clientId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "messages_senderId_clientId_idx" ON "messages"("senderId", "clientId");
