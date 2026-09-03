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

  /// Register citizen with email + password
  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['data']['token'] as String;
    await _storage.write(key: AppConstants.tokenKey, value: token);
    return response.data['data'];
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
