// backend/scripts/migrate-to-cloudinary.ts
import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { v2 as cloudinary } from 'cloudinary';
import { FileProvider, VideoStatus, VideoResolution } from '@prisma/client';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadsDir = path.resolve(process.cwd(), 'uploads');

async function runMigration() {
  console.log('🚀 Starting Cloudinary Media Storage Migration...\n');

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    console.error('❌ Cloudinary credentials missing in .env!');
    process.exit(1);
  }

  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
    secure: true,
  });

  console.log(`✓ Cloudinary configured with cloud_name: ${cloudName}`);

  const prisma = new PrismaService();
  await prisma.$connect();
  console.log('✓ Connected to Neon PostgreSQL database\n');

  let migratedFiles = 0;
  let skippedFiles = 0;
  let missingFiles = 0;

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Migrate `File` records
  // ─────────────────────────────────────────────────────────────────────────────
  console.log('--- 1. Auditing & Migrating `File` Records ---');
  const allFiles = await prisma.file.findMany({
    where: { deletedAt: null },
  });
  console.log(`Found ${allFiles.length} total active File records.`);

  for (const f of allFiles) {
    const isAlreadyCloudinary =
      f.provider === FileProvider.CLOUDINARY ||
      f.url.includes('res.cloudinary.com') ||
      f.url.includes('cloudinary.com');

    if (isAlreadyCloudinary) {
      skippedFiles++;
      continue;
    }

    // Check if local file exists on disk
    let localPath = path.isAbsolute(f.storageKey)
      ? f.storageKey
      : path.join(uploadsDir, f.storageKey);

    if (!fs.existsSync(localPath)) {
      // Try by fileName
      const altPath = path.join(uploadsDir, f.fileName);
      if (fs.existsSync(altPath)) {
        localPath = altPath;
      }
    }

    if (fs.existsSync(localPath)) {
      try {
        const subfolder = f.groupId
          ? `groups/${f.groupId}/${f.fileType.toLowerCase()}`
          : `users/${f.uploadedById}/${f.fileType.toLowerCase()}`;

        const isVideo = f.mimeType.startsWith('video/');
        const isAudio = f.mimeType.startsWith('audio/');
        const isImage = f.mimeType.startsWith('image/');
        const resourceType = (isVideo || isAudio) ? 'video' : isImage ? 'image' : 'raw';

        const uploadOptions: Record<string, any> = {
          folder: subfolder,
          resource_type: resourceType,
          use_filename: true,
          unique_filename: true,
        };

        if (isVideo) {
          uploadOptions.format = 'mp4';
          uploadOptions.transformation = [{ quality: 'auto', fetch_format: 'mp4' }];
        }

        const res = await cloudinary.uploader.upload(localPath, uploadOptions);

        await prisma.file.update({
          where: { id: f.id },
          data: {
            provider: FileProvider.CLOUDINARY,
            storageKey: res.public_id,
            url: res.secure_url,
            width: res.width ?? f.width,
            height: res.height ?? f.height,
            size: BigInt(res.bytes ?? Number(f.size)),
          },
        });

        console.log(`  ✓ Migrated File [${f.id}] (${f.originalName}) -> ${res.secure_url}`);
        migratedFiles++;
      } catch (err: any) {
        console.error(`  ✗ Failed to upload File [${f.id}] to Cloudinary: ${err.message}`);
      }
    } else {
      missingFiles++;
      console.warn(`  ⚠ Local file for File [${f.id}] (${f.storageKey}) not found on disk.`);
      // If URL has localhost, rewrite to onrender host fallback so mobile doesn't point to dead localhost
      if (f.url.includes('localhost:3000')) {
        const fixedUrl = f.url.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
        await prisma.file.update({
          where: { id: f.id },
          data: { url: fixedUrl },
        });
      }
    }
  }

  console.log(`\nFile Summary: Migrated: ${migratedFiles}, Already on Cloudinary: ${skippedFiles}, Missing on disk: ${missingFiles}\n`);

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Audit & Update `Video` records
  // ─────────────────────────────────────────────────────────────────────────────
  console.log('--- 2. Auditing & Updating `Video` Records ---');
  const videos = await prisma.video.findMany({
    include: { sourceFile: true, renditions: true },
  });
  console.log(`Found ${videos.length} Video records.`);

  let updatedVideos = 0;
  for (const v of videos) {
    let sourcePublicId = v.sourceFile?.storageKey;
    let isCloudinarySource = v.sourceFile?.provider === FileProvider.CLOUDINARY ||
      (v.sourceFile?.url && v.sourceFile.url.includes('res.cloudinary.com'));

    // Check if sourceFile url has Cloudinary publicId
    if (v.sourceFile?.url && isCloudinarySource && !sourcePublicId?.includes('/')) {
      const parsed = v.sourceFile.url.split('/upload/')[1]?.replace(/\.[^/.]+$/, '');
      if (parsed) sourcePublicId = parsed;
    }

    const updates: Record<string, any> = {};

    if (isCloudinarySource && sourcePublicId) {
      const hlsUrl = `https://res.cloudinary.com/${cloudName}/video/upload/sp_hd/${sourcePublicId}.m3u8`;
      const directMp4Url = `https://res.cloudinary.com/${cloudName}/video/upload/q_auto,vc_auto,f_mp4/${sourcePublicId}.mp4`;
      const posterThumb = v.thumbnailUrl && !v.thumbnailUrl.includes('localhost')
        ? v.thumbnailUrl
        : `https://res.cloudinary.com/${cloudName}/video/upload/so_1,q_auto,f_jpg/${sourcePublicId}.jpg`;

      updates.status = VideoStatus.READY;
      updates.hlsUrl = hlsUrl;
      if (!v.thumbnailUrl || v.thumbnailUrl.includes('localhost')) {
        updates.thumbnailUrl = posterThumb;
      }

      // Upsert Cloudinary renditions
      const targets = [
        { res: VideoResolution.R_240P, height: 240, width: 426, bitrate: 400 },
        { res: VideoResolution.R_360P, height: 360, width: 640, bitrate: 800 },
        { res: VideoResolution.R_480P, height: 480, width: 854, bitrate: 1200 },
        { res: VideoResolution.R_720P, height: 720, width: 1280, bitrate: 2500 },
        { res: VideoResolution.R_1080P, height: 1080, width: 1920, bitrate: 5000 },
      ];

      for (const t of targets) {
        const rendUrl = `https://res.cloudinary.com/${cloudName}/video/upload/h_${t.height},c_scale,q_auto,vc_auto/${sourcePublicId}.mp4`;
        await prisma.videoRendition.upsert({
          where: { videoId_resolution: { videoId: v.id, resolution: t.res } },
          create: {
            videoId: v.id,
            resolution: t.res,
            height: t.height,
            width: t.width,
            bitrate: t.bitrate,
            fileSize: BigInt(0),
            storageKey: sourcePublicId,
            url: rendUrl,
            provider: FileProvider.CLOUDINARY,
            isReady: true,
          },
          update: {
            url: rendUrl,
            storageKey: sourcePublicId,
            provider: FileProvider.CLOUDINARY,
            isReady: true,
          },
        });
      }
    } else {
      // Fix any lingering localhost:3000 URLs
      if (v.thumbnailUrl?.includes('localhost:3000')) {
        updates.thumbnailUrl = v.thumbnailUrl.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
      }
      if (v.hlsUrl?.includes('localhost:3000')) {
        updates.hlsUrl = v.hlsUrl.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
      }
    }

    if (Object.keys(updates).length > 0) {
      await prisma.video.update({
        where: { id: v.id },
        data: updates,
      });
      console.log(`  ✓ Updated Video [${v.id}] (${v.title}) -> status: ${updates.status || v.status}, hls: ${updates.hlsUrl || v.hlsUrl}`);
      updatedVideos++;
    }
  }

  console.log(`Video Summary: Updated ${updatedVideos} videos.\n`);

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Audit & Migrate `Group` avatar and cover URLs
  // ─────────────────────────────────────────────────────────────────────────────
  console.log('--- 3. Auditing Group Media ---');
  const groups = await prisma.group.findMany();
  for (const g of groups) {
    const updates: Record<string, any> = {};
    if (g.avatarUrl && g.avatarUrl.includes('localhost:3000')) {
      updates.avatarUrl = g.avatarUrl.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
    }
    if (g.coverUrl && g.coverUrl.includes('localhost:3000')) {
      updates.coverUrl = g.coverUrl.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
    }
    if (Object.keys(updates).length > 0) {
      await prisma.group.update({ where: { id: g.id }, data: updates });
      console.log(`  ✓ Sanitized Group [${g.id}] (${g.name}) URLs`);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Audit & Migrate `StreamRecording` records
  // ─────────────────────────────────────────────────────────────────────────────
  console.log('--- 4. Auditing Stream Recordings ---');
  const recordings = await prisma.streamRecording.findMany();
  for (const r of recordings) {
    if (r.hlsUrl && r.hlsUrl.includes('localhost:3000')) {
      const fixedHls = r.hlsUrl.replace('http://localhost:3000', 'https://zikrekidusan.onrender.com');
      await prisma.streamRecording.update({
        where: { id: r.id },
        data: { hlsUrl: fixedHls },
      });
      console.log(`  ✓ Sanitized StreamRecording [${r.id}] HLS URL`);
    }
  }

  console.log('\n🎉 Cloudinary Media Storage Migration Completed Successfully!');
  await prisma.$disconnect();
}

runMigration().catch((err) => {
  console.error('Migration error:', err);
  process.exit(1);
});
