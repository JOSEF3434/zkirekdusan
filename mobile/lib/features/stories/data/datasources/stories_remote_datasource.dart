// lib/features/stories/data/datasources/stories_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/stories/data/models/story_comment_model.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/data/models/story_reaction_model.dart';
import 'package:mobile/features/stories/data/models/story_view_model.dart';

final storiesRemoteDatasourceProvider = Provider<StoriesRemoteDatasource>((
  ref,
) {
  final dio = ref.watch(apiClientProvider);
  return StoriesRemoteDatasource(dio);
});

class StoriesRemoteDatasource {
  final Dio _dio;

  StoriesRemoteDatasource(this._dio);

  Future<List<StoryFeedGroupModel>> getFeed() async {
    final response = await _dio.get('/stories/feed');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => StoryFeedGroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoryModel>> getMyStories() async {
    final response = await _dio.get('/stories/me');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryModel> getStoryById(String id) async {
    final response = await _dio.get('/stories/$id');
    final data = parseEnvelope(response.data);
    return StoryModel.fromJson(data);
  }

  Future<StoryModel> viewStory(String id) async {
    final response = await _dio.post('/stories/$id/view');
    final data = parseEnvelope(response.data);
    return StoryModel.fromJson(data);
  }

  Future<StoryReactionModel> addReaction(String id, String reaction) async {
    final response = await _dio.post(
      '/stories/$id/reactions',
      data: {'reaction': reaction},
    );
    final data = parseEnvelope(response.data);
    return StoryReactionModel.fromJson(data);
  }

  Future<void> removeReaction(String id) async {
    await _dio.delete('/stories/$id/reactions/me');
  }

  Future<List<StoryViewModel>> getViewers(String id) async {
    final response = await _dio.get('/stories/$id/views');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => StoryViewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoryReactionModel>> getReactions(String id) async {
    final response = await _dio.get('/stories/$id/reactions');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => StoryReactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoryCommentModel> addComment(String id, String content) async {
    final response = await _dio.post(
      '/stories/$id/comments',
      data: {'content': content},
    );
    final data = parseEnvelope(response.data);
    return StoryCommentModel.fromJson(data);
  }

  Future<List<StoryCommentModel>> getComments(String id) async {
    final response = await _dio.get('/stories/$id/comments');
    final list = parseEnvelopeList(response.data);
    return list
        .map((e) => StoryCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteStory(String id) async {
    await _dio.delete('/stories/$id');
  }

  Future<StoryModel> createStoryWithFile({
    required XFile file,
    String? content,
    String? backgroundColor,
    String? textColor,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'story_media.jpg';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      if (content != null && content.isNotEmpty) 'content': content,
      if (backgroundColor != null && backgroundColor.isNotEmpty)
        'backgroundColor': backgroundColor,
      if (textColor != null && textColor.isNotEmpty) 'textColor': textColor,
    });

    final response = await _dio.post(
      '/stories/upload',
      data: formData,
      onSendProgress: onProgress,
    );

    final data = parseEnvelope(response.data);
    return StoryModel.fromJson(data);
  }

  Future<StoryModel> createStoryJson({
    required String type,
    String? fileId,
    String? content,
    String? backgroundColor,
    String? textColor,
  }) async {
    final response = await _dio.post(
      '/stories',
      data: {
        'type': type,
        'fileId': ?fileId,
        'content': ?content,
        'backgroundColor': ?backgroundColor,
        'textColor': ?textColor,
      },
    );
    final data = parseEnvelope(response.data);
    return StoryModel.fromJson(data);
  }
}
