// src/modules/books/dictionary/dictionary-parser.service.ts
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import AdmZip from 'adm-zip';
import { PDFParse } from 'pdf-parse';

export interface ParsedDefinition {
  text: string;
  partOfSpeech?: string;
  order?: number;
  examples?: string[];
}

export interface ParsedDictionaryEntry {
  headword: string;
  normalizedHeadword: string;
  definition: string;
  definitions: ParsedDefinition[];
  pageNumber?: number;
  chapterTitle?: string;
  metadata?: Record<string, any>;
}

export interface ParsedDictionaryResult {
  entries: ParsedDictionaryEntry[];
  totalExtracted: number;
  format: 'PDF' | 'EPUB';
  metadata: {
    totalPages?: number;
    totalChapters?: number;
    title?: string;
    sampleHeadwords?: string[];
  };
}

@Injectable()
export class DictionaryParserService {
  private readonly logger = new Logger(DictionaryParserService.name);

  /**
   * Unicode and punctuation normalization.
   * Strips zero-width chars and normalizes to NFKC.
   */
  normalizeText(text: string): string {
    if (!text) return '';
    return text
      .normalize('NFKC')
      .replace(/[\u200B-\u200D\uFEFF]/g, '')
      .trim();
  }

  /**
   * Normalizes a headword for search indexing.
   * Lowercases (for Latin scripts), removes surrounding punctuation and whitespace.
   * Preserves Ethiopic characters (U+1200 - U+137F).
   */
  normalizeHeadword(word: string): string {
    if (!word) return '';
    let normalized = this.normalizeText(word).toLowerCase();
    // Strip leading/trailing punctuation except Ethiopic letters
    normalized = normalized.replace(/^[\s\p{P}]+/u, '').replace(/[\s\p{P}]+$/u, '');
    // Replace multiple spaces with single space
    return normalized.replace(/\s+/g, ' ').trim();
  }

  /**
   * Parses a PDF dictionary buffer.
   */
  async parsePdf(buffer: Buffer): Promise<ParsedDictionaryResult> {
    if (!buffer || buffer.length === 0) {
      throw new BadRequestException('Empty PDF buffer received for dictionary processing');
    }

    try {
      const pdfParser = new PDFParse({ data: buffer });
      const textResult = await pdfParser.getText();

      const pages = (textResult.pages || []).map((p: any) => ({
        pageNumber: p.num,
        text: p.text || '',
      }));
      const fullText = (textResult.text || '').trim();

      // Check for scanned / image-based PDF
      if (fullText.length < 50 && pages.every((p: any) => p.text.trim().length < 20)) {
        throw new BadRequestException(
          'Uploaded PDF appears to be scanned or image-based with no extractable text layer. ' +
            'Please upload a searchable text-based PDF or EPUB.',
        );
      }

      const allEntries: ParsedDictionaryEntry[] = [];
      const entryMap = new Map<string, ParsedDictionaryEntry>();

      for (const page of pages) {
        const pageEntries = this.parseEntriesFromText(page.text, page.pageNumber);
        for (const entry of pageEntries) {
          const key = entry.normalizedHeadword;
          if (!entryMap.has(key)) {
            entryMap.set(key, entry);
            allEntries.push(entry);
          } else {
            // Merge multiple definitions for identical headword
            const existing = entryMap.get(key)!;
            if (!existing.definition.includes(entry.definition)) {
              existing.definition += ` ; ${entry.definition}`;
              existing.definitions.push(...entry.definitions);
            }
          }
        }
      }

      if (allEntries.length === 0) {
        // Fallback: parse full text as contiguous block
        const fallback = this.parseEntriesFromText(fullText);
        allEntries.push(...fallback);
      }

      if (allEntries.length === 0) {
        throw new BadRequestException(
          'Could not detect dictionary headwords or definitions in the PDF. ' +
            'Ensure the dictionary follows standard format (e.g. "word: definition" or "word - definition").',
        );
      }

      return {
        entries: allEntries,
        totalExtracted: allEntries.length,
        format: 'PDF',
        metadata: {
          totalPages: pages.length || textResult.total,
          sampleHeadwords: allEntries.slice(0, 10).map((e) => e.headword),
        },
      };
    } catch (err: any) {
      this.logger.error(`Failed to parse PDF dictionary: ${err.message}`, err.stack);
      if (err instanceof BadRequestException) throw err;
      throw new BadRequestException(`PDF dictionary parsing error: ${err.message}`);
    }
  }

  /**
   * Parses an EPUB dictionary buffer.
   */
  async parseEpub(buffer: Buffer): Promise<ParsedDictionaryResult> {
    if (!buffer || buffer.length === 0) {
      throw new BadRequestException('Empty EPUB buffer received for dictionary processing');
    }

    try {
      const zip = new AdmZip(buffer);
      const zipEntries = zip.getEntries();

      // 1. Locate container.xml to find root OPF file
      const containerEntry = zipEntries.find((e: any) =>
        e.entryName.toLowerCase().includes('meta-inf/container.xml'),
      );

      let opfPath = '';
      if (containerEntry) {
        const containerXml = containerEntry.getData().toString('utf8');
        const rootfileMatch = containerXml.match(/full-path\s*=\s*["']([^"']+)["']/i);
        if (rootfileMatch) {
          opfPath = rootfileMatch[1];
        }
      }

      // If no container, find any .opf file
      if (!opfPath) {
        const opfEntry = zipEntries.find((e: any) => e.entryName.endsWith('.opf'));
        if (opfEntry) opfPath = opfEntry.entryName;
      }

      let opfDir = '';
      if (opfPath.includes('/')) {
        opfDir = opfPath.substring(0, opfPath.lastIndexOf('/') + 1);
      }

      // 2. Read OPF to discover chapter order
      const chapterFiles: string[] = [];
      if (opfPath) {
        const opfEntry = zip.getEntry(opfPath);
        if (opfEntry) {
          const opfXml = opfEntry.getData().toString('utf8');
          // Parse manifest id -> href
          const manifestMap = new Map<string, string>();
          const itemRegex = /<item\s+[^>]*id=["']([^"']+)["'][^>]*href=["']([^"']+)["'][^>]*>/gi;
          let m: RegExpExecArray | null;
          while ((m = itemRegex.exec(opfXml)) !== null) {
            manifestMap.set(m[1], m[2]);
          }

          // Parse spine itemrefs in order
          const itemrefRegex = /<itemref\s+[^>]*idref=["']([^"']+)["'][^>]*>/gi;
          while ((m = itemrefRegex.exec(opfXml)) !== null) {
            const href = manifestMap.get(m[1]);
            if (href) {
              chapterFiles.push(opfDir ? `${opfDir}${href}` : href);
            }
          }
        }
      }

      // Fallback if no spine found: collect all html/xhtml files
      if (chapterFiles.length === 0) {
        for (const entry of zipEntries) {
          const name = entry.entryName.toLowerCase();
          if (
            (name.endsWith('.html') || name.endsWith('.xhtml') || name.endsWith('.htm')) &&
            !name.includes('toc')
          ) {
            chapterFiles.push(entry.entryName);
          }
        }
      }

      const allEntries: ParsedDictionaryEntry[] = [];
      const entryMap = new Map<string, ParsedDictionaryEntry>();
      let chapterIndex = 0;

      for (const filePath of chapterFiles) {
        // Clean relative path syntax like ../
        const normalizedPath = filePath.replace(/\\/g, '/');
        const entry =
          zip.getEntry(normalizedPath) ||
          zipEntries.find(
            (e: any) =>
              e.entryName.endsWith(normalizedPath.split('/').pop()!) ||
              e.entryName.toLowerCase() === normalizedPath.toLowerCase(),
          );

        if (!entry) continue;
        chapterIndex++;

        const content = entry.getData().toString('utf8');
        const chapterTitle = `Chapter ${chapterIndex}`;

        // Attempt structured HTML parsing first (<dl>, <dt>/<dd>, <b>word</b>: meaning, etc.)
        const parsedHtmlEntries = this.parseStructuredHtml(content, chapterTitle);

        if (parsedHtmlEntries.length > 0) {
          for (const ent of parsedHtmlEntries) {
            const key = ent.normalizedHeadword;
            if (!entryMap.has(key)) {
              entryMap.set(key, ent);
              allEntries.push(ent);
            } else {
              const existing = entryMap.get(key)!;
              if (!existing.definition.includes(ent.definition)) {
                existing.definition += ` ; ${ent.definition}`;
                existing.definitions.push(...ent.definitions);
              }
            }
          }
        } else {
          // Plain text extraction from HTML
          const textOnly = content
            .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
            .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
            .replace(/<[^>]+>/g, ' ')
            .replace(/&nbsp;/g, ' ')
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>');

          const textEntries = this.parseEntriesFromText(textOnly, undefined, chapterTitle);
          for (const ent of textEntries) {
            const key = ent.normalizedHeadword;
            if (!entryMap.has(key)) {
              entryMap.set(key, ent);
              allEntries.push(ent);
            } else {
              const existing = entryMap.get(key)!;
              if (!existing.definition.includes(ent.definition)) {
                existing.definition += ` ; ${ent.definition}`;
                existing.definitions.push(...ent.definitions);
              }
            }
          }
        }
      }

      if (allEntries.length === 0) {
        throw new BadRequestException(
          'Could not extract dictionary entries from the EPUB. ' +
            'Please verify the file contains dictionary headwords and definitions.',
        );
      }

      return {
        entries: allEntries,
        totalExtracted: allEntries.length,
        format: 'EPUB',
        metadata: {
          totalChapters: chapterFiles.length,
          sampleHeadwords: allEntries.slice(0, 10).map((e) => e.headword),
        },
      };
    } catch (err: any) {
      this.logger.error(`Failed to parse EPUB dictionary: ${err.message}`, err.stack);
      if (err instanceof BadRequestException) throw err;
      throw new BadRequestException(`EPUB dictionary parsing error: ${err.message}`);
    }
  }

  /**
   * Parses structured HTML/XHTML dictionary markup (e.g. <dl>, <b>headword</b>, class="entry")
   */
  parseStructuredHtml(html: string, chapterTitle?: string): ParsedDictionaryEntry[] {
    const entries: ParsedDictionaryEntry[] = [];

    // Pattern 1: <dt>word</dt><dd>meaning</dd>
    const dlRegex = /<dt[^>]*>([\s\S]*?)<\/dt>\s*<dd[^>]*>([\s\S]*?)<\/dd>/gi;
    let m: RegExpExecArray | null;
    while ((m = dlRegex.exec(html)) !== null) {
      const rawWord = this.stripHtml(m[1]);
      const rawDef = this.stripHtml(m[2]);
      const entry = this.createEntry(rawWord, rawDef, undefined, chapterTitle);
      if (entry) entries.push(entry);
    }
    if (entries.length > 0) return entries;

    // Pattern 2: <p><b>word</b> : meaning</p> or <p><strong>word</strong> — meaning</p>
    const boldRegex = /<p[^>]*>\s*<(?:b|strong)[^>]*>([\s\S]*?)<\/(?:b|strong)>\s*[:\-—=]\s*([\s\S]*?)<\/p>/gi;
    while ((m = boldRegex.exec(html)) !== null) {
      const rawWord = this.stripHtml(m[1]);
      const rawDef = this.stripHtml(m[2]);
      const entry = this.createEntry(rawWord, rawDef, undefined, chapterTitle);
      if (entry) entries.push(entry);
    }
    if (entries.length > 0) return entries;

    // Pattern 3: <div class="*entry*"><span class="*hw*|*headword*">word</span><span class="*def*">meaning</span></div>
    const classRegex = /class=["'][^"']*(?:entry|dict-item)[^"']*["'][\s\S]*?<(?:span|div|b)[^>]*class=["'][^"']*(?:hw|headword|word)[^"']*["']>([\s\S]*?)<\/(?:span|div|b)>[\s\S]*?<(?:span|div|p)[^>]*class=["'][^"']*(?:def|meaning|translation)[^"']*["']>([\s\S]*?)<\/(?:span|div|p)>/gi;
    while ((m = classRegex.exec(html)) !== null) {
      const rawWord = this.stripHtml(m[1]);
      const rawDef = this.stripHtml(m[2]);
      const entry = this.createEntry(rawWord, rawDef, undefined, chapterTitle);
      if (entry) entries.push(entry);
    }

    return entries;
  }

  /**
   * Parses raw lines of text into dictionary entries.
   * Handles patterns such as:
   *   "Word: Definition"
   *   "Word - Definition"
   *   "Word — Definition"
   *   "Word = Definition"
   *   "Word   Definition" (tab or 2+ spaces separator)
   *   "Word\n  Definition line 1\n  Definition line 2"
   */
  parseEntriesFromText(
    text: string,
    pageNumber?: number,
    chapterTitle?: string,
  ): ParsedDictionaryEntry[] {
    const entries: ParsedDictionaryEntry[] = [];
    if (!text) return entries;

    const lines = text.split(/\r?\n/);
    let currentHeadword: string | null = null;
    let currentDefinitionLines: string[] = [];

    const flushCurrent = () => {
      if (currentHeadword && currentDefinitionLines.length > 0) {
        const fullDef = currentDefinitionLines.join(' ').trim();
        const entry = this.createEntry(currentHeadword, fullDef, pageNumber, chapterTitle);
        if (entry) entries.push(entry);
      }
      currentHeadword = null;
      currentDefinitionLines = [];
    };

    // Primary inline delimiter pattern: "Headword: Definition" or "Headword - Definition" or "Headword — Definition"
    const inlineDelimRegex = /^([^\s:—=\-\t][^:—=\-\t\n]{0,60}?)\s*(?:[:—=]|\s+-\s+|\t)\s*(.+)$/;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) {
        flushCurrent();
        continue;
      }

      // Check if line contains a standard inline delimiter
      const match = line.match(inlineDelimRegex);
      if (match) {
        flushCurrent();
        const candWord = match[1].trim();
        const candDef = match[2].trim();

        // Validate candidate headword length and characteristics
        if (candWord.length > 0 && candWord.length <= 60 && !candWord.match(/^\d+$/)) {
          currentHeadword = candWord;
          currentDefinitionLines.push(candDef);
          continue;
        }
      }

      // Check if line looks like a standalone headword followed by indented definition
      if (line.length <= 50 && !line.includes('.') && !line.includes('፤') && !line.match(/^\d+$/)) {
        // If next line exists and is longer or indented, treat current as headword
        const nextLine = lines[i + 1]?.trim();
        if (nextLine && nextLine.length > line.length) {
          flushCurrent();
          currentHeadword = line;
          continue;
        }
      }

      // Otherwise, line is a continuation of the current definition
      if (currentHeadword) {
        currentDefinitionLines.push(line);
      }
    }

    flushCurrent();
    return entries;
  }

  /**
   * Helper to construct a normalized entry and parse sub-meanings.
   */
  private createEntry(
    rawWord: string,
    rawDef: string,
    pageNumber?: number,
    chapterTitle?: string,
  ): ParsedDictionaryEntry | null {
    const word = this.normalizeText(rawWord);
    const def = this.normalizeText(rawDef);
    const norm = this.normalizeHeadword(word);

    if (!word || !def || !norm || norm.length < 1 || norm.length > 100) {
      return null;
    }

    // Parse numbered or separated definitions
    const definitions = this.parseMultipleDefinitions(def);

    return {
      headword: word,
      normalizedHeadword: norm,
      definition: def,
      definitions,
      pageNumber,
      chapterTitle,
    };
  }

  /**
   * Parses multiple meanings from a definition string.
   * e.g. "1. First meaning. 2. Second meaning." or Amharic "ፍቅር፤ አድናቆት"
   */
  parseMultipleDefinitions(definitionText: string): ParsedDefinition[] {
    const results: ParsedDefinition[] = [];

    // Check for numbered meanings: 1. ... 2. ...
    const numberedRegex = /(?:^|\s)(?:\d+[\.\)]|\([0-9]+\))\s+/;
    if (numberedRegex.test(definitionText)) {
      const parts = definitionText.split(/(?:^|\s)(?:\d+[\.\)]|\([0-9]+\))\s+/).filter(Boolean);
      parts.forEach((p, idx) => {
        const trimmed = p.trim();
        if (trimmed) {
          results.push({
            order: idx + 1,
            text: trimmed,
          });
        }
      });
      if (results.length > 0) return results;
    }

    // Check for semicolon-separated items
    if (definitionText.includes(';') || definitionText.includes('፤')) {
      const items = definitionText.split(/[;፤]/).filter(Boolean);
      items.forEach((item, idx) => {
        const trimmed = item.trim();
        if (trimmed) {
          results.push({
            order: idx + 1,
            text: trimmed,
          });
        }
      });
      if (results.length > 0) return results;
    }

    // Default single meaning
    results.push({
      order: 1,
      text: definitionText,
    });
    return results;
  }

  private stripHtml(html: string): string {
    return (html || '')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .trim();
  }
}
