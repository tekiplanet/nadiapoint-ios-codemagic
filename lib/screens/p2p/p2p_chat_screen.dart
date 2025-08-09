import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/p2p_service.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../widgets/image_viewer.dart';

class P2PChatScreen extends StatefulWidget {
  final String orderId;
  final String trackingId;
  final bool isBuyer;
  final String userName;

  const P2PChatScreen({
    super.key,
    required this.orderId,
    required this.trackingId,
    required this.isBuyer,
    required this.userName,
  });

  @override
  State<P2PChatScreen> createState() => _P2PChatScreenState();
}

class _P2PChatScreenState extends State<P2PChatScreen> {
  final P2PService _p2pService = GetIt.I<P2PService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _deliveredMessages = {};
  final Set<String> _readMessages = {};
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  final _numberFormat = NumberFormat("#,##0.00", "en_US");
  List<StreamSubscription> _subscriptions = [];
  File? _selectedImage;
  bool _isChatDisabled = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupMessageStatusListeners();
    _loadOrderDetails();
  }

  Future<void> _initializeChat() async {
    print('=== INITIALIZING CHAT ===');
    print('OrderID: ${widget.orderId}');
    print('TrackingID: ${widget.trackingId}');
    try {
      await _p2pService.connectToChat();
      print('Connected to chat service');

      _p2pService.joinOrderChat(widget.orderId);
      print('Joined order chat: ${widget.orderId}');

      final messages = await _p2pService.getOrderMessages(widget.orderId);
      print('Fetched initial messages: ${messages.length}');

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      print('Set initial messages in state');

      _subscriptions.clear();
      _subscriptions.addAll([
        _p2pService.listenToMessages(widget.orderId, (message) {
          print('=== NEW MESSAGE CALLBACK ===');
          print('Current OrderID: ${widget.orderId}');
          print('Current TrackingID: ${widget.trackingId}');
          print('Message received: $message');
          print('=== MESSAGE DETAILS ===');
          print('Current messages count: ${_messages.length}');
          print('Message ID: ${message['id']}');
          print('Sender ID: ${message['senderId']}');
          setState(() {
            if (!_messages.any((m) => m['id'] == message['id'])) {
              _messages.add(message);
              print('Added new message to state');
              print('New messages count: ${_messages.length}');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            } else {
              print('Message already exists in state');
              print('Duplicate message ID: ${message['id']}');
            }
          });
        }),
        _p2pService.listenToDeliveryStatus(widget.orderId, (messageId) {
          if (!mounted) return;
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == messageId);
            if (index != -1) {
              _messages[index] = {
                ..._messages[index],
                'isDelivered': true,
              };
            }
          });
        }),
        _p2pService.listenToReadStatus(widget.orderId, (messageId) {
          if (!mounted) return;
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == messageId);
            if (index != -1) {
              _messages[index] = {
                ..._messages[index],
                'isDelivered': true,
                'isRead': true,
              };
            }
          });
        }),
      ]);
      print('Message listener set up');
    } catch (e) {
      print('=== CHAT INITIALIZATION ERROR ===');
      print('Error initializing chat');
      print(StackTrace.current);
    }
  }

  Future<void> _loadOrderDetails() async {
    try {
      print(
          'Attempting to load order details for trackingId: ${widget.trackingId}');
      // Get order details from the API
      final orderDetails = await _p2pService.getOrderDetails(widget.trackingId);
      if (orderDetails != null) {
        setState(() {
          _orderDetails = orderDetails;

          // Check if the chat should be disabled based on order status
          final buyerStatus =
              orderDetails['buyerStatus']?.toString().toLowerCase() ?? '';
          final sellerStatus =
              orderDetails['sellerStatus']?.toString().toLowerCase() ?? '';

          // Disable chat if order is completed or cancelled
          _isChatDisabled = buyerStatus == 'completed' ||
              sellerStatus == 'completed' ||
              buyerStatus == 'cancelled' ||
              sellerStatus == 'cancelled';

          print('Chat disabled status: $_isChatDisabled');
          print('Order buyer status: $buyerStatus');
          print('Order seller status: $sellerStatus');
        });
      } else {
        print('Failed to load order details');
      }
    } catch (e) {
      print('Error loading order details');
      // For now, let's create a simple order details object so the UI works
      setState(() {
        _orderDetails = {
          'trackingId': widget.trackingId,
          'status': 'In Progress',
          'amount': 0.0,
          'price': 0.0,
          'total': 0.0,
          'token': {'symbol': 'USDT'},
          'currency': {'symbol': 'NGN'},
        };
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateMessageStatus(String messageId, bool isDelivered, bool isRead) {
    setState(() {
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'isDelivered': isDelivered,
          'isRead': isRead,
        };
      }
    });
  }

  void _setupMessageStatusListeners() {
    // _p2pService.listenToDeliveryStatus(widget.orderId, (messageId) {
    //   print('Message marked as delivered: $messageId');
    //   _updateMessageStatus(messageId, true, false);
    // });

    // _p2pService.listenToReadStatus(widget.orderId, (messageId) {
    //   print('Message marked as read: $messageId');
    //   _updateMessageStatus(messageId, true, true);
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: widget.userName,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final messageType =
                          message['messageType']?.toString() ?? '';
                      final isSender = !messageType.contains('SYSTEM') &&
                          (widget.isBuyer
                              ? messageType == 'BUYER'
                              : messageType == 'SELLER');
                      return _buildMessageItem(message, isSender, isDark);
                    },
                  ),
          ),
          if (!_isChatDisabled) _buildMessageInput(isDark),
          if (_isChatDisabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? SafeJetColors.primaryBackground
                    : SafeJetColors.lightBackground,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.2)
                        : SafeJetColors.lightCardBorder,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  "This order has been completed or cancelled. You can no longer send messages.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
      Map<String, dynamic> message, bool isSender, bool isDark) {
    final isSystem = message['messageType'] == 'SYSTEM';
    final messageId = message['id'];

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SafeJetColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: SafeJetColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: SafeJetColors.warning,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(
                      DateTime.parse(message['createdAt']),
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Only mark other's messages as delivered/read
    if (!isSender) {
      if (!message['isDelivered']) {
        _p2pService.markMessageAsDelivered(messageId);
      }
      if (!message['isRead']) {
        _p2pService.markMessageAsRead(messageId);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSender) ...[
            CircleAvatar(
              backgroundColor: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
              radius: 16,
              child: Text(
                widget.userName[0].toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSender
                    ? SafeJetColors.primary
                    : isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: !isSender
                    ? Border.all(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: isSender
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message['attachmentUrl'] != null) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageViewer(
                                  imageUrl:
                                      '${_p2pService.apiUrl}/p2p/chat/images/${message['attachmentUrl']}',
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: message['attachmentUrl'],
                            child: Image.network(
                              '${_p2pService.apiUrl}/p2p/chat/images/${message['attachmentUrl']}',
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  width: 200,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isSender
                          ? Colors.white
                          : isDark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(
                          DateTime.parse(message['createdAt']),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSender
                              ? Colors.white70
                              : isDark
                                  ? Colors.grey[400]
                                  : SafeJetColors.lightTextSecondary,
                        ),
                      ),
                      if (isSender) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['isRead']
                              ? Icons.done_all
                              : message['isDelivered']
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 12,
                          color: message['isRead']
                              ? SafeJetColors.success
                              : isSender
                                  ? Colors.white70
                                  : Colors.grey[400],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSender) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: SafeJetColors.primary,
              radius: 16,
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              height: 100,
              width: 100,
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                  );

                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: SafeJetColors.primary,
                      ),
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: SafeJetColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () async {
                    if (_messageController.text.trim().isEmpty &&
                        _selectedImage == null) {
                      return;
                    }

                    String? base64Image;
                    if (_selectedImage != null) {
                      final bytes = await _selectedImage!.readAsBytes();
                      base64Image =
                          'data:image/jpeg;base64,${base64.encode(bytes)}';
                    }

                    await _p2pService.sendMessage(
                      widget.trackingId,
                      _messageController.text,
                      attachment: base64Image,
                    );

                    _messageController.clear();
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  icon: const Icon(Icons.send),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
