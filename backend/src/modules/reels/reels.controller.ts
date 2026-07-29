// src/modules/reels/reels.controller.ts
import {
  Body,
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
import { ReelsService } from './reels.service.js';
import { CreateReelDto } from './dto/create-reel.dto.js';
import { ReelResponseDto } from './dto/reel-response.dto.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';

@ApiTags('Reels (Short-form Videos)')
@Controller('reels')
export class ReelsController {
  constructor(private readonly reelsService: ReelsService) {}

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Publish a short-form video reel' })
  @ApiResponse({ status: 201, type: ReelResponseDto })
  async createReel(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateReelDto,
  ): Promise<ReelResponseDto> {
    return this.reelsService.createReel(userId, dto);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get reels feed' })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'authorId', required: false })
  async getReelsFeed(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('authorId') authorId?: string,
  ) {
    return this.reelsService.getReelsFeed(page, limit, authorId);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get reel by ID' })
  @ApiResponse({ status: 200, type: ReelResponseDto })
  async getReelById(@Param('id') id: string): Promise<ReelResponseDto> {
    return this.reelsService.getReelById(id);
  }

  @Delete(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete reel (author only)' })
  @ApiResponse({ status: 200, description: 'Reel deleted' })
  async deleteReel(
    @Param('id') id: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.reelsService.deleteReel(id, userId);
  }
}
