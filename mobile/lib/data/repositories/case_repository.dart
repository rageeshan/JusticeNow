import 'package:dio/dio.dart';
import '../services/api_service.dart';

class CaseRepository {
  final Dio _dio = ApiService.instance.client;

  /// Submit a new case report
  Future<Map<String, dynamic>> createCase(Map<String, dynamic> data) async {
    final response = await _dio.post('/cases', data: data);
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Get cases reported by current user (self-tracking)
  Future<Map<String, dynamic>> getMyCases({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/cases/my', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get all cases (officers/admins only)
  Future<Map<String, dynamic>> getCases({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
  }) async {
    final response = await _dio.get('/cases', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (search != null) 'search': search,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get a single case by ID
  Future<Map<String, dynamic>> getCaseById(String id) async {
    final response = await _dio.get('/cases/$id');
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Upload evidence files to a case
  Future<List<dynamic>> uploadEvidence(
    String caseId,
    List<String> filePaths, {
    String? description,
  }) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(path),
      ));
    }
    if (description != null) {
      formData.fields.add(MapEntry('description', description));
    }
    final response = await _dio.post('/cases/$caseId/evidence', data: formData);
    return response.data['data']['evidence'] as List<dynamic>;
  }
}
