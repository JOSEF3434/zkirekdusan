// src/modules/books/dictionary/dictionary.service.ts
import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service.js';
import { DictionaryParserService } from './dictionary-parser.service.js';
import { CreateDictionaryLanguageDto } from './dto/create-dictionary-language.dto.js';
import { UpdateDictionaryLanguageDto } from './dto/update-dictionary-language.dto.js';
import { UpdateDictionaryConfigDto } from './dto/update-dictionary-config.dto.js';
import { TranslateWordDto } from './dto/translate-word.dto.js';
import { SaveTranslationHistoryDto } from './dto/save-translation-history.dto.js';
import { QueryTranslationHistoryDto } from './dto/query-translation-history.dto.js';
import { DictionaryProcessingStatus, BookStatus } from '@prisma/client';
import { AppRole } from '../../../common/constants/roles.js';

@Injectable()
export class DictionaryService {
  private readonly logger = new Logger(DictionaryService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly parser: DictionaryParserService,
  ) {}

  // ──────────────────────────────────────────────────────────────────────────
  // RBAC HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  private async assertAdminAccess(userId: string) {
    if (!userId) throw new ForbiddenException('Authentication required');
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        role: {
          include: {
            permissions: {
              include: { permission: true },
            },
          },
        },
      },
    });

    if (!user) throw new ForbiddenException('User not found');
    const roleName = user.role.name;
    if (roleName === AppRole.SUPER_ADMIN || roleName === AppRole.ADMIN) {
      return true;
    }

    const perms = user.role.permissions.map((p) => p.permission.name);
    if (
      perms.includes('*') ||
      perms.includes('books.manage_library') ||
      perms.includes('books.manage_languages')
    ) {
      return true;
    }

    throw new ForbiddenException('Insufficient permissions to manage dictionaries');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DICTIONARY PROCESSING ENGINE (ASYNC LIFECYCLE)
  // ──────────────────────────────────────────────────────────────────────────

  async triggerProcessing(userId: string, bookId: string) {
    await this.assertAdminAccess(userId);

    const book = await this.prisma.book.findFirst({
      where: { id: bookId, deletedAt: null },
      include: {
        dictionaryConfig: true,
        contentFile: true,
      },
    });

    if (!book) throw new NotFoundException('Book not found');
    if (!book.isDictionary) {
      throw new BadRequestException('This book is not configured as a dictionary book');
    }
    if (!book.dictionaryConfig) {
      throw new BadRequestException('Dictionary configuration missing for this book');
    }
    if (!book.contentFile || !book.contentFile.url) {
      throw new BadRequestException('Dictionary book has no content file to process');
    }

    // Set status to VALIDATING immediately
    await this.prisma.dictionaryBookConfig.update({
      where: { bookId },
      data: {
        processingStatus: DictionaryProcessingStatus.VALIDATING,
        errorMessage: null,
      },
    });

    // Run processing asynchronously to avoid blocking HTTP request
    setImmediate(async () => {
      try {
        await this.executeProcessing(bookId, book.contentFile!.url, book.format);
      } catch (err: any) {
        this.logger.error(`Background processing failed for book ${bookId}: ${err.message}`, err.stack);
      }
    });

    return {
      success: true,
      message: 'Dictionary processing initiated successfully',
      processingStatus: DictionaryProcessingStatus.VALIDATING,
    };
  }

  private async executeProcessing(bookId: string, fileUrl: string, format: string) {
    try {
      this.logger.log(`Starting dictionary extraction for book ${bookId} from ${fileUrl}`);

      // 1. EXTRACTING: Fetch file buffer
      await this.prisma.dictionaryBookConfig.update({
        where: { bookId },
        data: { processingStatus: DictionaryProcessingStatus.EXTRACTING },
      });

      const response = await fetch(fileUrl);
      if (!response.ok) {
        throw new Error(`Failed to download dictionary file: HTTP ${response.status} ${response.statusText}`);
      }
      const arrayBuf = await response.arrayBuffer();
      const buffer = Buffer.from(arrayBuf);

      // 2. PARSING: Parse entries according to file format
      await this.prisma.dictionaryBookConfig.update({
        where: { bookId },
        data: { processingStatus: DictionaryProcessingStatus.PARSING },
      });

      const config = await this.prisma.dictionaryBookConfig.findUnique({
        where: { bookId },
        include: {
          sourceLanguage: true,
          targetLanguage: true,
        },
      });

      if (!config) throw new Error('Dictionary config not found');

      const isEpub = format === 'EPUB' || fileUrl.toLowerCase().endsWith('.epub');
      const parsedResult = isEpub
        ? await this.parser.parseEpub(buffer)
        : await this.parser.parsePdf(buffer);

      if (!parsedResult.entries || parsedResult.entries.length === 0) {
        throw new Error('No dictionary entries were extracted from the document');
      }

      this.logger.log(`Extracted ${parsedResult.entries.length} entries for book ${bookId}. Now indexing...`);

      // 3. INDEXING: Batch save entries to database
      await this.prisma.dictionaryBookConfig.update({
        where: { bookId },
        data: { processingStatus: DictionaryProcessingStatus.INDEXING },
      });

      // Clear existing entries for this book before inserting refreshed entries
      await this.prisma.dictionaryEntry.deleteMany({
        where: { bookId },
      });

      const srcLang = config.sourceLanguage.code;
      const tgtLang = config.targetLanguage.code;

      // Batch insert in chunks of 500 for optimal Postgres performance
      const CHUNK_SIZE = 500;
      for (let i = 0; i < parsedResult.entries.length; i += CHUNK_SIZE) {
        const chunk = parsedResult.entries.slice(i, i + CHUNK_SIZE);
        await this.prisma.dictionaryEntry.createMany({
          data: chunk.map((ent, idx) => ({
            bookId,
            configId: config.id,
            headword: ent.headword,
            normalizedHeadword: ent.normalizedHeadword,
            sourceLanguageCode: srcLang,
            targetLanguageCode: tgtLang,
            definition: ent.definition,
            definitions: (ent.definitions ?? []) as any,
            entryNumber: i + idx + 1,
            pageNumber: ent.pageNumber ?? null,
            chapterTitle: ent.chapterTitle ?? null,
            metadata: (ent.metadata ?? undefined) as any,
          })),
        });
      }

      // 4. READY: Complete indexing and update stats
      await this.prisma.dictionaryBookConfig.update({
        where: { bookId },
        data: {
          processingStatus: DictionaryProcessingStatus.READY,
          totalEntries: parsedResult.entries.length,
          errorMessage: null,
          processedAt: new Date(),
          metadata: parsedResult.metadata as any,
        },
      });

      this.logger.log(`Dictionary indexing COMPLETE for book ${bookId} with ${parsedResult.entries.length} entries.`);
    } catch (err: any) {
      this.logger.error(`Processing error for book ${bookId}: ${err.message}`, err.stack);
      await this.prisma.dictionaryBookConfig.update({
        where: { bookId },
        data: {
          processingStatus: DictionaryProcessingStatus.FAILED,
          errorMessage: err.message || 'Unknown processing error',
        },
      });
    }
  }

  async getStatus(userId: string, bookId: string) {
    await this.assertAdminAccess(userId);

    const config = await this.prisma.dictionaryBookConfig.findUnique({
      where: { bookId },
      include: {
        sourceLanguage: true,
        targetLanguage: true,
      },
    });

    if (!config) throw new NotFoundException('Dictionary configuration not found');

    return {
      bookId,
      dictionaryName: config.dictionaryName,
      processingStatus: config.processingStatus,
      totalEntries: config.totalEntries,
      errorMessage: config.errorMessage,
      processedAt: config.processedAt,
      sourceLanguage: config.sourceLanguage,
      targetLanguage: config.targetLanguage,
      metadata: config.metadata,
    };
  }

  async updateConfig(userId: string, bookId: string, dto: UpdateDictionaryConfigDto) {
    await this.assertAdminAccess(userId);

    const config = await this.prisma.dictionaryBookConfig.findUnique({
      where: { bookId },
    });
    if (!config) throw new NotFoundException('Dictionary config not found');

    const srcId = dto.sourceLanguageId ?? config.sourceLanguageId;
    const tgtId = dto.targetLanguageId ?? config.targetLanguageId;

    if (dto.sourceLanguageId) {
      const src = await this.prisma.dictionaryLanguage.findUnique({
        where: { id: dto.sourceLanguageId, deletedAt: null },
      });
      if (!src) throw new BadRequestException('Source language not found');
    }

    if (dto.targetLanguageId) {
      const tgt = await this.prisma.dictionaryLanguage.findUnique({
        where: { id: dto.targetLanguageId, deletedAt: null },
      });
      if (!tgt) throw new BadRequestException('Target language not found');
    }

    const updated = await this.prisma.dictionaryBookConfig.update({
      where: { bookId },
      data: {
        dictionaryName: dto.dictionaryName,
        description: dto.description,
        sourceLanguageId: dto.sourceLanguageId,
        targetLanguageId: dto.targetLanguageId,
      },
      include: {
        sourceLanguage: true,
        targetLanguage: true,
      },
    });

    return updated;
  }

  async publishDictionary(userId: string, bookId: string) {
    await this.assertAdminAccess(userId);

    const config = await this.prisma.dictionaryBookConfig.findUnique({
      where: { bookId },
    });
    if (!config) throw new NotFoundException('Dictionary config not found');

    if (config.processingStatus !== DictionaryProcessingStatus.READY) {
      throw new BadRequestException(
        `Cannot publish dictionary while processing status is ${config.processingStatus}. Only READY dictionaries can be published.`,
      );
    }

    const book = await this.prisma.book.update({
      where: { id: bookId },
      data: {
        status: BookStatus.PUBLISHED,
        updatedById: userId,
      },
    });

    return {
      success: true,
      bookId,
      status: book.status,
      message: 'Dictionary book published successfully and made available to users',
    };
  }

  async unpublishDictionary(userId: string, bookId: string) {
    await this.assertAdminAccess(userId);

    const book = await this.prisma.book.update({
      where: { id: bookId },
      data: {
        status: BookStatus.DRAFT,
        updatedById: userId,
      },
    });

    return {
      success: true,
      bookId,
      status: book.status,
      message: 'Dictionary book unpublished to draft',
    };
  }

  async listDictionariesAdmin(userId: string) {
    await this.assertAdminAccess(userId);

    const dictionaries = await this.prisma.book.findMany({
      where: {
        isDictionary: true,
        deletedAt: null,
      },
      include: {
        dictionaryConfig: {
          include: {
            sourceLanguage: true,
            targetLanguage: true,
          },
        },
        coverFile: { select: { id: true, url: true } },
        contentFile: { select: { id: true, url: true, size: true, mimeType: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return dictionaries;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CENTRALIZED LANGUAGE MANAGEMENT (ADMIN ONLY)
  // ──────────────────────────────────────────────────────────────────────────

  async createLanguage(userId: string, dto: CreateDictionaryLanguageDto) {
    await this.assertAdminAccess(userId);

    const existing = await this.prisma.dictionaryLanguage.findFirst({
      where: { code: dto.code.toLowerCase(), deletedAt: null },
    });
    if (existing) {
      throw new ConflictException(`Language with code '${dto.code}' already exists`);
    }

    return this.prisma.dictionaryLanguage.create({
      data: {
        code: dto.code.toLowerCase().trim(),
        name: dto.name.trim(),
        nativeName: dto.nativeName.trim(),
        direction: dto.direction ?? 'ltr',
        localizedNames: (dto.localizedNames as any) ?? null,
        isEnabled: dto.isEnabled ?? true,
        sortOrder: dto.sortOrder ?? 0,
        createdById: userId,
      },
    });
  }

  async updateLanguage(userId: string, id: string, dto: UpdateDictionaryLanguageDto) {
    await this.assertAdminAccess(userId);

    const lang = await this.prisma.dictionaryLanguage.findUnique({
      where: { id, deletedAt: null },
    });
    if (!lang) throw new NotFoundException('Language not found');

    if (dto.code && dto.code.toLowerCase() !== lang.code) {
      const existing = await this.prisma.dictionaryLanguage.findFirst({
        where: { code: dto.code.toLowerCase(), id: { not: id }, deletedAt: null },
      });
      if (existing) {
        throw new ConflictException(`Language with code '${dto.code}' already exists`);
      }
    }

    return this.prisma.dictionaryLanguage.update({
      where: { id },
      data: {
        code: dto.code ? dto.code.toLowerCase().trim() : undefined,
        name: dto.name ? dto.name.trim() : undefined,
        nativeName: dto.nativeName ? dto.nativeName.trim() : undefined,
        direction: dto.direction,
        localizedNames: dto.localizedNames !== undefined ? (dto.localizedNames as any) : undefined,
        isEnabled: dto.isEnabled,
        sortOrder: dto.sortOrder,
      },
    });
  }

  async deleteLanguage(userId: string, id: string) {
    await this.assertAdminAccess(userId);

    const lang = await this.prisma.dictionaryLanguage.findUnique({
      where: { id, deletedAt: null },
      include: {
        sourceDictionaries: { select: { id: true, dictionaryName: true } },
        targetDictionaries: { select: { id: true, dictionaryName: true } },
      },
    });
    if (!lang) throw new NotFoundException('Language not found');

    const totalDependent = lang.sourceDictionaries.length + lang.targetDictionaries.length;
    if (totalDependent > 0) {
      throw new ConflictException(
        `Cannot delete language '${lang.name}' because ${totalDependent} dictionary configuration(s) currently depend on it. Please reassign or delete dependent dictionaries first.`,
      );
    }

    await this.prisma.dictionaryLanguage.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    return { success: true, message: `Language '${lang.name}' successfully removed` };
  }

  async listLanguages(includeDisabled = false) {
    return this.prisma.dictionaryLanguage.findMany({
      where: {
        deletedAt: null,
        ...(includeDisabled ? {} : { isEnabled: true }),
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REGULAR USER APIS: SEARCH & TRANSLATION
  // ──────────────────────────────────────────────────────────────────────────

  async listAvailableDictionaries() {
    return this.prisma.book.findMany({
      where: {
        isDictionary: true,
        status: BookStatus.PUBLISHED,
        deletedAt: null,
        dictionaryConfig: {
          processingStatus: DictionaryProcessingStatus.READY,
        },
      },
      select: {
        id: true,
        title: true,
        titleAm: true,
        titleGez: true,
        description: true,
        format: true,
        status: true,
        viewsCount: true,
        coverFile: { select: { id: true, url: true } },
        dictionaryConfig: {
          select: {
            id: true,
            dictionaryName: true,
            description: true,
            processingStatus: true,
            totalEntries: true,
            sourceLanguage: {
              select: { id: true, code: true, name: true, nativeName: true, direction: true },
            },
            targetLanguage: {
              select: { id: true, code: true, name: true, nativeName: true, direction: true },
            },
          },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async searchDictionary(bookId: string, word: string) {
    if (!word || !word.trim()) {
      throw new BadRequestException('Search word is required');
    }

    const book = await this.prisma.book.findFirst({
      where: {
        id: bookId,
        isDictionary: true,
        deletedAt: null,
        status: BookStatus.PUBLISHED,
        dictionaryConfig: {
          processingStatus: DictionaryProcessingStatus.READY,
        },
      },
      include: {
        dictionaryConfig: {
          include: {
            sourceLanguage: true,
            targetLanguage: true,
          },
        },
      },
    });

    if (!book || !book.dictionaryConfig) {
      throw new NotFoundException('Published dictionary not found or indexing in progress');
    }

    const normalized = this.parser.normalizeHeadword(word);

    // 1. Exact match on normalized headword
    let entries = await this.prisma.dictionaryEntry.findMany({
      where: {
        bookId,
        normalizedHeadword: normalized,
      },
      take: 10,
    });

    // 2. Prefix match fallback if exact match yields nothing
    if (entries.length === 0 && normalized.length >= 2) {
      entries = await this.prisma.dictionaryEntry.findMany({
        where: {
          bookId,
          normalizedHeadword: { startsWith: normalized },
        },
        take: 10,
      });
    }

    // 3. Substring / contains fallback
    if (entries.length === 0 && normalized.length >= 3) {
      entries = await this.prisma.dictionaryEntry.findMany({
        where: {
          bookId,
          normalizedHeadword: { contains: normalized },
        },
        take: 10,
      });
    }

    return {
      word: word.trim(),
      normalizedWord: normalized,
      dictionaryBookId: book.id,
      dictionaryName: book.dictionaryConfig.dictionaryName,
      sourceLanguage: book.dictionaryConfig.sourceLanguage,
      targetLanguage: book.dictionaryConfig.targetLanguage,
      totalMatches: entries.length,
      definitions: entries.map((e) => ({
        entryId: e.id,
        headword: e.headword,
        text: e.definition,
        definitions: e.definitions,
        pageNumber: e.pageNumber,
        chapterTitle: e.chapterTitle,
        source: 'dictionary',
      })),
    };
  }

  async translate(dto: TranslateWordDto) {
    const rawWord = (dto.word || '').trim();
    if (!rawWord) throw new BadRequestException('Word to translate is required');

    const normalized = this.parser.normalizeHeadword(rawWord);

    // If specific bookId was requested, use it directly
    if (dto.bookId) {
      return this.searchDictionary(dto.bookId, rawWord);
    }

    // Otherwise, locate matching published & ready dictionary for language pair
    const whereConfig: any = {
      processingStatus: DictionaryProcessingStatus.READY,
    };
    if (dto.sourceLanguage) {
      whereConfig.sourceLanguage = { code: dto.sourceLanguage.toLowerCase() };
    }
    if (dto.targetLanguage) {
      whereConfig.targetLanguage = { code: dto.targetLanguage.toLowerCase() };
    }

    const availableDict = await this.prisma.book.findFirst({
      where: {
        isDictionary: true,
        status: BookStatus.PUBLISHED,
        deletedAt: null,
        dictionaryConfig: whereConfig,
      },
      include: {
        dictionaryConfig: {
          include: {
            sourceLanguage: true,
            targetLanguage: true,
          },
        },
      },
      orderBy: { viewsCount: 'desc' },
    });

    if (!availableDict || !availableDict.dictionaryConfig) {
      // Return clear empty result with search context
      return {
        word: rawWord,
        normalizedWord: normalized,
        sourceLanguage: dto.sourceLanguage ?? 'auto',
        targetLanguage: dto.targetLanguage ?? 'am',
        dictionaryName: null,
        totalMatches: 0,
        definitions: [],
        message: 'No published dictionary found for this language pair.',
      };
    }

    return this.searchDictionary(availableDict.id, rawWord);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TRANSLATION HISTORY (REGULAR USERS)
  // ──────────────────────────────────────────────────────────────────────────

  async saveHistory(userId: string, dto: SaveTranslationHistoryDto) {
    if (!userId) throw new ForbiddenException('User authentication required');

    // Deduplicate: check if identical word & definition was saved in the last 60 seconds
    const recent = await this.prisma.userTranslationHistory.findFirst({
      where: {
        userId,
        word: dto.word.trim(),
        definition: dto.definition.trim(),
        createdAt: { gte: new Date(Date.now() - 60000) },
      },
    });

    if (recent) return recent;

    return this.prisma.userTranslationHistory.create({
      data: {
        userId,
        word: dto.word.trim(),
        sourceLanguage: dto.sourceLanguage.trim(),
        targetLanguage: dto.targetLanguage.trim(),
        definition: dto.definition.trim(),
        dictionaryBookId: dto.dictionaryBookId ?? null,
        dictionaryEntryId: dto.dictionaryEntryId ?? null,
        dictionaryNameSnapshot: dto.dictionaryNameSnapshot.trim(),
        pageNumber: dto.pageNumber ?? null,
        chapter: dto.chapter ?? null,
        surroundingSentence: dto.surroundingSentence ?? null,
      },
    });
  }

  async getHistory(userId: string, query: QueryTranslationHistoryDto) {
    if (!userId) throw new ForbiddenException('User authentication required');

    const where: any = { userId };

    if (query.search) {
      where.OR = [
        { word: { contains: query.search.trim(), mode: 'insensitive' } },
        { definition: { contains: query.search.trim(), mode: 'insensitive' } },
      ];
    }

    if (query.sourceLanguage) {
      where.sourceLanguage = query.sourceLanguage.toLowerCase().trim();
    }
    if (query.targetLanguage) {
      where.targetLanguage = query.targetLanguage.toLowerCase().trim();
    }
    if (query.dictionaryBookId) {
      where.dictionaryBookId = query.dictionaryBookId;
    }

    const take = Math.min(query.limit || 20, 100);
    const skip = ((query.page || 1) - 1) * take;
    const orderBy = query.sort === 'oldest' ? { createdAt: 'asc' as const } : { createdAt: 'desc' as const };

    const [items, total] = await Promise.all([
      this.prisma.userTranslationHistory.findMany({
        where,
        take,
        skip,
        orderBy,
      }),
      this.prisma.userTranslationHistory.count({ where }),
    ]);

    return {
      items,
      total,
      page: query.page || 1,
      limit: take,
      totalPages: Math.ceil(total / take),
    };
  }

  async deleteHistoryItem(userId: string, id: string) {
    if (!userId) throw new ForbiddenException('User authentication required');

    const item = await this.prisma.userTranslationHistory.findFirst({
      where: { id, userId },
    });
    if (!item) throw new NotFoundException('History item not found');

    await this.prisma.userTranslationHistory.delete({
      where: { id },
    });

    return { success: true, message: 'History item removed' };
  }

  async clearHistory(userId: string) {
    if (!userId) throw new ForbiddenException('User authentication required');

    const result = await this.prisma.userTranslationHistory.deleteMany({
      where: { userId },
    });

    return {
      success: true,
      deletedCount: result.count,
      message: 'Translation history cleared successfully',
    };
  }
}
