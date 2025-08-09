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
import '../../widgets/loading_indicator.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class P2PDisputeChatScreen extends StatefulWidget {
  final String disputeId;
  final String orderId;
  final bool isAdmin;
  final String disputeTitle;

  const P2PDisputeChatScreen({
    super.key,
    required this.disputeId,
    required this.orderId,
    this.isAdmin = false,
    required this.disputeTitle,
  });

  @override
  State<P2PDisputeChatScreen> createState() => _P2PDisputeChatScreenState();
}

class _P2PDisputeChatScreenState extends State<P2PDisputeChatScreen> {
  final P2PService _p2pService = GetIt.I<P2PService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _deliveredMessages = {};
  final Set<String> _readMessages = {};
  bool _isLoading = true;
  Map<String, dynamic>? _disputeDetails;
  List<StreamSubscription> _subscriptions = [];
  File? _selectedImage;
  String? _currentUserId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print('=== INITIALIZING DISPUTE CHAT ===');
    print('DisputeID: ${widget.disputeId}');
    print('OrderID: ${widget.orderId}');

    try {
      // Test image endpoint to check if server configuration is correct
      _testImageEndpoint();

      // Extract the user ID directly from the token using the service
      final userId = await _p2pService.extractUserIdFromToken();

      setState(() {
        _currentUserId = userId;
      });

      print('Current user ID: $_currentUserId');

      // Connect to the dispute chat socket
      await _p2pService.connectToDisputeChat();
      print('Connected to dispute chat service');

      // Join the dispute chat room
      _p2pService.joinDisputeChat(widget.disputeId);
      print('Joined dispute chat: ${widget.disputeId}');

      // Fetch dispute details with full relations (includes buyer, seller, initiator, respondent)
      try {
        final details = await _p2pService.getDisputeByOrderId(widget.orderId);

        // Debug: Print the full dispute details structure
        print('=== FULL DISPUTE DETAILS ===');
        print('Dispute data keys: ${details.keys.toList()}');

        setState(() {
          _disputeDetails = details;
        });
        print('Dispute details loaded');

        // Log information about the involved parties to help with debugging
        if (_disputeDetails != null) {
          final order = _disputeDetails!['order'] ?? {};
          final buyer = order['buyer'] ?? {};
          final seller = order['seller'] ?? {};

          print(
              'Buyer: ${buyer['fullName'] ?? buyer['username'] ?? 'Unknown'} (ID: ${buyer['id'] ?? 'Unknown'})');
          print(
              'Seller: ${seller['fullName'] ?? seller['username'] ?? 'Unknown'} (ID: ${seller['id'] ?? 'Unknown'})');

          if (_currentUserId != null) {
            print('Current user is buyer: ${_currentUserId == buyer['id']}');
            print('Current user is seller: ${_currentUserId == seller['id']}');
          } else {
            print('Cannot determine user role: currentUserId is null');
          }
        }
      } catch (e) {
        print('Error loading dispute details');
      }

      // Fetch initial messages
      final messages = await _p2pService.getDisputeMessages(widget.disputeId);
      print('Fetched initial dispute messages: ${messages.length}');

      // If we have messages, analyze the first few to understand structure
      if (messages.isNotEmpty) {
        print('=== MESSAGE DATA STRUCTURE ===');
        final firstMessage = messages[0];
        print('Message keys: ${firstMessage.keys.toList()}');

        for (int i = 0; i < math.min(3, messages.length); i++) {
          final message = messages[i];
          print('Sample message $i:');
          print('  Sender ID: ${message['senderId']}');
          print('  Sender Type: ${message['senderType']}');
          print('  Message: ${message['message']}');

          // Check if there's a sender object
          if (message['sender'] != null) {
            print('  Sender object keys: ${message['sender'].keys.toList()}');
            print(
                '  Sender username: ${message['sender']['username'] ?? 'N/A'}');
          } else {
            print('  No sender object in message');
          }
        }
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
        _isInitializing = false;
      });
      print('Set initial dispute messages in state');

      // Setup message listeners
      _setupMessageListeners();

      // Scroll to bottom once messages are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('=== DISPUTE CHAT INITIALIZATION ERROR ===');
      print('Error initializing dispute chat');
      print(StackTrace.current);
      setState(() {
        _isLoading = false;
        _isInitializing = false;
      });
    }
  }

  Future<void> _testImageEndpoint() async {
    try {
      // Create a simple HTTP GET request to test if the image endpoint is accessible
      print('=== TESTING IMAGE ENDPOINT ===');
      final imageUrl = '${_p2pService.apiUrl}/p2p/chat/images/test.jpg';
      print('Testing endpoint: $imageUrl');

      final response = await http.head(Uri.parse(imageUrl));
      print('Image endpoint status code: ${response.statusCode}');
      print('Image endpoint headers: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✓ Image endpoint appears to be available');
      } else if (response.statusCode == 404) {
        print(
            '⚠ Image endpoint returned 404 - this is expected for a test file');
        print('✓ Image endpoint appears to be correctly configured');
      } else {
        print(
            '⚠ Image endpoint may have configuration issues: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠ Error testing image endpoint');
    }
  }

  void _setupMessageListeners() {
    _subscriptions.clear();
    _subscriptions.addAll([
      _p2pService.listenToDisputeMessages(widget.disputeId, (message) {
        print('=== NEW DISPUTE MESSAGE CALLBACK ===');
        print('Current DisputeID: ${widget.disputeId}');
        print('Message received: $message');
        print('=== MESSAGE DETAILS ===');
        print('Current messages count: ${_messages.length}');
        print('Message ID: ${message['id']}');
        print('Sender ID: ${message['senderId']}');
        setState(() {
          if (!_messages.any((m) => m['id'] == message['id'])) {
            _messages.add(message);
            print('Added new dispute message to state');
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
      _p2pService.listenToDisputeDeliveryStatus(widget.disputeId, (messageId) {
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
      _p2pService.listenToDisputeReadStatus(widget.disputeId, (messageId) {
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
      // Add listener for dispute status updates
      _p2pService.listenToDisputeStatusUpdates(widget.disputeId, (statusData) {
        print('=== DISPUTE STATUS UPDATE RECEIVED ===');
        print('New status: ${statusData['status']}');

        // Refresh dispute details to get the latest status
        _refreshDisputeDetails();
      }),
    ]);
    print('Dispute message listeners set up');
  }

  Future<void> _refreshDisputeDetails() async {
    print('Refreshing dispute details after status update');
    try {
      final details = await _p2pService.getDisputeByOrderId(widget.orderId);

      if (mounted) {
        setState(() {
          _disputeDetails = details;
          print('Dispute details refreshed with status: ${details['status']}');
        });
      }
    } catch (e) {
      print('Error refreshing dispute details');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Check if the dispute is closed or resolved
    final String disputeStatus =
        _disputeDetails?['status']?.toString().toLowerCase() ?? '';
    final bool isDisputeClosedOrResolved = disputeStatus == 'closed' ||
        disputeStatus == 'resolved_buyer' ||
        disputeStatus == 'resolved_seller';

    return Scaffold(
      appBar: P2PAppBar(
        title: widget.disputeTitle,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: _isInitializing
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: LoadingIndicator())
                      : _messages.isEmpty
                          ? Center(
                              child: Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return _buildMessageItem(message, isDark);
                              },
                            ),
                ),
                // Only show message input if dispute is not closed or resolved
                if (!isDisputeClosedOrResolved) _buildMessageInput(isDark),
              ],
            ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isDark) {
    final senderType = message['senderType']?.toString().toLowerCase() ?? '';
    final senderId = message['senderId']?.toString() ?? '';
    final isSystem = senderType == 'system';
    final isAdmin = senderType == 'admin';
    final isCurrentUser = _currentUserId != null && senderId == _currentUserId;
    final messageId = message['id'];

    // Add more detailed logging for debugging
    // print('=== BUILDING MESSAGE ITEM ===');
    // print('Message ID: $messageId');
    // print('Sender Type: $senderType');
    // print('Sender ID: $senderId');
    // print('Current User ID: $_currentUserId');
    // print('Is Current User: $isCurrentUser');

    // Log sender data if available
    if (message['sender'] != null) {
      //   print('Sender data available:');
      //   print('  Username: ${message['sender']['username']}');
      //   print('  Full name: ${message['sender']['fullName']}');

      // Print all keys and values to help debug
      message['sender'].forEach((key, value) {
        // print('  $key: $value');
      });
    } else {
      print('No sender data available in message');
    }

    // Log dispute details
    if (_disputeDetails != null) {
      //   print('Dispute details available:');
      final order = _disputeDetails!['order'] ?? {};
      final buyer = order['buyer'] ?? {};
      final seller = order['seller'] ?? {};
      //   print('  Order buyer ID: ${buyer['id']}');
      //   print('  Order buyer username: ${buyer['username']}');
      //   print('  Order buyer fullName: ${buyer['fullName']}');
      //   print('  Order seller ID: ${seller['id']}');
      //   print('  Order seller username: ${seller['username']}');
      //   print('  Order seller fullName: ${seller['fullName']}');

      // Try to determine if sender is buyer or seller based on ID
      if (senderId.isNotEmpty) {
        final isSenderBuyer = senderId == buyer['id'];
        final isSenderSeller = senderId == seller['id'];
        //     print('  Sender is buyer: $isSenderBuyer');
        //     print('  Sender is seller: $isSenderSeller');
      }
    } else {
      print('No dispute details available');
    }

    // If it's a system message, display a special bubble
    if (isSystem) {
      return _buildSystemMessage(message, isDark);
    }

    // If it's from admin, display it with admin styling
    if (isAdmin) {
      return _buildAdminMessage(message, isDark);
    }

    // Only mark other's messages as delivered/read if we have a valid user ID
    if (_currentUserId != null && !isCurrentUser) {
      print('Marking message as delivered/read: $messageId');
      if (!message['isDelivered']) {
        _p2pService.markDisputeMessageAsDelivered(messageId);
      }
      if (!message['isRead']) {
        _p2pService.markDisputeMessageAsRead(messageId);
      }
    }

    // Determine if the sender is a buyer or seller
    final isSenderBuyer = _isSenderBuyer(message);
    print('Is Sender Buyer: $isSenderBuyer');

    // Display user messages (either current user or other party)
    return _buildUserMessage(message, isCurrentUser, isDark, isSenderBuyer);
  }

  // Helper method to determine if a sender is a buyer based on message data
  bool _isSenderBuyer(Map<String, dynamic> message) {
    // If we don't have dispute details or sender ID, default to false
    if (_disputeDetails == null) return false;

    final senderId = message['senderId']?.toString() ?? '';
    if (senderId.isEmpty) return false;

    // Get buyer and seller IDs from the order
    final order = _disputeDetails!['order'] ?? {};
    final buyerId = order['buyerId']?.toString() ?? '';
    final sellerId = order['sellerId']?.toString() ?? '';

    print('Comparing sender ID: $senderId');
    print('With buyer ID: $buyerId');
    print('With seller ID: $sellerId');

    // Simple check if sender matches buyer ID
    return senderId == buyerId;
  }

  Widget _buildSystemMessage(Map<String, dynamic> message, bool isDark) {
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

  Widget _buildAdminMessage(Map<String, dynamic> message, bool isDark) {
    final adminName = message['sender']?['username'] ?? 'Admin';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: SafeJetColors.primary,
            radius: 16,
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SafeJetColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    adminName,
                    style: TextStyle(
                      color: SafeJetColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.2)
                          : SafeJetColors.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          value: progress.expectedTotalBytes !=
                                                  null
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(
                          DateTime.parse(message['createdAt']),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey[400]
                              : SafeJetColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(Map<String, dynamic> message, bool isCurrentUser,
      bool isDark, bool isBuyer) {
    // Get the sender's full name from the sender object
    final fullName = message['sender']?['fullName'] ?? '';

    // Log available data for debugging
    // print('=== BUILDING USER MESSAGE ===');
    // print('Is Current User: $isCurrentUser');
    // print('Is Buyer: $isBuyer');
    // print('Sender Full Name: $fullName');
    // print('All sender data: ${message['sender']}');

    // Get the appropriate name to display
    String displayName;
    if (isCurrentUser) {
      displayName = 'You';
    } else {
      // If we have dispute details and the sender's full name isn't available from the message
      if (_disputeDetails != null && (fullName == null || fullName.isEmpty)) {
        final order = _disputeDetails!['order'] ?? {};
        final buyer = order['buyer'] ?? {};
        final seller = order['seller'] ?? {};

        if (isBuyer) {
          displayName = buyer['fullName'] ?? 'Buyer';
        } else {
          displayName = seller['fullName'] ?? 'Seller';
        }
      } else {
        // Use the full name from the message if available
        displayName =
            fullName.isNotEmpty ? fullName : (isBuyer ? 'Buyer' : 'Seller');
      }
    }

    // Always use B/S in avatars to match the screenshot
    final String avatarText = isBuyer ? 'B' : 'S';

    final bubbleColor = isDark
        ? SafeJetColors.primaryAccent.withOpacity(0.1)
        : SafeJetColors.lightCardBackground;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        // Always align to the left side for both buyer and seller messages
        // This matches the exact UI shown in the screenshot
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show the avatar on the left
          CircleAvatar(
            backgroundColor: isBuyer
                ? SafeJetColors.blue.withOpacity(0.2)
                : SafeJetColors.success.withOpacity(0.2),
            radius: 16,
            child: Text(
              avatarText,
              style: TextStyle(
                color: isBuyer ? SafeJetColors.blue : SafeJetColors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Always show the name/role label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isBuyer
                        ? SafeJetColors.blue.withOpacity(0.1)
                        : SafeJetColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color:
                          isBuyer ? SafeJetColors.blue : SafeJetColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Use a simplified message content that matches the screenshot
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.2)
                          : SafeJetColors.lightCardBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          value: progress.expectedTotalBytes !=
                                                  null
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
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(
                          DateTime.parse(message['createdAt']),
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? Colors.grey[400]
                              : SafeJetColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  onPressed: () => _sendMessage(),
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    String? base64Image;
    if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage!.readAsBytes();
        print('Image size before encoding: ${bytes.length} bytes');

        // Get file extension from path
        final extension = _selectedImage!.path.split('.').last.toLowerCase();
        String mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg'; // Default to JPEG
        }

        base64Image = 'data:$mimeType;base64,${base64.encode(bytes)}';
        print('Image encoded successfully, length: ${base64Image.length}');
        print('MIME type: $mimeType');
      } catch (e) {
        print('Error encoding image');
        print(StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image')),
        );
        return;
      }
    }

    try {
      print('=== SENDING DISPUTE MESSAGE WITH ATTACHMENT ===');
      print('Dispute ID: ${widget.disputeId}');
      print('Has attachment: ${_selectedImage != null}');
      if (_selectedImage != null) {
        print('Original image path: ${_selectedImage!.path}');
        print(
            'Image base64 prefix: ${base64Image!.substring(0, math.min(100, base64Image.length))}...');
      }

      await _p2pService.sendDisputeMessage(
        widget.disputeId,
        _messageController.text.trim(),
        attachment: base64Image,
      );

      print('Message sent successfully');

      _messageController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      print('Error sending message with attachment');
      print(StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
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
