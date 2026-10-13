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

  /// Get all cases (officers/admins only) with optional filters including dateFilter
  Future<Map<String, dynamic>> getCases({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
    String? dateFilter,
  }) async {
    final response = await _dio.get('/cases', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null && status != 'All') 'status': status,
      if (category != null && category != 'All') 'category': category,
      if (priority != null && priority != 'All') 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFilter != null && dateFilter != 'all') 'dateFilter': dateFilter,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get a single case by ID with full citizen details and populated evidence
  Future<Map<String, dynamic>> getCaseById(String id) async {
    final response = await _dio.get('/cases/$id');
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Update case status with optional note and reason (e.g., assign to lawyer, reject)
  Future<Map<String, dynamic>> updateCaseStatus(
    String caseId,
    String status, {
    String? note,
    String? reason,
  }) async {
    final response = await _dio.patch('/cases/$caseId/status', data: {
      'status': status,
      if (note != null) 'note': note,
      if (reason != null) 'reason': reason,
    });
    final caseData = response.data['data']?['case'];
    if (caseData is Map) {
      return Map<String, dynamic>.from(caseData);
    }
    return <String, dynamic>{};
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
