import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'api_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class P2PService {
  late final Dio _dio;
  final AuthService _authService = GetIt.I<AuthService>();
  final storage = const FlutterSecureStorage();
  Timer? _pollTimer;
  final _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  IO.Socket? _chatSocket;
  IO.Socket? _disputeChatSocket;
  final _chatUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _disputeChatUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _chatSubscription;
  String? _currentOrderId;
  String? _currentDisputeId;

  String get apiUrl {
    return _dio.options.baseUrl;
  }

  P2PService() {
    final baseUrl = _authService.baseUrl.replaceAll('/auth', '');
    // print('P2P Service initialized with base URL: $baseUrl');
    // print('AuthService instance: $_authService');

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500; // Accept all status codes less than 500
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // print('Making request to: ${options.baseUrl}${options.path}');
          // print('Headers: ${options.headers}');

          final token = await storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            // print('Token added to request: $token');
          } else {
            // print('No token found!');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          print('Full error details:');
          print('Base URL: ${error.requestOptions.baseUrl}');
          print('Path: ${error.requestOptions.path}');
          print('Error Response: ${error.response?.data}');
          print('Error Status Code: ${error.response?.statusCode}');
          print('Headers sent: ${error.requestOptions.headers}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getAvailableAssets(bool isBuy) async {
    try {
      final response = await _dio.get(
        '/p2p/available-assets',
        queryParameters: {'type': isBuy ? 'buy' : 'sell'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load assets');
    } catch (e) {
      throw Exception('Failed to load assets');
    }
  }

  Future<Map<String, dynamic>> getTraderSettings() async {
    try {
      print('Attempting to get trader settings...');
      final response = await _dio.get('/p2p/trader-settings');
      print('Response received: ${response.data}');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to load trader settings');
    } catch (e) {
      print('Error in getTraderSettings');
      throw Exception('Failed to load trader settings');
    }
  }

  Future<double> getMarketPrice(String tokenSymbol, String currency) async {
    try {
      print(
          'Making request to: ${_dio.options.baseUrl}/p2p/market-price?symbol=$tokenSymbol&currency=$currency');
      final response = await _dio.get(
        '/p2p/market-price',
        queryParameters: {
          'symbol': tokenSymbol,
          'currency': currency,
        },
      );

      if (response.statusCode == 200) {
        print('Market price response: ${response.data}');
        return double.parse(response.data['price'].toString());
      }
      throw Exception('Failed to load market price');
    } catch (e) {
      print('Error getting market price');
      throw Exception('Failed to load market price');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods(bool isBuy) async {
    try {
      final response = await _dio.get(
        '/p2p/payment-methods',
        queryParameters: {'type': isBuy ? 'buy' : 'sell'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load payment methods');
    } catch (e) {
      throw Exception('Failed to load payment methods');
    }
  }

  Future<Map<String, dynamic>> createOffer(
      Map<String, dynamic> offerData) async {
    try {
      final response = await _dio.post(
        '/p2p/offers',
        data: offerData,
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to process offer');
      }

      return response.data;
    } catch (e) {
      throw Exception('Failed to process offer');
    }
  }

  Future<Map<String, dynamic>> getUserKycLevel() async {
    try {
      final response = await _dio.get('/p2p/user-kyc-level');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to load KYC level');
    } catch (e) {
      throw Exception('Failed to load KYC level');
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      // Try user profile endpoint first
      final response = await _dio.get('/user/profile');
      if (response.statusCode == 200) {
        print('Profile fetched successfully: ${response.data}');
        return Map<String, dynamic>.from(response.data);
      }

      // If that fails, try the account endpoint
      print(
          'Profile endpoint returned ${response.statusCode}, trying account endpoint');
      final accountResponse = await _dio.get('/account');
      if (accountResponse.statusCode == 200) {
        print('Account fetched successfully: ${accountResponse.data}');
        return Map<String, dynamic>.from(accountResponse.data);
      }

      // If all API calls fail, try to extract user ID from token
      print(
          'Failed to load profile from APIs, attempting to extract from token');
      final userId = await extractUserIdFromToken();
      if (userId != null) {
        print('Extracted user ID from token: $userId');
        return {'id': userId};
      }

      print('Failed to get user profile through all methods');
      return null;
    } catch (e) {
      print('Error fetching profile');

      // Last resort: try to get ID from token
      try {
        final userId = await extractUserIdFromToken();
        if (userId != null) {
          print('Extracted user ID from token as fallback: $userId');
          return {'id': userId};
        }
      } catch (tokenError) {
        print('Error extracting user ID from token: $tokenError');
      }

      return null;
    }
  }

  Future<String?> extractUserIdFromToken() async {
    try {
      final token = await storage.read(key: 'accessToken');
      if (token == null) return null;

      // JWT tokens are split into 3 parts by dots
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // The second part contains the payload
      String payload = parts[1];

      // Add padding if needed
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Decode the base64 payload
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);

      // Extract the user ID (typically stored as 'sub' or 'id' in JWT)
      final userId = data['sub'] ?? data['id'] ?? data['userId'];
      print('Token payload: $data');
      return userId?.toString();
    } catch (e) {
      print('Error parsing JWT token');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyOffers(bool isBuy) async {
    try {
      final response = await _dio.get(
        '/p2p/my-offers',
        queryParameters: {
          'type': isBuy ? 'buy' : 'sell',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load offers');
    } catch (e) {
      throw Exception('Failed to load offers');
    }
  }

  Future<Map<String, dynamic>> getPublicOffers({
    required bool isBuy,
    String? currency,
    String? tokenId,
    String? paymentMethodId,
    double? minAmount,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'type': isBuy ? 'buy' : 'sell',
        if (currency != null) 'currency': currency,
        if (tokenId != null) 'tokenId': tokenId,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (minAmount != null) 'minAmount': minAmount.toString(),
        'page': page,
      };
      print('Query parameters being sent: $queryParams');

      final response = await _dio.get(
        '/p2p/public-offers',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveCurrencies() async {
    try {
      final response = await _dio.get('/p2p/currencies');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getActivePaymentMethodTypes() async {
    try {
      final response = await _dio.get('/p2p/payment-method-types');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getOfferDetails(String offerId) async {
    final response = await _dio
        .get('/p2p/offer-details', queryParameters: {'offerId': offerId});
    return response.data;
  }

  Future<Map<String, dynamic>> submitOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post(
        '/p2p/orders',
        data: orderData,
      );

      if (response.statusCode == 201) {
        print('Order submitted successfully');
        return response.data;
      } else {
        // Parse the error message from the response
        String errorMessage = 'Failed to submit order';
        print('Error response: ${response.data}');

        if (response.data is Map) {
          errorMessage = response.data['message'] ?? 'Failed to submit order';
        } else if (response.data is String) {
          errorMessage = response.data;
        }

        print('Error message extracted: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error submitting order');
      print('Error type: ${e.runtimeType}');

      // If we already have a properly formatted exception, just rethrow it
      if (e is Exception && e.toString().contains('Exception: ')) {
        print('Rethrowing existing exception with message');
        rethrow;
      }

      // Check if it's a DioError to get the actual error message
      if (e is DioException) {
        final response = e.response;
        if (response != null) {
          print('DioError response data: ${response.data}');
          String errorMessage = 'Failed to submit order';

          if (response.data is Map) {
            errorMessage = response.data['message'] ?? errorMessage;
          } else if (response.data is String) {
            // Sometimes the error might come as a string
            errorMessage = response.data;
          }

          print('Final error message: $errorMessage');
          throw Exception(errorMessage);
        }
      }

      // For any other type of error, create a clear exception
      String errorMsg = e.toString();
      // Remove any leading "Exception: " to avoid duplication
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring('Exception: '.length);
      }

      print('Throwing formatted exception: $errorMsg');
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String trackingId) async {
    try {
      final token = await storage.read(key: 'accessToken');
      final headers = token != null
          ? <String, dynamic>{'Authorization': 'Bearer $token'}
          : <String, dynamic>{};

      final response = await _dio.get(
        '/p2p/orders/$trackingId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        // print('Order details fetched successfully: ${response.data}');
        return response.data;
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      print('Error fetching order details');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPaymentMethodDetails(String methodId) async {
    try {
      final token = await storage.read(key: 'accessToken');
      final headers = token != null
          ? <String, dynamic>{'Authorization': 'Bearer $token'}
          : <String, dynamic>{};

      final response = await _dio.get(
        '/p2p/payment-methods/$methodId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('Payment method details fetched successfully: ${response.data}');
        return response.data;
      } else {
        throw Exception('Failed to load payment method details');
      }
    } catch (e) {
      print('Error fetching payment method details');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrders({
    bool? isBuy,
    String? status,
    String? searchQuery,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        if (isBuy != null) 'type': isBuy ? 'buy' : 'sell',
        if (status != null && status.toLowerCase() != 'all')
          'status': status.toLowerCase(),
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery.trim(),
        'page': page.toString(),
      };

      print('Sending search request with params: $queryParams');

      final response = await _dio.get(
        '/p2p/orders',
        queryParameters: queryParams,
        options: Options(headers: await _getAuthHeaders()),
      );

      // print('Search response: ${response.data}');
      return response.data;
    } catch (e) {
      print('Error in getOrders');
      _handleError(e);
      rethrow;
    }
  }

  Future<void> confirmOrderPayment(String trackingId) async {
    try {
      final response = await _dio.post(
        '/p2p/orders/by-tracking-id/$trackingId/confirm-payment',
        options: Options(headers: await _getAuthHeaders()),
      );
      print('Payment confirmation response: ${response.data}');
    } catch (e) {
      print('Error confirming payment');
      _handleError(e);
      rethrow;
    }
  }

  Future<void> releaseOrder(String trackingId, String password) async {
    try {
      final response = await _dio.post(
        '/p2p/orders/$trackingId/release',
        data: {'password': password},
        options: Options(headers: await _getAuthHeaders()),
      );
      print('Release order response: ${response.data}');

      // Check for non-success status codes (not in 200 range)
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        final errorMessage =
            response.data['message'] ?? 'Failed to release coins';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error releasing order');
      _handleError(e);
      rethrow;
    }
  }

  Future<void> cancelOrder(String trackingId,
      {String? reason, String? additionalDetails}) async {
    try {
      final response = await _dio.post(
        '/p2p/orders/$trackingId/cancel',
        data: reason != null || additionalDetails != null
            ? {'reason': reason, 'additionalDetails': additionalDetails}
            : null,
        options: Options(headers: await _getAuthHeaders()),
      );
      print('Cancel order response: ${response.data}');
    } catch (e) {
      print('Error cancelling order');
      _handleError(e);
      rethrow;
    }
  }

  Future<void> disputeOrder(
      String trackingId, String reasonType, String reason) async {
    try {
      final response = await _dio.post(
        '/p2p/orders/$trackingId/dispute',
        data: {
          'reasonType': reasonType,
          'reason': reason,
        },
        options: Options(headers: await _getAuthHeaders()),
      );
      print('Dispute order response: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to dispute order');
      }
    } catch (e) {
      print('Error disputing order');
      throw Exception('Failed to dispute order');
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final response = e.response;
      if (response != null) {
        final data = response.data;
        if (data is Map && data.containsKey('message')) {
          return Exception(data['message']);
        }
      }
      return Exception(e.message ?? 'An error occurred');
    }
    return Exception(e.toString());
  }

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await storage.read(key: 'accessToken');
    return token != null
        ? <String, dynamic>{'Authorization': 'Bearer $token'}
        : <String, dynamic>{};
  }

  void startOrderUpdates(String orderId) {
    stopOrderUpdates();
    _fetchOrderDetails(orderId);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchOrderDetails(orderId);
    });
  }

  Future<void> _fetchOrderDetails(String orderId) async {
    try {
      final response = await _dio.get(
        '/p2p/orders/$orderId',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        _orderUpdateController.add(response.data);
      }
    } catch (e) {
      print('Error fetching order details');
    }
  }

  void stopOrderUpdates() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdateController.stream;

  Future<String?> _getAuthToken() async {
    try {
      final token = await storage.read(key: 'accessToken');
      print('Token retrieved: ${token != null ? 'Yes' : 'No'}');
      return token;
    } catch (e) {
      print('Error getting token');
      return null;
    }
  }

  Future<void> connectToChat() async {
    print('=== CHAT CONNECTION START ===');
    _chatSocket?.disconnect();
    _chatSocket = null;

    final token = await _getAuthToken();
    if (token == null) {
      print('=== ERROR: No token found for socket connection ===');
      return;
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000';
    final uri = Uri.parse(apiUrl);
    print('apiUrl: $apiUrl');
    print('uri.host: ${uri.host}');
    print('uri.port: ${uri.port}');
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
    print('Final wsUrl: $wsUrl');
    print('Connecting to Socket.IO: $wsUrl/p2p/chat');

    // For P2P chat, connect to the correct namespace
    _chatSocket = IO.io('$wsUrl/p2p/chat', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'query': {'token': token, 'EIO': '4'},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5
    });

    _chatSocket?.onConnecting((_) {
      print('=== SOCKET CONNECTING ===');
      print('Socket ID: ${_chatSocket?.id}');
      print('Socket namespace: ${_chatSocket?.nsp}');
    });

    _chatSocket?.onConnect((_) {
      print('=== SOCKET CONNECTED ===');
      print('Socket ID: ${_chatSocket?.id}');
      print('Socket namespace: ${_chatSocket?.nsp}');
      if (_currentOrderId != null) {
        print('Rejoining order room: $_currentOrderId');
        _chatSocket?.emit('joinOrder', {'orderId': _currentOrderId});
      }
    });

    _chatSocket?.onReconnect((_) {
      print('=== SOCKET RECONNECTED ===');
      print('Socket ID: ${_chatSocket?.id}');
      if (_currentOrderId != null) {
        print('Rejoining room after reconnect: $_currentOrderId');
        _chatSocket?.emit('joinOrder', {'orderId': _currentOrderId});
      }
    });

    _chatSocket?.onDisconnect((_) {
      print('=== SOCKET DISCONNECTED ===');
      print('Reason: ${_chatSocket?.io?.engine?.transport?.readyState}');
    });

    _chatSocket?.onConnectError((err) {
      print('=== SOCKET CONNECT ERROR ===');
      print('Error details: $err');
      print('Attempting to connect to: $apiUrl/p2p/chat');
    });
    _chatSocket
        ?.onConnectTimeout((_) => print('=== SOCKET CONNECT TIMEOUT ==='));

    _chatSocket?.on('chatUpdate', (data) {
      print('=== CHAT UPDATE RECEIVED ===');
      print('Raw socket data: $data');
      print('Current OrderID: $_currentOrderId');
      print('Data type: ${data['type']}');
      print('Data orderId: ${data['orderId']}');
      print('Message content: ${data['message']}');

      try {
        if (!_chatUpdateController.isClosed) {
          _chatUpdateController.add(data);
          print('Data added to controller');
        } else {
          print('Warning: Attempted to add data to closed controller');
        }
      } catch (e) {
        print('Error adding data to stream');
      }
    });

    _chatSocket?.on('messageDelivered', (data) {
      print('=== MESSAGE DELIVERED ===');
      print('Data: $data');
      if (!_chatUpdateController.isClosed) {
        _chatUpdateController.add(data);
      }
    });

    _chatSocket?.on('messageRead', (data) {
      print('=== MESSAGE READ ===');
      print('Data: $data');
      if (!_chatUpdateController.isClosed) {
        _chatUpdateController.add(data);
      }
    });

    _chatSocket?.onError((error) {
      print('=== SOCKET ERROR ===');
      print(error);
    });

    _chatSocket?.connect();

    print('=== CONNECTION ATTEMPT COMPLETE ===');
  }

  void joinOrderChat(String orderId) {
    print('Joining order chat room: $orderId');
    _currentOrderId = orderId;
    print('Current socket status: ${_chatSocket?.connected}');
    print('Socket ID: ${_chatSocket?.id}');
    _chatSocket?.emit('joinOrder', {'orderId': orderId});
  }

  StreamSubscription listenToMessages(
      String orderId, Function(Map<String, dynamic>) onMessage) {
    // print('Setting up message listener for order: $orderId');
    return _chatUpdateController.stream.listen((data) {
      // print('=== STREAM DATA RECEIVED ===');
      print('Data: $data');
      print('Expected orderId: $orderId');
      print('Received orderId: ${data['orderId']}');

      // Convert data to Map if needed
      final messageData = data is Map
          ? Map<String, dynamic>.from(data)
          : jsonDecode(data.toString());

      if (messageData['type'] == 'chatUpdate' &&
          messageData['orderId'].toString() == orderId) {
        print('✓ Message matches current order');
        print('Message content: ${messageData['message']}');
        onMessage(messageData['message']);
      } else {
        print('✗ Message mismatch:');
        print('Expected type: chatUpdate, got: ${messageData['type']}');
        print('Expected orderId: $orderId, got: ${messageData['orderId']}');
      }
    });
  }

  StreamSubscription listenToDeliveryStatus(
      String orderId, Function(String) onDelivered) {
    print('=== SETTING UP DELIVERY STATUS LISTENER ===');
    print('Listening for delivery status on order: $orderId');
    return _chatUpdateController.stream.listen((data) {
      print('=== DELIVERY STATUS DATA RECEIVED ===');
      print('Data type: ${data['type']}');
      print('Data orderId: ${data['orderId']}');
      print('Expected orderId: $orderId');
      if (data['type'] == 'messageDelivered' && data['orderId'] == orderId) {
        print('✓ Delivery status matches current order');
        print('Message ID: ${data['messageId']}');
        onDelivered(data['messageId']);
      } else {
        print('✗ Delivery status mismatch');
      }
    });
  }

  StreamSubscription listenToReadStatus(
      String orderId, Function(String) onRead) {
    print('=== SETTING UP READ STATUS LISTENER ===');
    print('Listening for read status on order: $orderId');
    return _chatUpdateController.stream.listen((data) {
      print('=== READ STATUS DATA RECEIVED ===');
      print('Data type: ${data['type']}');
      print('Data orderId: ${data['orderId']}');
      print('Expected orderId: $orderId');
      if (data['type'] == 'messageRead' && data['orderId'] == orderId) {
        print('✓ Read status matches current order');
        print('Message ID: ${data['messageId']}');
        onRead(data['messageId']);
      } else {
        print('✗ Read status mismatch');
      }
    });
  }

  Future<List<Map<String, dynamic>>> getOrderMessages(String orderId) async {
    try {
      final response = await _dio.get(
        '/p2p/chat/$orderId/messages',
        options: Options(headers: await _getAuthHeaders()),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error getting order messages');
      rethrow;
    }
  }

  Future<void> sendMessage(String trackingId, String message,
      {String? attachment}) async {
    print('=== SENDING MESSAGE ===');
    print('TrackingID for sending: $trackingId');
    print('Current OrderID: $_currentOrderId');
    try {
      final response =
          await _dio.post('/p2p/orders/$trackingId/messages', data: {
        'message': message,
        'attachment': attachment,
      });

      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }

      print('Message sent via HTTP, emitting to WebSocket');
      print('Response data: ${response.data}');
      _chatSocket
          ?.emit('sendMessage', {'trackingId': trackingId, 'message': message});

      print('Message sent successfully');
    } catch (e) {
      print('=== MESSAGE SEND ERROR ===');
      print('Error sending message');
      print(StackTrace.current);
    }
  }

  Future<void> markMessageAsDelivered(String messageId) async {
    try {
      print('Marking message as delivered: $messageId');
      await _dio.post(
        '/p2p/chat/message/$messageId/delivered',
        options: Options(headers: await _getAuthHeaders()),
      );

      // Emit to socket
      _chatSocket?.emit('messageDelivered', {
        'messageId': messageId,
        'orderId': _currentOrderId,
      });
      print('Delivery status emitted for message: $messageId');
    } catch (e) {
      print('Error marking message as delivered');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      print('Marking message as read: $messageId');
      await _dio.post(
        '/p2p/chat/message/$messageId/read',
        options: Options(headers: await _getAuthHeaders()),
      );

      // Emit to socket
      _chatSocket?.emit('messageRead', {
        'messageId': messageId,
        'orderId': _currentOrderId,
      });
      print('Read status emitted for message: $messageId');
    } catch (e) {
      print('Error marking message as read');
    }
  }

  void disposeChatSocket() {
    print('=== DISPOSING CHAT SOCKET ===');
    _chatSocket?.disconnect();
    _chatSocket = null;
  }

  Future<Map<String, dynamic>> getDisputeByOrderId(String trackingId) async {
    try {
      final response = await _dio.get(
        '/p2p/disputes/order/$trackingId',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Enhance debugging - log token information at different levels
        print('Dispute API response successful, examining token/asset data:');

        // Check if order and token data are present
        if (data != null && data['order'] != null) {
          print('Order data is present in dispute response');

          // Check various paths for token information
          if (data['order']['offer'] != null &&
              data['order']['offer']['token'] != null) {
            print(
                'Found token info in order.offer.token: ${jsonEncode(data['order']['offer']['token'])}');
          }

          // Check directly attached token data to order
          if (data['order']['cryptoAsset'] != null) {
            print(
                'Found cryptoAsset directly on order: ${data['order']['cryptoAsset']}');
          }

          // Check token symbol on order
          if (data['order']['tokenSymbol'] != null) {
            print(
                'Found tokenSymbol directly on order: ${data['order']['tokenSymbol']}');
          }
        }

        // Debug log - limit size to prevent excessive output
        final debugData = jsonEncode(data);
        print(
            'Dispute data: ${debugData.substring(0, math.min(debugData.length, 500))}...');

        return data;
      } else {
        throw Exception('Failed to load dispute details');
      }
    } catch (e) {
      print('Error fetching dispute details');
      throw _handleError(e);
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        // Today - show time only
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        // This week
        final weekday = _getWeekdayName(date.weekday);
        return '$weekday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        // Older - show full date
        final monthName = _getMonthName(date.month);
        return '$monthName ${date.day}, ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error formatting date');
      return dateString; // Return original string if parsing fails
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  Future<void> connectToDisputeChat() async {
    print('=== DISPUTE CHAT CONNECTION START ===');
    _disputeChatSocket?.disconnect();
    _disputeChatSocket = null;

    final token = await _getAuthToken();
    if (token == null) {
      print('=== ERROR: No token found for socket connection ===');
      return;
    }

    final apiUrl = dotenv.env['API_URL'] ?? 'https://decrypted.nadiapoint.com';
    final uri = Uri.parse(apiUrl);
    print('apiUrl: $apiUrl');
    print('uri.host: ${uri.host}');
    print('uri.port: ${uri.port}');
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
    print('Final wsUrl: $wsUrl');
    print('Connecting to Socket.IO: $wsUrl/p2p/dispute');

    // For dispute chat, connect to the correct namespace
    _disputeChatSocket = IO.io('$wsUrl/p2p/dispute', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
      'query': {'token': token, 'EIO': '4'},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5
    });

    _disputeChatSocket?.onConnecting((_) {
      print('=== DISPUTE SOCKET CONNECTING ===');
      print('Socket ID: ${_disputeChatSocket?.id}');
      print('Socket namespace: ${_disputeChatSocket?.nsp}');
    });

    _disputeChatSocket?.onConnect((_) {
      print('=== DISPUTE SOCKET CONNECTED ===');
      print('Socket ID: ${_disputeChatSocket?.id}');
      print('Socket namespace: ${_disputeChatSocket?.nsp}');
      if (_currentDisputeId != null) {
        print('Joining dispute room: $_currentDisputeId');
        _disputeChatSocket
            ?.emit('joinDispute', {'disputeId': _currentDisputeId});
      }
    });

    _disputeChatSocket?.onReconnect((_) {
      print('=== DISPUTE SOCKET RECONNECTED ===');
      print('Socket ID: ${_disputeChatSocket?.id}');
      if (_currentDisputeId != null) {
        print('Rejoining dispute room after reconnect: $_currentDisputeId');
        _disputeChatSocket
            ?.emit('joinDispute', {'disputeId': _currentDisputeId});
      }
    });

    _disputeChatSocket?.onDisconnect((_) {
      // print('=== DISPUTE SOCKET DISCONNECTED ===');
      // print('Reason: ${_disputeChatSocket?.io?.engine?.transport?.readyState}');
    });

    _disputeChatSocket?.onConnectError((err) {
      print('=== DISPUTE SOCKET CONNECT ERROR ===');
      print('Error details: $err');
      // print('Attempting to connect to: $apiUrl/p2p/dispute');
    });
    _disputeChatSocket?.onConnectTimeout(
        (_) => print('=== DISPUTE SOCKET CONNECT TIMEOUT ==='));

    _disputeChatSocket?.on('disputeMessageUpdate', (data) {
      // print('=== DISPUTE MESSAGE UPDATE RECEIVED ===');
      // print('Raw socket data: $data');
      // print('Current DisputeID: $_currentDisputeId');
      // print('Data type: ${data['type']}');
      // print('Data disputeId: ${data['disputeId']}');
      // print('Message content: ${data['message']}');

      try {
        if (!_disputeChatUpdateController.isClosed) {
          _disputeChatUpdateController.add(data);
          // print('Dispute data added to controller');
        } else {
          print('Warning: Attempted to add data to closed dispute controller');
        }
      } catch (e) {
        print('Error adding dispute data to stream');
      }
    });

    _disputeChatSocket?.on('disputeMessageDelivered', (data) {
      // print('=== DISPUTE MESSAGE DELIVERED ===');
      // print('Data: $data');
      if (!_disputeChatUpdateController.isClosed) {
        _disputeChatUpdateController.add(data);
      }
    });

    _disputeChatSocket?.on('disputeMessageRead', (data) {
      // print('=== DISPUTE MESSAGE READ ===');
      // print('Data: $data');
      if (!_disputeChatUpdateController.isClosed) {
        _disputeChatUpdateController.add(data);
      }
    });

    _disputeChatSocket?.on('disputeUpdate', (data) {
      // print('=== DISPUTE UPDATE RECEIVED ===');
      // print('Data: $data');
      if (!_disputeChatUpdateController.isClosed) {
        _disputeChatUpdateController.add(data);
      }
    });

    // Add listener for dispute status updates
    _disputeChatSocket?.on('disputeStatusUpdate', (data) {
      print('=== DISPUTE STATUS UPDATE RECEIVED ===');
      print('Data: $data');
      if (!_disputeChatUpdateController.isClosed) {
        // Make sure the data includes the type for our stream listeners
        if (data is Map && !data.containsKey('type')) {
          data['type'] = 'disputeStatusUpdate';
        }
        _disputeChatUpdateController.add(data);
      }
    });

    _disputeChatSocket?.onError((error) {
      print('=== DISPUTE SOCKET ERROR ===');
      print(error);
    });

    _disputeChatSocket?.connect();

    // print('=== DISPUTE CONNECTION ATTEMPT COMPLETE ===');
  }

  void joinDisputeChat(String disputeId) {
    // print('Joining dispute chat room: $disputeId');
    _currentDisputeId = disputeId;
    // print('Current dispute socket status: ${_disputeChatSocket?.connected}');
    // print('Socket ID: ${_disputeChatSocket?.id}');
    _disputeChatSocket?.emit('joinDispute', {'disputeId': disputeId});
  }

  Future<List<Map<String, dynamic>>> getDisputeMessages(
      String disputeId) async {
    try {
      final response = await _dio.get(
        '/p2p/disputes/$disputeId/messages',
        options: Options(headers: await _getAuthHeaders()),
      );
      // print('Fetched dispute messages: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error getting dispute messages');
      rethrow;
    }
  }

  Future<void> sendDisputeMessage(String disputeId, String message,
      {String? attachment}) async {
    print('=== SENDING DISPUTE MESSAGE ===');
    print('DisputeID for sending: $disputeId');
    print('Current DisputeID: $_currentDisputeId');
    print('Message length: ${message.length}');
    print('Has attachment: ${attachment != null}');

    try {
      // Validate attachment format if present
      if (attachment != null) {
        print('Attachment length: ${attachment.length}');
        print(
            'Attachment starts with: ${attachment.substring(0, math.min(100, attachment.length))}...');

        if (!attachment.startsWith('data:image/')) {
          throw Exception(
              'Invalid attachment format: Missing data:image/ prefix');
        }

        if (!attachment.contains(';base64,')) {
          throw Exception('Invalid attachment format: Missing ;base64, marker');
        }
      }

      print(
          'Sending HTTP request to: ${_dio.options.baseUrl}/p2p/disputes/$disputeId/messages');
      final response = await _dio.post(
        '/p2p/disputes/$disputeId/messages',
        data: {
          'message': message,
          'attachment': attachment,
        },
        options: Options(
          headers: {
            ...await _getAuthHeaders(),
            'Content-Type': 'application/json',
          },
          validateStatus: (status) =>
              status! < 500, // Allow 4xx responses to be handled
        ),
      );

      print('HTTP response status: ${response.statusCode}');
      print('HTTP response data: ${response.data}');

      if (response.statusCode != 201) {
        print(
            'Failed to send dispute message: ${response.statusCode} - ${response.data}');
        throw Exception(
            'Failed to send dispute message: ${response.statusCode} - ${response.data}');
      }

      print('Dispute message sent via HTTP, emitting to WebSocket');
      _disputeChatSocket?.emit('sendDisputeMessage', {
        'disputeId': disputeId,
        'message': message,
        'hasAttachment': attachment != null,
      });

      print('Dispute message sent successfully');
      return response.data;
    } catch (e) {
      print('=== DISPUTE MESSAGE SEND ERROR ===');
      print('Error sending dispute message');
      print('Error type: ${e.runtimeType}');
      print(StackTrace.current);
      rethrow;
    }
  }

  Future<void> markDisputeMessageAsDelivered(String messageId) async {
    try {
      // print('Marking dispute message as delivered: $messageId');
      await _dio.post(
        '/p2p/disputes/messages/$messageId/delivered',
        options: Options(headers: await _getAuthHeaders()),
      );

      // Emit to socket
      _disputeChatSocket?.emit('disputeMessageDelivered', {
        'messageId': messageId,
        'disputeId': _currentDisputeId,
      });
      print('Delivery status emitted for dispute message: $messageId');
    } catch (e) {
      print('Error marking dispute message as delivered');
    }
  }

  Future<void> markDisputeMessageAsRead(String messageId) async {
    try {
      print('Marking dispute message as read: $messageId');
      await _dio.post(
        '/p2p/disputes/messages/$messageId/read',
        options: Options(headers: await _getAuthHeaders()),
      );

      // Emit to socket
      _disputeChatSocket?.emit('disputeMessageRead', {
        'messageId': messageId,
        'disputeId': _currentDisputeId,
      });
      print('Read status emitted for dispute message: $messageId');
    } catch (e) {
      print('Error marking dispute message as read');
    }
  }

  StreamSubscription listenToDisputeMessages(
      String disputeId, Function(Map<String, dynamic>) onMessage) {
    print('Setting up dispute message listener for dispute: $disputeId');
    return _disputeChatUpdateController.stream.listen((data) {
      print('Data: $data');
      print('Expected disputeId: $disputeId');
      print('Received disputeId: ${data['disputeId']}');

      // Convert data to Map if needed
      final messageData = data is Map
          ? Map<String, dynamic>.from(data)
          : jsonDecode(data.toString());

      if (messageData['type'] == 'disputeMessageUpdate' &&
          messageData['disputeId'].toString() == disputeId) {
        print('✓ Dispute message matches current dispute');
        print('Message content: ${messageData['message']}');
        onMessage(messageData['message']);
      } else {
        print('✗ Dispute message mismatch:');
        print(
            'Expected type: disputeMessageUpdate, got: ${messageData['type']}');
        print(
            'Expected disputeId: $disputeId, got: ${messageData['disputeId']}');
      }
    });
  }

  StreamSubscription listenToDisputeDeliveryStatus(
      String disputeId, Function(String) onDelivered) {
    print('=== SETTING UP DISPUTE DELIVERY STATUS LISTENER ===');
    print('Listening for delivery status on dispute: $disputeId');
    return _disputeChatUpdateController.stream.listen((data) {
      print('=== DISPUTE DELIVERY STATUS DATA RECEIVED ===');
      print('Data type: ${data['type']}');
      print('Data disputeId: ${data['disputeId']}');
      print('Expected disputeId: $disputeId');
      if (data['type'] == 'disputeMessageDelivered' &&
          data['disputeId'] == disputeId) {
        print('✓ Delivery status matches current dispute');
        print('Message ID: ${data['messageId']}');
        onDelivered(data['messageId']);
      } else {
        print('✗ Delivery status mismatch');
      }
    });
  }

  StreamSubscription listenToDisputeReadStatus(
      String disputeId, Function(String) onRead) {
    print('=== SETTING UP DISPUTE READ STATUS LISTENER ===');
    print('Listening for read status on dispute: $disputeId');
    return _disputeChatUpdateController.stream.listen((data) {
      print('=== DISPUTE READ STATUS DATA RECEIVED ===');
      print('Data type: ${data['type']}');
      print('Data disputeId: ${data['disputeId']}');
      print('Expected disputeId: $disputeId');
      if (data['type'] == 'disputeMessageRead' &&
          data['disputeId'] == disputeId) {
        print('✓ Read status matches current dispute');
        print('Message ID: ${data['messageId']}');
        onRead(data['messageId']);
      } else {
        print('✗ Read status mismatch');
      }
    });
  }

  // Add new method to listen for dispute status updates
  StreamSubscription listenToDisputeStatusUpdates(
      String disputeId, Function(Map<String, dynamic>) onStatusUpdate) {
    print('Setting up dispute status update listener for dispute: $disputeId');
    return _disputeChatUpdateController.stream.listen((data) {
      if (data['type'] == 'disputeStatusUpdate' &&
          data['disputeId'] == disputeId) {
        print('Received dispute status update: ${data['status']}');
        onStatusUpdate(data);
      }
    });
  }

  // Get user's dispute history
  Future<List<Map<String, dynamic>>> getUserDisputes({
    String? status,
    String? searchQuery,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('Fetching user disputes history...');

      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'includeRelations': 'true',
        'includeOrder': 'true',
        'includeBuyer': 'true',
        'includeSeller': 'true',
        'includeToken': 'true',
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional parameters if provided
      if (status != null && status.toLowerCase() != 'all') {
        queryParams['status'] = status;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      final response = await _dio.get(
        '/p2p/disputes',
        queryParameters: queryParams,
      );

      print('Got dispute response with status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Log the response structure for debugging
        print('Response data type: ${response.data.runtimeType}');

        // Handle both direct list and paginated response formats
        if (response.data is List) {
          print('Got ${response.data.length} disputes');
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          if (response.data['disputes'] != null) {
            print(
                'Got ${response.data['disputes'].length} disputes from paginated response');
            return List<Map<String, dynamic>>.from(response.data['disputes']);
          } else if (response.data['items'] != null) {
            print('Got ${response.data['items'].length} disputes');
            return List<Map<String, dynamic>>.from(response.data['items']);
          } else {
            print('Unexpected response format: ${response.data}');
            return [];
          }
        } else {
          print('Unexpected response format: ${response.data}');
          return [];
        }
      }
      print('Failed to load disputes: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error loading disputes');
      return [];
    }
  }

  void dispose() {
    print('=== DISPOSING P2P SERVICE ===');
    _chatSocket?.disconnect();
    _chatSocket = null;
    _disputeChatSocket?.disconnect();
    _disputeChatSocket = null;
    _chatUpdateController.close();
    _disputeChatUpdateController.close();
    _orderUpdateController.close();
  }
}
