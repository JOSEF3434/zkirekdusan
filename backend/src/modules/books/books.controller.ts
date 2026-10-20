import 'multer';
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
  ParseIntPipe,
  DefaultValuePipe,
  ParseBoolPipe,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiConsumes } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { BooksService } from './books.service.js';
import { CreateBookCategoryDto } from './dto/create-book-category.dto.js';
import { UpdateBookCategoryDto } from './dto/update-book-category.dto.js';
import { CreateBookDto } from './dto/create-book.dto.js';
import { UpdateBookDto } from './dto/update-book.dto.js';
import { QueryBooksDto } from './dto/query-books.dto.js';
import { UpsertReadingProgressDto } from './dto/upsert-reading-progress.dto.js';
import { CreateBookBookmarkDto } from './dto/create-bookmark.dto.js';
import { UpsertReadingPrefsDto } from './dto/upsert-reading-prefs.dto.js';
import { CreateBookChapterDto, UpdateBookChapterDto } from './dto/create-book-chapter.dto.js';
import { UpdateBookDownloadSettingDto } from './dto/book-download-setting.dto.js';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../../common/guards/roles.guard.js';
import { PermissionsGuard } from '../../common/guards/permissions.guard.js';
import { Roles } from '../../common/decorators/roles.decorator.js';
import { Permissions } from '../../common/decorators/permissions.decorator.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { Public } from '../../common/decorators/public.decorator.js';
import { AppRole } from '../../common/constants/roles.js';
import { PERMISSIONS } from '../../common/constants/permissions.js';

// ── Public read controller (categories + published books listing, no auth) ──

@ApiTags('Books — Public')
@Controller('books')
@Public()
export class BooksPublicController {
  constructor(private readonly booksService: BooksService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List book categories (tree)' })
  listCategories() {
    return this.booksService.listCategories(false);
  }

  @Get('settings/download-destination')
  @ApiOperation({ summary: 'Get current book download destination setting' })
  getDownloadDestination() {
    return this.booksService.getDownloadDestinationSetting();
  }

  @Get()
  @ApiOperation({ summary: 'List published books (paginated)' })
  listBooks(@Query() query: QueryBooksDto) {
    return this.booksService.listBooks(query, false);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a published book detail' })
  getBook(@Param('id') id: string) {
    return this.booksService.getBook(id);
  }

  @Get(':id/chapters')
  @ApiOperation({ summary: 'Get chapter list for a book' })
  getChapters(@Param('id') id: string) {
    return this.booksService.getChapters(id, false);
  }

  @Get(':id/chapters/:order')
  @ApiOperation({ summary: 'Get chapter content by order index' })
  getChapterContent(@Param('id') id: string, @Param('order', ParseIntPipe) order: number) {
    return this.booksService.getChapterContent(id, order);
  }
}

// ── Authenticated user controller ───────────────────────────────────────────

@ApiTags('Books — User')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, PermissionsGuard)
@Controller('books')
export class BooksUserController {
  constructor(private readonly booksService: BooksService) {}

  @Get('me/recently-read')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get recently read books for current user' })
  getRecentlyRead(
    @CurrentUser('sub') userId: string,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.booksService.getRecentlyRead(userId, limit);
  }

  @Get(':id/with-auth')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get book detail with reading progress for authenticated user' })
  getBookAuthenticated(@Param('id') id: string, @CurrentUser('sub') userId: string) {
    return this.booksService.getBook(id, userId);
  }

  // ── Reading Progress ────────────────────────────────────────────────────

  @Get(':id/progress')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get my reading progress for a book' })
  getProgress(@CurrentUser('sub') userId: string, @Param('id') bookId: string) {
    return this.booksService.getProgress(userId, bookId);
  }

  @Post(':id/progress')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Save reading progress for a book' })
  upsertProgress(
    @CurrentUser('sub') userId: string,
    @Param('id') bookId: string,
    @Body() dto: UpsertReadingProgressDto,
  ) {
    return this.booksService.upsertProgress(userId, bookId, dto);
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────

  @Get('me/bookmarks')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get all my bookmarks (optionally filtered by book)' })
  getBookmarks(@CurrentUser('sub') userId: string, @Query('bookId') bookId?: string) {
    return this.booksService.getBookmarks(userId, bookId);
  }

  @Post(':id/bookmarks')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Add bookmark to a book' })
  createBookmark(
    @CurrentUser('sub') userId: string,
    @Param('id') bookId: string,
    @Body() dto: CreateBookBookmarkDto,
  ) {
    return this.booksService.createBookmark(userId, bookId, dto);
  }

  @Delete('bookmarks/:bookmarkId')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Remove a bookmark' })
  deleteBookmark(@CurrentUser('sub') userId: string, @Param('bookmarkId') bookmarkId: string) {
    return this.booksService.deleteBookmark(userId, bookmarkId);
  }

  // ── Reading Preferences ─────────────────────────────────────────────────

  @Get('me/preferences')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Get my reading preferences' })
  getPrefs(@CurrentUser('sub') userId: string) {
    return this.booksService.getReadingPrefs(userId);
  }

  @Post('me/preferences')
  @Permissions(PERMISSIONS.BOOKS.VIEW)
  @ApiOperation({ summary: 'Save my reading preferences' })
  upsertPrefs(@CurrentUser('sub') userId: string, @Body() dto: UpsertReadingPrefsDto) {
    return this.booksService.upsertReadingPrefs(userId, dto);
  }

  // ── Download info ───────────────────────────────────────────────────────

  @Get(':id/download-info')
  @Permissions(PERMISSIONS.BOOKS.DOWNLOAD)
  @ApiOperation({ summary: 'Get authorized download URLs for a book' })
  getDownloadInfo(@CurrentUser('sub') userId: string, @Param('id') bookId: string) {
    return this.booksService.getDownloadInfo(userId, bookId);
  }
}

// ── Admin controller ────────────────────────────────────────────────────────

@ApiTags('Books — Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Controller('books')
export class BooksAdminController {
  constructor(private readonly booksService: BooksService) {}

  // Categories

  @Get('admin/categories')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_CATEGORIES)
  @ApiOperation({ summary: 'List all categories including archived (admin)' })
  listAllCategories(@Query('includeArchived', new DefaultValuePipe(false), ParseBoolPipe) includeArchived: boolean) {
    return this.booksService.listCategories(includeArchived);
  }

  @Post('admin/categories')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_CATEGORIES)
  @ApiOperation({ summary: 'Create a book category (admin)' })
  createCategory(@CurrentUser('sub') userId: string, @Body() dto: CreateBookCategoryDto) {
    return this.booksService.createCategory(userId, dto);
  }

  @Patch('admin/categories/:id')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_CATEGORIES)
  @ApiOperation({ summary: 'Update a book category (admin)' })
  updateCategory(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateBookCategoryDto,
  ) {
    return this.booksService.updateCategory(userId, id, dto);
  }

  @Delete('admin/categories/:id')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_CATEGORIES)
  @ApiOperation({ summary: 'Archive a book category (admin)' })
  deleteCategory(
    @Param('id') id: string,
    @Query('reassignCategoryId') reassignCategoryId?: string,
  ) {
    return this.booksService.deleteCategory(id, reassignCategoryId);
  }

  // Uploads

  @Post('admin/upload-cover')
  @Permissions(PERMISSIONS.BOOKS.CREATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a book cover image (admin)' })
  uploadCover(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.booksService.uploadCover(userId, file);
  }

  @Post('admin/upload-content')
  @Permissions(PERMISSIONS.BOOKS.CREATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a book content file (PDF, EPUB, Audio, etc.) (admin)' })
  uploadContent(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.booksService.uploadContent(userId, file);
  }

  @Post('admin/upload-attachment')
  @Permissions(PERMISSIONS.BOOKS.CREATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a book media attachment (admin)' })
  uploadAttachment(
    @CurrentUser('sub') userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.booksService.uploadAttachment(userId, file);
  }

  @Get('admin/settings/download-destination')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LIBRARY)
  @ApiOperation({ summary: 'Get book download destination setting (admin)' })
  getAdminDownloadDestination() {
    return this.booksService.getDownloadDestinationSetting();
  }

  @Patch('admin/settings/download-destination')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LIBRARY)
  @ApiOperation({ summary: 'Update book download destination setting (admin)' })
  updateDownloadDestination(
    @CurrentUser('sub') userId: string,
    @Body() dto: UpdateBookDownloadSettingDto,
  ) {
    return this.booksService.updateDownloadDestinationSetting(userId, dto);
  }

  // Books

  @Get('admin/list')
  @Permissions(PERMISSIONS.BOOKS.MANAGE_LIBRARY)
  @ApiOperation({ summary: 'List all books including drafts (admin)' })
  listBooksAdmin(@Query() query: QueryBooksDto) {
    return this.booksService.listBooks(query, true);
  }

  @Post('admin')
  @Permissions(PERMISSIONS.BOOKS.CREATE)
  @ApiOperation({ summary: 'Create a book (admin)' })
  createBook(@CurrentUser('sub') userId: string, @Body() dto: CreateBookDto) {
    return this.booksService.createBook(userId, dto);
  }

  @Patch('admin/:id')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Update a book (admin)' })
  updateBook(
    @CurrentUser('sub') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateBookDto,
  ) {
    return this.booksService.updateBook(userId, id, dto);
  }

  @Post('admin/:id/publish')
  @Permissions(PERMISSIONS.BOOKS.PUBLISH)
  @ApiOperation({ summary: 'Publish a book (admin)' })
  publishBook(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.booksService.publishBook(userId, id);
  }

  @Post('admin/:id/unpublish')
  @Permissions(PERMISSIONS.BOOKS.PUBLISH)
  @ApiOperation({ summary: 'Unpublish a book to draft (admin)' })
  unpublishBook(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.booksService.unpublishBook(userId, id);
  }

  @Post('admin/:id/archive')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Archive a book (admin)' })
  archiveBook(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.booksService.archiveBook(userId, id);
  }

  @Post('admin/:id/restore')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Restore an archived/deleted book (admin)' })
  restoreBook(@CurrentUser('sub') userId: string, @Param('id') id: string) {
    return this.booksService.restoreBook(userId, id);
  }

  @Delete('admin/:id')
  @Permissions(PERMISSIONS.BOOKS.DELETE)
  @ApiOperation({ summary: 'Soft-delete or permanently delete a book (admin)' })
  deleteBook(
    @Param('id') id: string,
    @Query('permanent', new DefaultValuePipe(false), ParseBoolPipe) permanent: boolean,
  ) {
    return this.booksService.deleteBook(id, permanent);
  }

  // Chapters

  @Get('admin/:id/chapters')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'List all chapters including unpublished (admin)' })
  getChaptersAdmin(@Param('id') id: string) {
    return this.booksService.getChapters(id, true);
  }

  @Post('admin/:id/chapters')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Create a chapter for a book (admin)' })
  createChapter(@Param('id') bookId: string, @Body() dto: CreateBookChapterDto) {
    return this.booksService.createChapter(bookId, dto);
  }

  @Patch('admin/:id/chapters/:chapterId')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Update a chapter (admin)' })
  updateChapter(
    @Param('id') bookId: string,
    @Param('chapterId') chapterId: string,
    @Body() dto: UpdateBookChapterDto,
  ) {
    return this.booksService.updateChapter(bookId, chapterId, dto);
  }

  @Delete('admin/:id/chapters/:chapterId')
  @Permissions(PERMISSIONS.BOOKS.UPDATE)
  @ApiOperation({ summary: 'Delete a chapter (admin)' })
  deleteChapter(@Param('id') bookId: string, @Param('chapterId') chapterId: string) {
    return this.booksService.deleteChapter(bookId, chapterId);
  }
}

