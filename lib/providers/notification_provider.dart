import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../config/env/env_config.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;
  final List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _initialized = false;
  late final Dio _dio;
  final AuthService _authService = AuthService();

  NotificationProvider(this._service) {
    _setupDio();
  }

  void _setupDio() {
    // Use the main API URL instead of auth base URL for notification endpoints
    final baseUrl = EnvConfig.apiUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  Future<void> initialize() async {
    if (_initialized) return;
    await _service.connect();
    _service.notifications.listen((notification) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    });
    _initialized = true;
  }

  Future<void> fetchNotifications() async {
    try {
      print(
          '🔔 Fetching notifications from: ${_dio.options.baseUrl}/notifications');
      final response = await _dio.get('/notifications');
      print('✅ Fetch notifications response: ${response.data}');

      // Handle the correct response format from backend
      final responseData = response.data;
      List<Map<String, dynamic>> notifications = [];

      if (responseData['notifications'] != null) {
        notifications =
            List<Map<String, dynamic>>.from(responseData['notifications']);
      } else if (responseData is List) {
        // Fallback if response is directly an array
        notifications = List<Map<String, dynamic>>.from(responseData);
      }

      print('📋 Parsed notifications: $notifications');

      _notifications.clear();
      _notifications.addAll(notifications);

      // Calculate unread count
      _unreadCount = _notifications.where((n) => n['isRead'] != true).length;

      print(
          '📊 Total notifications: ${_notifications.length}, Unread: $_unreadCount');
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      print('🔔 Marking notification as read: $notificationId');
      await _dio.post('/notifications/$notificationId/read');

      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
        print('🔔 Updated notification state - Unread count: $_unreadCount');
        notifyListeners();
        print('🔔 Notified listeners for markAsRead');
      } else {
        print('🔔 Notification not found in local state: $notificationId');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      print('🔔 Marking all notifications as read');
      await _dio.post('/notifications/mark-all-read');

      // Update local state
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _unreadCount = 0;
      print('🔔 Updated all notifications state - Unread count: $_unreadCount');
      notifyListeners();
      print('🔔 Notified listeners for markAllAsRead');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      print('🔔 Deleting notification: $notificationId');
      print(
          '🔔 Making DELETE request to: ${_dio.options.baseUrl}/notifications/$notificationId');
      final response = await _dio.delete('/notifications/$notificationId');
      print('🔔 Delete response: ${response.data}');

      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        final wasUnread = _notifications[index]['isRead'] != true;
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount =
              _notifications.where((n) => n['isRead'] != true).length;
        }
        print('🔔 Deleted notification - Unread count: $_unreadCount');
        notifyListeners();
        print('🔔 Notified listeners for deleteNotification');
      } else {
        print('🔔 Notification not found in local state: $notificationId');
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      print('🗑️ Deleting all notifications');
      print(
          '🗑️ Making DELETE request to: ${_dio.options.baseUrl}/notifications');
      final response = await _dio.delete('/notifications');
      print('🗑️ Delete all response: ${response.data}');

      // Update local state
      _notifications.clear();
      _unreadCount = 0;
      print('🗑️ Deleted all notifications');
      notifyListeners();
      print('🗑️ Notified listeners for deleteAllNotifications');
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      if (e is DioException) {
        print('❌ DioException details: ${e.response?.data}');
        print('❌ Status code: ${e.response?.statusCode}');
      }
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Dispose the notification socket and reset initialization state
  void disposeSocket() {
    try {
      _service.dispose();
    } catch (e) {
      print('Error disposing notification socket: $e');
    }
    _initialized = false;
    clearNotifications();
  }
}
