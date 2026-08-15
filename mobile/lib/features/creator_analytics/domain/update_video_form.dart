// lib/features/creator_analytics/domain/update_video_form.dart

/// Matches the backend UpdateVideoDto exactly.
class UpdateVideoForm {
  final String? title;
  final String? description;
  final String? visibility;
  final String? downloadPermission;
  final bool? isDownloadable;
  final List<String>? categories;
  final List<String>? tags;
  final List<String>? hashtags;
  final String? seoTitle;
  final String? seoDescription;
  final String? scheduledAt;

  const UpdateVideoForm({
    this.title,
    this.description,
    this.visibility,
    this.downloadPermission,
    this.isDownloadable,
    this.categories,
    this.tags,
    this.hashtags,
    this.seoTitle,
    this.seoDescription,
    this.scheduledAt,
  });

  /// Convert to PATCH body, omitting null fields.
  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (visibility != null) 'visibility': visibility,
      if (downloadPermission != null) 'downloadPermission': downloadPermission,
      if (isDownloadable != null) 'isDownloadable': isDownloadable,
      if (categories != null) 'categories': categories,
      if (tags != null) 'tags': tags,
      if (hashtags != null) 'hashtags': hashtags,
      if (seoTitle != null) 'seoTitle': seoTitle,
      if (seoDescription != null) 'seoDescription': seoDescription,
      if (scheduledAt != null) 'scheduledAt': scheduledAt,
    };
  }
}
