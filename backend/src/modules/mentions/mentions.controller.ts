// src/modules/mentions/mentions.controller.ts
import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { MentionsService } from './mentions.service.js';
import { MentionQueryDto } from './dto/mention-suggestion.dto.js';

@ApiTags('Mentions')
@ApiBearerAuth()
@Controller('mentions')
export class MentionsController {
  constructor(private readonly mentionsService: MentionsService) {}

  /**
   * GET /api/mentions/suggest?q=abc&limit=10
   * Combined users + groups + channels for @ autocomplete.
   */
  @Get('suggest')
  @ApiOperation({ summary: 'Autocomplete @ mentions (users, groups, channels)' })
  async suggest(
    @Query() dto: MentionQueryDto,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.mentionsService.suggestAll(dto, userId);
  }

  /**
   * GET /api/mentions/users?q=abc&limit=10
   */
  @Get('users')
  @ApiOperation({ summary: 'Autocomplete user mentions' })
  async users(
    @Query() dto: MentionQueryDto,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.mentionsService.suggestUsers(dto, userId);
  }

  /**
   * GET /api/mentions/groups?q=abc&limit=10
   */
  @Get('groups')
  @ApiOperation({ summary: 'Autocomplete group mentions' })
  async groups(
    @Query() dto: MentionQueryDto,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.mentionsService.suggestGroups(dto, userId);
  }

  /**
   * GET /api/mentions/channels?q=abc&limit=10
   */
  @Get('channels')
  @ApiOperation({ summary: 'Autocomplete channel mentions' })
  async channels(
    @Query() dto: MentionQueryDto,
    @CurrentUser('sub') userId?: string,
  ) {
    return this.mentionsService.suggestChannels(dto, userId);
  }
}
