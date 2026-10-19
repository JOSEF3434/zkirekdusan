// lib/features/calendar/alephat/domain/alephat_22_model.dart

class Alephat22Model {
  final String id;
  final String letter;
  final String title;
  final String? meaning;
  final int order;
  final String note;
  final String? supplementaryInfo;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Alephat22Model({
    required this.id,
    required this.letter,
    required this.title,
    this.meaning,
    this.order = 0,
    required this.note,
    this.supplementaryInfo,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Alephat22Model.fromJson(Map<String, dynamic> json) {
    return Alephat22Model(
      id: json['id'] as String? ?? '',
      letter: json['letter'] as String? ?? '',
      title: json['title'] as String? ?? '',
      meaning: json['meaning'] as String?,
      order: json['order'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      supplementaryInfo: json['supplementaryInfo'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'letter': letter,
    'title': title,
    if (meaning != null) 'meaning': meaning,
    'order': order,
    'note': note,
    if (supplementaryInfo != null) 'supplementaryInfo': supplementaryInfo,
    'isPublished': isPublished,
  };

  Alephat22Model copyWith({
    String? id,
    String? letter,
    String? title,
    String? meaning,
    int? order,
    String? note,
    String? supplementaryInfo,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alephat22Model(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      title: title ?? this.title,
      meaning: meaning ?? this.meaning,
      order: order ?? this.order,
      note: note ?? this.note,
      supplementaryInfo: supplementaryInfo ?? this.supplementaryInfo,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
