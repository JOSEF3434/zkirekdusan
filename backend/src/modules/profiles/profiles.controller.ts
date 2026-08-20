// src/modules/profiles/profiles.controller.ts
import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Query,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { ProfilesService } from './profiles.service.js';
import { PostsService } from '../posts/posts.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';
import { ProfileResponseDto } from './dto/profile-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';

@ApiTags('Profiles')
@ApiBearerAuth()
@Controller('profiles')
export class ProfilesController {
  constructor(
    private readonly profilesService: ProfilesService,
    private readonly postsService: PostsService,
  ) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, type: ProfileResponseDto })
  async getMyProfile(
    @CurrentUser('sub') userId: string,
  ): Promise<ProfileResponseDto> {
    return this.profilesService.getMyProfile(userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({ status: 200, type: ProfileResponseDto })
  async updateMyProfile(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateProfileDto,
  ): Promise<ProfileResponseDto> {
    return this.profilesService.updateMyProfile(userId, dto);
  }

  @Public()
  @Get(':userId/posts')
  @ApiOperation({ summary: 'Get posts for a user profile (newest first)' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getUserPosts(
    @Param('userId') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.postsService.getFeed(page, limit, userId);
  }

  @Public()
  @Get(':username')
  @ApiOperation({ summary: 'Get public user profile by username' })
  @ApiResponse({ status: 200, type: ProfileResponseDto })
  @ApiResponse({ status: 404, description: 'Profile not found' })
  async getByUsername(
    @Param('username') username: string,
    @CurrentUser('sub') viewerId?: string,
  ): Promise<ProfileResponseDto> {
    return this.profilesService.getProfileByUsername(username, viewerId);
  }
}
