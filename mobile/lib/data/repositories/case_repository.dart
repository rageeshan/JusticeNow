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

  /// Track a case by reference number (e.g. JN-2026-00001)
  Future<Map<String, dynamic>> trackByReferenceNumber(String refNum) async {
    final response = await _dio.get('/cases/ref/$refNum');
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

  // ─────────────────────────────────────────────────────────────────────────
  //  Officer-Specific Repository Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Get cases assigned to the current officer
  Future<Map<String, dynamic>> getAssignedCases({
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    String? priority,
    String? search,
  }) async {
    final response = await _dio.get('/cases/assigned', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (category != null && category.isNotEmpty && category != 'all') 'category': category,
      if (priority != null && priority.isNotEmpty && priority != 'all') 'priority': priority,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get officer dashboard summary statistics
  Future<Map<String, dynamic>> getOfficerStats() async {
    final response = await _dio.get('/cases/officer/stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Update case status with an optional note
  Future<Map<String, dynamic>> updateCaseStatus(
    String caseId,
    String status, {
    String? note,
  }) async {
    final response = await _dio.patch(
      '/cases/$caseId/status',
      data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Add internal confidential investigation note to case
  Future<Map<String, dynamic>> addInternalNote(String caseId, String note) async {
    final response = await _dio.post(
      '/cases/$caseId/notes',
      data: {'note': note},
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Assign case to an officer (or self-assign)
  Future<Map<String, dynamic>> assignCase(String caseId, {String? officerId}) async {
    final response = await _dio.patch(
      '/cases/$caseId/assign',
      data: {
        if (officerId != null) 'officerId': officerId,
      },
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Evidence Request Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Request additional evidence from reporter
  Future<Map<String, dynamic>> createEvidenceRequest(
    String caseId, {
    required String description,
    String? reason,
    String? instructions,
    String? dueDate,
    String? internalNote,
  }) async {
    final response = await _dio.post(
      '/evidence-requests/case/$caseId',
      data: {
        'description': description,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (instructions != null && instructions.isNotEmpty) 'instructions': instructions,
        if (dueDate != null) 'dueDate': dueDate,
        if (internalNote != null && internalNote.isNotEmpty) 'internalNote': internalNote,
      },
    );
    return response.data['data']['evidenceRequest'] as Map<String, dynamic>;
  }

  /// Get all evidence requests for a specific case
  Future<List<dynamic>> getEvidenceRequestsByCase(String caseId) async {
    final response = await _dio.get('/evidence-requests/case/$caseId');
    return response.data['data']['evidenceRequests'] as List<dynamic>;
  }

  /// Get list of evidence requests for the officer
  Future<Map<String, dynamic>> getOfficerEvidenceRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/evidence-requests',
      queryParameters: {
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Update the status of an evidence request
  Future<Map<String, dynamic>> updateEvidenceRequestStatus(
    String requestId, {
    required String status,
    String? reviewNotes,
  }) async {
    final response = await _dio.patch(
      '/evidence-requests/$requestId/status',
      data: {
        'status': status,
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
      },
    );
    return response.data['data']['evidenceRequest'] as Map<String, dynamic>;
  }
}

