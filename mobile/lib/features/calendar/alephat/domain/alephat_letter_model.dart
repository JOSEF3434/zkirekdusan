// lib/features/calendar/alephat/domain/alephat_letter_model.dart

class AlephatFamilyMemberModel {
  final String id;
  final String baseLetterId;
  final String glyph;
  final int orderIndex;
  final String? orderName;
  final String? note;
  final String? pronunciation;
  final bool isPublished;

  const AlephatFamilyMemberModel({
    required this.id,
    required this.baseLetterId,
    required this.glyph,
    required this.orderIndex,
    this.orderName,
    this.note,
    this.pronunciation,
    this.isPublished = true,
  });

  factory AlephatFamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return AlephatFamilyMemberModel(
      id: json['id'] as String? ?? '',
      baseLetterId: json['baseLetterId'] as String? ?? '',
      glyph: json['glyph'] as String? ?? '',
      orderIndex: json['orderIndex'] as int? ?? 1,
      orderName: json['orderName'] as String?,
      note: json['note'] as String?,
      pronunciation: json['pronunciation'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'baseLetterId': baseLetterId,
    'glyph': glyph,
    'orderIndex': orderIndex,
    if (orderName != null) 'orderName': orderName,
    if (note != null) 'note': note,
    if (pronunciation != null) 'pronunciation': pronunciation,
    'isPublished': isPublished,
  };

  AlephatFamilyMemberModel copyWith({
    String? id,
    String? baseLetterId,
    String? glyph,
    int? orderIndex,
    String? orderName,
    String? note,
    String? pronunciation,
    bool? isPublished,
  }) {
    return AlephatFamilyMemberModel(
      id: id ?? this.id,
      baseLetterId: baseLetterId ?? this.baseLetterId,
      glyph: glyph ?? this.glyph,
      orderIndex: orderIndex ?? this.orderIndex,
      orderName: orderName ?? this.orderName,
      note: note ?? this.note,
      pronunciation: pronunciation ?? this.pronunciation,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

class AlephatLetterModel {
  final String id;
  final String letter;
  final String? name;
  final int order;
  final String? defaultNote;
  final String? pronunciationGuide;
  final bool isPublished;
  final List<AlephatFamilyMemberModel> familyMembers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AlephatLetterModel({
    required this.id,
    required this.letter,
    this.name,
    this.order = 0,
    this.defaultNote,
    this.pronunciationGuide,
    this.isPublished = true,
    this.familyMembers = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AlephatLetterModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['familyMembers'];
    List<AlephatFamilyMemberModel> members = [];
    if (rawMembers is List) {
      members = rawMembers
          .map((m) => AlephatFamilyMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
      members.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return AlephatLetterModel(
      id: json['id'] as String? ?? '',
      letter: json['letter'] as String? ?? '',
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      defaultNote: json['defaultNote'] as String?,
      pronunciationGuide: json['pronunciationGuide'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
      familyMembers: members,
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
    if (name != null) 'name': name,
    'order': order,
    if (defaultNote != null) 'defaultNote': defaultNote,
    if (pronunciationGuide != null) 'pronunciationGuide': pronunciationGuide,
    'isPublished': isPublished,
    'familyMembers': familyMembers.map((m) => m.toJson()).toList(),
  };

  AlephatLetterModel copyWith({
    String? id,
    String? letter,
    String? name,
    int? order,
    String? defaultNote,
    String? pronunciationGuide,
    bool? isPublished,
    List<AlephatFamilyMemberModel>? familyMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlephatLetterModel(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      name: name ?? this.name,
      order: order ?? this.order,
      defaultNote: defaultNote ?? this.defaultNote,
      pronunciationGuide: pronunciationGuide ?? this.pronunciationGuide,
      isPublished: isPublished ?? this.isPublished,
      familyMembers: familyMembers ?? this.familyMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
