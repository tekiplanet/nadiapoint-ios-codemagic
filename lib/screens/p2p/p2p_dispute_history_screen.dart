import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/theme/colors.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../services/p2p_service.dart';
import '../../widgets/loading_indicator.dart';
import 'p2p_dispute_details_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class P2PDisputeHistoryScreen extends StatefulWidget {
  const P2PDisputeHistoryScreen({super.key});

  @override
  State<P2PDisputeHistoryScreen> createState() => _P2PDisputeHistoryScreenState();
}

class _P2PDisputeHistoryScreenState extends State<P2PDisputeHistoryScreen> {
  final P2PService _p2pService = GetIt.I<P2PService>();
  List<Map<String, dynamic>> _disputes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _currentUserId;
  
  // Pagination and search state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  
  // Status filter options
  final List<String> _statusFilters = ['All', 'Pending', 'In_Progress', 'Resolved_Buyer', 'Resolved_Seller', 'Closed'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _init();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _handleScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreDisputes();
    }
  }
  
  Future<void> _loadMoreDisputes() async {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      await _loadDisputes(refresh: false);
    }
  }

  Future<void> _init() async {
    try {
      // Get current user ID first to help with determining counterparty
      _currentUserId = await _p2pService.extractUserIdFromToken();
      print('Current user ID: $_currentUserId');
    } catch (e) {
      print('Error getting user ID');
    }
    
    _loadDisputes();
  }

  Future<void> _loadDisputes({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        if (_currentPage == 1) {
          _disputes = [];
        }
        _hasMoreData = true;
      });
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print('Searching disputes with text: ${_searchController.text}');
      print('Status filter: $_selectedStatus');
      
      final disputes = await _p2pService.getUserDisputes(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        searchQuery: _searchController.text.trim(),
        page: _currentPage,
      );
      
      // In a real implementation, the backend would return pagination info
      // For now, we'll simulate it by assuming 10 items per page
      setState(() {
        if (refresh && _currentPage == 1) {
          _disputes = disputes;
        } else {
          _disputes.addAll(disputes);
        }
        
        // Assume we don't have more data if we received fewer items than requested
        _hasMoreData = disputes.length >= 10;
        _isLoading = false;
      });
      
      print('Loaded ${disputes.length} disputes');
      
      // More detailed logging for debugging
      if (disputes.isNotEmpty) {
        print('\n=== DETAILED DISPUTE DATA DEBUG ===');
        for (int i = 0; i < disputes.length; i++) {
          final dispute = disputes[i];
          final order = dispute['order'] ?? {};
          
          print('\nDISPUTE #${i+1}:');
          print('Dispute ID: ${dispute['id']}');
          print('Order ID: ${order['id']}');
          print('Tracking ID: ${order['trackingId']}');
          
          print('\nUSER INFO:');
          print('Current user ID: $_currentUserId');
          
          print('\nBUYER INFO:');
          final buyer = order['buyer'] ?? {};
          print('Buyer ID: ${buyer['id']}');
          print('Buyer username: ${buyer['username']}');
          print('Buyer fullName: ${buyer['fullName']}');
          
          print('\nSELLER INFO:');
          final seller = order['seller'] ?? {};
          print('Seller ID: ${seller['id']}');
          print('Seller username: ${seller['username']}');
          print('Seller fullName: ${seller['fullName']}');
          
          print('\nAMOUNT INFO:');
          print('assetAmount: ${order['assetAmount']}');
          print('amount: ${order['amount']}');
          print('dispute assetAmount: ${dispute['assetAmount']}');
          print('dispute amount: ${dispute['amount']}');
          
          print('\nTOKEN INFO:');
          print('order.cryptoAsset: ${order['cryptoAsset']}');
          print('dispute.cryptoAsset: ${dispute['cryptoAsset']}');
          print('order.offer?.token?.symbol: ${order['offer']?['token']?['symbol']}');
          print('dispute.offer?.token?.symbol: ${dispute['offer']?['token']?['symbol']}');
          print('order.token?.symbol: ${order['token']?['symbol']}');
          print('dispute.token?.symbol: ${dispute['token']?['symbol']}');
          print('order.tokenSymbol: ${order['tokenSymbol']}');
          print('dispute.tokenSymbol: ${dispute['tokenSymbol']}');
          print('order.symbol: ${order['symbol']}');
          print('dispute.symbol: ${dispute['symbol']}');
          
          // Check the entire offer object structure
          if (order['offer'] != null) {
            print('\nOFFER OBJECT:');
            _printObjectFlat(order['offer'], 'order.offer');
          }
          
          print('\n-----------------------------------');
        }
      }
    } catch (e) {
      print('Error loading disputes');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load disputes: $e';
      });
    }
  }
  
  // Helper method to print an object as flat key-value pairs
  void _printObjectFlat(dynamic obj, String prefix) {
    if (obj is Map) {
      obj.forEach((key, value) {
        final currentPath = '$prefix.$key';
        if (value is Map || value is List) {
          if (value is Map && value.isEmpty) {
            print('$currentPath: {}');
          } else if (value is List && value.isEmpty) {
            print('$currentPath: []');
          } else {
            _printObjectFlat(value, currentPath);
          }
        } else {
          print('$currentPath: $value');
        }
      });
    } else if (obj is List) {
      for (int i = 0; i < obj.length; i++) {
        _printObjectFlat(obj[i], '$prefix[$i]');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Dispute History',
        hasNotification: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Counterparty',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _currentPage = 1;
                });
                _loadDisputes(refresh: true);
              },
            ),
          ),

          // Status Filters
          _buildStatusFilters(isDark),

          // Disputes List or loading/error states
          Expanded(
            child: _isLoading && _disputes.isEmpty
                ? const Center(child: LoadingIndicator())
                : _hasError
                    ? _buildErrorView()
                    : _disputes.isEmpty
                        ? _buildEmptyView(isDark)
                        : RefreshIndicator(
                            onRefresh: () {
                              setState(() {
                                _currentPage = 1;
                              });
                              return _loadDisputes(refresh: true);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _disputes.length + (_hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _disputes.length) {
                                  return _isLoading
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: CircularProgressIndicator(
                                              color: SafeJetColors.secondaryHighlight,
                                            ),
                                          ),
                                        )
                                      : const SizedBox();
                                }
                                
                                final dispute = _disputes[index];
                                final order = dispute['order'] ?? {};
                                final buyer = order['buyer'] ?? {};
                                final seller = order['seller'] ?? {};
                                
                                // Extract amount and crypto asset with extensive fallbacks
                                dynamic amount = null;
                                // Try multiple possible paths for amount
                                if (order['assetAmount'] != null) amount = order['assetAmount'];
                                else if (order['amount'] != null) amount = order['amount'];
                                else if (dispute['assetAmount'] != null) amount = dispute['assetAmount'];
                                else if (dispute['amount'] != null) amount = dispute['amount'];
                                
                                // Extract token symbol using the helper method
                                final cryptoAsset = _extractTokenSymbol(order, dispute);
                                
                                // Format the amount 
                                final formattedAmount = _formatCryptoAmount(amount);
                                
                                // Now try to determine counterparty name
                                print('\nDetermining counterparty for dispute ${dispute['id']}');
                                print('Current user ID: $_currentUserId');
                                print('Buyer ID: ${buyer['id']}');
                                print('Seller ID: ${seller['id']}');
                                
                                // Get counsterparty name with improved logic
                                String counterpartyName = '';
                                
                                // Check if we're the buyer
                                if (_currentUserId == buyer['id']) {
                                  print('User is buyer, counterparty is seller');
                                  // Get seller name with detailed fallbacks
                                  if (seller['username'] != null && seller['username'].toString().isNotEmpty) {
                                    counterpartyName = seller['username'].toString();
                                    print('Using seller username: $counterpartyName');
                                  } else if (seller['fullName'] != null && seller['fullName'].toString().isNotEmpty) {
                                    counterpartyName = seller['fullName'].toString();
                                    print('Using seller fullName: $counterpartyName');
                                  } else if (seller['name'] != null && seller['name'].toString().isNotEmpty) {
                                    counterpartyName = seller['name'].toString();
                                    print('Using seller name: $counterpartyName');
                                  } else {
                                    counterpartyName = 'Seller';
                                    print('No seller name found, using default: $counterpartyName');
                                  }
                                } 
                                // Check if we're the seller
                                else if (_currentUserId == seller['id']) {
                                  print('User is seller, counterparty is buyer');
                                  // Get buyer name with detailed fallbacks
                                  if (buyer['username'] != null && buyer['username'].toString().isNotEmpty) {
                                    counterpartyName = buyer['username'].toString();
                                    print('Using buyer username: $counterpartyName');
                                  } else if (buyer['fullName'] != null && buyer['fullName'].toString().isNotEmpty) {
                                    counterpartyName = buyer['fullName'].toString();
                                    print('Using buyer fullName: $counterpartyName');
                                  } else if (buyer['name'] != null && buyer['name'].toString().isNotEmpty) {
                                    counterpartyName = buyer['name'].toString();
                                    print('Using buyer name: $counterpartyName');
                                  } else {
                                    counterpartyName = 'Buyer';
                                    print('No buyer name found, using default: $counterpartyName');
                                  }
                                } 
                                // If we can't determine our role
                                else {
                                  print('Cannot determine user role, using seller data');
                                  // Default to seller info since that's more common
                                  if (seller['username'] != null && seller['username'].toString().isNotEmpty) {
                                    counterpartyName = seller['username'].toString();
                                    print('Using seller username as fallback: $counterpartyName');
                                  } else if (seller['fullName'] != null && seller['fullName'].toString().isNotEmpty) {
                                    counterpartyName = seller['fullName'].toString();
                                    print('Using seller fullName as fallback: $counterpartyName');
                                  } else {
                                    counterpartyName = 'Unknown';
                                    print('No counterparty name found, using default: $counterpartyName');
                                  }
                                }

                                // Process dates and order ID
                                final createdAt = dispute['createdAt'] ?? order['createdAt'] ?? '';
                                final formattedDate = _formatDateWithAmPm(createdAt);
                                
                                final orderId = order['trackingId'] ?? dispute['id'] ?? 'Unknown';
                                
                                // Get the dispute status
                                final status = dispute['status'] ?? 'Pending';
                                final formattedStatus = _formatStatus(status);
                                
                                print('Final asset symbol: $cryptoAsset');
                                print('Final counterparty name: $counterpartyName');

                                return _buildDisputeCard(
                                  context,
                                  isDark,
                                  orderId: orderId,
                                  status: formattedStatus,
                                  date: formattedDate,
                                  amount: "$formattedAmount $cryptoAsset",
                                  counterparty: counterpartyName,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  
  // Status filter widget
  Widget _buildStatusFilters(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final isSelected = status == _selectedStatus;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                    _currentPage = 1;  // Reset to first page
                    _disputes = [];    // Clear current disputes
                  });
                  _loadDisputes(refresh: true);  // Reload with new status
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? SafeJetColors.secondaryHighlight 
                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _formatFilterLabel(status),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.black 
                          : (isDark ? Colors.white : Colors.black),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper to format filter labels for display
  String _formatFilterLabel(String status) {
    // Convert from filter value to user-friendly display
    switch (status.toUpperCase()) {
      case 'ALL':
        return 'All';
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED_BUYER':
        return 'Resolved (Buyer)';
      case 'RESOLVED_SELLER':
        return 'Resolved (Seller)';
      case 'CLOSED':
        return 'Closed';
      default:
        return status.replaceAll('_', ' ');
    }
  }
  
  // Helper method to format crypto amounts with 8 decimal places max, no trailing zeros
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
  
  String _formatDateWithAmPm(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown date';
    
    try {
      final date = DateTime.parse(dateString);
      
      // Use DateFormat from intl package for AM/PM format
      final formatter = DateFormat('MMM d, yyyy h:mm a');
      return formatter.format(date);
    } catch (e) {
      print('Error formatting date');
      return dateString;
    }
  }
  
  String _formatStatus(String status) {
    // Convert from backend status to user-friendly status
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED_BUYER':
        return 'Resolved (Buyer)';
      case 'RESOLVED_SELLER':
        return 'Resolved (Seller)';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      return _p2pService.formatDate(dateString);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildEmptyView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No disputes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you have disputes, they will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadDisputes,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load disputes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDisputes,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(
    BuildContext context,
    bool isDark, {
    required String orderId,
    required String status,
    required String date,
    required String amount,
    required String counterparty,
  }) {
    final isResolved = status.toLowerCase().contains('resolved') || status.toLowerCase() == 'closed';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => P2PDisputeDetailsScreen(
                  orderId: orderId,
                ),
              ),
            ).then((_) => _loadDisputes()); // Refresh after returning
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$orderId',
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
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Counterparty',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          counterparty,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Opened on $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('resolved') || statusLower == 'closed') {
      return SafeJetColors.success;
    } else if (statusLower == 'in progress') {
      return SafeJetColors.blue;
    } else if (statusLower == 'pending') {
      return SafeJetColors.warning;
    } else {
      return SafeJetColors.warning;
    }
  }

  // Helper method to extract token symbol from all possible sources
  String _extractTokenSymbol(Map<String, dynamic> order, Map<String, dynamic> dispute) {
    String cryptoAsset = '';
    
    // First check for token from offer.token relation (highest priority)
    if (order['offer']?['token'] != null) {
      final token = order['offer']['token'];
      
      // Print token object for debugging
      print('Full token object in offer.token:');
      _printObjectFlat(token, 'token');
      
      if (token is Map<String, dynamic>) {
        if (token['symbol'] != null) {
          cryptoAsset = token['symbol'].toString();
          print('Found symbol in order.offer.token.symbol: $cryptoAsset');
          return cryptoAsset;
        } else if (token['name'] != null) {
          cryptoAsset = token['name'].toString();
          print('Found symbol in order.offer.token.name: $cryptoAsset');
          return cryptoAsset;
        }
      }
    }
    
    // Check for direct token symbol properties
    if (order['cryptoAsset'] != null) {
      cryptoAsset = order['cryptoAsset'].toString();
      print('Found symbol in order.cryptoAsset: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (dispute['cryptoAsset'] != null) {
      cryptoAsset = dispute['cryptoAsset'].toString();
      print('Found symbol in dispute.cryptoAsset: $cryptoAsset');
      return cryptoAsset;
    }
    
    // Nested in token objects
    if (dispute['offer']?['token']?['symbol'] != null) {
      cryptoAsset = dispute['offer']['token']['symbol'].toString();
      print('Found symbol in dispute.offer.token.symbol: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (order['token']?['symbol'] != null) {
      cryptoAsset = order['token']['symbol'].toString();
      print('Found symbol in order.token.symbol: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (dispute['token']?['symbol'] != null) {
      cryptoAsset = dispute['token']['symbol'].toString();
      print('Found symbol in dispute.token.symbol: $cryptoAsset');
      return cryptoAsset;
    }
    
    // Direct symbol properties
    if (order['tokenSymbol'] != null) {
      cryptoAsset = order['tokenSymbol'].toString();
      print('Found symbol in order.tokenSymbol: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (dispute['tokenSymbol'] != null) {
      cryptoAsset = dispute['tokenSymbol'].toString();
      print('Found symbol in dispute.tokenSymbol: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (order['symbol'] != null) {
      cryptoAsset = order['symbol'].toString();
      print('Found symbol in order.symbol: $cryptoAsset');
      return cryptoAsset;
    } 
    
    if (dispute['symbol'] != null) {
      cryptoAsset = dispute['symbol'].toString();
      print('Found symbol in dispute.symbol: $cryptoAsset');
      return cryptoAsset;
    }
    
    // Try to extract from the offer.tokenId
    if (order['offer']?['tokenId'] != null) {
      final tokenId = order['offer']['tokenId'].toString();
      print('Found tokenId in offer: $tokenId');
      
      // Check if this is a known token ID
      if (tokenId == '0b3c5559-e321-4304-9ceb-71552cb6ee03') {
        print('Recognized known tokenId for BTC');
        return 'BTC';
      } else if (tokenId == 'e661358e-1fa5-4248-9bf8-50cf7e65bf3f') {
        print('Recognized known tokenId for USDT');
        return 'USDT';
      }
    }
    
    if (cryptoAsset.isEmpty && order['offer'] != null) {
      // Check for tokenPair in the offer
      if (order['offer']['tokenPair'] != null) {
        final tokenPair = order['offer']['tokenPair'].toString();
        print('Found tokenPair: $tokenPair');
        
        // Usually token pairs are in format BASE/QUOTE (e.g. BTC/USDT)
        if (tokenPair.contains('/')) {
          final parts = tokenPair.split('/');
          cryptoAsset = parts[0].trim();
          print('Extracted symbol from tokenPair: $cryptoAsset');
          return cryptoAsset;
        }
      }
    }
    
    // Default to USDT if nothing found
    print('No token symbol found in any property, defaulting to USDT');
    return 'USDT';
  }
} 