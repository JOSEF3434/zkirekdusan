// lib/features/books/data/models/dictionary_model.dart

class DictionaryLanguageModel {
  final String id;
  final String code;
  final String name;
  final String nativeName;
  final String direction;
  final bool isEnabled;
  final int sortOrder;
  final Map<String, dynamic>? localizedNames;

  const DictionaryLanguageModel({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
    this.direction = 'ltr',
    this.isEnabled = true,
    this.sortOrder = 0,
    this.localizedNames,
  });

  bool get isRtl => direction.toLowerCase() == 'rtl';

  factory DictionaryLanguageModel.fromJson(Map<String, dynamic> json) {
    return DictionaryLanguageModel(
      id: json['id'] as String? ?? '',
      code: (json['code'] as String? ?? '').toLowerCase(),
      name: json['name'] as String? ?? '',
      nativeName: json['nativeName'] as String? ?? json['name'] as String? ?? '',
      direction: json['direction'] as String? ?? 'ltr',
      isEnabled: json['isEnabled'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      localizedNames: json['localizedNames'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'nativeName': nativeName,
        'direction': direction,
        'isEnabled': isEnabled,
        'sortOrder': sortOrder,
        'localizedNames': localizedNames,
      };

  String localizedDisplayName(String appLangCode) {
    if (localizedNames != null &&
        localizedNames!.containsKey(appLangCode) &&
        (localizedNames![appLangCode]?.toString().isNotEmpty ?? false)) {
      return localizedNames![appLangCode].toString();
    }
    if (appLangCode == 'am' && nativeName.isNotEmpty && code == 'am') {
      return nativeName;
    }
    return '$nativeName ($name)';
  }
}

class DictionaryConfigModel {
  final String id;
  final String dictionaryName;
  final String? description;
  final String sourceLanguageId;
  final String targetLanguageId;
  final DictionaryLanguageModel? sourceLanguage;
  final DictionaryLanguageModel? targetLanguage;
  final String processingStatus;
  final int totalEntries;
  final String? errorMessage;
  final DateTime? processedAt;

  const DictionaryConfigModel({
    required this.id,
    required this.dictionaryName,
    this.description,
    required this.sourceLanguageId,
    required this.targetLanguageId,
    this.sourceLanguage,
    this.targetLanguage,
    required this.processingStatus,
    this.totalEntries = 0,
    this.errorMessage,
    this.processedAt,
  });

  bool get isReady => processingStatus.toUpperCase() == 'READY';
  bool get isProcessing =>
      processingStatus.toUpperCase() == 'VALIDATING' ||
      processingStatus.toUpperCase() == 'EXTRACTING' ||
      processingStatus.toUpperCase() == 'PARSING' ||
      processingStatus.toUpperCase() == 'INDEXING' ||
      processingStatus.toUpperCase() == 'RETRYING';
  bool get isFailed => processingStatus.toUpperCase() == 'FAILED';

  factory DictionaryConfigModel.fromJson(Map<String, dynamic> json) {
    return DictionaryConfigModel(
      id: json['id'] as String? ?? '',
      dictionaryName: json['dictionaryName'] as String? ?? 'መዝገበ ቃላት',
      description: json['description'] as String?,
      sourceLanguageId: json['sourceLanguageId'] as String? ?? '',
      targetLanguageId: json['targetLanguageId'] as String? ?? '',
      sourceLanguage: json['sourceLanguage'] != null
          ? DictionaryLanguageModel.fromJson(json['sourceLanguage'] as Map<String, dynamic>)
          : null,
      targetLanguage: json['targetLanguage'] != null
          ? DictionaryLanguageModel.fromJson(json['targetLanguage'] as Map<String, dynamic>)
          : null,
      processingStatus: json['processingStatus'] as String? ?? 'PENDING',
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dictionaryName': dictionaryName,
        'description': description,
        'sourceLanguageId': sourceLanguageId,
        'targetLanguageId': targetLanguageId,
        'processingStatus': processingStatus,
        'totalEntries': totalEntries,
        'errorMessage': errorMessage,
        'processedAt': processedAt?.toIso8601String(),
      };
}

class DefinitionItem {
  final String text;
  final String? entryId;
  final String? headword;
  final int? pageNumber;
  final String? chapterTitle;
  final List<dynamic>? subDefinitions;

  const DefinitionItem({
    required this.text,
    this.entryId,
    this.headword,
    this.pageNumber,
    this.chapterTitle,
    this.subDefinitions,
  });

  factory DefinitionItem.fromJson(Map<String, dynamic> json) {
    return DefinitionItem(
      text: json['text'] as String? ?? '',
      entryId: json['entryId'] as String?,
      headword: json['headword'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      chapterTitle: json['chapterTitle'] as String?,
      subDefinitions: json['definitions'] as List<dynamic>?,
    );
  }
}

class DictionaryTranslationResult {
  final String word;
  final String? normalizedWord;
  final String? dictionaryBookId;
  final String? dictionaryName;
  final String sourceLanguage;
  final String targetLanguage;
  final int totalMatches;
  final List<DefinitionItem> definitions;
  final String? message;

  const DictionaryTranslationResult({
    required this.word,
    this.normalizedWord,
    this.dictionaryBookId,
    this.dictionaryName,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.totalMatches = 0,
    required this.definitions,
    this.message,
  });

  bool get hasDefinitions => definitions.isNotEmpty;

  factory DictionaryTranslationResult.fromJson(Map<String, dynamic> json) {
    final rawDefs = json['definitions'] as List? ?? [];
    return DictionaryTranslationResult(
      word: json['word'] as String? ?? '',
      normalizedWord: json['normalizedWord'] as String?,
      dictionaryBookId: json['dictionaryBookId'] as String?,
      dictionaryName: json['dictionaryName'] as String?,
      sourceLanguage: json['sourceLanguage'] is Map
          ? (json['sourceLanguage']['name'] as String? ?? json['sourceLanguage']['code'] as String? ?? 'en')
          : (json['sourceLanguage'] as String? ?? 'en'),
      targetLanguage: json['targetLanguage'] is Map
          ? (json['targetLanguage']['nativeName'] as String? ?? json['targetLanguage']['name'] as String? ?? 'am')
          : (json['targetLanguage'] as String? ?? 'am'),
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? rawDefs.length,
      definitions: rawDefs
          .map((d) => DefinitionItem.fromJson(d as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}

class TranslationHistoryItemModel {
  final String id;
  final String userId;
  final String word;
  final String sourceLanguage;
  final String targetLanguage;
  final String definition;
  final String? dictionaryBookId;
  final String? dictionaryEntryId;
  final String dictionaryNameSnapshot;
  final int? pageNumber;
  final String? chapter;
  final String? surroundingSentence;
  final DateTime createdAt;

  const TranslationHistoryItemModel({
    required this.id,
    required this.userId,
    required this.word,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.definition,
    this.dictionaryBookId,
    this.dictionaryEntryId,
    required this.dictionaryNameSnapshot,
    this.pageNumber,
    this.chapter,
    this.surroundingSentence,
    required this.createdAt,
  });

  factory TranslationHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return TranslationHistoryItemModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      word: json['word'] as String? ?? '',
      sourceLanguage: json['sourceLanguage'] as String? ?? '',
      targetLanguage: json['targetLanguage'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      dictionaryBookId: json['dictionaryBookId'] as String?,
      dictionaryEntryId: json['dictionaryEntryId'] as String?,
      dictionaryNameSnapshot:
          json['dictionaryNameSnapshot'] as String? ?? 'መዝገበ ቃላት',
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      chapter: json['chapter'] as String?,
      surroundingSentence: json['surroundingSentence'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'word': word,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'definition': definition,
        'dictionaryBookId': dictionaryBookId,
        'dictionaryEntryId': dictionaryEntryId,
        'dictionaryNameSnapshot': dictionaryNameSnapshot,
        'pageNumber': pageNumber,
        'chapter': chapter,
        'surroundingSentence': surroundingSentence,
        'createdAt': createdAt.toIso8601String(),
      };
}

