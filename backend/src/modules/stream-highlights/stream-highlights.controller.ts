import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { StreamHighlightsService } from './stream-highlights.service.js';

@ApiTags('Live Streaming - Highlights')
@Controller('live-streams/:streamId/highlights')
export class StreamHighlightsController {
  constructor(private readonly highlightsService: StreamHighlightsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a stream highlight' })
  async createHighlight(
    @CurrentUser('sub') userId: string,
    @Param('streamId') streamId: string,
    @Body()
    body: {
      title: string;
      description?: string;
      startTimeSec: number;
      endTimeSec: number;
    },
  ) {
    return this.highlightsService.createHighlight(userId, streamId, body);
  }

  @Get()
  @ApiOperation({ summary: 'Get highlights for a stream' })
  async getHighlights(@Param('streamId') streamId: string) {
    return this.highlightsService.getHighlights(streamId);
  }

  @Delete(':highlightId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a stream highlight' })
  async deleteHighlight(
    @CurrentUser('sub') userId: string,
    @Param('highlightId') highlightId: string,
  ) {
    await this.highlightsService.deleteHighlight(userId, highlightId);
  }
}
