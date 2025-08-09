import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../services/p2p_service.dart';
import '../../widgets/loading_indicator.dart';
import 'dart:math' as math;
import 'p2p_dispute_chat_screen.dart';
import 'dart:convert';
import 'dart:async';

class P2PDisputeDetailsScreen extends StatefulWidget {
  final String orderId;

  const P2PDisputeDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<P2PDisputeDetailsScreen> createState() => _P2PDisputeDetailsScreenState();
}

class _P2PDisputeDetailsScreenState extends State<P2PDisputeDetailsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _disputeData;
  P2PService? _p2pService;
  String? _counterparty;

  @override
  void initState() {
    super.initState();
    // Defer service lookup and fetch to the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDisputeDetails();
    });
  }

  Future<void> _fetchDisputeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Fetching dispute details for order ID: ${widget.orderId}');
      final P2PService p2pService = P2PService();
      final dispute = await p2pService.getDisputeByOrderId(widget.orderId);
      print('Received dispute data: ${dispute != null ? 'Found' : 'Not found'}');
      
      // Log all potential token symbol paths
      final possibleTokenPaths = [
        'order.offer.token.symbol',
        'order.cryptoAsset',
        'order.tokenSymbol',
        'order.symbol',
        'cryptoAsset',
        'tokenSymbol',
        'symbol',
        'offer.token.symbol'
      ];
      
      // Debug function to inspect each path
      void inspectObjectPaths(Map<String, dynamic> obj, String basePath) {
        obj.forEach((key, value) {
          final currentPath = basePath.isEmpty ? key : '$basePath.$key';
          
          if (value is Map<String, dynamic>) {
            // If this is an object, recursively inspect its properties
            inspectObjectPaths(value, currentPath);
          } else if (key == 'symbol' || key == 'tokenSymbol' || key == 'cryptoAsset') {
            // Special check for any key that might contain token symbol
            print('🔍 Found potential token info at path "$currentPath": $value');
          }
          
          // Also check if this particular path might contain token info
          if (currentPath.endsWith('.symbol') || 
              currentPath.endsWith('.tokenSymbol') || 
              currentPath.endsWith('.cryptoAsset')) {
            print('🔍 Found potential token info at path "$currentPath": $value');
          }
        });
      }
      
      // Try to find token symbol in all possible paths
      print('🔍 Checking for token symbol in dispute data...');
      for (final path in possibleTokenPaths) {
        final parts = path.split('.');
        dynamic value = dispute;
        
        bool pathExists = true;
        for (final part in parts) {
          if (value is Map && value.containsKey(part)) {
            value = value[part];
          } else {
            pathExists = false;
            break;
          }
        }
        
        if (pathExists && value != null) {
          print('✅ Found token symbol at path "$path": $value');
        }
      }
      
      // Inspect the entire object structure for symbol-related fields
      if (dispute is Map<String, dynamic>) {
        print('🔍 Inspecting complete dispute object structure:');
        inspectObjectPaths(dispute, '');
      }
      
      setState(() {
        _disputeData = dispute;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dispute details');
      setState(() {
        _errorMessage = 'Failed to load dispute details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Dispute Details',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red[300],
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchDisputeDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDisputeDetails,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(isDark),
                const SizedBox(height: 16),
                _buildOrderDetailsCard(isDark),
                const SizedBox(height: 16),
                _buildDisputeTimeline(isDark),
              ],
            ),
          ),
      floatingActionButton: _disputeData != null 
        ? FloatingActionButton(
            onPressed: () => _openDisputeChat(), 
            backgroundColor: SafeJetColors.primary,
            child: const Icon(Icons.chat, color: Colors.white),
          )
        : null,
    );
  }

  void _openDisputeChat() {
    if (_disputeData == null) return;
    
    final dispute = _disputeData!;
    final disputeId = dispute['id'] ?? '';
    
    if (disputeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open chat: Dispute ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get order tracking ID or any other details
    final status = dispute['status'] ?? 'PENDING';
    final order = dispute['order'] ?? {};
    final trackingId = order['trackingId'] ?? widget.orderId;
    
    // Generate dispute title from reason or order ID
    String disputeTitle = 'Dispute Chat';
    if (dispute['reasonType'] != null) {
      final reasonType = dispute['reasonType'].toString()
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
      disputeTitle = reasonType;
    } else {
      disputeTitle = "Dispute #${trackingId.substring(0, 8)}";
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => P2PDisputeChatScreen(
          disputeId: disputeId,
          orderId: trackingId,
          disputeTitle: disputeTitle,
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final dispute = _disputeData!;
    final status = dispute['status'] ?? 'PENDING';
    
    // Get reason type from different possible API formats
    String reasonType = 'Not specified';
    if (dispute['reasonType'] != null) {
      reasonType = dispute['reasonType'];
    } else if (dispute['reason_type'] != null) {
      reasonType = dispute['reason_type'];
    } else if (dispute['metadata'] != null && dispute['metadata']['reasonType'] != null) {
      reasonType = dispute['metadata']['reasonType'];
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${widget.orderId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatOrderStatus(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dispute Reason',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatReasonType(reasonType),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReasonType(String reasonType) {
    // Convert from backend enum format (e.g., PAYMENT_NOT_RECEIVED) to readable format
    return reasonType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.red;
      case 'PENDING':
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return SafeJetColors.warning;
      default:
        return SafeJetColors.warning;
    }
  }

  Widget _buildOrderDetailsCard(bool isDark) {
    final dispute = _disputeData!;
    
    // Get order from different possible API response formats
    Map<String, dynamic> order = {};
    if (dispute['order'] != null) {
      order = dispute['order'];
    } else if (dispute['orderData'] != null) {
      order = dispute['orderData'];
    }
    
    // Extract order details with fallbacks
    final amount = order['assetAmount'] ?? order['amount'] ?? dispute['assetAmount'] ?? '0';
    final price = order['price']?.toString() ?? dispute['price']?.toString() ?? '0';
    final total = order['currencyAmount'] ?? order['total'] ?? dispute['currencyAmount'] ?? '0';
    final createdAtStr = order['createdAt'] ?? dispute['createdAt'] ?? '';
    
    // Get crypto asset from different possible API response formats with more checks
    String cryptoAsset = '';
    
    // Check for direct token symbol first
    if (order['cryptoAsset'] != null) {
      cryptoAsset = order['cryptoAsset'];
    } else if (dispute['cryptoAsset'] != null) {
      cryptoAsset = dispute['cryptoAsset'];
    }
    // Check nested token objects
    else if (order['offer']?['token']?['symbol'] != null) {
      cryptoAsset = order['offer']['token']['symbol'];
    } else if (dispute['offer']?['token']?['symbol'] != null) {
      cryptoAsset = dispute['offer']['token']['symbol'];
    } else if (order['token']?['symbol'] != null) {
      cryptoAsset = order['token']['symbol'];
    } else if (dispute['token']?['symbol'] != null) {
      cryptoAsset = dispute['token']['symbol'];
    }
    // Check direct symbol property
    else if (order['tokenSymbol'] != null) {
      cryptoAsset = order['tokenSymbol'];
    } else if (dispute['tokenSymbol'] != null) {
      cryptoAsset = dispute['tokenSymbol'];
    } else if (order['symbol'] != null) {
      cryptoAsset = order['symbol'];
    } else if (dispute['symbol'] != null) {
      cryptoAsset = dispute['symbol'];
    }
    
    // Only fallback to USDT if nothing was found
    if (cryptoAsset.isEmpty) {
      cryptoAsset = 'USDT';
      print('Warning: Using fallback crypto asset symbol USDT');
    }
    
    // Get fiat currency from different possible API response formats with more checks
    String fiatCurrency = '';
    
    if (order['fiatCurrency'] != null) {
      fiatCurrency = order['fiatCurrency'];
    } else if (dispute['fiatCurrency'] != null) {
      fiatCurrency = dispute['fiatCurrency'];
    } else if (order['currency'] != null) {
      fiatCurrency = order['currency'];
    } else if (dispute['currency'] != null) {
      fiatCurrency = dispute['currency'];
    } else if (order['offer']?['currency'] != null) {
      fiatCurrency = order['offer']['currency'];
    } else if (dispute['offer']?['currency'] != null) {
      fiatCurrency = dispute['offer']['currency'];
    }
    
    // Only fallback to NGN if nothing was found
    if (fiatCurrency.isEmpty) {
      fiatCurrency = 'NGN';
      print('Warning: Using fallback fiat currency NGN');
    }
    
    final buyerStatus = order['buyerStatus'] ?? dispute['buyerStatus'] ?? 'unknown';
    final sellerStatus = order['sellerStatus'] ?? dispute['sellerStatus'] ?? 'unknown';
    
    // Format the created date
    final createdAt = _formatDate(createdAtStr);
    
    // Format asset amount (crypto) - up to 8 decimal places, no trailing zeros
    final formattedAssetAmount = _formatCryptoAmount(amount);
    
    // Format price - with thousand separators
    final formattedPrice = _formatFiatAmount(price);
    
    // Format total amount - with thousand separators
    final formattedTotal = _formatFiatAmount(total);
    
    // Get buyer and seller details
    final buyer = order['buyer'] ?? dispute['buyer'] ?? {};
    final seller = order['seller'] ?? dispute['seller'] ?? {};
    
    // Get buyer and seller names
    final buyerName = buyer['fullName'] ?? buyer['username'] ?? 'Unknown Buyer';
    final sellerName = seller['fullName'] ?? seller['username'] ?? 'Unknown Seller';
    
    // Determine if current user is buyer or seller by checking the dispute initiator
    final initiatorId = dispute['initiatorId'] ?? '';
    final respondentId = dispute['respondentId'] ?? '';
    final buyerId = buyer['id'] ?? '';
    final sellerId = seller['id'] ?? '';
    
    // Extract current user ID from secure storage
    Future<String> getCurrentUserId() async {
      if (_p2pService == null) {
        _p2pService = P2PService();
      }
      
      try {
        final userId = await _p2pService!.extractUserIdFromToken();
        print('Current user ID from token: $userId');
        return userId ?? '';
      } catch (e) {
        print('Error getting user ID');
        return '';
      }
    }
    
    // Async method to determine and update counterparty
    Future<void> updateCounterparty() async {
      final currentUserId = await getCurrentUserId();
      
      String newCounterparty = 'Unknown';
      
      if (currentUserId.isNotEmpty) {
        if (currentUserId == buyerId) {
          // Current user is buyer, counterparty is seller
          newCounterparty = sellerName;
          print('User is buyer, counterparty is seller: $sellerName');
        } else if (currentUserId == sellerId) {
          // Current user is seller, counterparty is buyer
          newCounterparty = buyerName;
          print('User is seller, counterparty is buyer: $buyerName');
        } else {
          // If we can't match the user, provide a fallback
          newCounterparty = initiatorId == buyerId ? sellerName : buyerName;
          print('Could not match user ID, showing counterparty as: $newCounterparty');
        }
        
        // Update the UI if counterparty changed
        if (mounted) {
          setState(() {
            _counterparty = newCounterparty;
          });
        }
      }
    }
    
    // Start the async operation to update counterparty
    if (_counterparty == null) {
      // Set initial value
      _counterparty = 'Loading...';
      // Update it asynchronously
      updateCounterparty();
    }
    
    // Use the _counterparty field or fallback
    final counterparty = _counterparty ?? 'Unknown';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Amount:', '$formattedAssetAmount $cryptoAsset', isDark),
          _buildDetailRow('Price:', '${_formatCurrency(fiatCurrency)}$formattedPrice/$cryptoAsset', isDark),
          _buildDetailRow('Total:', '${_formatCurrency(fiatCurrency)}$formattedTotal', isDark),
          _buildDetailRow('Created:', createdAt, isDark),
          _buildDetailRow('Counterparty:', counterparty, isDark),
          _buildDetailRow(
            'Buyer Status:',
            _formatOrderStatus(buyerStatus),
            isDark,
            valueColor: _getOrderStatusColor(buyerStatus),
          ),
          _buildDetailRow(
            'Seller Status:',
            _formatOrderStatus(sellerStatus),
            isDark,
            valueColor: _getOrderStatusColor(sellerStatus),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  String _formatOrderStatus(String status) {
    return status.replaceAll('_', ' ').split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return SafeJetColors.warning;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeTimeline(bool isDark) {
    final dispute = _disputeData!;
    final progressHistory = dispute['progressHistory'] as List<dynamic>? ?? [];
    final status = dispute['status']?.toString()?.toUpperCase() ?? '';
    final isResolved = status == 'RESOLVED' || status == 'COMPLETED';
    final isRejected = status == 'REJECTED' || status == 'FAILED';
    final isCompleted = isResolved || isRejected;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dispute Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (progressHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No progress updates yet'),
              ),
            )
          else
            ...List.generate(progressHistory.length, (index) {
              final progress = progressHistory[index] as Map<String, dynamic>;
              final title = progress['title'] ?? 'Unknown Step';
              final timestamp = progress['timestamp'] ?? '';
              final details = progress['details'] ?? '';
              final formattedTime = _formatDate(timestamp);
              
              // Calculate states for timeline display
              final isLast = index == progressHistory.length - 1;
              final itemCompleted = index < progressHistory.length - 1 || isCompleted;
              final itemInProgress = isLast && !isCompleted;
              
              return _buildTimelineItem(
                title,
                formattedTime,
                details,
            isDark,
                isFirst: index == 0,
                isLast: isLast,
                isCompleted: itemCompleted,
                isInProgress: itemInProgress,
                statusColor: isResolved ? Colors.green : (isRejected ? Colors.red : SafeJetColors.warning),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    String description,
    bool isDark, {
    bool isFirst = false,
    bool isLast = false,
    bool isCompleted = false,
    bool isInProgress = false,
    Color statusColor = SafeJetColors.warning,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted || isInProgress
                    ? statusColor
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                shape: BoxShape.circle,
                border: isInProgress
                    ? Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 4,
                      )
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? statusColor
                    : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isInProgress ? statusColor : null,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : SafeJetColors.lightText,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to format crypto amounts (up to 8 decimal places, no trailing zeros)
  String _formatCryptoAmount(dynamic amount) {
    if (amount == null) return '0';
    
    // Convert to double
    double value;
    try {
      value = amount is String ? double.parse(amount) : amount.toDouble();
    } catch (e) {
      return amount.toString();
    }
    
    if (value == 0) return '0';
    
    // Format with up to 8 decimal places
    String formatted = value.toStringAsFixed(8);
    
    // Remove trailing zeros
    while (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    
    // Remove decimal point if it's the last character
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    
    return formatted;
  }

  // Helper method to format fiat amounts (with thousand separators, 2 decimal places)
  String _formatFiatAmount(dynamic amount) {
    if (amount == null) return '0';
    
    // Convert to double
    double value;
    try {
      value = amount is String ? double.parse(amount) : amount.toDouble();
    } catch (e) {
      return amount.toString();
    }
    
    // Use a simple formatting approach for thousands separator
    final parts = value.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    
    final formattedWhole = wholePart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    
    return '$formattedWhole.$decimalPart';
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      // Format: Jun 12, 2023 12:30
      final month = _getShortMonthName(date.month);
      final formattedHour = date.hour.toString().padLeft(2, '0');
      final formattedMinute = date.minute.toString().padLeft(2, '0');
      
      return '$month ${date.day}, ${date.year} $formattedHour:$formattedMinute';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _getShortMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
} 