import 'package:dio/dio.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final Dio _dio = ApiService.instance.client;

  /// Get notifications for currently logged in user
  Future<Map<String, dynamic>> getMyNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }
}
