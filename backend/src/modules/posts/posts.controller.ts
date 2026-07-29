// src/modules/posts/posts.controller.ts
import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PostsService } from './posts.service.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { UpdatePostDto } from './dto/update-post.dto.js';
import { PostResponseDto } from './dto/post-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';

@ApiTags('Posts')
@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new post (text, image, video, carousel)' })
  @ApiResponse({ status: 201, type: PostResponseDto })
  async createPost(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreatePostDto,
  ): Promise<PostResponseDto> {
    return this.postsService.createPost(userId, dto);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get posts feed with optional filtering by author, group, or hashtag' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'authorId', required: false })
  @ApiQuery({ name: 'groupId', required: false })
  @ApiQuery({ name: 'hashtag', required: false })
  async getFeed(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('authorId') authorId?: string,
    @Query('groupId') groupId?: string,
    @Query('hashtag') hashtag?: string,
  ) {
    return this.postsService.getFeed(page, limit, authorId, groupId, hashtag);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get post by ID' })
  @ApiResponse({ status: 200, type: PostResponseDto })
  async getPostById(@Param('id') id: string): Promise<PostResponseDto> {
    return this.postsService.getPostById(id);
  }

  @Patch(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update post (author only)' })
  @ApiResponse({ status: 200, type: PostResponseDto })
  async updatePost(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdatePostDto,
  ): Promise<PostResponseDto> {
    return this.postsService.updatePost(id, userId, dto);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Soft delete post (author only)' })
  @ApiResponse({ status: 200, description: 'Post deleted successfully' })
  async deletePost(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.postsService.deletePost(id, userId);
  }
}
