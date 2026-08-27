// src/modules/profiles/profiles.service.ts
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { ProfilesRepository } from './profiles.repository.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { ProfileResponseDto } from './dto/profile-response.dto.js';
import { UploadsService } from '../uploads/uploads.service.js';

@Injectable()
export class ProfilesService {
  constructor(
    private readonly profilesRepository: ProfilesRepository,
    private readonly uploadsService: UploadsService,
  ) {}

  async getProfileByUsername(
    username: string,
    viewerId?: string,
  ): Promise<ProfileResponseDto> {
    const profile = await this.profilesRepository.findByUsername(username);
    if (!profile) {
      throw new NotFoundException(
        `Profile for username '${username}' not found`,
      );
    }

    // Check visibility permissions
    if (profile.visibility === 'PRIVATE' && profile.userId !== viewerId) {
      throw new ForbiddenException('This profile is private');
    }

    const stats = await this.profilesRepository.getProfileStats(profile.userId);

    return {
      id: profile.id,
      userId: profile.userId,
      username: profile.user.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      displayName: profile.displayName ?? profile.user.username,
      bio: profile.bio,
      website: profile.website,
      country: profile.country,
      visibility: profile.visibility,
      isVerified: profile.isVerified,
      avatarUrl: profile.avatar?.url ?? null,
      coverUrl: profile.cover?.url ?? null,
      stats,
      createdAt: profile.createdAt,
    };
  }

  async getMyProfile(userId: string): Promise<ProfileResponseDto> {
    const profile = await this.profilesRepository.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const stats = await this.profilesRepository.getProfileStats(userId);

    return {
      id: profile.id,
      userId: profile.userId,
      username: profile.user.username,
      firstName: profile.firstName,
      lastName: profile.lastName,
      displayName: profile.displayName ?? profile.user.username,
      bio: profile.bio,
      website: profile.website,
      country: profile.country,
      visibility: profile.visibility,
      isVerified: profile.isVerified,
      avatarUrl: profile.avatar?.url ?? null,
      coverUrl: profile.cover?.url ?? null,
      stats,
      createdAt: profile.createdAt,
    };
  }

  async updateMyProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<ProfileResponseDto> {
    await this.profilesRepository.update(userId, dto);
    return this.getMyProfile(userId);
  }

  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<ProfileResponseDto> {
    await this.uploadsService.uploadUserAvatar(userId, file);
    return this.getMyProfile(userId);
  }

  async uploadCover(userId: string, file: Express.Multer.File): Promise<ProfileResponseDto> {
    await this.uploadsService.uploadUserCover(userId, file);
    return this.getMyProfile(userId);
  }
}
