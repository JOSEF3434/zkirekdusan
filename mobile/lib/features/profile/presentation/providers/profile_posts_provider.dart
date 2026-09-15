// lib/features/profile/presentation/providers/profile_posts_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/post_model.dart';

class ProfilePostsState {
  final List<PostResponseDto> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasNextPage;

  const ProfilePostsState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasNextPage = true,
  });

  ProfilePostsState copyWith({
    List<PostResponseDto>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    bool? hasNextPage,
    bool clearError = false,
  }) {
    return ProfilePostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class ProfilePostsNotifier extends StateNotifier<ProfilePostsState> {
  final Dio _dio;
  final String _userId;

  ProfilePostsNotifier(this._dio, this._userId)
    : super(const ProfilePostsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get(
        '/profiles/$_userId/posts',
        queryParameters: {'page': 1, 'limit': 20, 'sortBy': 'createdAt', 'order': 'DESC'},
      );
      final envelope = parsePaginatedEnvelope(response.data);
      final rawItems = envelope['data'] as List<dynamic>;
      final posts = rawItems
          .map((json) => PostResponseDto.fromJson(json as Map<String, dynamic>))
          .toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final meta = envelope['meta'] as Map<String, dynamic>;
      final hasNext = meta['hasNext'] as bool? ?? (posts.length >= 20);

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        page: 1,
        hasNextPage: hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unable to load posts');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasNextPage || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final response = await _dio.get(
        '/profiles/$_userId/posts',
        queryParameters: {'page': nextPage, 'limit': 20, 'sortBy': 'createdAt', 'order': 'DESC'},
      );
      final envelope = parsePaginatedEnvelope(response.data);
      final rawItems = envelope['data'] as List<dynamic>;
      final newPosts = rawItems
          .map((json) => PostResponseDto.fromJson(json as Map<String, dynamic>))
          .toList();

      final meta = envelope['meta'] as Map<String, dynamic>;
      final hasNext = meta['hasNext'] as bool? ?? (newPosts.length >= 20);

      final combined = [...state.posts, ...newPosts];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        posts: combined,
        isLoadingMore: false,
        page: nextPage,
        hasNextPage: hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async => loadInitial();
}

final profilePostsProvider =
    StateNotifierProvider.family<
      ProfilePostsNotifier,
      ProfilePostsState,
      String
    >((ref, userId) {
      final dio = ref.watch(apiClientProvider);
      return ProfilePostsNotifier(dio, userId);
    });
