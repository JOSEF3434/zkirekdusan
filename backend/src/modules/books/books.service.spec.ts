import { Test, TestingModule } from '@nestjs/testing';
import { BooksService } from './books.service.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { UploadsService } from '../uploads/uploads.service.js';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { BookStatus } from '@prisma/client';

describe('BooksService', () => {
  let service: BooksService;
  let prisma: any;
  let uploads: any;

  beforeEach(async () => {
    prisma = {
      bookCategory: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      book: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        delete: jest.fn(),
        count: jest.fn(),
      },
      file: {
        findUnique: jest.fn(),
      },
      userBookProgress: {
        deleteMany: jest.fn(),
      },
      userBookmark: {
        deleteMany: jest.fn(),
      },
      userBookAnnotation: {
        deleteMany: jest.fn(),
      },
      bookChapter: {
        deleteMany: jest.fn(),
      },
    };

    uploads = {
      uploadMediaFile: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BooksService,
        { provide: PrismaService, useValue: prisma },
        { provide: UploadsService, useValue: uploads },
      ],
    }).compile();

    service = module.get<BooksService>(BooksService);
  });

  describe('Category circular reference prevention', () => {
    it('should throw BadRequestException if category is set as its own parent', async () => {
      prisma.bookCategory.findFirst.mockResolvedValue({ id: 'cat-1', slug: 'cat-1' });

      await expect(
        service.updateCategory('user-1', 'cat-1', { parentId: 'cat-1' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if circular parent-child loop is detected', async () => {
      prisma.bookCategory.findFirst.mockResolvedValue({ id: 'cat-1', slug: 'cat-1' });
      // parent of cat-2 is cat-1, so setting cat-2 as parent of cat-1 creates a cycle
      prisma.bookCategory.findUnique.mockImplementation(({ where }: any) => {
        if (where.id === 'cat-2') return Promise.resolve({ id: 'cat-2', parentId: 'cat-1' });
        return Promise.resolve(null);
      });

      await expect(
        service.updateCategory('user-1', 'cat-1', { parentId: 'cat-2' }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('Safe Category Deletion', () => {
    it('should reassign books and child categories when reassignCategoryId is provided', async () => {
      prisma.bookCategory.findFirst.mockImplementation(({ where }: any) => {
        if (where.id === 'cat-to-delete') return Promise.resolve({ id: 'cat-to-delete' });
        if (where.id === 'cat-target') return Promise.resolve({ id: 'cat-target' });
        return Promise.resolve(null);
      });

      await service.deleteCategory('cat-to-delete', 'cat-target');

      expect(prisma.book.updateMany).toHaveBeenCalledWith({
        where: { categoryId: 'cat-to-delete' },
        data: { categoryId: 'cat-target' },
      });
      expect(prisma.bookCategory.updateMany).toHaveBeenCalledWith({
        where: { parentId: 'cat-to-delete' },
        data: { parentId: 'cat-target' },
      });
      expect(prisma.bookCategory.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'cat-to-delete' },
          data: expect.objectContaining({ isArchived: true, isVisible: false }),
        }),
      );
    });

    it('should detach books and subcategories when reassignCategoryId is omitted', async () => {
      prisma.bookCategory.findFirst.mockResolvedValue({ id: 'cat-to-delete' });

      await service.deleteCategory('cat-to-delete');

      expect(prisma.book.updateMany).toHaveBeenCalledWith({
        where: { categoryId: 'cat-to-delete' },
        data: { categoryId: null },
      });
      expect(prisma.bookCategory.updateMany).toHaveBeenCalledWith({
        where: { parentId: 'cat-to-delete' },
        data: { parentId: null },
      });
    });
  });

  describe('Book publication and lifecycle', () => {
    it('publishBook updates book status to PUBLISHED', async () => {
      prisma.book.findFirst.mockResolvedValue({ id: 'book-1' });
      prisma.book.update.mockResolvedValue({ id: 'book-1', status: BookStatus.PUBLISHED });

      const result = await service.publishBook('user-admin', 'book-1');
      expect(prisma.book.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'book-1' },
          data: { status: BookStatus.PUBLISHED, updatedById: 'user-admin' },
        }),
      );
      expect(result.status).toBe(BookStatus.PUBLISHED);
    });

    it('unpublishBook updates book status to DRAFT', async () => {
      prisma.book.findFirst.mockResolvedValue({ id: 'book-1' });
      prisma.book.update.mockResolvedValue({ id: 'book-1', status: BookStatus.DRAFT });

      const result = await service.unpublishBook('user-admin', 'book-1');
      expect(prisma.book.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'book-1' },
          data: { status: BookStatus.DRAFT, updatedById: 'user-admin' },
        }),
      );
      expect(result.status).toBe(BookStatus.DRAFT);
    });

    it('archiveBook updates book status to ARCHIVED', async () => {
      prisma.book.findFirst.mockResolvedValue({ id: 'book-1' });
      prisma.book.update.mockResolvedValue({ id: 'book-1', status: BookStatus.ARCHIVED });

      const result = await service.archiveBook('user-admin', 'book-1');
      expect(prisma.book.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'book-1' },
          data: { status: BookStatus.ARCHIVED, updatedById: 'user-admin' },
        }),
      );
      expect(result.status).toBe(BookStatus.ARCHIVED);
    });

    it('restoreBook un-deletes and sets status to DRAFT', async () => {
      prisma.book.findUnique.mockResolvedValue({ id: 'book-1', deletedAt: new Date() });
      prisma.book.update.mockResolvedValue({ id: 'book-1', status: BookStatus.DRAFT, deletedAt: null });

      const result = await service.restoreBook('user-admin', 'book-1');
      expect(prisma.book.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'book-1' },
          data: { deletedAt: null, status: BookStatus.DRAFT, updatedById: 'user-admin' },
        }),
      );
      expect(result.status).toBe(BookStatus.DRAFT);
    });

    it('deleteBook soft deletes by default', async () => {
      prisma.book.findUnique.mockResolvedValue({ id: 'book-1' });

      const result = await service.deleteBook('book-1', false);
      expect(prisma.book.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'book-1' },
          data: expect.objectContaining({ status: BookStatus.DELETED }),
        }),
      );
      expect(result.success).toBe(true);
    });

    it('deleteBook with permanent=true cascades dependent data safely', async () => {
      prisma.book.findUnique.mockResolvedValue({ id: 'book-1' });

      const result = await service.deleteBook('book-1', true);
      expect(prisma.userBookProgress.deleteMany).toHaveBeenCalledWith({ where: { bookId: 'book-1' } });
      expect(prisma.userBookmark.deleteMany).toHaveBeenCalledWith({ where: { bookId: 'book-1' } });
      expect(prisma.userBookAnnotation.deleteMany).toHaveBeenCalledWith({ where: { bookId: 'book-1' } });
      expect(prisma.bookChapter.deleteMany).toHaveBeenCalledWith({ where: { bookId: 'book-1' } });
      expect(prisma.book.delete).toHaveBeenCalledWith({ where: { id: 'book-1' } });
      expect(result.success).toBe(true);
    });
  });
});
