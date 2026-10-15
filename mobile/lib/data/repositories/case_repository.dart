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

  /// Translate incident / case report text and title using Gemini AI
  Future<Map<String, dynamic>> translateReport({
    String? title,
    String? text,
    required String targetLang,
  }) async {
    final response = await _dio.post('/translate', data: {
      if (title != null) 'title': title,
      if (text != null) 'text': text,
      'targetLang': targetLang,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Track a case by reference number (e.g. JN-2026-00001)
  Future<Map<String, dynamic>> trackByReferenceNumber(String refNum) async {
    final response = await _dio.get('/cases/ref/$refNum');
    return response.data['data']['case'] as Map<String, dynamic>;
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

  /// Get cases assigned to this police officer by tab (pending, in_progress, completed)
  Future<List<dynamic>> getPoliceCases(String tab, {String? search}) async {
    final response = await _dio.get('/cases/officer/cases', queryParameters: {
      'tab': tab,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data['data']['cases'] as List<dynamic>;
  }

  /// Accept assigned police case and set investigation schedule
  Future<Map<String, dynamic>> acceptPoliceCase(
    String caseId, {
    required String startDate,
    required String startTime,
  }) async {
    final response = await _dio.patch(
      '/cases/officer/cases/$caseId/accept',
      data: {
        'startDate': startDate,
        'startTime': startTime,
      },
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Decline assigned police case with reason (returns to admin pool)
  Future<Map<String, dynamic>> rejectPoliceCase(
    String caseId, {
    required String reason,
  }) async {
    final response = await _dio.patch(
      '/cases/officer/cases/$caseId/reject',
      data: {
        'reason': reason,
      },
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Update police investigation stage (investigating, suspect_identified, referred_to_court, closed)
  Future<Map<String, dynamic>> updatePoliceCaseStage(
    String caseId, {
    required String stage,
    String? note,
  }) async {
    final response = await _dio.patch(
      '/cases/officer/cases/$caseId/stage',
      data: {
        'stage': stage,
        if (note != null) 'note': note,
      },
    );
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Mark police case as completed
  Future<Map<String, dynamic>> completePoliceCase(String caseId) async {
    final response = await _dio.patch('/cases/officer/cases/$caseId/complete');
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Get officer saved availability schedule
  Future<Map<String, dynamic>> getPoliceAvailability() async {
    final response = await _dio.get('/cases/officer/availability');
    final avail = response.data['data']?['availability'];
    if (avail is Map) {
      return Map<String, dynamic>.from(avail);
    }
    return <String, dynamic>{};
  }

  /// Save officer availability schedule
  Future<Map<String, dynamic>> updatePoliceAvailability(
    Map<String, dynamic> availability,
  ) async {
    final response = await _dio.put(
      '/cases/officer/availability',
      data: {'availability': availability},
    );
    final avail = response.data['data']?['availability'];
    if (avail is Map) {
      return Map<String, dynamic>.from(avail);
    }
    return <String, dynamic>{};
  }

  /// Get officer dashboard summary statistics
  Future<Map<String, dynamic>> getOfficerStats() async {
    final response = await _dio.get('/cases/officer/stats');
    return response.data['data'] as Map<String, dynamic>;
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

  /// Get available police officers auto-filtered by case location for admin assignment
  Future<Map<String, dynamic>> getAvailableOfficersForCase(
    String caseId, {
    String? sortBy,
    String? province,
    String? district,
  }) async {
    final response = await _dio.get(
      '/cases/$caseId/officers-available',
      queryParameters: {
        if (sortBy != null) 'sortBy': sortBy,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
      },
    );
    final data = response.data['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  /// Admin assigns case to chosen police officer
  Future<Map<String, dynamic>> assignOfficerToCase(String caseId, String officerId) async {
    final response = await _dio.patch(
      '/cases/$caseId/assign-officer',
      data: {'officerId': officerId},
    );
    final data = response.data['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
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
