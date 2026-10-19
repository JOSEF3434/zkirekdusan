// lib/features/calendar/alephat/data/alephat_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';

final alephatRepositoryProvider = Provider<AlephatRepository>((ref) {
  return AlephatRepository(ref.watch(apiClientProvider));
});

class AlephatRepository {
  final Dio _dio;

  AlephatRepository(this._dio);

  // Helper to extract data from optional response envelope
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─────────────────────────────────────────────────────────
  // TAB 1: Letters & Families
  // ─────────────────────────────────────────────────────────

  Future<List<AlephatLetterModel>> getLetters({
    String? search,
    bool? includeUnpublished,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (includeUnpublished != null) {
      queryParams['includeUnpublished'] = includeUnpublished;
    }

    final response = await _dio.get(
      '/alephat/letters',
      queryParameters: queryParams,
    );

    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((item) => AlephatLetterModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AlephatLetterModel> getLetter(
    String id, {
    bool? includeUnpublished,
  }) async {
    final queryParams = <String, dynamic>{};
    if (includeUnpublished != null) {
      queryParams['includeUnpublished'] = includeUnpublished;
    }

    final response = await _dio.get(
      '/alephat/letters/$id',
      queryParameters: queryParams,
    );

    final data = _extractData(response.data);
    return AlephatLetterModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AlephatLetterModel> createLetter(Map<String, dynamic> data) async {
    final response = await _dio.post('/alephat/letters', data: data);
    final resData = _extractData(response.data);
    return AlephatLetterModel.fromJson(resData as Map<String, dynamic>);
  }

  Future<AlephatLetterModel> updateLetter(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/alephat/letters/$id', data: data);
    final resData = _extractData(response.data);
    return AlephatLetterModel.fromJson(resData as Map<String, dynamic>);
  }

  Future<void> deleteLetter(String id) async {
    await _dio.delete('/alephat/letters/$id');
  }

  Future<void> reorderLetters(List<Map<String, dynamic>> items) async {
    await _dio.post('/alephat/letters/reorder', data: {'items': items});
  }

  Future<AlephatFamilyMemberModel> addFamilyMember(
    String letterId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/alephat/letters/$letterId/family',
      data: data,
    );
    final resData = _extractData(response.data);
    return AlephatFamilyMemberModel.fromJson(resData as Map<String, dynamic>);
  }

  Future<AlephatFamilyMemberModel> updateFamilyMember(
    String letterId,
    String memberId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/alephat/letters/$letterId/family/$memberId',
      data: data,
    );
    final resData = _extractData(response.data);
    return AlephatFamilyMemberModel.fromJson(resData as Map<String, dynamic>);
  }

  Future<void> deleteFamilyMember(String letterId, String memberId) async {
    await _dio.delete('/alephat/letters/$letterId/family/$memberId');
  }

  Future<void> reorderFamilyMembers(
    String letterId,
    List<Map<String, dynamic>> items,
  ) async {
    await _dio.post(
      '/alephat/letters/$letterId/family/reorder',
      data: {'items': items},
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2: 22 Alephats
  // ─────────────────────────────────────────────────────────

  Future<List<Alephat22Model>> get22List({
    String? search,
    bool? includeUnpublished,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (includeUnpublished != null) {
      queryParams['includeUnpublished'] = includeUnpublished;
    }

    final response = await _dio.get(
      '/alephat/22',
      queryParameters: queryParams,
    );

    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((item) => Alephat22Model.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Alephat22Model> get22Detail(
    String id, {
    bool? includeUnpublished,
  }) async {
    final queryParams = <String, dynamic>{};
    if (includeUnpublished != null) {
      queryParams['includeUnpublished'] = includeUnpublished;
    }

    final response = await _dio.get(
      '/alephat/22/$id',
      queryParameters: queryParams,
    );

    final data = _extractData(response.data);
    return Alephat22Model.fromJson(data as Map<String, dynamic>);
  }

  Future<Alephat22Model> create22(Map<String, dynamic> data) async {
    final response = await _dio.post('/alephat/22', data: data);
    final resData = _extractData(response.data);
    return Alephat22Model.fromJson(resData as Map<String, dynamic>);
  }

  Future<Alephat22Model> update22(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/alephat/22/$id', data: data);
    final resData = _extractData(response.data);
    return Alephat22Model.fromJson(resData as Map<String, dynamic>);
  }

  Future<void> delete22(String id) async {
    await _dio.delete('/alephat/22/$id');
  }

  Future<void> reorder22(List<Map<String, dynamic>> items) async {
    await _dio.post('/alephat/22/reorder', data: {'items': items});
  }
}
