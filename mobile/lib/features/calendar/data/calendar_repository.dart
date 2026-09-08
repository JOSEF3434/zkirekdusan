// lib/features/calendar/data/calendar_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(apiClientProvider));
});

class CalendarRepository {
  final Dio _dio;

  CalendarRepository(this._dio);

  /// Get calendar notes (optionally filtered by year, month, day)
  Future<List<CalendarNoteModel>> getNotes({
    int? year,
    int? month,
    int? day,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;
      if (day != null) queryParams['day'] = day;

      final response = await _dio.get(
        '/calendar/notes',
        queryParameters: queryParams,
      );

      final data = response.data;
      
      // Handle both envelope and direct array responses
      final List<dynamic> notesJson;
      if (data is Map && data.containsKey('data')) {
        notesJson = data['data'] as List<dynamic>;
      } else if (data is List) {
        notesJson = data;
      } else {
        throw ServerException('Unexpected response format');
      }

      return notesJson
          .map((json) => CalendarNoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single calendar note by ID
  Future<CalendarNoteModel> getNote(String id) async {
    try {
      final response = await _dio.get('/calendar/notes/$id');

      final data = response.data;
      final Map<String, dynamic> noteJson;
      if (data is Map && data.containsKey('data')) {
        noteJson = data['data'] as Map<String, dynamic>;
      } else if (data is Map) {
        noteJson = data as Map<String, dynamic>;
      } else {
        throw ServerException('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new calendar note
  Future<CalendarNoteModel> createNote(CreateCalendarNoteDto dto) async {
    try {
      final response = await _dio.post(
        '/calendar/notes',
        data: dto.toJson(),
      );

      final data = response.data;
      final Map<String, dynamic> noteJson;
      if (data is Map && data.containsKey('data')) {
        noteJson = data['data'] as Map<String, dynamic>;
      } else if (data is Map) {
        noteJson = data as Map<String, dynamic>;
      } else {
        throw ServerException('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing calendar note
  Future<CalendarNoteModel> updateNote(
    String id,
    UpdateCalendarNoteDto dto,
  ) async {
    try {
      final response = await _dio.patch(
        '/calendar/notes/$id',
        data: dto.toJson(),
      );

      final data = response.data;
      final Map<String, dynamic> noteJson;
      if (data is Map && data.containsKey('data')) {
        noteJson = data['data'] as Map<String, dynamic>;
      } else if (data is Map) {
        noteJson = data as Map<String, dynamic>;
      } else {
        throw ServerException('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a calendar note
  Future<void> deleteNote(String id) async {
    try {
      await _dio.delete('/calendar/notes/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String message = 'An error occurred';
      if (data is Map && data.containsKey('message')) {
        message = data['message'] as String;
      } else if (data is String) {
        message = data;
      }

      if (statusCode == 401) {
        return UnauthorizedException(message);
      } else if (statusCode == 403) {
        return ForbiddenException(message);
      } else if (statusCode == 404) {
        return NotFoundException(message);
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return ValidationException(message);
      } else {
        return ServerException(message);
      }
    } else {
      return NetworkException('Network error: ${e.message}');
    }
  }
}
