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

  const UploadVideoFormData({
    required this.title,
    this.description = '',
    this.visibility = 'PUBLIC',
    this.categories = const [],
    this.tags = const [],
    this.hashtags = const [],
    this.downloadPermission = 'PUBLIC',
    this.isDownloadable = true,
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
    };
  }
}

class UploadInitRequest {
  final String title;
  final String description;
  final String visibility;
  final String channelId;
  final int sizeBytes;

  const UploadInitRequest({
    required this.title,
    this.description = '',
    this.visibility = 'PUBLIC',
    required this.channelId,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'visibility': visibility,
      'channelId': channelId,
      'sizeBytes': sizeBytes,
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
