// src/modules/saved-posts/saved-posts.controller.ts
import {
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { SavedPostsService } from './saved-posts.service.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';

@ApiTags('Saved Posts')
@ApiBearerAuth()
@Controller('posts')
export class SavedPostsController {
  constructor(private readonly savedPostsService: SavedPostsService) {}

  @Post(':id/save')
  @ApiOperation({ summary: 'Toggle save/bookmark a post' })
  @ApiResponse({ status: 200, description: 'Post save toggled' })
  async toggleSavePost(
    @Param('id') postId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.savedPostsService.toggleSavePost(userId, postId);
  }

  @Get('saved/my')
  @ApiOperation({
    summary: 'List saved posts for the current authenticated user',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  async getMySavedPosts(
    @CurrentUser('sub') userId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.savedPostsService.getSavedPosts(userId, page, limit);
  }
}
