import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

enum SearchEntityType {
  users,
  groups,
  channels,
  posts,
  videos,
  reels,
  playlists,
  streams,
}

class SearchUserDto {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const SearchUserDto({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory SearchUserDto.fromJson(Map<String, dynamic> json) {
    return SearchUserDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class SearchResultsDto {
  final List<SearchUserDto> users;
  final List<PostResponseDto> posts;
  final List<VideoResponseDto> videos;

  const SearchResultsDto({
    this.users = const [],
    this.posts = const [],
    this.videos = const [],
  });

  factory SearchResultsDto.fromJson(Map<String, dynamic> json) {
    return SearchResultsDto(
      users:
          (json['users'] as List<dynamic>?)
              ?.map((e) => SearchUserDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      posts:
          (json['posts'] as List<dynamic>?)
              ?.map((e) => PostResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos:
          (json['videos'] as List<dynamic>?)
              ?.map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SearchResponseDto {
  final SearchResultsDto results;
  final int page;
  final int limit;

  const SearchResponseDto({
    required this.results,
    required this.page,
    required this.limit,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    return SearchResponseDto(
      results: SearchResultsDto.fromJson(
        json['results'] as Map<String, dynamic>? ?? {},
      ),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
