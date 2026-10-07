// src/modules/uploads/uploads.service.ts
import 'multer';
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import crypto from 'crypto';
import path from 'path';
import { FileProvider, FileType } from '@prisma/client';
import { UploadsRepository } from './uploads.repository.js';
import { IStorageProvider } from './providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from './providers/storage.factory.js';
import { CloudinaryStorageProvider } from './providers/cloudinary.provider.js';
import { FileResponseDto } from './dto/file-response.dto.js';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class UploadsService {
  private readonly logger = new Logger(UploadsService.name);

  constructor(
    private readonly uploadsRepository: UploadsRepository,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider & Record<string, any>,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Generic media upload into organized Cloudinary namespace folders.
   */
  async uploadMediaFile(
    userId: string,
    file: Express.Multer.File,
    subfolder: string,
    groupId?: string,
  ): Promise<FileResponseDto> {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    // When the client sends application/octet-stream (e.g. image_picker on Android
    // returns UUID filenames with no extension), sniff the real MIME from file bytes
    // so Cloudinary stores it as an image rather than a raw resource.
    const effectiveMime =
      file.mimetype === 'application/octet-stream' || !file.mimetype
        ? (this.sniffMimeFromBuffer(file.buffer) ?? file.mimetype)
        : file.mimetype;

    let ext = path.extname(file.originalname).toLowerCase().replace('.', '');
    if (!ext) {
      ext = this.resolveExtensionFromMime(effectiveMime);
    }

    const resolvedFilename =
      ext && !path.extname(file.originalname)
        ? `${file.originalname}.${ext}`
        : file.originalname;

    const resolvedFile: Express.Multer.File = {
      ...file,
      mimetype: effectiveMime,
      originalname: resolvedFilename,
    };

    const fileType = this.resolveFileType(effectiveMime);
    const checksum = crypto
      .createHash('sha256')
      .update(file.buffer)
      .digest('hex');

    const result = await this.storageProvider.upload(resolvedFile, subfolder);

    // For video files on Cloudinary, derive the universal direct playback MP4 URL
    let mediaUrl = result.url;
    if (
      fileType === FileType.VIDEO &&
      this.storageProvider.providerType === 'CLOUDINARY'
    ) {
      const cloudinaryProvider = this
        .storageProvider as CloudinaryStorageProvider;
      mediaUrl = cloudinaryProvider.getVideoDirectUrl(result.storageKey);
    }

    const dbFile = await this.uploadsRepository.createFile({
      originalName: resolvedFilename,
      fileName: path.basename(result.storageKey),
      mimeType: effectiveMime,
      extension: ext,
      size: file.size,
      fileType,
      provider: result.provider,
      storageKey: result.storageKey,
      url: mediaUrl,
      uploadedById: userId,
      groupId: groupId ?? null,
      checksum,
    });

    return this.mapToFileResponse(dbFile);
  }

  /**
   * Calendar note media upload.
   * Routes to the calendar/ Cloudinary folder and ensures correct resource_type.
   */
  async uploadCalendarMedia(
    userId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    return this.uploadMediaFile(userId, file, `calendar/${userId}`);
  }

  /**
   * Chat media upload (images, videos, audio/voice notes, documents)
   */
  async uploadChatMedia(
    userId: string,
    file: Express.Multer.File,
    conversationId?: string,
  ): Promise<FileResponseDto> {
    const subfolder = conversationId
      ? `chat/${conversationId}`
      : `chat/${userId}`;
    return this.uploadMediaFile(userId, file, subfolder);
  }

  /**
   * Post media upload (images and videos)
   */
  async uploadPostMedia(
    userId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    return this.uploadMediaFile(userId, file, `posts/${userId}`);
  }

  /**
   * User Avatar upload
   */
  async uploadUserAvatar(
    userId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    // 1. Fetch current profile avatar to clean up old asset
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      include: { avatar: true },
    });

    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `users/${userId}/avatar`,
    );

    // 2. Link to profile
    await this.prisma.profile.upsert({
      where: { userId },
      create: { userId, avatarFileId: uploaded.id },
      update: { avatarFileId: uploaded.id },
    });

    // 3. Clean up previous avatar if it exists
    if (
      profile?.avatar?.storageKey &&
      profile.avatar.storageKey !== uploaded.id
    ) {
      await this.safeDeleteAsset(profile.avatar.storageKey, profile.avatar.id);
    }

    return uploaded;
  }

  /**
   * User Cover upload
   */
  async uploadUserCover(
    userId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
      include: { cover: true },
    });

    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `users/${userId}/cover`,
    );

    await this.prisma.profile.upsert({
      where: { userId },
      create: { userId, coverFileId: uploaded.id },
      update: { coverFileId: uploaded.id },
    });

    if (
      profile?.cover?.storageKey &&
      profile.cover.storageKey !== uploaded.id
    ) {
      await this.safeDeleteAsset(profile.cover.storageKey, profile.cover.id);
    }

    return uploaded;
  }

  /**
   * Group-scoped file upload endpoint requirement
   */
  async uploadGroupFile(
    groupId: string,
    uploaderId: string,
    file: Express.Multer.File,
  ): Promise<FileResponseDto> {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const group = await this.prisma.group.findUnique({
      where: { id: groupId, deletedAt: null },
      select: { id: true, status: true },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    if (group.status === 'PENDING_APPROVAL') {
      throw new ForbiddenException(
        'Group is not privileged to upload files. Please communicate with system admin to approve your group.',
      );
    }

    if (group.status !== 'ACTIVE') {
      throw new ForbiddenException(
        'This group is inactive — uploads are disabled until approved by an Admin',
      );
    }

    const fileType = this.resolveFileType(file.mimetype);
    const subfolder = `groups/${groupId}/${fileType.toLowerCase()}`;
    return this.uploadMediaFile(uploaderId, file, subfolder, groupId);
  }

  /**
   * Group Avatar upload
   */
  async uploadGroupAvatar(
    groupId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ avatarUrl: string; fileId: string }> {
    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `groups/${groupId}/avatar`,
      groupId,
    );

    // Update group avatarUrl
    await this.prisma.group.update({
      where: { id: groupId },
      data: { avatarUrl: uploaded.url },
    });

    return { avatarUrl: uploaded.url, fileId: uploaded.id };
  }

  /**
   * Group Cover upload
   */
  async uploadGroupCover(
    groupId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ coverUrl: string; fileId: string }> {
    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `groups/${groupId}/cover`,
      groupId,
    );

    await this.prisma.group.update({
      where: { id: groupId },
      data: { coverUrl: uploaded.url },
    });

    return { coverUrl: uploaded.url, fileId: uploaded.id };
  }

  /**
   * Channel Avatar upload
   */
  async uploadChannelAvatar(
    channelId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ avatarUrl: string; fileId: string }> {
    const channel = await this.prisma.videoChannel.findUnique({
      where: { id: channelId },
      include: { avatarFile: true },
    });
    if (!channel) throw new NotFoundException('Channel not found');

    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `channels/${channelId}/avatar`,
      channel.groupId,
    );

    await this.prisma.videoChannel.update({
      where: { id: channelId },
      data: { avatarFileId: uploaded.id },
    });

    if (channel.avatarFile?.storageKey) {
      await this.safeDeleteAsset(
        channel.avatarFile.storageKey,
        channel.avatarFile.id,
      );
    }

    return { avatarUrl: uploaded.url, fileId: uploaded.id };
  }

  /**
   * Channel Banner upload
   */
  async uploadChannelBanner(
    channelId: string,
    userId: string,
    file: Express.Multer.File,
  ): Promise<{ bannerUrl: string; fileId: string }> {
    const channel = await this.prisma.videoChannel.findUnique({
      where: { id: channelId },
      include: { bannerFile: true },
    });
    if (!channel) throw new NotFoundException('Channel not found');

    const uploaded = await this.uploadMediaFile(
      userId,
      file,
      `channels/${channelId}/banner`,
      channel.groupId,
    );

    await this.prisma.videoChannel.update({
      where: { id: channelId },
      data: { bannerFileId: uploaded.id },
    });

    if (channel.bannerFile?.storageKey) {
      await this.safeDeleteAsset(
        channel.bannerFile.storageKey,
        channel.bannerFile.id,
      );
    }

    return { bannerUrl: uploaded.url, fileId: uploaded.id };
  }

  async listGroupFiles(groupId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const { items, total } = await this.uploadsRepository.findByGroup(
      groupId,
      skip,
      limit,
    );

    const data: FileResponseDto[] = items.map((f) => this.mapToFileResponse(f));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async deleteFile(fileId: string, userId: string) {
    const file = await this.uploadsRepository.findById(fileId);
    if (!file) {
      throw new NotFoundException('File not found');
    }

    if (file.uploadedById !== userId) {
      throw new ForbiddenException('You can only delete files you uploaded');
    }

    await this.safeDeleteAsset(file.storageKey, fileId);
    await this.uploadsRepository.softDelete(fileId);

    return { message: 'File deleted successfully' };
  }

  /**
   * Safe asset deletion with orphan protection
   */
  async safeDeleteAsset(storageKey: string, fileId?: string): Promise<void> {
    if (!storageKey) return;

    try {
      if (fileId) {
        // Check if any other entity is actively using this fileId
        const [
          postCount,
          storyCount,
          reelCount,
          profileAvatarCount,
          profileCoverCount,
        ] = await Promise.all([
          this.prisma.postMedia.count({ where: { fileId } }),
          this.prisma.story.count({ where: { fileId, deletedAt: null } }),
          this.prisma.reel.count({ where: { fileId, deletedAt: null } }),
          this.prisma.profile.count({ where: { avatarFileId: fileId } }),
          this.prisma.profile.count({ where: { coverFileId: fileId } }),
        ]);

        if (
          postCount +
            storyCount +
            reelCount +
            profileAvatarCount +
            profileCoverCount >
          1
        ) {
          this.logger.warn(
            `Storage asset [${storageKey}] is still referenced by other records — skipping remote deletion`,
          );
          return;
        }
      }

      await this.storageProvider.delete(storageKey);
      this.logger.log(`Deleted storage asset: ${storageKey}`);
    } catch (err: any) {
      this.logger.warn(
        `Could not delete storage asset [${storageKey}]: ${err?.message}`,
      );
    }
  }

  private mapToFileResponse(f: any): FileResponseDto {
    return {
      id: f.id,
      originalName: f.originalName,
      mimeType: f.mimeType,
      size: Number(f.size),
      fileType: f.fileType,
      provider: f.provider,
      url: f.url,
      status: f.status,
      uploadedById: f.uploadedById,
      groupId: f.groupId,
      createdAt: f.createdAt,
    };
  }

  private resolveFileType(mimeType: string): FileType {
    if (mimeType.startsWith('image/')) return FileType.IMAGE;
    if (mimeType.startsWith('video/')) return FileType.VIDEO;
    if (mimeType.startsWith('audio/')) return FileType.AUDIO;
    if (
      mimeType.includes('pdf') ||
      mimeType.includes('msword') ||
      mimeType.includes('document') ||
      mimeType.includes('text') ||
      mimeType.includes('csv') ||
      mimeType.includes('excel') ||
      mimeType.includes('spreadsheet')
    ) {
      return FileType.DOCUMENT;
    }
    if (
      mimeType.includes('zip') ||
      mimeType.includes('tar') ||
      mimeType.includes('gzip') ||
      mimeType.includes('rar') ||
      mimeType.includes('7z')
    ) {
      return FileType.ARCHIVE;
    }
    return FileType.OTHER;
  }

  /**
   * Sniff MIME type from the first 12 bytes of a buffer.
   * Used to detect images sent with application/octet-stream content-type
   * (e.g. Flutter image_picker on Android sends UUID filenames without extensions).
   */
  private sniffMimeFromBuffer(buffer: Buffer): string | null {
    if (!buffer || buffer.length < 4) return null;
    const h = buffer;

    // JPEG: FF D8 FF
    if (h[0] === 0xff && h[1] === 0xd8 && h[2] === 0xff) return 'image/jpeg';

    // PNG: 89 50 4E 47
    if (h[0] === 0x89 && h[1] === 0x50 && h[2] === 0x4e && h[3] === 0x47)
      return 'image/png';

    // GIF87a / GIF89a: 47 49 46 38
    if (h[0] === 0x47 && h[1] === 0x49 && h[2] === 0x46 && h[3] === 0x38)
      return 'image/gif';

    // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
    if (
      buffer.length >= 12 &&
      h[0] === 0x52 && h[1] === 0x49 && h[2] === 0x46 && h[3] === 0x46 &&
      h[8] === 0x57 && h[9] === 0x45 && h[10] === 0x42 && h[11] === 0x50
    )
      return 'image/webp';

    // HEIC / HEIF / MP4 / MOV — all share 'ftyp' at bytes 4-7
    if (
      buffer.length >= 8 &&
      h[4] === 0x66 && h[5] === 0x74 && h[6] === 0x79 && h[7] === 0x70
    ) {
      if (buffer.length >= 12) {
        const brand = buffer.slice(8, 12).toString('ascii');
        if (brand === 'heic' || brand === 'heix' || brand === 'mif1')
          return 'image/heic';
        if (brand === 'isom' || brand === 'mp41' || brand === 'mp42')
          return 'video/mp4';
        if (brand === 'qt  ') return 'video/quicktime';
      }
      return 'video/mp4';
    }

    // BMP: 42 4D
    if (h[0] === 0x42 && h[1] === 0x4d) return 'image/bmp';

    return null;
  }

  private resolveExtensionFromMime(mimeType: string): string {
    if (mimeType === 'image/jpeg') return 'jpg';
    if (mimeType === 'image/png') return 'png';
    if (mimeType === 'image/gif') return 'gif';
    if (mimeType === 'image/webp') return 'webp';
    if (mimeType === 'image/heic') return 'heic';
    if (mimeType === 'image/bmp') return 'bmp';
    if (mimeType === 'video/mp4') return 'mp4';
    if (mimeType === 'video/quicktime') return 'mov';
    if (mimeType === 'audio/mpeg' || mimeType === 'audio/mp3') return 'mp3';
    return '';
  }
}
