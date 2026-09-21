import {
  Controller,
  Get,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { AdminStorageService } from './services/admin-storage.service.js';

@ApiTags('Admin Storage')
@Controller('admin/storage')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(AppRole.SUPER_ADMIN, AppRole.ADMIN)
@ApiBearerAuth()
export class AdminStorageController {
  constructor(private readonly storageService: AdminStorageService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get aggregated storage utilization statistics' })
  async getStats() {
    return this.storageService.getStorageStats();
  }

  @Get('files')
  @ApiOperation({
    summary: 'List platform storage files with pagination and filters',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 20 })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'fileType', required: false })
  @ApiQuery({ name: 'provider', required: false })
  async getFiles(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('search') search?: string,
    @Query('fileType') fileType?: string,
    @Query('provider') provider?: string,
  ) {
    return this.storageService.listFiles({
      page,
      limit,
      search,
      fileType,
      provider,
    });
  }

  @Delete('files/:id')
  @ApiOperation({ summary: 'Delete file from storage' })
  async deleteFile(
    @Param('id') id: string,
    @CurrentUser('sub') actorId: string,
    @Body() body?: { reason?: string },
  ) {
    return this.storageService.deleteFile(id, actorId, body?.reason);
  }
}
