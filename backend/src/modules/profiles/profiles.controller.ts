// src/modules/profiles/profiles.controller.ts
import 'multer';
import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
  ApiConsumes,
  ApiBody,
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

  @Post('me/avatar')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload avatar for current user profile' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiResponse({ status: 200, type: ProfileResponseDto })
  async uploadAvatar(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<ProfileResponseDto> {
    return this.profilesService.uploadAvatar(userId, file);
  }

  @Post('me/cover')
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload cover for current user profile' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiResponse({ status: 200, type: ProfileResponseDto })
  async uploadCover(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ): Promise<ProfileResponseDto> {
    return this.profilesService.uploadCover(userId, file);
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
