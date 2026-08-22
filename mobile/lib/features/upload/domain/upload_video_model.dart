// lib/features/upload/domain/upload_video_model.dart

class UploadVideoFormData {
  final String title;
  final String description;
  final String visibility;
  final List<String> categories;
  final List<String> tags;
  final List<String> hashtags;
  final String downloadPermission;
  final bool isDownloadable;
  final String? playlistId;

  const UploadVideoFormData({
    required this.title,
    this.description = '',
    this.visibility = 'PUBLIC',
    this.categories = const [],
    this.tags = const [],
    this.hashtags = const [],
    this.downloadPermission = 'PUBLIC',
    this.isDownloadable = true,
    this.playlistId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'visibility': visibility,
      'categories': categories,
      'tags': tags,
      'hashtags': hashtags,
      'downloadPermission': downloadPermission,
      'isDownloadable': isDownloadable,
      if (playlistId != null) 'playlistId': playlistId,
    };
  }
}

class UploadInitRequest {
  final String title;
  final String description;
  final String visibility;
  final String channelId;
  final int sizeBytes;
  final String? playlistId;
  final String downloadPermission;
  final bool isDownloadable;
  final List<String> categories;
  final List<String> tags;
  final List<String> hashtags;

  const UploadInitRequest({
    required this.title,
    this.description = '',
    this.visibility = 'PUBLIC',
    required this.channelId,
    this.sizeBytes = 0,
    this.playlistId,
    this.downloadPermission = 'PUBLIC',
    this.isDownloadable = true,
    this.categories = const [],
    this.tags = const [],
    this.hashtags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'visibility': visibility,
      'downloadPermission': downloadPermission,
      'isDownloadable': isDownloadable,
      if (categories.isNotEmpty) 'categories': categories,
      if (tags.isNotEmpty) 'tags': tags,
      if (hashtags.isNotEmpty) 'hashtags': hashtags,
    };
  }
}

class UploadInitResponse {
  final String videoId;
  final String uploadUrl;

  const UploadInitResponse({required this.videoId, required this.uploadUrl});

  factory UploadInitResponse.fromJson(Map<String, dynamic> json) {
    return UploadInitResponse(
      videoId: json['videoId'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
    );
  }
}
