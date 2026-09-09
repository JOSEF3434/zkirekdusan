// lib/features/calendar/data/calendar_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        throw Exception('Unexpected response format');
      }

      return notesJson
          .map(
            (json) => CalendarNoteModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      rethrow;
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
        throw Exception('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new calendar note
  Future<CalendarNoteModel> createNote(CreateCalendarNoteDto dto) async {
    try {
      final response = await _dio.post('/calendar/notes', data: dto.toJson());

      final data = response.data;
      final Map<String, dynamic> noteJson;
      if (data is Map && data.containsKey('data')) {
        noteJson = data['data'] as Map<String, dynamic>;
      } else if (data is Map) {
        noteJson = data as Map<String, dynamic>;
      } else {
        throw Exception('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } catch (e) {
      rethrow;
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
        throw Exception('Unexpected response format');
      }

      return CalendarNoteModel.fromJson(noteJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a calendar note
  Future<void> deleteNote(String id) async {
    try {
      await _dio.delete('/calendar/notes/$id');
    } catch (e) {
      rethrow;
    }
  }
}
