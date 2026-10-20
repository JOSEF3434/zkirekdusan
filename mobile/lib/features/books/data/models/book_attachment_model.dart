// lib/features/books/data/models/book_attachment_model.dart

enum AttachmentMediaType {
  document,
  image,
  audio,
  video,
  other,
}

AttachmentMediaType parseAttachmentMediaType(String? mimeType, String? fileType) {
  final ft = fileType?.toUpperCase();
  if (ft == 'IMAGE') return AttachmentMediaType.image;
  if (ft == 'AUDIO') return AttachmentMediaType.audio;
  if (ft == 'VIDEO') return AttachmentMediaType.video;
  if (ft == 'DOCUMENT') return AttachmentMediaType.document;

  if (mimeType != null) {
    if (mimeType.startsWith('image/')) return AttachmentMediaType.image;
    if (mimeType.startsWith('audio/')) return AttachmentMediaType.audio;
    if (mimeType.startsWith('video/')) return AttachmentMediaType.video;
    if (mimeType.contains('pdf') ||
        mimeType.contains('epub') ||
        mimeType.contains('word') ||
        mimeType.contains('text')) {
      return AttachmentMediaType.document;
    }
  }
  return AttachmentMediaType.other;
}

class BookAttachmentModel {
  final String id;
  final String fileId;
  final String? title;
  final int sortOrder;
  final String? url;
  final String? originalName;
  final String? mimeType;
  final int? fileSizeBytes;
  final AttachmentMediaType mediaType;
  final DateTime createdAt;

  const BookAttachmentModel({
    required this.id,
    required this.fileId,
    this.title,
    this.sortOrder = 0,
    this.url,
    this.originalName,
    this.mimeType,
    this.fileSizeBytes,
    this.mediaType = AttachmentMediaType.other,
    required this.createdAt,
  });

  factory BookAttachmentModel.fromJson(Map<String, dynamic> json) {
    final fileObj = json['file'] as Map<String, dynamic>?;
    final mime = fileObj?['mimeType'] as String?;
    final ft = fileObj?['fileType'] as String?;

    return BookAttachmentModel(
      id: json['id'] as String? ?? '',
      fileId: json['fileId'] as String? ?? fileObj?['id'] as String? ?? '',
      title: json['title'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      url: fileObj?['url'] as String?,
      originalName: fileObj?['originalName'] as String?,
      mimeType: mime,
      fileSizeBytes: ((fileObj?['size'] ?? fileObj?['fileSize']) as num?)?.toInt(),
      mediaType: parseAttachmentMediaType(mime, ft),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileId': fileId,
        if (title != null) 'title': title,
        'sortOrder': sortOrder,
      };

  String get displayName =>
      (title != null && title!.trim().isNotEmpty) ? title! : (originalName ?? 'Attachment');
}
