// lib/features/books/data/models/book_model.dart

enum BookFormat { pdf, epub, text, audio, externalLink }

enum BookLanguage { amharic, geez, english, other }

enum BookStatus { draft, published, archived, deleted }

BookFormat _parseFormat(String? v) {
  switch (v?.toUpperCase()) {
    case 'PDF': return BookFormat.pdf;
    case 'EPUB': return BookFormat.epub;
    case 'TEXT': return BookFormat.text;
    case 'AUDIO': return BookFormat.audio;
    case 'EXTERNAL_LINK': return BookFormat.externalLink;
    default: return BookFormat.pdf;
  }
}

BookLanguage _parseLang(String? v) {
  switch (v?.toUpperCase()) {
    case 'AMHARIC': return BookLanguage.amharic;
    case 'GEEZ': return BookLanguage.geez;
    case 'ENGLISH': return BookLanguage.english;
    default: return BookLanguage.other;
  }
}

BookStatus _parseStatus(String? v) {
  switch (v?.toUpperCase()) {
    case 'DRAFT': return BookStatus.draft;
    case 'PUBLISHED': return BookStatus.published;
    case 'ARCHIVED': return BookStatus.archived;
    case 'DELETED': return BookStatus.deleted;
    default: return BookStatus.draft;
  }
}

class BookChapterModel {
  final String id;
  final int order;
  final String title;
  final String? titleAm;
  final String? titleGez;
  final String? content;
  final String? contentFileId;
  final String? contentFileUrl;
  final int? durationSeconds;

  const BookChapterModel({
    required this.id,
    required this.order,
    required this.title,
    this.titleAm,
    this.titleGez,
    this.content,
    this.contentFileId,
    this.contentFileUrl,
    this.durationSeconds,
  });

  factory BookChapterModel.fromJson(Map<String, dynamic> json) {
    return BookChapterModel(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      title: json['title'] as String,
      titleAm: json['titleAm'] as String?,
      titleGez: json['titleGez'] as String?,
      content: json['content'] as String?,
      contentFileId: json['contentFileId'] as String?,
      contentFileUrl: json['contentFile']?['url'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );
  }

  String localizedTitle(String langCode) {
    if (langCode == 'am' && titleAm != null && titleAm!.isNotEmpty) return titleAm!;
    if (langCode == 'gez' && titleGez != null && titleGez!.isNotEmpty) return titleGez!;
    return title;
  }
}

class ReadingProgressModel {
  final String bookId;
  final String? userId;
  final int? currentPage;
  final int? currentChapter;
  final double? scrollOffset;
  final double percentComplete;
  final bool isCompleted;
  final DateTime? lastReadAt;

  const ReadingProgressModel({
    required this.bookId,
    this.userId,
    this.currentPage,
    this.currentChapter,
    this.scrollOffset,
    required this.percentComplete,
    required this.isCompleted,
    this.lastReadAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      bookId: json['bookId'] as String? ?? '',
      userId: json['userId'] as String?,
      currentPage: (json['currentPage'] as num?)?.toInt(),
      currentChapter: (json['currentChapter'] as num?)?.toInt(),
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble(),
      percentComplete: (json['percentComplete'] as num?)?.toDouble() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'] as String)
          : null,
    );
  }

  ReadingProgressModel copyWith({
    int? currentPage,
    int? currentChapter,
    double? scrollOffset,
    double? percentComplete,
    bool? isCompleted,
  }) {
    return ReadingProgressModel(
      bookId: bookId,
      userId: userId,
      currentPage: currentPage ?? this.currentPage,
      currentChapter: currentChapter ?? this.currentChapter,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      percentComplete: percentComplete ?? this.percentComplete,
      isCompleted: isCompleted ?? this.isCompleted,
      lastReadAt: lastReadAt,
    );
  }
}

class BookModel {
  final String id;
  final String title;
  final String? titleAm;
  final String? titleGez;
  final String? subtitle;
  final String? author;
  final String? translator;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final BookLanguage language;
  final BookFormat format;
  final BookStatus status;
  final String? publisher;
  final int? publishedYear;
  final String? edition;
  final String? isbn;
  final int? pageCount;
  final List<String> tags;
  final int sortOrder;
  final String? externalUrl;
  final int viewsCount;
  final int bookmarksCount;

  // File refs
  final String? coverFileId;
  final String? coverUrl;
  final String? contentFileId;
  final String? contentUrl;
  final int? contentFileSizeBytes;

  // Chapter list (populated on detail view)
  final List<BookChapterModel> chapters;

  // My progress (populated when authenticated)
  final ReadingProgressModel? myProgress;

  final DateTime createdAt;
  final DateTime updatedAt;

  const BookModel({
    required this.id,
    required this.title,
    this.titleAm,
    this.titleGez,
    this.subtitle,
    this.author,
    this.translator,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.language,
    required this.format,
    required this.status,
    this.publisher,
    this.publishedYear,
    this.edition,
    this.isbn,
    this.pageCount,
    required this.tags,
    required this.sortOrder,
    this.externalUrl,
    required this.viewsCount,
    required this.bookmarksCount,
    this.coverFileId,
    this.coverUrl,
    this.contentFileId,
    this.contentUrl,
    this.contentFileSizeBytes,
    required this.chapters,
    this.myProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'];
    final rawProgress = json['myProgress'] ?? json['progress'];
    final rawCover = json['coverFile'];
    final rawContent = json['contentFile'];
    final rawCat = json['category'];

    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAm: json['titleAm'] as String?,
      titleGez: json['titleGez'] as String?,
      subtitle: json['subtitle'] as String?,
      author: json['author'] as String?,
      translator: json['translator'] as String?,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: rawCat != null ? rawCat['name'] as String? : null,
      language: _parseLang(json['language'] as String?),
      format: _parseFormat(json['format'] as String?),
      status: _parseStatus(json['status'] as String?),
      publisher: json['publisher'] as String?,
      publishedYear: (json['publishedYear'] as num?)?.toInt(),
      edition: json['edition'] as String?,
      isbn: json['isbn'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      externalUrl: json['externalUrl'] as String?,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarksCount'] as num?)?.toInt() ?? 0,
      coverFileId: rawCover?['id'] as String?,
      coverUrl: rawCover?['url'] as String?,
      contentFileId: rawContent?['id'] as String?,
      contentUrl: rawContent?['url'] as String?,
      contentFileSizeBytes:
          (rawContent?['fileSize'] as num?)?.toInt(),
      chapters: rawChapters is List
          ? rawChapters
              .map((c) => BookChapterModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      myProgress: rawProgress != null && rawProgress is Map
          ? ReadingProgressModel.fromJson(
              rawProgress as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String localizedTitle(String langCode) {
    if (langCode == 'am' && titleAm != null && titleAm!.isNotEmpty) return titleAm!;
    if (langCode == 'gez' && titleGez != null && titleGez!.isNotEmpty) return titleGez!;
    return title;
  }

  bool get isReadable =>
      format == BookFormat.pdf ||
      format == BookFormat.text ||
      format == BookFormat.epub;

  bool get hasContent =>
      contentUrl != null || externalUrl != null || chapters.isNotEmpty;
}

class PaginatedBooks {
  final List<BookModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;

  const PaginatedBooks({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
  });

  factory PaginatedBooks.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedBooks(
      items: data
          .map((b) => BookModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 20,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: meta['hasNext'] as bool? ?? false,
    );
  }
}
