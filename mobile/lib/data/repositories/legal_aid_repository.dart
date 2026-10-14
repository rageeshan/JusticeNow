import 'dart:io';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class LegalAidRepository {
  final Dio _dio = ApiService.instance.client;

  /// Fetch approved lawyers with search and filters
  Future<List<dynamic>> getLawyers({
    String? search,
    String? language,
    String? province,
    String? district,
    String? sortBy,
  }) async {
    final response = await _dio.get('/legal-aid/lawyers', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (language != null && language != 'All') 'language': language,
      if (province != null && province != 'All') 'province': province,
      if (district != null && district != 'All') 'district': district,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
    });
    return response.data['data']['lawyers'] as List<dynamic>;
  }

  /// Get single lawyer full details
  Future<Map<String, dynamic>> getLawyerById(String id) async {
    final response = await _dio.get('/legal-aid/lawyers/$id');
    return response.data['data']['lawyer'] as Map<String, dynamic>;
  }

  /// Book an approved case with a specific lawyer
  Future<Map<String, dynamic>> bookLawyer({
    required String caseId,
    required String lawyerId,
    required String preferredContactMethod,
    String? shortMessage,
  }) async {
    final response = await _dio.post('/legal-aid/book', data: {
      'caseId': caseId,
      'lawyerId': lawyerId,
      'preferredContactMethod': preferredContactMethod,
      'shortMessage': shortMessage ?? '',
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Lawyer side: Get full case details with citizen and report information
  Future<Map<String, dynamic>> getLawyerCase(String caseId) async {
    final response = await _dio.get('/legal-aid/lawyer/cases/$caseId');
    return response.data['data']['case'] as Map<String, dynamic>;
  }

  /// Lawyer side: Get cases assigned to this lawyer filtered by tab ('pending', 'in_progress', 'completed')
  Future<List<dynamic>> getLawyerCases(String tab) async {
    final response = await _dio.get('/legal-aid/lawyer/cases', queryParameters: {'tab': tab});
    return response.data['data']['cases'] as List<dynamic>;
  }

  /// Lawyer side: Approve a case with scheduled date and time
  Future<Map<String, dynamic>> approveLawyerCase({
    required String caseId,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    final response = await _dio.patch('/legal-aid/lawyer/cases/$caseId/approve', data: {
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Lawyer side: Reject a case with mandatory reason
  Future<Map<String, dynamic>> rejectLawyerCase({
    required String caseId,
    required String reason,
  }) async {
    final response = await _dio.patch('/legal-aid/lawyer/cases/$caseId/reject', data: {
      'reason': reason,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Lawyer side: Mark accepted case as completed
  Future<Map<String, dynamic>> completeLawyerCase(String caseId) async {
    final response = await _dio.patch('/legal-aid/lawyer/cases/$caseId/complete');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Lawyer side: Get saved weekly availability schedule
  Future<Map<String, dynamic>> getLawyerAvailability() async {
    final response = await _dio.get('/legal-aid/lawyer/availability');
    return response.data['data']['availability'] as Map<String, dynamic>;
  }

  /// Lawyer side: Update saved weekly availability schedule
  Future<Map<String, dynamic>> updateLawyerAvailability(Map<String, dynamic> availability) async {
    final response = await _dio.put('/legal-aid/lawyer/availability', data: {
      'availability': availability,
    });
    return response.data['data']['availability'] as Map<String, dynamic>;
  }

  /// Lawyer side: Submit an advertisement post with photo
  Future<Map<String, dynamic>> submitLawyerAdPost(File photoFile) async {
    final fileName = photoFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoFile.path, filename: fileName),
    });
    final response = await _dio.post('/legal-aid/lawyer/advertisement', data: formData);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get active advertisements for citizen dashboard
  Future<List<dynamic>> getAdvertisements() async {
    final response = await _dio.get('/legal-aid/advertisements');
    return response.data['data']['ads'] as List<dynamic>;
  }

  /// Lawyer side: Submit an advertisement (legacy fallback)
  Future<Map<String, dynamic>> submitLawyerAd({
    required String title,
    required String description,
    String? category,
    String? contactNumber,
    String? specialOffers,
  }) async {
    final response = await _dio.post('/legal-aid/lawyer/advertisement', data: {
      'title': title,
      'description': description,
      if (category != null) 'category': category,
      if (contactNumber != null) 'contactNumber': contactNumber,
      if (specialOffers != null) 'specialOffers': specialOffers,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}

