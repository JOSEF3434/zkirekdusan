// lib/features/books/data/models/book_category_model.dart

class BookCategoryModel {
  final String id;
  final String name;
  final String? nameAm;
  final String? nameGez;
  final String? description;
  final String slug;
  final String? parentId;
  final int sortOrder;
  final bool isVisible;
  final bool isArchived;
  final String? iconName;
  final String? coverUrl;
  final int booksCount;
  final List<BookCategoryModel> children;

  const BookCategoryModel({
    required this.id,
    required this.name,
    this.nameAm,
    this.nameGez,
    this.description,
    required this.slug,
    this.parentId,
    required this.sortOrder,
    required this.isVisible,
    required this.isArchived,
    this.iconName,
    this.coverUrl,
    required this.booksCount,
    required this.children,
  });

  factory BookCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    return BookCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAm: json['nameAm'] as String?,
      nameGez: json['nameGez'] as String?,
      description: json['description'] as String?,
      slug: json['slug'] as String,
      parentId: json['parentId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isArchived: json['isArchived'] as bool? ?? false,
      iconName: json['iconName'] as String?,
      coverUrl: json['coverUrl'] as String?,
      booksCount: (json['booksCount'] as num?)?.toInt() ??
          (json['_count']?['books'] as num?)?.toInt() ??
          0,
      children: rawChildren is List
          ? rawChildren
              .map((c) => BookCategoryModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Returns the localized name based on language code
  String localizedName(String langCode) {
    if (langCode == 'am' && nameAm != null && nameAm!.isNotEmpty) return nameAm!;
    if (langCode == 'gez' && nameGez != null && nameGez!.isNotEmpty) return nameGez!;
    return name;
  }
}
