-- AlterEnum
ALTER TYPE "GroupStatus" ADD VALUE IF NOT EXISTS 'REJECTED';

-- DropForeignKey
ALTER TABLE "files" DROP CONSTRAINT IF EXISTS "files_groupId_fkey";

-- DropIndex
DROP INDEX IF EXISTS "posts_status_visibility_idx";

-- DropIndex
DROP INDEX IF EXISTS "search_history_userId_idx";

-- DropIndex
DROP INDEX IF EXISTS "videos_publishedAt_idx";

-- DropIndex
DROP INDEX IF EXISTS "videos_status_idx";

-- DropIndex
DROP INDEX IF EXISTS "videos_visibility_idx";

-- AlterTable
ALTER TABLE "files" ALTER COLUMN "groupId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "stories" ADD COLUMN IF NOT EXISTS "commentsCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "reactionsCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- AlterTable
ALTER TABLE "users" ALTER COLUMN "username" DROP NOT NULL;

-- CreateTable
CREATE TABLE IF NOT EXISTS "story_reactions" (
    "storyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reaction" "ReactionType" NOT NULL DEFAULT 'LIKE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "story_reactions_pkey" PRIMARY KEY ("storyId","userId")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "story_comments" (
    "id" TEXT NOT NULL,
    "storyId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "story_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "device_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "deviceId" TEXT,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "conversation_blocks" (
    "id" TEXT NOT NULL,
    "blockerId" TEXT NOT NULL,
    "blockedUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_blocks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "message_forwards" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "originalMessageId" TEXT NOT NULL,
    "originalSenderId" TEXT NOT NULL,
    "originalConversationId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_forwards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "message_mentions" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "mentionedUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_mentions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_reactions_storyId_idx" ON "story_reactions"("storyId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_reactions_userId_idx" ON "story_reactions"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_reactions_createdAt_idx" ON "story_reactions"("createdAt" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_comments_storyId_idx" ON "story_comments"("storyId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_comments_authorId_idx" ON "story_comments"("authorId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_comments_createdAt_idx" ON "story_comments"("createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "device_tokens_token_key" ON "device_tokens"("token");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "device_tokens_userId_idx" ON "device_tokens"("userId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "conversation_blocks_blockerId_idx" ON "conversation_blocks"("blockerId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "conversation_blocks_blockedUserId_idx" ON "conversation_blocks"("blockedUserId");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "conversation_blocks_blockerId_blockedUserId_key" ON "conversation_blocks"("blockerId", "blockedUserId");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "message_forwards_messageId_key" ON "message_forwards"("messageId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "message_forwards_messageId_idx" ON "message_forwards"("messageId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "message_forwards_originalMessageId_idx" ON "message_forwards"("originalMessageId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "message_mentions_messageId_idx" ON "message_mentions"("messageId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "message_mentions_mentionedUserId_idx" ON "message_mentions"("mentionedUserId");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "message_mentions_messageId_mentionedUserId_key" ON "message_mentions"("messageId", "mentionedUserId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "conversation_members_userId_unreadCount_idx" ON "conversation_members"("userId", "unreadCount");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "conversation_members_userId_isPinned_idx" ON "conversation_members"("userId", "isPinned");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "conversations_lastMessageAt_idx" ON "conversations"("lastMessageAt" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "messages_conversationId_createdAt_idx" ON "messages"("conversationId", "createdAt" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "messages_conversationId_deletedForEveryoneAt_idx" ON "messages"("conversationId", "deletedForEveryoneAt");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "messages_replyToId_idx" ON "messages"("replyToId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "posts_status_visibility_publishedAt_idx" ON "posts"("status", "visibility", "publishedAt" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "search_history_userId_timestamp_idx" ON "search_history"("userId", "timestamp" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "stories_authorId_expiresAt_idx" ON "stories"("authorId", "expiresAt");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "stories_createdAt_idx" ON "stories"("createdAt");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_views_viewerId_idx" ON "story_views"("viewerId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "story_views_viewedAt_idx" ON "story_views"("viewedAt" DESC);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "videos_status_visibility_publishedAt_idx" ON "videos"("status", "visibility", "publishedAt" DESC);

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'files_groupId_fkey') THEN
        ALTER TABLE "files" ADD CONSTRAINT "files_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'story_reactions_storyId_fkey') THEN
        ALTER TABLE "story_reactions" ADD CONSTRAINT "story_reactions_storyId_fkey" FOREIGN KEY ("storyId") REFERENCES "stories"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'story_reactions_userId_fkey') THEN
        ALTER TABLE "story_reactions" ADD CONSTRAINT "story_reactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'story_comments_storyId_fkey') THEN
        ALTER TABLE "story_comments" ADD CONSTRAINT "story_comments_storyId_fkey" FOREIGN KEY ("storyId") REFERENCES "stories"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'story_comments_authorId_fkey') THEN
        ALTER TABLE "story_comments" ADD CONSTRAINT "story_comments_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'device_tokens_userId_fkey') THEN
        ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversation_blocks_blockerId_fkey') THEN
        ALTER TABLE "conversation_blocks" ADD CONSTRAINT "conversation_blocks_blockerId_fkey" FOREIGN KEY ("blockerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'conversation_blocks_blockedUserId_fkey') THEN
        ALTER TABLE "conversation_blocks" ADD CONSTRAINT "conversation_blocks_blockedUserId_fkey" FOREIGN KEY ("blockedUserId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'message_forwards_messageId_fkey') THEN
        ALTER TABLE "message_forwards" ADD CONSTRAINT "message_forwards_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'message_forwards_originalSenderId_fkey') THEN
        ALTER TABLE "message_forwards" ADD CONSTRAINT "message_forwards_originalSenderId_fkey" FOREIGN KEY ("originalSenderId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'message_mentions_messageId_fkey') THEN
        ALTER TABLE "message_mentions" ADD CONSTRAINT "message_mentions_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'message_mentions_mentionedUserId_fkey') THEN
        ALTER TABLE "message_mentions" ADD CONSTRAINT "message_mentions_mentionedUserId_fkey" FOREIGN KEY ("mentionedUserId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
