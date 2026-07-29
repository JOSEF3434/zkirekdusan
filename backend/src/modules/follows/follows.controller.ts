// src/modules/follows/follows.controller.ts
import {
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { FollowsService } from './follows.service.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { FollowStatusDto } from './dto/follow-response.dto.js';

@ApiTags('Follows')
@ApiBearerAuth()
@Controller('users')
export class FollowsController {
  constructor(private readonly followsService: FollowsService) {}

  @Post(':userId/follow')
  @ApiOperation({ summary: 'Follow a user' })
  @ApiResponse({ status: 201, description: 'User followed successfully' })
  async followUser(
    @Param('userId') targetUserId: string,
    @CurrentUser('sub') currentUserId: string,
  ) {
    return this.followsService.followUser(currentUserId, targetUserId);
  }

  @Delete(':userId/follow')
  @ApiOperation({ summary: 'Unfollow a user' })
  @ApiResponse({ status: 200, description: 'User unfollowed successfully' })
  async unfollowUser(
    @Param('userId') targetUserId: string,
    @CurrentUser('sub') currentUserId: string,
  ) {
    return this.followsService.unfollowUser(currentUserId, targetUserId);
  }

  @Get(':userId/followers')
  @ApiOperation({ summary: 'List followers of a user' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getFollowers(
    @Param('userId') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.followsService.getFollowers(userId, page, limit);
  }

  @Get(':userId/following')
  @ApiOperation({ summary: 'List users a user is following' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getFollowing(
    @Param('userId') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.followsService.getFollowing(userId, page, limit);
  }

  @Get(':userId/follow-status')
  @ApiOperation({ summary: 'Check mutual follow status between current user and target user' })
  @ApiResponse({ status: 200, type: FollowStatusDto })
  async getFollowStatus(
    @Param('userId') targetUserId: string,
    @CurrentUser('sub') currentUserId: string,
  ) {
    return this.followsService.getFollowStatus(currentUserId, targetUserId);
  }
}
