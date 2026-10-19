// src/modules/alephat/alephat.service.ts
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CreateAlephatLetterDto } from './dto/create-alephat-letter.dto.js';
import { UpdateAlephatLetterDto } from './dto/update-alephat-letter.dto.js';
import { CreateFamilyMemberDto } from './dto/create-family-member.dto.js';
import { UpdateFamilyMemberDto } from './dto/update-family-member.dto.js';
import { ReorderItemsDto } from './dto/reorder-items.dto.js';
import { CreateAlephat22Dto } from './dto/create-alephat-22.dto.js';
import { UpdateAlephat22Dto } from './dto/update-alephat-22.dto.js';
import { QueryAlephatDto } from './dto/query-alephat.dto.js';
import { INITIAL_ALEPHAT_LETTERS, INITIAL_22_ALEPHATS } from './alephat.seed-data.js';

@Injectable()
export class AlephatService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AlephatService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap() {
    try {
      await this.ensureInitialSeed();
    } catch (error) {
      this.logger.warn(`Initial Alephat seed deferred or skipped: ${(error as Error).message}`);
    }
  }

  /**
   * Idempotently seeds initial base letters and 22 Alephats if database is empty or missing entries.
   * Does not overwrite existing records modified by administrators.
   */
  async ensureInitialSeed(adminUserId?: string) {
    const lettersCount = await this.prisma.alephatLetter.count();
    if (lettersCount === 0) {
      this.logger.log('🌱 Seeding initial Amharic base letters and letter families...');
      for (const item of INITIAL_ALEPHAT_LETTERS) {
        await this.prisma.alephatLetter.create({
          data: {
            letter: item.letter,
            name: item.name,
            order: item.order,
            defaultNote: item.defaultNote,
            pronunciationGuide: item.pronunciationGuide,
            isPublished: true,
            createdById: adminUserId ?? null,
            familyMembers: {
              create: item.familyMembers.map((fm) => ({
                glyph: fm.glyph,
                orderIndex: fm.orderIndex,
                orderName: fm.orderName,
                note: fm.note,
                pronunciation: fm.pronunciation,
                isPublished: true,
              })),
            },
          },
        });
      }
      this.logger.log(`✅ Seeded ${INITIAL_ALEPHAT_LETTERS.length} Amharic base letters with complete families`);
    }

    const entries22Count = await this.prisma.alephat22Entry.count();
    if (entries22Count === 0) {
      this.logger.log('🌱 Seeding initial 22 Alephats reference collection...');
      for (const item of INITIAL_22_ALEPHATS) {
        await this.prisma.alephat22Entry.create({
          data: {
            letter: item.letter,
            title: item.title,
            meaning: item.meaning,
            order: item.order,
            note: item.note,
            supplementaryInfo: item.supplementaryInfo,
            isPublished: true,
            createdById: adminUserId ?? null,
          },
        });
      }
      this.logger.log(`✅ Seeded ${INITIAL_22_ALEPHATS.length} classical 22 Alephat entries`);
    }
  }

  // ─────────────────────────────────────────────────────────
  // TAB 1: Base Letters & Families
  // ─────────────────────────────────────────────────────────

  async findAllLetters(query: QueryAlephatDto) {
    const where: any = {};

    if (!query.includeUnpublished) {
      where.isPublished = true;
    }

    if (query.search && query.search.trim().length > 0) {
      const term = query.search.trim();
      where.OR = [
        { letter: { contains: term, mode: 'insensitive' } },
        { name: { contains: term, mode: 'insensitive' } },
        { defaultNote: { contains: term, mode: 'insensitive' } },
      ];
    }

    const membersWhere = query.includeUnpublished ? {} : { isPublished: true };

    return this.prisma.alephatLetter.findMany({
      where,
      orderBy: { order: 'asc' },
      include: {
        familyMembers: {
          where: membersWhere,
          orderBy: { orderIndex: 'asc' },
        },
        _count: {
          select: { familyMembers: true },
        },
      },
    });
  }

  async findLetterById(id: string, includeUnpublished = false) {
    const membersWhere = includeUnpublished ? {} : { isPublished: true };

    const letter = await this.prisma.alephatLetter.findUnique({
      where: { id },
      include: {
        familyMembers: {
          where: membersWhere,
          orderBy: { orderIndex: 'asc' },
        },
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
        updatedBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
      },
    });

    if (!letter || (!includeUnpublished && !letter.isPublished)) {
      throw new NotFoundException(`Alephat letter with ID '${id}' not found`);
    }

    return letter;
  }

  async createLetter(userId: string, dto: CreateAlephatLetterDto) {
    const existing = await this.prisma.alephatLetter.findUnique({
      where: { letter: dto.letter.trim() },
    });
    if (existing) {
      throw new BadRequestException(`Base letter '${dto.letter}' already exists`);
    }

    // Default order to highest + 1 if not explicitly provided
    let order = dto.order;
    if (order === undefined || order === null) {
      const highest = await this.prisma.alephatLetter.findFirst({
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      order = (highest?.order ?? 0) + 1;
    }

    return this.prisma.$transaction(async (tx) => {
      const created = await tx.alephatLetter.create({
        data: {
          letter: dto.letter.trim(),
          name: dto.name?.trim(),
          order,
          defaultNote: dto.defaultNote?.trim(),
          pronunciationGuide: dto.pronunciationGuide?.trim(),
          isPublished: dto.isPublished ?? true,
          createdById: userId,
          updatedById: userId,
          familyMembers: dto.familyMembers && dto.familyMembers.length > 0
            ? {
                create: dto.familyMembers.map((fm) => ({
                  glyph: fm.glyph.trim(),
                  orderIndex: fm.orderIndex,
                  orderName: fm.orderName?.trim(),
                  note: fm.note?.trim(),
                  pronunciation: fm.pronunciation?.trim(),
                  isPublished: fm.isPublished ?? true,
                })),
              }
            : undefined,
        },
        include: {
          familyMembers: { orderBy: { orderIndex: 'asc' } },
        },
      });

      return created;
    });
  }

  async updateLetter(userId: string, id: string, dto: UpdateAlephatLetterDto) {
    const existing = await this.prisma.alephatLetter.findUnique({
      where: { id },
      include: { familyMembers: true },
    });
    if (!existing) {
      throw new NotFoundException(`Alephat letter with ID '${id}' not found`);
    }

    if (dto.letter && dto.letter.trim() !== existing.letter) {
      const duplicate = await this.prisma.alephatLetter.findUnique({
        where: { letter: dto.letter.trim() },
      });
      if (duplicate && duplicate.id !== id) {
        throw new BadRequestException(`Base letter '${dto.letter}' already exists`);
      }
    }

    return this.prisma.$transaction(async (tx) => {
      // If familyMembers are provided in bulk update, sync them
      if (dto.familyMembers) {
        await tx.alephatFamilyMember.deleteMany({
          where: { baseLetterId: id },
        });

        await tx.alephatFamilyMember.createMany({
          data: dto.familyMembers.map((fm) => ({
            baseLetterId: id,
            glyph: fm.glyph.trim(),
            orderIndex: fm.orderIndex,
            orderName: fm.orderName?.trim(),
            note: fm.note?.trim(),
            pronunciation: fm.pronunciation?.trim(),
            isPublished: fm.isPublished ?? true,
          })),
        });
      }

      return tx.alephatLetter.update({
        where: { id },
        data: {
          letter: dto.letter?.trim(),
          name: dto.name !== undefined ? dto.name?.trim() : undefined,
          order: dto.order !== undefined ? dto.order : undefined,
          defaultNote: dto.defaultNote !== undefined ? dto.defaultNote?.trim() : undefined,
          pronunciationGuide: dto.pronunciationGuide !== undefined ? dto.pronunciationGuide?.trim() : undefined,
          isPublished: dto.isPublished !== undefined ? dto.isPublished : undefined,
          updatedById: userId,
        },
        include: {
          familyMembers: { orderBy: { orderIndex: 'asc' } },
        },
      });
    });
  }

  async deleteLetter(id: string) {
    const existing = await this.prisma.alephatLetter.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`Alephat letter with ID '${id}' not found`);
    }

    await this.prisma.alephatLetter.delete({ where: { id } });
    return { success: true, message: `Letter '${existing.letter}' successfully deleted` };
  }

  async reorderLetters(dto: ReorderItemsDto) {
    await this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.alephatLetter.update({
          where: { id: item.id },
          data: { order: item.order },
        }),
      ),
    );
    return { success: true };
  }

  // ── Family Members Sub-operations ────────────────────────

  async addFamilyMember(letterId: string, dto: CreateFamilyMemberDto) {
    const letter = await this.prisma.alephatLetter.findUnique({
      where: { id: letterId },
    });
    if (!letter) {
      throw new NotFoundException(`Alephat letter with ID '${letterId}' not found`);
    }

    const existingOrder = await this.prisma.alephatFamilyMember.findUnique({
      where: {
        baseLetterId_orderIndex: {
          baseLetterId: letterId,
          orderIndex: dto.orderIndex,
        },
      },
    });
    if (existingOrder) {
      throw new BadRequestException(
        `Family member with order index ${dto.orderIndex} already exists for '${letter.letter}'`,
      );
    }

    return this.prisma.alephatFamilyMember.create({
      data: {
        baseLetterId: letterId,
        glyph: dto.glyph.trim(),
        orderIndex: dto.orderIndex,
        orderName: dto.orderName?.trim(),
        note: dto.note?.trim(),
        pronunciation: dto.pronunciation?.trim(),
        isPublished: dto.isPublished ?? true,
      },
    });
  }

  async updateFamilyMember(
    letterId: string,
    memberId: string,
    dto: UpdateFamilyMemberDto,
  ) {
    const member = await this.prisma.alephatFamilyMember.findFirst({
      where: { id: memberId, baseLetterId: letterId },
    });
    if (!member) {
      throw new NotFoundException(`Family member '${memberId}' not found for letter '${letterId}'`);
    }

    if (dto.orderIndex && dto.orderIndex !== member.orderIndex) {
      const conflict = await this.prisma.alephatFamilyMember.findUnique({
        where: {
          baseLetterId_orderIndex: {
            baseLetterId: letterId,
            orderIndex: dto.orderIndex,
          },
        },
      });
      if (conflict && conflict.id !== memberId) {
        throw new BadRequestException(
          `Order index ${dto.orderIndex} is already occupied by member '${conflict.glyph}'`,
        );
      }
    }

    return this.prisma.alephatFamilyMember.update({
      where: { id: memberId },
      data: {
        glyph: dto.glyph?.trim(),
        orderIndex: dto.orderIndex,
        orderName: dto.orderName !== undefined ? dto.orderName?.trim() : undefined,
        note: dto.note !== undefined ? dto.note?.trim() : undefined,
        pronunciation: dto.pronunciation !== undefined ? dto.pronunciation?.trim() : undefined,
        isPublished: dto.isPublished !== undefined ? dto.isPublished : undefined,
      },
    });
  }

  async deleteFamilyMember(letterId: string, memberId: string) {
    const member = await this.prisma.alephatFamilyMember.findFirst({
      where: { id: memberId, baseLetterId: letterId },
    });
    if (!member) {
      throw new NotFoundException(`Family member '${memberId}' not found for letter '${letterId}'`);
    }

    await this.prisma.alephatFamilyMember.delete({ where: { id: memberId } });
    return { success: true };
  }

  async reorderFamilyMembers(letterId: string, dto: ReorderItemsDto) {
    await this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.alephatFamilyMember.update({
          where: { id: item.id },
          data: { orderIndex: item.order },
        }),
      ),
    );
    return { success: true };
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2: 22 Alephats Reference Section
  // ─────────────────────────────────────────────────────────

  async findAll22(query: QueryAlephatDto) {
    const where: any = {};

    if (!query.includeUnpublished) {
      where.isPublished = true;
    }

    if (query.search && query.search.trim().length > 0) {
      const term = query.search.trim();
      where.OR = [
        { letter: { contains: term, mode: 'insensitive' } },
        { title: { contains: term, mode: 'insensitive' } },
        { meaning: { contains: term, mode: 'insensitive' } },
        { note: { contains: term, mode: 'insensitive' } },
        { supplementaryInfo: { contains: term, mode: 'insensitive' } },
      ];
    }

    return this.prisma.alephat22Entry.findMany({
      where,
      orderBy: { order: 'asc' },
      include: {
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
        updatedBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
      },
    });
  }

  async find22ById(id: string, includeUnpublished = false) {
    const entry = await this.prisma.alephat22Entry.findUnique({
      where: { id },
      include: {
        createdBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
        updatedBy: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
      },
    });

    if (!entry || (!includeUnpublished && !entry.isPublished)) {
      throw new NotFoundException(`22 Alephat entry with ID '${id}' not found`);
    }

    return entry;
  }

  async create22(userId: string, dto: CreateAlephat22Dto) {
    let order = dto.order;
    if (order === undefined || order === null) {
      const highest = await this.prisma.alephat22Entry.findFirst({
        orderBy: { order: 'desc' },
        select: { order: true },
      });
      order = (highest?.order ?? 0) + 1;
    }

    return this.prisma.alephat22Entry.create({
      data: {
        letter: dto.letter.trim(),
        title: dto.title.trim(),
        meaning: dto.meaning?.trim(),
        order,
        note: dto.note.trim(),
        supplementaryInfo: dto.supplementaryInfo?.trim(),
        isPublished: dto.isPublished ?? true,
        createdById: userId,
        updatedById: userId,
      },
    });
  }

  async update22(userId: string, id: string, dto: UpdateAlephat22Dto) {
    const existing = await this.prisma.alephat22Entry.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`22 Alephat entry with ID '${id}' not found`);
    }

    return this.prisma.alephat22Entry.update({
      where: { id },
      data: {
        letter: dto.letter?.trim(),
        title: dto.title?.trim(),
        meaning: dto.meaning !== undefined ? dto.meaning?.trim() : undefined,
        order: dto.order !== undefined ? dto.order : undefined,
        note: dto.note !== undefined ? dto.note?.trim() : undefined,
        supplementaryInfo: dto.supplementaryInfo !== undefined ? dto.supplementaryInfo?.trim() : undefined,
        isPublished: dto.isPublished !== undefined ? dto.isPublished : undefined,
        updatedById: userId,
      },
    });
  }

  async delete22(id: string) {
    const existing = await this.prisma.alephat22Entry.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException(`22 Alephat entry with ID '${id}' not found`);
    }

    await this.prisma.alephat22Entry.delete({ where: { id } });
    return { success: true, message: `Entry '${existing.title}' successfully deleted` };
  }

  async reorder22(dto: ReorderItemsDto) {
    await this.prisma.$transaction(
      dto.items.map((item) =>
        this.prisma.alephat22Entry.update({
          where: { id: item.id },
          data: { order: item.order },
        }),
      ),
    );
    return { success: true };
  }
}
