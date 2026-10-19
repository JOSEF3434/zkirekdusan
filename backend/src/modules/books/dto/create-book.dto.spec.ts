import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { CreateBookDto, BookLanguageDto, BookFormatDto, BookStatusDto } from './create-book.dto.js';

describe('CreateBookDto Validation Contract', () => {
  const validPayload = {
    title: 'test',
    titleAm: 'ሙከራ',
    titleGez: 'ሙከራ',
    subtitle: 'test book',
    author: 'Mr. z',
    translator: 'mr. Y',
    publishedYear: 2019,
    pageCount: 300,
    description: 'test book uploaded',
    language: 'GEEZ',
    format: 'PDF',
    status: 'DRAFT',
    categoryId: '3dbbe380-2777-4a76-9d9d-3976a62fff3a',
    tags: ['test'],
    sortOrder: 0,
    coverFileId: '5e8caaac-5534-422f-8ca4-91521f941c4c',
    contentFileId: '4d6643ca-3697-49ac-bd67-6048d819fa91',
  };

  it('successfully validates user observed representative book creation payload', async () => {
    const dto = plainToInstance(CreateBookDto, validPayload);
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
    expect(dto.title).toBe('test');
    expect(dto.language).toBe(BookLanguageDto.GEEZ);
    expect(dto.format).toBe(BookFormatDto.PDF);
    expect(dto.status).toBe(BookStatusDto.DRAFT);
    expect(dto.publishedYear).toBe(2019);
    expect(dto.pageCount).toBe(300);
    expect(dto.tags).toEqual(['test']);
  });

  it('transforms comma-separated string tags into an array', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      tags: 'ethiopia, orthodox, ge\'ez',
    });
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
    expect(dto.tags).toEqual(['ethiopia', 'orthodox', "ge'ez"]);
  });

  it('transforms empty strings for optional fields into undefined', async () => {
    const dto = plainToInstance(CreateBookDto, {
      title: 'Valid Book',
      language: 'AMHARIC',
      format: 'PDF',
      categoryId: '',
      coverFileId: '',
      contentFileId: '',
      publishedYear: '',
      pageCount: '',
      sortOrder: '',
    });
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
    expect(dto.categoryId).toBeUndefined();
    expect(dto.coverFileId).toBeUndefined();
    expect(dto.contentFileId).toBeUndefined();
    expect(dto.publishedYear).toBeUndefined();
    expect(dto.pageCount).toBeUndefined();
  });

  it('rejects missing required title', async () => {
    const { title, ...missingTitle } = validPayload;
    const dto = plainToInstance(CreateBookDto, missingTitle);
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'title')).toBe(true);
  });

  it('rejects invalid language enum', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      language: 'LATIN',
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'language')).toBe(true);
  });

  it('rejects invalid format enum', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      format: 'DOCX',
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'format')).toBe(true);
  });

  it('rejects invalid status enum', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      status: 'DELETED',
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'status')).toBe(true);
  });

  it('rejects malformed UUID for categoryId, coverFileId, contentFileId', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      categoryId: 'not-a-uuid',
      coverFileId: 'invalid-cover-uuid',
      contentFileId: 'invalid-content-uuid',
    });
    const errors = await validate(dto);
    const props = errors.map((e) => e.property);
    expect(props).toContain('categoryId');
    expect(props).toContain('coverFileId');
    expect(props).toContain('contentFileId');
  });

  it('rejects invalid publishedYear out of range', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      publishedYear: 800,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'publishedYear')).toBe(true);
  });

  it('rejects invalid pageCount less than 1', async () => {
    const dto = plainToInstance(CreateBookDto, {
      ...validPayload,
      pageCount: 0,
    });
    const errors = await validate(dto);
    expect(errors.some((e) => e.property === 'pageCount')).toBe(true);
  });
});
