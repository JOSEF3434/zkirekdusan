// src/modules/alephat/alephat.controller.ts
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
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AlephatService } from './alephat.service.js';
import { CreateAlephatLetterDto } from './dto/create-alephat-letter.dto.js';
import { UpdateAlephatLetterDto } from './dto/update-alephat-letter.dto.js';
import { CreateFamilyMemberDto } from './dto/create-family-member.dto.js';
import { UpdateFamilyMemberDto } from './dto/update-family-member.dto.js';
import { ReorderItemsDto } from './dto/reorder-items.dto.js';
import { CreateAlephat22Dto } from './dto/create-alephat-22.dto.js';
import { UpdateAlephat22Dto } from './dto/update-alephat-22.dto.js';
import { QueryAlephatDto } from './dto/query-alephat.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';

@ApiTags('Alephat — Amharic Alphabet Learning & Reference')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller('alephat')
export class AlephatController {
  constructor(private readonly alephatService: AlephatService) {}

  // ─────────────────────────────────────────────────────────
  // TAB 1: Letters & Families
  // ─────────────────────────────────────────────────────────

  @Get('letters')
  @Permissions(PERMISSIONS.ALEPHAT.VIEW)
  @ApiOperation({ summary: 'List published or all base letters with families' })
  findAllLetters(@Query() query: QueryAlephatDto) {
    return this.alephatService.findAllLetters(query);
  }

  @Get('letters/:id')
  @Permissions(PERMISSIONS.ALEPHAT.VIEW)
  @ApiOperation({ summary: 'Get a single base letter with its family members' })
  findLetterById(
    @Param('id') id: string,
    @Query('includeUnpublished') includeUnpublished?: boolean,
  ) {
    return this.alephatService.findLetterById(id, includeUnpublished);
  }

  @Post('letters')
  @Permissions(PERMISSIONS.ALEPHAT.CREATE)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new base letter with optional family members' })
  createLetter(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateAlephatLetterDto,
  ) {
    return this.alephatService.createLetter(userId, dto);
  }

  @Patch('letters/:id')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @ApiOperation({ summary: 'Update a base letter' })
  updateLetter(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateAlephatLetterDto,
  ) {
    return this.alephatService.updateLetter(userId, id, dto);
  }

  @Delete('letters/:id')
  @Permissions(PERMISSIONS.ALEPHAT.DELETE)
  @ApiOperation({ summary: 'Delete a base letter and its family members' })
  deleteLetter(@Param('id') id: string) {
    return this.alephatService.deleteLetter(id);
  }

  @Post('letters/reorder')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder base letters' })
  reorderLetters(@Body() dto: ReorderItemsDto) {
    return this.alephatService.reorderLetters(dto);
  }

  // ── Family Members Sub-routes ────────────────────────────

  @Post('letters/:id/family')
  @Permissions(PERMISSIONS.ALEPHAT.CREATE)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a family member to a base letter' })
  addFamilyMember(
    @Param('id') letterId: string,
    @Body() dto: CreateFamilyMemberDto,
  ) {
    return this.alephatService.addFamilyMember(letterId, dto);
  }

  @Patch('letters/:id/family/:memberId')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @ApiOperation({ summary: 'Update a family member' })
  updateFamilyMember(
    @Param('id') letterId: string,
    @Param('memberId') memberId: string,
    @Body() dto: UpdateFamilyMemberDto,
  ) {
    return this.alephatService.updateFamilyMember(letterId, memberId, dto);
  }

  @Delete('letters/:id/family/:memberId')
  @Permissions(PERMISSIONS.ALEPHAT.DELETE)
  @ApiOperation({ summary: 'Delete a family member' })
  deleteFamilyMember(
    @Param('id') letterId: string,
    @Param('memberId') memberId: string,
  ) {
    return this.alephatService.deleteFamilyMember(letterId, memberId);
  }

  @Post('letters/:id/family/reorder')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder family members of a letter' })
  reorderFamilyMembers(
    @Param('id') letterId: string,
    @Body() dto: ReorderItemsDto,
  ) {
    return this.alephatService.reorderFamilyMembers(letterId, dto);
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2: 22 Alephats Reference Section
  // ─────────────────────────────────────────────────────────

  @Get('22')
  @Permissions(PERMISSIONS.ALEPHAT.VIEW)
  @ApiOperation({ summary: 'List 22 Alephats entries' })
  findAll22(@Query() query: QueryAlephatDto) {
    return this.alephatService.findAll22(query);
  }

  @Get('22/:id')
  @Permissions(PERMISSIONS.ALEPHAT.VIEW)
  @ApiOperation({ summary: 'Get a single 22 Alephat entry' })
  find22ById(
    @Param('id') id: string,
    @Query('includeUnpublished') includeUnpublished?: boolean,
  ) {
    return this.alephatService.find22ById(id, includeUnpublished);
  }

  @Post('22')
  @Permissions(PERMISSIONS.ALEPHAT.CREATE)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new 22 Alephat entry' })
  create22(
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateAlephat22Dto,
  ) {
    return this.alephatService.create22(userId, dto);
  }

  @Patch('22/:id')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @ApiOperation({ summary: 'Update a 22 Alephat entry' })
  update22(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateAlephat22Dto,
  ) {
    return this.alephatService.update22(userId, id, dto);
  }

  @Delete('22/:id')
  @Permissions(PERMISSIONS.ALEPHAT.DELETE)
  @ApiOperation({ summary: 'Delete a 22 Alephat entry' })
  delete22(@Param('id') id: string) {
    return this.alephatService.delete22(id);
  }

  @Post('22/reorder')
  @Permissions(PERMISSIONS.ALEPHAT.UPDATE)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder 22 Alephat entries' })
  reorder22(@Body() dto: ReorderItemsDto) {
    return this.alephatService.reorder22(dto);
  }

  // ── Seed Endpoint for Admin / Setup ──────────────────────

  @Post('seed-defaults')
  @Permissions(PERMISSIONS.ALEPHAT.CREATE)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Idempotently re-seed default base letters and 22 Alephats if empty' })
  seedDefaults(@CurrentUser('sub') userId: string) {
    return this.alephatService.ensureInitialSeed(userId);
  }
}
