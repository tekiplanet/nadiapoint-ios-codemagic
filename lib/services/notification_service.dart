import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  IO.Socket? _notificationSocket;
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final storage = const FlutterSecureStorage();

  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;

  Future<String?> _getAuthToken() async {
    try {
      final token = await storage.read(key: 'accessToken');
      return token;
    } catch (e) {
      print('Error getting token');
      return null;
    }
  }

  Future<String?> _getUserId() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = String.fromCharCodes(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);
      final userId = data['sub'] ?? data['id'] ?? data['userId'];
      return userId?.toString();
    } catch (e) {
      print('Error parsing JWT token');
      return null;
    }
  }

  Future<void> connect() async {
    _notificationSocket?.disconnect();
    _notificationSocket = null;
    final token = await _getAuthToken();
    final userId = await _getUserId();
    if (token == null || userId == null) {
      print('No token or userId for notification socket connection');
      return;
    }
    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    final uri = Uri.parse(apiUrl);
    String wsUrl;
    if ((uri.scheme == 'http' && (uri.port == 80 || uri.port == 0)) ||
        (uri.scheme == 'https' && (uri.port == 443 || uri.port == 0))) {
      wsUrl = '${uri.scheme}://${uri.host}';
    } else {
      wsUrl = '${uri.scheme}://${uri.host}:${uri.port}';
    }
    if (wsUrl.endsWith(':0')) {
      wsUrl = wsUrl.replaceAll(':0', '');
    }
    print('Connecting to Socket.IO: $wsUrl/notifications');
    _notificationSocket = IO.io('$wsUrl/notifications', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'query': {'userId': userId, 'token': token, 'EIO': '4'},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5
    });
    _notificationSocket?.onConnecting((_) {
      print('=== NOTIFICATION SOCKET CONNECTING ===');
    });
    _notificationSocket?.onConnect((_) {
      print('=== NOTIFICATION SOCKET CONNECTED ===');
    });
    _notificationSocket?.onReconnect((_) {
      print('=== NOTIFICATION SOCKET RECONNECTED ===');
    });
    _notificationSocket?.onDisconnect((_) {
      print('=== NOTIFICATION SOCKET DISCONNECTED ===');
    });
    _notificationSocket?.onConnectError((err) {
      print('=== NOTIFICATION SOCKET CONNECT ERROR ===');
      print('Error details: $err');
    });
    _notificationSocket?.onConnectTimeout(
        (_) => print('=== NOTIFICATION SOCKET CONNECT TIMEOUT ==='));
    _notificationSocket?.on('notification', (data) {
      print('=== IN-APP NOTIFICATION RECEIVED ===');
      print('Notification data: $data');
      if (!_notificationController.isClosed) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });
    _notificationSocket?.onError((error) {
      print('=== NOTIFICATION SOCKET ERROR ===');
      print(error);
    });
    _notificationSocket?.connect();
  }

  void dispose() {
    _notificationSocket?.disconnect();
    _notificationSocket = null;
    _notificationController.close();
  }
}
