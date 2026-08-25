// backend/scripts/fix-localhost-urls.ts
// One-time migration: rewrite http://localhost:3000 → https://zikrekidusan.onrender.com
// in all tables that store media URLs, and patch stuck video records.
//
// Usage (from backend/ directory):
//   npx tsx scripts/fix-localhost-urls.ts
//
import { PrismaClient } from '@prisma/client';
import { PrismaNeon } from '@prisma/adapter-neon';
import { neonConfig } from '@neondatabase/serverless';
import ws from 'ws';
import * as dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

neonConfig.webSocketConstructor = ws;
const connectionString = process.env.DATABASE_URL!;
const adapter = new PrismaNeon({ connectionString });
const prisma = new PrismaClient({ adapter });

const OLD_HOST = 'http://localhost:3000';
const NEW_HOST = 'https://zikrekidusan.onrender.com';

function rewrite(url: string | null | undefined): string | null {
  if (!url) return null;
  return url.startsWith(OLD_HOST) ? url.replace(OLD_HOST, NEW_HOST) : url;
}

async function main() {
  console.log(`\n🔧 Rewriting all "${OLD_HOST}" → "${NEW_HOST}" in database...\n`);
  let totalFixed = 0;

  // ─── 1. File table ─────────────────────────────────────────────────────────
  const files = await prisma.file.findMany({
    where: { url: { startsWith: OLD_HOST } },
    select: { id: true, url: true },
  });
  console.log(`  File records with localhost URL: ${files.length}`);
  for (const f of files) {
    await prisma.file.update({
      where: { id: f.id },
      data: { url: rewrite(f.url)! },
    });
  }
  totalFixed += files.length;

  // ─── 2. Video table — thumbnailUrl, hlsUrl, dashUrl, previewUrl ─────────────
  const videos = await prisma.video.findMany({
    where: {
      OR: [
        { thumbnailUrl: { startsWith: OLD_HOST } },
        { hlsUrl: { startsWith: OLD_HOST } },
        { dashUrl: { startsWith: OLD_HOST } },
        { previewUrl: { startsWith: OLD_HOST } },
      ],
    },
    select: { id: true, thumbnailUrl: true, hlsUrl: true, dashUrl: true, previewUrl: true },
  });
  console.log(`  Video records with localhost URL: ${videos.length}`);
  for (const v of videos) {
    await prisma.video.update({
      where: { id: v.id },
      data: {
        thumbnailUrl: rewrite(v.thumbnailUrl),
        hlsUrl: rewrite(v.hlsUrl),
        dashUrl: rewrite(v.dashUrl),
        previewUrl: rewrite(v.previewUrl),
      },
    });
  }
  totalFixed += videos.length;

  // ─── 3. Story table — check if any custom URL fields exist ────────────────
  try {
    const stories = await (prisma as any).story.findMany({
      where: {
        OR: [
          { mediaUrl: { startsWith: OLD_HOST } },
        ],
      },
      select: { id: true, mediaUrl: true },
    });
    console.log(`  Story records with localhost URL: ${stories.length}`);
    for (const s of stories) {
      await (prisma as any).story.update({
        where: { id: s.id },
        data: { mediaUrl: rewrite(s.mediaUrl) },
      });
    }
    totalFixed += stories.length;
  } catch (err) {
    // Stories link to File model which was already migrated in step 1
  }

  // ─── 4. Group table — avatarUrl, bannerUrl, logoUrl ────────────────────────
  try {
    const groups = await (prisma as any).group.findMany({
      where: {
        OR: [
          { avatarUrl: { startsWith: OLD_HOST } },
          { bannerUrl: { startsWith: OLD_HOST } },
        ],
      },
      select: { id: true, avatarUrl: true, bannerUrl: true },
    });
    console.log(`  Group records with localhost URL: ${groups.length}`);
    for (const g of groups) {
      await (prisma as any).group.update({
        where: { id: g.id },
        data: {
          avatarUrl: rewrite(g.avatarUrl),
          bannerUrl: rewrite(g.bannerUrl),
        },
      });
    }
    totalFixed += groups.length;
  } catch (err) {
    console.warn('  Group avatarUrl/bannerUrl fields — skipping (may not exist).');
  }

  // ─── 5. UserProfile table — avatarUrl, coverUrl ─────────────────────────────
  try {
    const profiles = await (prisma as any).userProfile.findMany({
      where: {
        OR: [
          { avatarUrl: { startsWith: OLD_HOST } },
          { coverUrl: { startsWith: OLD_HOST } },
        ],
      },
      select: { id: true, avatarUrl: true, coverUrl: true },
    });
    console.log(`  UserProfile records with localhost URL: ${profiles.length}`);
    for (const p of profiles) {
      await (prisma as any).userProfile.update({
        where: { id: p.id },
        data: {
          avatarUrl: rewrite(p.avatarUrl),
          coverUrl: rewrite(p.coverUrl),
        },
      });
    }
    totalFixed += profiles.length;
  } catch (err) {
    console.warn('  UserProfile table — skipping (may not exist or different field name).');
  }

  // ─── 6. Fix stuck QUEUED/UPLOADING videos — set READY + hlsUrl from File ────
  console.log('\n🔧 Fixing stuck QUEUED/UPLOADING videos...');
  const stuckVideos = await prisma.video.findMany({
    where: {
      status: { in: ['QUEUED', 'UPLOADING'] as any },
      sourceFileId: { not: null },
      deletedAt: null,
    },
    select: { id: true, status: true, sourceFileId: true, hlsUrl: true },
  });
  console.log(`  Stuck videos: ${stuckVideos.length}`);

  for (const v of stuckVideos) {
    let hlsUrl = v.hlsUrl;

    if (v.sourceFileId) {
      const fileRecord = await prisma.file.findUnique({
        where: { id: v.sourceFileId },
        select: { url: true },
      });
      if (fileRecord?.url) {
        const fileUrl = rewrite(fileRecord.url)!;
        // If it's Cloudinary, derive MP4 URL
        if (fileUrl.includes('res.cloudinary.com') && !fileUrl.endsWith('.m3u8')) {
          hlsUrl = fileUrl; // Already a direct Cloudinary URL (secure_url)
        } else if (!hlsUrl) {
          hlsUrl = fileUrl;
        }
      }
    }

    await prisma.video.update({
      where: { id: v.id },
      data: {
        status: 'READY' as any,
        hlsUrl: hlsUrl ? rewrite(hlsUrl) : null,
      },
    });
    console.log(`  ✓ Video ${v.id}: ${v.status} → READY | hlsUrl: ${hlsUrl ?? 'null'}`);
  }

  console.log(`\n✅ Done! Total records updated: ${totalFixed + stuckVideos.length}`);
}

main()
  .catch((e) => {
    console.error('❌ Migration failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
