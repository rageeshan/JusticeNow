import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final Dio _dio = ApiService.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Create anonymous session — returns JWT token
  Future<Map<String, dynamic>> loginAnonymous() async {
    final response = await _dio.post('/auth/anonymous');
    final token = response.data['data']['token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    return response.data['data'];
  }

  /// Upload lawyer certificate or credential document
  Future<String> uploadCertificate(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'certificate': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _dio.post('/auth/upload-certificate', data: formData);
    return response.data['data']['fileUrl'] as String;
  }

  /// Register user with email, password, name and role-specific details
  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? fullName,
    String? role,
    String? phone,
    String? nic,
    String? gender,
    String? province,
    String? district,
    String? policeId,
    String? lawyerId,
    String? courtNumber,
    String? certificateUrl,
    String? aboutMe,
    String? preferredLanguage,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (fullName != null) 'fullName': fullName,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (nic != null) 'nic': nic,
      if (gender != null) 'gender': gender,
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (policeId != null) 'policeId': policeId,
      if (lawyerId != null) 'lawyerId': lawyerId,
      if (courtNumber != null) 'courtNumber': courtNumber,
      if (certificateUrl != null) 'certificateUrl': certificateUrl,
      if (aboutMe != null) 'aboutMe': aboutMe,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    }
    return data;
  }

  /// Admin: Get users filtered by approvalStatus and/or role
  Future<List<dynamic>> getAdminUsers({String? approvalStatus, String? role, String? search}) async {
    final response = await _dio.get('/admin/users', queryParameters: {
      if (approvalStatus != null && approvalStatus.isNotEmpty) 'approvalStatus': approvalStatus,
      if (role != null && role.isNotEmpty) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data['data']['users'] as List<dynamic>;
  }

  /// Admin: Get single user detailed verification profile
  Future<Map<String, dynamic>> getAdminUserDetail(String userId) async {
    final response = await _dio.get('/admin/users/$userId');
    return response.data['data']['user'] as Map<String, dynamic>;
  }

  /// Admin: Update user approval status (approved / rejected)
  Future<Map<String, dynamic>> updateUserApprovalStatus(String userId, String status, {String? reason}) async {
    final response = await _dio.patch('/admin/users/$userId/status', data: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return response.data['data']['user'] as Map<String, dynamic>;
  }

  /// Login citizen with email + password
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['data']['token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    return response.data['data'];
  }

  /// Authenticate via Firebase (NGO/Officer/Admin)
  Future<Map<String, dynamic>> loginWithFirebase(String firebaseIdToken) async {
    final response = await _dio.post('/auth/firebase', data: {
      'idToken': firebaseIdToken,
    });
    final token = response.data['data']['token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    return response.data['data'];
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data['data']['user'] as Map<String, dynamic>;
  }

  /// Logout — clear stored token
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  /// Check if a token exists in secure storage
  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
