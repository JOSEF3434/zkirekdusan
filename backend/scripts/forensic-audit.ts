// backend/scripts/forensic-audit.ts
import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { PrismaService } from '../src/prisma/prisma.service.js';

interface CategoryStats {
  total: number;
  providerLocal: number;
  providerCloudinary: number;
  providerOther: number;
  hasLocalhostUrl: number;
  hasRenderUploadsUrl: number;
  hasValidCloudinaryUrl: number;
  hasMissingOrNullUrl: number;
  physicalFileExistsOnDisk: number;
  physicalFileMissingOnDisk: number;
  details: any[];
}

function createEmptyStats(): CategoryStats {
  return {
    total: 0,
    providerLocal: 0,
    providerCloudinary: 0,
    providerOther: 0,
    hasLocalhostUrl: 0,
    hasRenderUploadsUrl: 0,
    hasValidCloudinaryUrl: 0,
    hasMissingOrNullUrl: 0,
    physicalFileExistsOnDisk: 0,
    physicalFileMissingOnDisk: 0,
    details: [],
  };
}

function classifyUrl(url: string | null | undefined): 'LOCALHOST' | 'RENDER_UPLOADS' | 'CLOUDINARY' | 'MISSING' | 'OTHER' {
  if (!url || url.trim() === '') return 'MISSING';
  const u = url.trim();
  if (u.includes('localhost') || u.includes('127.0.0.1') || u.includes('0.0.0.0') || u.includes('10.0.2.2')) {
    return 'LOCALHOST';
  }
  if (u.includes('res.cloudinary.com') || u.includes('cloudinary.com')) {
    return 'CLOUDINARY';
  }
  if (u.includes('/uploads/') || u.startsWith('uploads/') || u.includes('onrender.com/uploads')) {
    return 'RENDER_UPLOADS';
  }
  return 'OTHER';
}

function checkDiskFile(storageKey: string | null | undefined, fileName: string | null | undefined): boolean {
  const uploadsDir = path.resolve(process.cwd(), 'uploads');
  if (storageKey) {
    const directPath = path.isAbsolute(storageKey) ? storageKey : path.join(uploadsDir, storageKey);
    if (fs.existsSync(directPath)) return true;
    const relClean = storageKey.replace(/^[\\/]+/, '').replace(/^uploads[\\/]/, '');
    if (fs.existsSync(path.join(uploadsDir, relClean))) return true;
  }
  if (fileName) {
    if (fs.existsSync(path.join(uploadsDir, fileName))) return true;
  }
  return false;
}

async function forensicAudit() {
  console.log('═══════════════════════════════════════════════════════════════════════════');
  console.log('           FORENSIC DATABASE MEDIA STORAGE AUDIT REPORT                    ');
  console.log('═══════════════════════════════════════════════════════════════════════════\n');

  const prisma = new PrismaService();
  await prisma.$connect();

  const report: Record<string, CategoryStats> = {
    File: createEmptyStats(),
    Video: createEmptyStats(),
    VideoRendition: createEmptyStats(),
    Story: createEmptyStats(),
    PostMedia: createEmptyStats(),
    Reel: createEmptyStats(),
    MessageAttachment: createEmptyStats(),
    StreamRecording: createEmptyStats(),
    ProfileAvatar: createEmptyStats(),
    ProfileCover: createEmptyStats(),
    GroupAvatar: createEmptyStats(),
    GroupCover: createEmptyStats(),
    VideoChannelAvatar: createEmptyStats(),
    VideoChannelBanner: createEmptyStats(),
    LiveStreamThumbnail: createEmptyStats(),
  };

  // 1. Files
  const files = await prisma.file.findMany();
  report.File.total = files.length;
  for (const f of files) {
    if (f.provider === 'LOCAL') report.File.providerLocal++;
    else if (f.provider === 'CLOUDINARY') report.File.providerCloudinary++;
    else report.File.providerOther++;

    const classification = classifyUrl(f.url);
    if (classification === 'LOCALHOST') report.File.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.File.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.File.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.File.hasMissingOrNullUrl++;

    const onDisk = checkDiskFile(f.storageKey, f.fileName);
    if (onDisk) report.File.physicalFileExistsOnDisk++;
    else report.File.physicalFileMissingOnDisk++;

    report.File.details.push({
      id: f.id,
      originalName: f.originalName,
      provider: f.provider,
      storageKey: f.storageKey,
      url: f.url,
      classification,
      onDisk,
    });
  }

  // 2. Videos
  const videos = await prisma.video.findMany({
    include: { sourceFile: true, renditions: true },
  });
  report.Video.total = videos.length;
  for (const v of videos) {
    const classification = classifyUrl(v.hlsUrl);
    if (classification === 'LOCALHOST') report.Video.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.Video.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.Video.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.Video.hasMissingOrNullUrl++;

    report.Video.details.push({
      id: v.id,
      title: v.title,
      status: v.status,
      hlsUrl: v.hlsUrl,
      thumbnailUrl: v.thumbnailUrl,
      classification,
      sourceFileProvider: v.sourceFile?.provider,
      sourceFileUrl: v.sourceFile?.url,
    });
  }

  // 3. Video Renditions
  const renditions = await prisma.videoRendition.findMany();
  report.VideoRendition.total = renditions.length;
  for (const r of renditions) {
    if (r.provider === 'LOCAL') report.VideoRendition.providerLocal++;
    else if (r.provider === 'CLOUDINARY') report.VideoRendition.providerCloudinary++;
    else report.VideoRendition.providerOther++;

    const classification = classifyUrl(r.url);
    if (classification === 'LOCALHOST') report.VideoRendition.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.VideoRendition.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.VideoRendition.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.VideoRendition.hasMissingOrNullUrl++;
  }

  // 4. Stories
  const stories = await prisma.story.findMany({ include: { file: true } });
  report.Story.total = stories.length;
  for (const s of stories) {
    const url = s.file?.url;
    const classification = classifyUrl(url);
    if (s.file?.provider === 'LOCAL') report.Story.providerLocal++;
    else if (s.file?.provider === 'CLOUDINARY') report.Story.providerCloudinary++;
    else report.Story.providerOther++;

    if (classification === 'LOCALHOST') report.Story.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.Story.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.Story.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.Story.hasMissingOrNullUrl++;
  }

  // 5. PostMedia
  const postMedias = await prisma.postMedia.findMany({ include: { file: true } });
  report.PostMedia.total = postMedias.length;
  for (const pm of postMedias) {
    const url = pm.file?.url;
    const classification = classifyUrl(url);
    if (pm.file?.provider === 'LOCAL') report.PostMedia.providerLocal++;
    else if (pm.file?.provider === 'CLOUDINARY') report.PostMedia.providerCloudinary++;
    else report.PostMedia.providerOther++;

    if (classification === 'LOCALHOST') report.PostMedia.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.PostMedia.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.PostMedia.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.PostMedia.hasMissingOrNullUrl++;
  }

  // 6. Reels
  const reels = await prisma.reel.findMany({ include: { file: true } });
  report.Reel.total = reels.length;
  for (const r of reels) {
    const url = r.file?.url;
    const classification = classifyUrl(url);
    if (r.file?.provider === 'LOCAL') report.Reel.providerLocal++;
    else if (r.file?.provider === 'CLOUDINARY') report.Reel.providerCloudinary++;
    else report.Reel.providerOther++;

    if (classification === 'LOCALHOST') report.Reel.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.Reel.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.Reel.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.Reel.hasMissingOrNullUrl++;
  }

  // 7. MessageAttachment
  const attachments = await prisma.messageAttachment.findMany({ include: { file: true } });
  report.MessageAttachment.total = attachments.length;
  for (const ma of attachments) {
    const url = ma.file?.url;
    const classification = classifyUrl(url);
    if (ma.file?.provider === 'LOCAL') report.MessageAttachment.providerLocal++;
    else if (ma.file?.provider === 'CLOUDINARY') report.MessageAttachment.providerCloudinary++;
    else report.MessageAttachment.providerOther++;

    if (classification === 'LOCALHOST') report.MessageAttachment.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.MessageAttachment.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.MessageAttachment.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.MessageAttachment.hasMissingOrNullUrl++;
  }

  // 8. StreamRecordings
  const recordings = await prisma.streamRecording.findMany({ include: { file: true } });
  report.StreamRecording.total = recordings.length;
  for (const sr of recordings) {
    const url = sr.hlsUrl || sr.url || sr.file?.url;
    const classification = classifyUrl(url);
    if (sr.file?.provider === 'LOCAL') report.StreamRecording.providerLocal++;
    else if (sr.file?.provider === 'CLOUDINARY') report.StreamRecording.providerCloudinary++;
    else report.StreamRecording.providerOther++;

    if (classification === 'LOCALHOST') report.StreamRecording.hasLocalhostUrl++;
    else if (classification === 'RENDER_UPLOADS') report.StreamRecording.hasRenderUploadsUrl++;
    else if (classification === 'CLOUDINARY') report.StreamRecording.hasValidCloudinaryUrl++;
    else if (classification === 'MISSING') report.StreamRecording.hasMissingOrNullUrl++;
  }

  // 9. Profiles
  const profiles = await prisma.profile.findMany({
    include: { avatar: true, cover: true },
  });
  report.ProfileAvatar.total = profiles.filter((p) => p.avatarFileId != null).length;
  report.ProfileCover.total = profiles.filter((p) => p.coverFileId != null).length;

  for (const p of profiles) {
    if (p.avatar) {
      const classification = classifyUrl(p.avatar.url);
      if (p.avatar.provider === 'LOCAL') report.ProfileAvatar.providerLocal++;
      else if (p.avatar.provider === 'CLOUDINARY') report.ProfileAvatar.providerCloudinary++;

      if (classification === 'LOCALHOST') report.ProfileAvatar.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.ProfileAvatar.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.ProfileAvatar.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.ProfileAvatar.hasMissingOrNullUrl++;
    }
    if (p.cover) {
      const classification = classifyUrl(p.cover.url);
      if (p.cover.provider === 'LOCAL') report.ProfileCover.providerLocal++;
      else if (p.cover.provider === 'CLOUDINARY') report.ProfileCover.providerCloudinary++;

      if (classification === 'LOCALHOST') report.ProfileCover.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.ProfileCover.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.ProfileCover.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.ProfileCover.hasMissingOrNullUrl++;
    }
  }

  // 10. Groups
  const groups = await prisma.group.findMany();
  report.GroupAvatar.total = groups.filter((g) => g.avatarUrl != null).length;
  report.GroupCover.total = groups.filter((g) => g.coverUrl != null).length;

  for (const g of groups) {
    if (g.avatarUrl) {
      const classification = classifyUrl(g.avatarUrl);
      if (classification === 'LOCALHOST') report.GroupAvatar.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.GroupAvatar.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.GroupAvatar.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.GroupAvatar.hasMissingOrNullUrl++;
    }
    if (g.coverUrl) {
      const classification = classifyUrl(g.coverUrl);
      if (classification === 'LOCALHOST') report.GroupCover.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.GroupCover.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.GroupCover.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.GroupCover.hasMissingOrNullUrl++;
    }
  }

  // 11. Channels
  const channels = await prisma.videoChannel.findMany({
    include: { avatarFile: true, bannerFile: true },
  });
  report.VideoChannelAvatar.total = channels.filter((c) => c.avatarFileId != null).length;
  report.VideoChannelBanner.total = channels.filter((c) => c.bannerFileId != null).length;

  for (const c of channels) {
    if (c.avatarFile) {
      const classification = classifyUrl(c.avatarFile.url);
      if (c.avatarFile.provider === 'LOCAL') report.VideoChannelAvatar.providerLocal++;
      else if (c.avatarFile.provider === 'CLOUDINARY') report.VideoChannelAvatar.providerCloudinary++;

      if (classification === 'LOCALHOST') report.VideoChannelAvatar.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.VideoChannelAvatar.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.VideoChannelAvatar.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.VideoChannelAvatar.hasMissingOrNullUrl++;
    }
    if (c.bannerFile) {
      const classification = classifyUrl(c.bannerFile.url);
      if (c.bannerFile.provider === 'LOCAL') report.VideoChannelBanner.providerLocal++;
      else if (c.bannerFile.provider === 'CLOUDINARY') report.VideoChannelBanner.providerCloudinary++;

      if (classification === 'LOCALHOST') report.VideoChannelBanner.hasLocalhostUrl++;
      else if (classification === 'RENDER_UPLOADS') report.VideoChannelBanner.hasRenderUploadsUrl++;
      else if (classification === 'CLOUDINARY') report.VideoChannelBanner.hasValidCloudinaryUrl++;
      else if (classification === 'MISSING') report.VideoChannelBanner.hasMissingOrNullUrl++;
    }
  }

  // Print Formatted Table
  console.log(
    'Category'.padEnd(22) +
    'Total'.padEnd(8) +
    'LOCAL'.padEnd(8) +
    'CLOUDINARY'.padEnd(12) +
    'Localhost'.padEnd(12) +
    'Render/Upload'.padEnd(15) +
    'CloudinaryURL'.padEnd(15) +
    'Missing/Null'
  );
  console.log('─'.repeat(105));

  for (const [key, val] of Object.entries(report)) {
    console.log(
      key.padEnd(22) +
      String(val.total).padEnd(8) +
      String(val.providerLocal).padEnd(8) +
      String(val.providerCloudinary).padEnd(12) +
      String(val.hasLocalhostUrl).padEnd(12) +
      String(val.hasRenderUploadsUrl).padEnd(15) +
      String(val.hasValidCloudinaryUrl).padEnd(15) +
      String(val.hasMissingOrNullUrl)
    );
  }

  console.log('\n--- Files On Local Disk Status ---');
  console.log(`  Physical files found on local disk:    ${report.File.physicalFileExistsOnDisk}`);
  console.log(`  Physical files missing on local disk:  ${report.File.physicalFileMissingOnDisk}`);

  console.log('\n--- Forensic Details of Non-Cloudinary Active Records ---');
  for (const f of report.File.details) {
    if (f.classification !== 'CLOUDINARY') {
      console.log(`  [File ${f.id}] name: "${f.originalName}" | provider: ${f.provider} | class: ${f.classification} | onDisk: ${f.onDisk} | url: ${f.url}`);
    }
  }
  for (const v of report.Video.details) {
    if (v.classification !== 'CLOUDINARY') {
      console.log(`  [Video ${v.id}] title: "${v.title}" | status: ${v.status} | class: ${v.classification} | hlsUrl: ${v.hlsUrl} | thumb: ${v.thumbnailUrl}`);
    }
  }

  await prisma.$disconnect();
}

forensicAudit().catch((err) => {
  console.error('Forensic audit error:', err);
  process.exit(1);
});
