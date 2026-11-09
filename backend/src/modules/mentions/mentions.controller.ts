// src/modules/mentions/mentions.controller.ts
import {
  Controller,
  Get,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { MentionsService } from './mentions.service.js';
import { MentionQueryDto } from './dto/mention-suggestion.dto.js';

@ApiTags('Mentions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('mentions')
export class MentionsController {
  constructor(private readonly mentionsService: MentionsService) {}

  /**
   * GET /api/mentions/suggest?q=abc&limit=8
   * Combined users + groups + channels for @ autocomplete.
   */
  @Get('suggest')
  @ApiOperation({ summary: 'Autocomplete @ mentions (users, groups, channels)' })
  async suggest(@Query() dto: MentionQueryDto, @Request() req: any) {
    return this.mentionsService.suggestAll(dto, req.user?.sub);
  }

  /**
   * GET /api/mentions/users?q=abc&limit=8
   * User-only suggestions.
   */
  @Get('users')
  @ApiOperation({ summary: 'Autocomplete user mentions' })
  async users(@Query() dto: MentionQueryDto, @Request() req: any) {
    return this.mentionsService.suggestUsers(dto, req.user?.sub);
  }

  /**
   * GET /api/mentions/groups?q=abc&limit=8
   */
  @Get('groups')
  @ApiOperation({ summary: 'Autocomplete group mentions' })
  async groups(@Query() dto: MentionQueryDto) {
    return this.mentionsService.suggestGroups(dto);
  }

  /**
   * GET /api/mentions/channels?q=abc&limit=8
   */
  @Get('channels')
  @ApiOperation({ summary: 'Autocomplete channel mentions' })
  async channels(@Query() dto: MentionQueryDto) {
    return this.mentionsService.suggestChannels(dto);
  }
}
