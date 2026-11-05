// src/modules/books/dictionary/dto/update-dictionary-language.dto.ts
import { PartialType } from '@nestjs/swagger';
import { CreateDictionaryLanguageDto } from './create-dictionary-language.dto.js';

export class UpdateDictionaryLanguageDto extends PartialType(CreateDictionaryLanguageDto) {}

