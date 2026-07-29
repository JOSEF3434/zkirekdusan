// src/modules/likes/likes.controller.ts
import { Body, Controller, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { LikesService } from './likes.service.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { LikeRequestDto } from './dto/like-request.dto.js';

@ApiTags('Likes & Reactions')
@ApiBearerAuth()
@Controller()
export class LikesController {
  constructor(private readonly likesService: LikesService) {}

  @Post('posts/:postId/like')
  @ApiOperation({ summary: 'Toggle like/reaction on a post' })
  @ApiResponse({ status: 200, description: 'Post like toggled' })
  async togglePostLike(
    @Param('postId') postId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: LikeRequestDto,
  ) {
    return this.likesService.togglePostLike(userId, postId, dto.reaction);
  }

  @Post('reels/:reelId/like')
  @ApiOperation({ summary: 'Toggle like/reaction on a reel' })
  @ApiResponse({ status: 200, description: 'Reel like toggled' })
  async toggleReelLike(
    @Param('reelId') reelId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: LikeRequestDto,
  ) {
    return this.likesService.toggleReelLike(userId, reelId, dto.reaction);
  }

  @Post('comments/:commentId/like')
  @ApiOperation({ summary: 'Toggle like on a comment' })
  @ApiResponse({ status: 200, description: 'Comment like toggled' })
  async toggleCommentLike(
    @Param('commentId') commentId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.likesService.toggleCommentLike(userId, commentId);
  }
}
