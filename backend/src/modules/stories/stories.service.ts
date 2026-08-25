// src/modules/stories/stories.service.ts
import 'multer';
import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import path from 'path';
import crypto from 'crypto';
import { FileProvider, FileType, ReactionType, StoryType } from '@prisma/client';
import { StoriesRepository } from './stories.repository.js';
import { UploadsRepository } from '../uploads/uploads.repository.js';
import { IStorageProvider } from '../uploads/providers/storage.interface.js';
import { STORAGE_PROVIDER_TOKEN } from '../uploads/providers/storage.factory.js';
import { CloudinaryStorageProvider } from '../uploads/providers/cloudinary.provider.js';
import { CreateStoryDto } from './dto/create-story.dto.js';
import { StoryAuthorDto, StoryResponseDto } from './dto/story-response.dto.js';
import { StoryFeedGroupDto } from './dto/story-feed.dto.js';
import { StoryReactionResponseDto } from './dto/story-reaction.dto.js';
import { StoryCommentResponseDto } from './dto/story-comment.dto.js';
import { StoryViewerResponseDto } from './dto/story-viewer.dto.js';

@Injectable()
export class StoriesService {
  private readonly logger = new Logger(StoriesService.name);

  constructor(
    private readonly storiesRepository: StoriesRepository,
    private readonly uploadsRepository: UploadsRepository,
    @Inject(STORAGE_PROVIDER_TOKEN)
    private readonly storageProvider: IStorageProvider & Record<string, any>,
  ) {}

  async createStory(
    authorId: string,
    dto: CreateStoryDto,
  ): Promise<StoryResponseDto> {
    const story = await this.storiesRepository.createStory(authorId, dto);
    return this.mapToDto(story);
  }

  async createStoryWithFile(
    authorId: string,
    file: Express.Multer.File,
    content?: string,
    backgroundColor?: string,
    textColor?: string,
  ): Promise<StoryResponseDto> {
    if (!file) {
      throw new BadRequestException('Media file is required');
    }

    const isVideo = file.mimetype.startsWith('video/');
    const fileType = isVideo ? FileType.VIDEO : FileType.IMAGE;
    const storyType = isVideo ? StoryType.VIDEO : StoryType.IMAGE;

    const checksum = crypto
      .createHash('sha256')
      .update(file.buffer)
      .digest('hex');

    const subfolder = `stories/${authorId}`;
    const result = await this.storageProvider.upload(file, subfolder);
    const ext = path.extname(file.originalname).toLowerCase().replace('.', '');

    // For Cloudinary video stories: use optimized streaming URL so videos play on all devices
    let mediaUrl = result.url;
    if (
      isVideo &&
      this.storageProvider.providerType === 'CLOUDINARY'
    ) {
      const cloudinaryProvider = this.storageProvider as CloudinaryStorageProvider;
      // Use direct optimized MP4 URL for story videos (stories are short, no need for HLS)
      mediaUrl = cloudinaryProvider.getVideoDirectUrl(result.storageKey);
      this.logger.log(
        `[Stories] Cloudinary video story URL: ${mediaUrl} (publicId: ${result.storageKey})`,
      );
    }

    const dbFile = await this.uploadsRepository.createFile({
      originalName: file.originalname,
      fileName: path.basename(result.storageKey),
      mimeType: file.mimetype,
      extension: ext,
      size: file.size,
      fileType,
      provider: result.provider as FileProvider,
      storageKey: result.storageKey,
      url: mediaUrl, // Store optimized URL
      uploadedById: authorId,
      groupId: null,
      checksum,
    });

    const story = await this.storiesRepository.createStory(authorId, {
      type: storyType,
      fileId: dbFile.id,
      content,
      backgroundColor,
      textColor,
    });

    return this.mapToDto(story);
  }

  async getStoryFeed(viewerId?: string): Promise<StoryFeedGroupDto[]> {
    const [followingIds, activeStories, myProfile] = await Promise.all([
      this.storiesRepository.findFollowingUserIds(viewerId),
      this.storiesRepository.findActiveStoriesForViewer(viewerId),
      viewerId ? this.storiesRepository.findAuthorProfile(viewerId) : null,
    ]);

    const followingSet = new Set(followingIds);

    // Group active stories by authorId
    const groupsMap = new Map<string, any[]>();
    for (const story of activeStories) {
      const authorId = story.authorId;
      if (!groupsMap.has(authorId)) {
        groupsMap.set(authorId, []);
      }
      groupsMap.get(authorId)!.push(story);
    }

    // Process each author group
    const myStories = viewerId ? (groupsMap.get(viewerId) ?? []) : [];
    const otherGroups: {
      owner: StoryAuthorDto;
      stories: StoryResponseDto[];
      hasUnseen: boolean;
      latestStoryAt: Date;
      isFollowed: boolean;
      totalStories: number;
    }[] = [];

    for (const [authorId, storiesList] of groupsMap.entries()) {
      if (viewerId && authorId === viewerId) continue;

      const firstAuthor = storiesList[0].author;
      const owner: StoryAuthorDto = {
        id: firstAuthor.id,
        username: firstAuthor.username,
        displayName: firstAuthor.profile?.displayName ?? firstAuthor.username,
        avatarUrl: firstAuthor.profile?.avatar?.url ?? null,
      };

      const mappedStories = storiesList.map((s) => this.mapToDto(s, viewerId));
      const hasUnseen = mappedStories.some((s) => !s.hasViewedByMe);
      const latestStoryAt = new Date(
        Math.max(...storiesList.map((s) => new Date(s.createdAt).getTime())),
      );

      otherGroups.push({
        owner,
        stories: mappedStories,
        hasUnseen,
        latestStoryAt,
        isFollowed: followingSet.has(authorId),
        totalStories: mappedStories.length,
      });
    }

    // Deterministic Sorting Logic:
    // 1. Unseen from followed users (latestStoryAt DESC)
    // 2. Unseen from other users (latestStoryAt DESC)
    // 3. Seen from followed users (latestStoryAt DESC)
    // 4. Seen from other users (latestStoryAt DESC)
    const unseenFollowed = otherGroups
      .filter((g) => g.hasUnseen && g.isFollowed)
      .sort((a, b) => b.latestStoryAt.getTime() - a.latestStoryAt.getTime());

    const unseenOthers = otherGroups
      .filter((g) => g.hasUnseen && !g.isFollowed)
      .sort((a, b) => b.latestStoryAt.getTime() - a.latestStoryAt.getTime());

    const seenFollowed = otherGroups
      .filter((g) => !g.hasUnseen && g.isFollowed)
      .sort((a, b) => b.latestStoryAt.getTime() - a.latestStoryAt.getTime());

    const seenOthers = otherGroups
      .filter((g) => !g.hasUnseen && !g.isFollowed)
      .sort((a, b) => b.latestStoryAt.getTime() - a.latestStoryAt.getTime());

    // If unauthenticated / guest viewer, return public story groups sorted by latestStoryAt DESC
    if (!viewerId) {
      return otherGroups.sort(
        (a, b) => b.latestStoryAt.getTime() - a.latestStoryAt.getTime(),
      );
    }

    // Build Current User's "My Story" Group (ALWAYS POSITION 0)
    const myMappedStories = myStories.map((s) => this.mapToDto(s, viewerId));
    const myLatestStoryAt =
      myStories.length > 0
        ? new Date(
            Math.max(...myStories.map((s) => new Date(s.createdAt).getTime())),
          )
        : new Date();

    const myOwnerDto: StoryAuthorDto = {
      id: viewerId,
      username: myProfile?.username ?? null,
      displayName: myProfile?.profile?.displayName ?? myProfile?.username ?? 'You',
      avatarUrl: myProfile?.profile?.avatar?.url ?? null,
    };

    const myGroup: StoryFeedGroupDto = {
      owner: myOwnerDto,
      stories: myMappedStories,
      hasUnseen: myMappedStories.some((s) => !s.hasViewedByMe),
      latestStoryAt: myLatestStoryAt,
      totalStories: myMappedStories.length,
    };

    return [
      myGroup,
      ...unseenFollowed,
      ...unseenOthers,
      ...seenFollowed,
      ...seenOthers,
    ];
  }

  async getMyStories(userId: string): Promise<StoryResponseDto[]> {
    const stories = await this.storiesRepository.findMyActiveStories(userId);
    return stories.map((s) => this.mapToDto(s, userId));
  }

  async getStoryById(
    storyId: string,
    viewerId?: string,
  ): Promise<StoryResponseDto> {
    const story = await this.storiesRepository.findById(storyId, viewerId);
    if (!story || story.expiresAt < new Date()) {
      throw new NotFoundException('Story not found or has expired');
    }
    return this.mapToDto(story, viewerId);
  }

  async viewStory(
    storyId: string,
    viewerId: string,
  ): Promise<StoryResponseDto> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.expiresAt < new Date()) {
      throw new NotFoundException('Story has expired');
    }

    await this.storiesRepository.recordView(storyId, viewerId);
    const updated = await this.storiesRepository.findById(storyId, viewerId);
    return this.mapToDto(updated!, viewerId);
  }

  async addReaction(
    storyId: string,
    userId: string,
    reaction: ReactionType,
  ): Promise<StoryReactionResponseDto> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story || story.expiresAt < new Date()) {
      throw new NotFoundException('Story not found or has expired');
    }

    const rec = await this.storiesRepository.addReaction(
      storyId,
      userId,
      reaction,
    );

    return {
      storyId: rec.storyId,
      userId: rec.userId,
      reaction: rec.reaction,
      user: {
        id: rec.user.id,
        username: rec.user.username,
        displayName: rec.user.profile?.displayName ?? rec.user.username,
        avatarUrl: rec.user.profile?.avatar?.url ?? null,
      },
      createdAt: rec.createdAt,
    };
  }

  async removeReaction(
    storyId: string,
    userId: string,
  ): Promise<{ message: string }> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    await this.storiesRepository.removeReaction(storyId, userId);
    return { message: 'Reaction removed' };
  }

  async getViewers(
    storyId: string,
    requesterId: string,
  ): Promise<StoryViewerResponseDto[]> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== requesterId) {
      throw new ForbiddenException('Only the story author can view viewer analytics');
    }

    const viewers = await this.storiesRepository.findViewers(storyId);
    return viewers.map((v) => ({
      storyId: v.storyId,
      viewerId: v.viewerId,
      viewer: {
        id: v.viewer.id,
        username: v.viewer.username,
        displayName: v.viewer.profile?.displayName ?? v.viewer.username,
        avatarUrl: v.viewer.profile?.avatar?.url ?? null,
      },
      viewedAt: v.viewedAt,
    }));
  }

  async getReactions(
    storyId: string,
    requesterId: string,
  ): Promise<StoryReactionResponseDto[]> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== requesterId) {
      throw new ForbiddenException(
        'Only the story author can view reaction analytics',
      );
    }

    const reactions = await this.storiesRepository.findReactions(storyId);
    return reactions.map((r) => ({
      storyId: r.storyId,
      userId: r.userId,
      reaction: r.reaction,
      user: {
        id: r.user.id,
        username: r.user.username,
        displayName: r.user.profile?.displayName ?? r.user.username,
        avatarUrl: r.user.profile?.avatar?.url ?? null,
      },
      createdAt: r.createdAt,
    }));
  }

  async addComment(
    storyId: string,
    userId: string,
    content: string,
  ): Promise<StoryCommentResponseDto> {
    const story = await this.storiesRepository.findById(storyId);
    if (!story || story.expiresAt < new Date()) {
      throw new NotFoundException('Story not found or has expired');
    }

    const comment = await this.storiesRepository.addComment(
      storyId,
      userId,
      content,
    );

    return {
      id: comment.id,
      storyId: comment.storyId,
      content: comment.content,
      author: {
        id: comment.author.id,
        username: comment.author.username,
        displayName:
          comment.author.profile?.displayName ?? comment.author.username,
        avatarUrl: comment.author.profile?.avatar?.url ?? null,
      },
      createdAt: comment.createdAt,
    };
  }

  async getComments(storyId: string): Promise<StoryCommentResponseDto[]> {
    const comments = await this.storiesRepository.findComments(storyId);
    return comments.map((c) => ({
      id: c.id,
      storyId: c.storyId,
      content: c.content,
      author: {
        id: c.author.id,
        username: c.author.username,
        displayName: c.author.profile?.displayName ?? c.author.username,
        avatarUrl: c.author.profile?.avatar?.url ?? null,
      },
      createdAt: c.createdAt,
    }));
  }

  async deleteStory(storyId: string, userId: string) {
    const story = await this.storiesRepository.findById(storyId);
    if (!story) {
      throw new NotFoundException('Story not found');
    }

    if (story.authorId !== userId) {
      throw new ForbiddenException('You can only delete your own stories');
    }

    await this.storiesRepository.softDelete(storyId);
    return { message: 'Story deleted successfully' };
  }

  private sanitizeUrl(url: string | null | undefined): string | null {
    if (!url) return null;
    const RENDER_HOST = 'https://zikrekidusan.onrender.com';
    const LOCALHOST_PATTERNS = [
      /^http:\/\/localhost:\d+/,
      /^http:\/\/127\.0\.0\.1:\d+/,
      /^http:\/\/0\.0\.0\.0:\d+/,
      /^http:\/\/10\.0\.2\.2:\d+/,
    ];
    for (const pattern of LOCALHOST_PATTERNS) {
      if (pattern.test(url)) return url.replace(pattern, RENDER_HOST);
    }
    return url;
  }

  private mapToDto(s: any, viewerId?: string): StoryResponseDto {
    const hasViewedByMe = viewerId
      ? Array.isArray(s.views) && s.views.length > 0
      : false;

    const myReaction =
      viewerId && Array.isArray(s.reactions) && s.reactions.length > 0
        ? (s.reactions[0].reaction as ReactionType)
        : null;

    return {
      id: s.id,
      type: s.type,
      mediaUrl: this.sanitizeUrl(s.mediaUrl ?? s.file?.url ?? null),
      content: s.content,
      backgroundColor: s.backgroundColor,
      textColor: s.textColor,
      viewsCount: s.viewsCount ?? 0,
      reactionsCount: s.reactionsCount ?? 0,
      commentsCount: s.commentsCount ?? 0,
      hasViewedByMe,
      myReaction,
      author: {
        id: s.author.id,
        username: s.author.username,
        displayName: s.author.profile?.displayName ?? s.author.username,
        avatarUrl: this.sanitizeUrl(s.author.profile?.avatar?.url ?? null),
      },
      expiresAt: s.expiresAt,
      createdAt: s.createdAt,
    };
  }
}
