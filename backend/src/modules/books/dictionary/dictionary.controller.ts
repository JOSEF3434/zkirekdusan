// src/modules/books/dictionary/dictionary.controller.ts
import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  DefaultValuePipe,
  ParseBoolPipe,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { DictionaryService } from './dictionary.service.js';
import { CreateDictionaryLanguageDto } from './dto/create-dictionary-language.dto.js';
import { UpdateDictionaryLanguageDto } from './dto/update-dictionary-language.dto.js';
import { UpdateDictionaryConfigDto } from './dto/update-dictionary-config.dto.js';
import { TranslateWordDto } from './dto/translate-word.dto.js';
import { SaveTranslationHistoryDto } from './dto/save-translation-history.dto.js';
import { QueryTranslationHistoryDto } from './dto/query-translation-history.dto.js';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../../common/guards/permissions.guard.js';
import { Permissions } from '../../../common/decorators/permissions.decorator.js';
import { Roles } from '../../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../../common/constants/roles.js';
import { PERMISSIONS } from '../../../common/constants/permissions.js';

// ── Administrator Dictionary Controller ─────────────────────────────────────

@ApiTags('Books — Dictionary Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller('books/dictionaries')
export class DictionaryAdminController {
  constructor(private readonly dictionaryService: DictionaryService) {}

  @Get('admin')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LIBRARY)
  @ApiOperation({ summary: 'List all dictionaries including drafts and processing (admin)' })
  listDictionariesAdmin(@CurrentUser('sub') userId: string) {
    return this.dictionaryService.listDictionariesAdmin(userId);
  }

  @Post(':bookId/process')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.CREATE)
  @ApiOperation({ summary: 'Trigger asynchronous dictionary extraction & indexing (admin)' })
  processDictionary(
    @CurrentUser('sub') userId: string,
    @Param('bookId') bookId: string,
  ) {
    return this.dictionaryService.triggerProcessing(userId, bookId);
  }

  @Get(':bookId/status')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LIBRARY)
  @ApiOperation({ summary: 'Get dictionary processing status & statistics (admin)' })
  getStatus(
    @CurrentUser('sub') userId: string,
    @Param('bookId') bookId: string,
  ) {
    return this.dictionaryService.getStatus(userId, bookId);
  }

  @Patch(':bookId/config')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Update dictionary configuration & language pairs (admin)' })
  updateConfig(
    @CurrentUser('sub') userId: string,
    @Param('bookId') bookId: string,
    @Body() dto: UpdateDictionaryConfigDto,
  ) {
    return this.dictionaryService.updateConfig(userId, bookId, dto);
  }

  @Post(':bookId/publish')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.PUBLISH)
  @ApiOperation({ summary: 'Publish ready dictionary to library (admin)' })
  publishDictionary(
    @CurrentUser('sub') userId: string,
    @Param('bookId') bookId: string,
  ) {
    return this.dictionaryService.publishDictionary(userId, bookId);
  }

  @Post(':bookId/unpublish')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.PUBLISH)
  @ApiOperation({ summary: 'Unpublish dictionary back to draft (admin)' })
  unpublishDictionary(
    @CurrentUser('sub') userId: string,
    @Param('bookId') bookId: string,
  ) {
    return this.dictionaryService.unpublishDictionary(userId, bookId);
  }

  // ── Language Management (Admin) ──

  @Get('languages/all')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LANGUAGES)
  @ApiOperation({ summary: 'List all dictionary languages including disabled (admin)' })
  listLanguagesAdmin(
    @Query('includeDisabled', new DefaultValuePipe(true), ParseBoolPipe) includeDisabled: boolean,
  ) {
    return this.dictionaryService.listLanguages(includeDisabled);
  }

  @Post('languages')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LANGUAGES)
  @ApiOperation({ summary: 'Create a new dictionary language (admin)' })
  createLanguage(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateDictionaryLanguageDto,
  ) {
    return this.dictionaryService.createLanguage(userId, dto);
  }

  @Patch('languages/:id')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LANGUAGES)
  @ApiOperation({ summary: 'Update a dictionary language (admin)' })
  updateLanguage(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateDictionaryLanguageDto,
  ) {
    return this.dictionaryService.updateLanguage(userId, id, dto);
  }

  @Delete('languages/:id')
  @Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LANGUAGES)
  @ApiOperation({ summary: 'Delete a dictionary language if unused (admin)' })
  deleteLanguage(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.dictionaryService.deleteLanguage(userId, id);
  }
}

// ── Regular User Dictionary Controller ──────────────────────────────────────

@ApiTags('Books — Dictionary User')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('books/dictionaries')
export class DictionaryUserController {
  constructor(private readonly dictionaryService: DictionaryService) {}

  @Get('available')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'List available published & ready dictionaries (user)' })
  listAvailable() {
    return this.dictionaryService.listAvailableDictionaries();
  }

  @Get('languages/available')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'List available enabled dictionary languages (user)' })
  listAvailableLanguages() {
    return this.dictionaryService.listLanguages(false);
  }

  @Get(':bookId/search')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Search words inside a published dictionary (user)' })
  searchDictionary(
    @Param('bookId') bookId: string,
    @Query('word') word: string,
  ) {
    return this.dictionaryService.searchDictionary(bookId, word);
  }

  @Post('translate')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Translate a word using available dictionaries (user)' })
  translate(@Body() dto: TranslateWordDto) {
    return this.dictionaryService.translate(dto);
  }

  // ── Translation History ──

  @Post('history')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Save word translation to personal history (user)' })
  saveHistory(
    @CurrentUser('sub') userId: string,
    @Body() dto: SaveTranslationHistoryDto,
  ) {
    return this.dictionaryService.saveHistory(userId, dto);
  }

  @Get('history')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get my personal translation history (user)' })
  getHistory(
    @CurrentUser('sub') userId: string,
    @Query() query: QueryTranslationHistoryDto,
  ) {
    return this.dictionaryService.getHistory(userId, query);
  }

  @Delete('history/:id')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Delete a single translation history item (user)' })
  deleteHistoryItem(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
  ) {
    return this.dictionaryService.deleteHistoryItem(userId, id);
  }

  @Delete('history')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Clear all personal translation history (user)' })
  clearHistory(@CurrentUser('sub') userId: string) {
    return this.dictionaryService.clearHistory(userId);
  }
}

