// backend/scripts/final-purge.ts
import 'dotenv/config';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { FileProvider, FileStatus, VideoStatus } from '@prisma/client';

async function finalPurge() {
  const prisma = new PrismaService();
  await prisma.$connect();

  console.log('Cleaning up remaining legacy records...');

  // Update all Files with LOCAL provider or localhost/render URL to FAILED
  const updatedFiles = await prisma.file.updateMany({
    where: {
      OR: [
        { provider: FileProvider.LOCAL },
        { url: { contains: 'localhost' } },
        { url: { contains: '/uploads/' } },
      ],
    },
    data: {
      status: FileStatus.FAILED,
      deletedAt: new Date(),
      url: '[MISSING_LOCAL_FILE]',
    },
  });
  console.log(`Updated ${updatedFiles.count} legacy File records.`);

  // Update all Videos with localhost/render URL to FAILED
  const updatedVideos = await prisma.video.updateMany({
    where: {
      OR: [
        { hlsUrl: { contains: 'localhost' } },
        { hlsUrl: { contains: '/uploads/' } },
        { thumbnailUrl: { contains: 'localhost' } },
        { thumbnailUrl: { contains: '/uploads/' } },
      ],
    },
    data: {
      status: VideoStatus.FAILED,
      deletedAt: new Date(),
      hlsUrl: null,
      thumbnailUrl: null,
    },
  });
  console.log(`Updated ${updatedVideos.count} legacy Video records.`);

  // Clean groups
  await prisma.group.updateMany({
    where: {
      OR: [
        { avatarUrl: { contains: 'localhost' } },
        { avatarUrl: { contains: '/uploads/' } },
        { coverUrl: { contains: 'localhost' } },
        { coverUrl: { contains: '/uploads/' } },
      ],
    },
    data: {
      avatarUrl: null,
      coverUrl: null,
    },
  });

  console.log('Cleanup complete.');
  await prisma.$disconnect();
}

finalPurge().catch((e) => {
  console.error(e);
  process.exit(1);
});
