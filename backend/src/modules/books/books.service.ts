// src/modules/books/books.service.ts
import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateBookCategoryDto } from './dto/create-book-category.dto.js';
import { UpdateBookCategoryDto } from './dto/update-book-category.dto.js';
import { CreateBookDto } from './dto/create-book.dto.js';
import { UpdateBookDto } from './dto/update-book.dto.js';
import { QueryBooksDto } from './dto/query-books.dto.js';
import { UpsertReadingProgressDto } from './dto/upsert-reading-progress.dto.js';
import { CreateBookBookmarkDto } from './dto/create-bookmark.dto.js';
import { UpsertReadingPrefsDto } from './dto/upsert-reading-prefs.dto.js';
import { CreateBookChapterDto, UpdateBookChapterDto } from './dto/create-book-chapter.dto.js';
import { BookStatus, Prisma } from '@prisma/client';

// ── Selects (shared projection shapes) ─────────────────────────────────────

const CATEGORY_SELECT = {
  id: true,
  name: true,
  nameAm: true,
  nameGez: true,
  description: true,
  slug: true,
  parentId: true,
  sortOrder: true,
  isVisible: true,
  isArchived: true,
  iconName: true,
  coverUrl: true,
  createdAt: true,
  updatedAt: true,
} as const;

const BOOK_LIST_SELECT = {
  id: true,
  title: true,
  titleAm: true,
  titleGez: true,
  subtitle: true,
  author: true,
  language: true,
  format: true,
  status: true,
  pageCount: true,
  publishedYear: true,
  tags: true,
  sortOrder: true,
  externalUrl: true,
  viewsCount: true,
  bookmarksCount: true,
  categoryId: true,
  category: { select: { id: true, name: true, nameAm: true, nameGez: true, slug: true } },
  coverFile: { select: { id: true, url: true } },
  createdAt: true,
  updatedAt: true,
} as const;

const BOOK_DETAIL_SELECT = {
  ...BOOK_LIST_SELECT,
  description: true,
  translator: true,
  publisher: true,
  edition: true,
  isbn: true,
  contentFileId: true,
  contentFile: { select: { id: true, url: true, fileSize: true, mimeType: true } },
  chapters: {
    where: { isPublished: true },
    select: {
      id: true,
      order: true,
      title: true,
      titleAm: true,
      titleGez: true,
      durationSeconds: true,
      contentFileId: true,
      contentFile: { select: { id: true, url: true } },
    },
    orderBy: { order: 'asc' as const },
  },
} as const;

// ── Service ─────────────────────────────────────────────────────────────────

@Injectable()
export class BooksService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Categories ─────────────────────────────────────────────────────────

  async listCategories(includeArchived = false) {
    const where: Prisma.BookCategoryWhereInput = {
      deletedAt: null,
      ...(includeArchived ? {} : { isArchived: false }),
    };

    const cats = await this.prisma.bookCategory.findMany({
      where,
      select: {
        ...CATEGORY_SELECT,
        _count: { select: { books: { where: { deletedAt: null, status: BookStatus.PUBLISHED } } } },
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });

    // Build tree
    const map = new Map<string, any>();
    const roots: any[] = [];
    for (const c of cats) {
      map.set(c.id, { ...c, children: [] });
    }
    for (const c of cats) {
      if (c.parentId && map.has(c.parentId)) {
        map.get(c.parentId)!.children.push(map.get(c.id)!);
      } else {
        roots.push(map.get(c.id)!);
      }
    }
    return roots;
  }

  async createCategory(userId: string, dto: CreateBookCategoryDto) {
    const existing = await this.prisma.bookCategory.findUnique({ where: { slug: dto.slug } });
    if (existing && !existing.deletedAt) {
      throw new ConflictException(`Category slug '${dto.slug}' already exists`);
    }

    if (dto.parentId) {
      const parent = await this.prisma.bookCategory.findUnique({ where: { id: dto.parentId } });
      if (!parent || parent.deletedAt) throw new NotFoundException('Parent category not found');
    }

    return this.prisma.bookCategory.create({
      data: {
        name: dto.name,
        nameAm: dto.nameAm,
        nameGez: dto.nameGez,
        description: dto.description,
        slug: dto.slug,
        parentId: dto.parentId,
        sortOrder: dto.sortOrder ?? 0,
        isVisible: dto.isVisible ?? true,
        iconName: dto.iconName,
        coverUrl: dto.coverUrl,
        createdById: userId,
      },
      select: CATEGORY_SELECT,
    });
  }

  async updateCategory(userId: string, id: string, dto: UpdateBookCategoryDto) {
    const cat = await this.prisma.bookCategory.findFirst({ where: { id, deletedAt: null } });
    if (!cat) throw new NotFoundException('Category not found');

    if (dto.slug && dto.slug !== cat.slug) {
      const conflict = await this.prisma.bookCategory.findUnique({ where: { slug: dto.slug } });
      if (conflict && conflict.id !== id) throw new ConflictException('Slug already in use');
    }

    return this.prisma.bookCategory.update({
      where: { id },
      data: {
        name: dto.name,
        nameAm: dto.nameAm,
        nameGez: dto.nameGez,
        description: dto.description,
        slug: dto.slug,
        parentId: dto.parentId,
        sortOrder: dto.sortOrder,
        isVisible: dto.isVisible,
        isArchived: dto.isArchived,
        iconName: dto.iconName,
        coverUrl: dto.coverUrl,
      },
      select: CATEGORY_SELECT,
    });
  }

  async deleteCategory(id: string) {
    const cat = await this.prisma.bookCategory.findFirst({ where: { id, deletedAt: null } });
    if (!cat) throw new NotFoundException('Category not found');

    // Soft-delete; books keep categoryId but category becomes invisible
    await this.prisma.bookCategory.update({
      where: { id },
      data: { deletedAt: new Date(), isVisible: false },
    });
    return { success: true, message: 'Category archived' };
  }

  // ── Books ───────────────────────────────────────────────────────────────

  async listBooks(query: QueryBooksDto, isAdmin = false) {
    const {
      search,
      categoryId,
      status,
      format,
      language,
      tag,
      page = 1,
      limit = 20,
      sortBy = 'sortOrder',
      sortDir = 'asc',
    } = query;

    const where: Prisma.BookWhereInput = {
      deletedAt: null,
      // Non-admins only see published books
      ...(isAdmin ? {} : { status: BookStatus.PUBLISHED }),
      ...(status && isAdmin ? { status } : {}),
      ...(categoryId ? { categoryId } : {}),
      ...(format ? { format } : {}),
      ...(language ? { language } : {}),
      ...(tag ? { tags: { has: tag } } : {}),
      ...(search
        ? {
            OR: [
              { title: { contains: search, mode: 'insensitive' } },
              { titleAm: { contains: search, mode: 'insensitive' } },
              { titleGez: { contains: search, mode: 'insensitive' } },
              { author: { contains: search, mode: 'insensitive' } },
              { description: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const ALLOWED_SORT = ['title', 'author', 'createdAt', 'sortOrder', 'publishedYear'];
    const orderField = ALLOWED_SORT.includes(sortBy) ? sortBy : 'sortOrder';
    const orderBy: Prisma.BookOrderByWithRelationInput[] = [
      { [orderField]: sortDir },
      { title: 'asc' },
    ];

    const [total, items] = await Promise.all([
      this.prisma.book.count({ where }),
      this.prisma.book.findMany({
        where,
        select: BOOK_LIST_SELECT,
        orderBy,
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);

    return {
      data: items,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      },
    };
  }

  async getBook(id: string, userId?: string) {
    const book = await this.prisma.book.findFirst({
      where: { id, deletedAt: null },
      select: BOOK_DETAIL_SELECT,
    });
    if (!book) throw new NotFoundException('Book not found');

    // Track view (fire-and-forget, not awaited to avoid blocking)
    if (userId) {
      this.prisma.book
        .update({ where: { id }, data: { viewsCount: { increment: 1 } } })
        .catch(() => {});
    }

    let progress: any = null;
    if (userId) {
      progress = await this.prisma.userBookProgress.findUnique({
        where: { userId_bookId: { userId, bookId: id } },
      });
    }

    return { ...book, myProgress: progress ?? null };
  }

  async createBook(userId: string, dto: CreateBookDto) {
    if (dto.contentFileId) {
      const file = await this.prisma.file.findUnique({ where: { id: dto.contentFileId } });
      if (!file) throw new BadRequestException('Content file not found');
    }
    if (dto.coverFileId) {
      const file = await this.prisma.file.findUnique({ where: { id: dto.coverFileId } });
      if (!file) throw new BadRequestException('Cover file not found');
    }

    return this.prisma.book.create({
      data: {
        title: dto.title,
        titleAm: dto.titleAm,
        titleGez: dto.titleGez,
        subtitle: dto.subtitle,
        author: dto.author,
        translator: dto.translator,
        description: dto.description,
        categoryId: dto.categoryId,
        language: dto.language as any,
        format: dto.format as any,
        publisher: dto.publisher,
        publishedYear: dto.publishedYear,
        edition: dto.edition,
        isbn: dto.isbn,
        pageCount: dto.pageCount,
        tags: dto.tags ?? [],
        status: (dto.status as any) ?? BookStatus.DRAFT,
        coverFileId: dto.coverFileId,
        contentFileId: dto.contentFileId,
        externalUrl: dto.externalUrl,
        sortOrder: dto.sortOrder ?? 0,
        createdById: userId,
        updatedById: userId,
      },
      select: BOOK_DETAIL_SELECT,
    });
  }

  async updateBook(userId: string, id: string, dto: UpdateBookDto) {
    const book = await this.prisma.book.findFirst({ where: { id, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    return this.prisma.book.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.titleAm !== undefined && { titleAm: dto.titleAm }),
        ...(dto.titleGez !== undefined && { titleGez: dto.titleGez }),
        ...(dto.subtitle !== undefined && { subtitle: dto.subtitle }),
        ...(dto.author !== undefined && { author: dto.author }),
        ...(dto.translator !== undefined && { translator: dto.translator }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.categoryId !== undefined && { categoryId: dto.categoryId }),
        ...(dto.language !== undefined && { language: dto.language as any }),
        ...(dto.format !== undefined && { format: dto.format as any }),
        ...(dto.publisher !== undefined && { publisher: dto.publisher }),
        ...(dto.publishedYear !== undefined && { publishedYear: dto.publishedYear }),
        ...(dto.edition !== undefined && { edition: dto.edition }),
        ...(dto.isbn !== undefined && { isbn: dto.isbn }),
        ...(dto.pageCount !== undefined && { pageCount: dto.pageCount }),
        ...(dto.tags !== undefined && { tags: dto.tags }),
        ...(dto.status !== undefined && { status: dto.status as any }),
        ...(dto.coverFileId !== undefined && { coverFileId: dto.coverFileId }),
        ...(dto.contentFileId !== undefined && { contentFileId: dto.contentFileId }),
        ...(dto.externalUrl !== undefined && { externalUrl: dto.externalUrl }),
        ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
        updatedById: userId,
      },
      select: BOOK_DETAIL_SELECT,
    });
  }

  async deleteBook(id: string) {
    const book = await this.prisma.book.findFirst({ where: { id, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    await this.prisma.book.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'DELETED' },
    });
    return { success: true, message: 'Book deleted' };
  }

  // ── Chapters ────────────────────────────────────────────────────────────

  async getChapters(bookId: string, isAdmin = false) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    return this.prisma.bookChapter.findMany({
      where: {
        bookId,
        ...(isAdmin ? {} : { isPublished: true }),
      },
      select: {
        id: true,
        order: true,
        title: true,
        titleAm: true,
        titleGez: true,
        durationSeconds: true,
        isPublished: true,
        contentFileId: true,
        contentFile: { select: { id: true, url: true } },
        createdAt: true,
      },
      orderBy: { order: 'asc' },
    });
  }

  async getChapterContent(bookId: string, chapterOrder: number) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    const chapter = await this.prisma.bookChapter.findFirst({
      where: { bookId, order: chapterOrder, isPublished: true },
      select: {
        id: true,
        order: true,
        title: true,
        titleAm: true,
        titleGez: true,
        content: true,
        durationSeconds: true,
        contentFileId: true,
        contentFile: { select: { id: true, url: true, mimeType: true } },
      },
    });

    if (!chapter) throw new NotFoundException('Chapter not found');
    return chapter;
  }

  async createChapter(bookId: string, dto: CreateBookChapterDto) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    const existing = await this.prisma.bookChapter.findFirst({
      where: { bookId, order: dto.order },
    });
    if (existing) {
      throw new ConflictException(`Chapter with order ${dto.order} already exists for this book`);
    }

    return this.prisma.bookChapter.create({
      data: {
        bookId,
        order: dto.order,
        title: dto.title,
        titleAm: dto.titleAm,
        titleGez: dto.titleGez,
        content: dto.content,
        contentFileId: dto.contentFileId,
        durationSeconds: dto.durationSeconds,
        isPublished: dto.isPublished ?? true,
      },
    });
  }

  async updateChapter(bookId: string, chapterId: string, dto: UpdateBookChapterDto) {
    const chapter = await this.prisma.bookChapter.findFirst({ where: { id: chapterId, bookId } });
    if (!chapter) throw new NotFoundException('Chapter not found');

    if (dto.order !== undefined && dto.order !== chapter.order) {
      const conflict = await this.prisma.bookChapter.findFirst({
        where: { bookId, order: dto.order, id: { not: chapterId } },
      });
      if (conflict) throw new ConflictException(`Order ${dto.order} already taken`);
    }

    return this.prisma.bookChapter.update({
      where: { id: chapterId },
      data: {
        ...(dto.order !== undefined && { order: dto.order }),
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.titleAm !== undefined && { titleAm: dto.titleAm }),
        ...(dto.titleGez !== undefined && { titleGez: dto.titleGez }),
        ...(dto.content !== undefined && { content: dto.content }),
        ...(dto.contentFileId !== undefined && { contentFileId: dto.contentFileId }),
        ...(dto.durationSeconds !== undefined && { durationSeconds: dto.durationSeconds }),
        ...(dto.isPublished !== undefined && { isPublished: dto.isPublished }),
      },
    });
  }

  async deleteChapter(bookId: string, chapterId: string) {
    const chapter = await this.prisma.bookChapter.findFirst({ where: { id: chapterId, bookId } });
    if (!chapter) throw new NotFoundException('Chapter not found');

    await this.prisma.bookChapter.delete({ where: { id: chapterId } });
    return { success: true };
  }

  // ── Reading Progress ────────────────────────────────────────────────────

  async getProgress(userId: string, bookId: string) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    const progress = await this.prisma.userBookProgress.findUnique({
      where: { userId_bookId: { userId, bookId } },
    });
    return progress ?? { bookId, userId, percentComplete: 0, isCompleted: false };
  }

  async upsertProgress(userId: string, bookId: string, dto: UpsertReadingProgressDto) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    return this.prisma.userBookProgress.upsert({
      where: { userId_bookId: { userId, bookId } },
      create: {
        userId,
        bookId,
        currentPage: dto.currentPage,
        currentChapter: dto.currentChapter,
        scrollOffset: dto.scrollOffset,
        percentComplete: dto.percentComplete ?? 0,
        isCompleted: dto.isCompleted ?? false,
        lastReadAt: new Date(),
      },
      update: {
        ...(dto.currentPage !== undefined && { currentPage: dto.currentPage }),
        ...(dto.currentChapter !== undefined && { currentChapter: dto.currentChapter }),
        ...(dto.scrollOffset !== undefined && { scrollOffset: dto.scrollOffset }),
        ...(dto.percentComplete !== undefined && { percentComplete: dto.percentComplete }),
        ...(dto.isCompleted !== undefined && { isCompleted: dto.isCompleted }),
        lastReadAt: new Date(),
      },
    });
  }

  async getRecentlyRead(userId: string, limit = 10) {
    return this.prisma.userBookProgress.findMany({
      where: { userId },
      orderBy: { lastReadAt: 'desc' },
      take: limit,
      include: {
        book: { select: BOOK_LIST_SELECT },
      },
    });
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────

  async getBookmarks(userId: string, bookId?: string) {
    return this.prisma.userBookmark.findMany({
      where: {
        userId,
        ...(bookId ? { bookId } : {}),
      },
      include: {
        book: { select: { id: true, title: true, titleAm: true, coverFile: { select: { url: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createBookmark(userId: string, bookId: string, dto: CreateBookBookmarkDto) {
    const book = await this.prisma.book.findFirst({ where: { id: bookId, deletedAt: null } });
    if (!book) throw new NotFoundException('Book not found');

    // Allow multiple bookmarks per user per book (they differ by page/chapter)
    return this.prisma.userBookmark.create({
      data: {
        userId,
        bookId,
        page: dto.page,
        chapter: dto.chapter,
        label: dto.label,
        note: dto.note,
      },
    });
  }

  async deleteBookmark(userId: string, bookmarkId: string) {
    const bm = await this.prisma.userBookmark.findFirst({
      where: { id: bookmarkId, userId },
    });
    if (!bm) throw new NotFoundException('Bookmark not found');

    await this.prisma.userBookmark.delete({ where: { id: bookmarkId } });
    return { success: true };
  }

  // ── Reading Preferences ─────────────────────────────────────────────────

  async getReadingPrefs(userId: string) {
    let prefs = await this.prisma.userReadingPrefs.findUnique({ where: { userId } });
    if (!prefs) {
      // Return defaults without persisting (lazy creation on first PUT)
      return {
        userId,
        fontSize: 16,
        lineSpacing: 1.5,
        fontFamily: 'default',
        textAlign: 'left',
        themeMode: 'system',
        pageMargin: 16,
        scrollMode: 'paginated',
        gridView: true,
        sortBy: 'title',
        sortAsc: true,
        defaultCategoryId: null,
        defaultHighlightColor: '#FFEB3B',
      };
    }
    return prefs;
  }

  async upsertReadingPrefs(userId: string, dto: UpsertReadingPrefsDto) {
    return this.prisma.userReadingPrefs.upsert({
      where: { userId },
      create: {
        userId,
        ...dto,
      },
      update: {
        ...(dto.fontSize !== undefined && { fontSize: dto.fontSize }),
        ...(dto.lineSpacing !== undefined && { lineSpacing: dto.lineSpacing }),
        ...(dto.fontFamily !== undefined && { fontFamily: dto.fontFamily }),
        ...(dto.textAlign !== undefined && { textAlign: dto.textAlign }),
        ...(dto.themeMode !== undefined && { themeMode: dto.themeMode }),
        ...(dto.pageMargin !== undefined && { pageMargin: dto.pageMargin }),
        ...(dto.scrollMode !== undefined && { scrollMode: dto.scrollMode }),
        ...(dto.gridView !== undefined && { gridView: dto.gridView }),
        ...(dto.sortBy !== undefined && { sortBy: dto.sortBy }),
        ...(dto.sortAsc !== undefined && { sortAsc: dto.sortAsc }),
        ...(dto.defaultCategoryId !== undefined && { defaultCategoryId: dto.defaultCategoryId }),
        ...(dto.defaultHighlightColor !== undefined && { defaultHighlightColor: dto.defaultHighlightColor }),
      },
    });
  }

  // ── Download link (authorized) ──────────────────────────────────────────
  // Returns the existing file URL from the DB (secured by JWT guard).
  // Signed URL generation can be plugged in here when a CDN/storage provider
  // that supports it is configured. For now we return the stored URL directly.

  async getDownloadInfo(userId: string, bookId: string) {
    const book = await this.prisma.book.findFirst({
      where: { id: bookId, deletedAt: null, status: BookStatus.PUBLISHED },
      select: {
        id: true,
        title: true,
        format: true,
        pageCount: true,
        contentFileId: true,
        contentFile: { select: { id: true, url: true, fileSize: true, mimeType: true } },
        chapters: {
          where: { isPublished: true },
          select: {
            id: true,
            order: true,
            title: true,
            contentFileId: true,
            contentFile: { select: { id: true, url: true, fileSize: true, mimeType: true } },
          },
          orderBy: { order: 'asc' },
        },
      },
    });

    if (!book) throw new NotFoundException('Book not found or not available');
    if (!book.contentFile && book.chapters.length === 0) {
      throw new BadRequestException('This book has no downloadable content available');
    }

    return book;
  }
}
