import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import 'p2p_order_confirmation_screen.dart';
import 'p2p_dispute_history_screen.dart';
import 'p2p_chat_screen.dart';
import 'package:get_it/get_it.dart';
import '../../services/p2p_service.dart';
import 'package:intl/intl.dart';

class P2POrderHistoryScreen extends StatefulWidget {
  const P2POrderHistoryScreen({super.key});

  @override
  State<P2POrderHistoryScreen> createState() => _P2POrderHistoryScreenState();
}

class _P2POrderHistoryScreenState extends State<P2POrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _p2pService = GetIt.I<P2PService>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Completed',
    'Cancelled',
    'Disputed'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _orders = [];
        _currentPage = 1;
        _hasMoreData = true;
      });
      _loadOrders();
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _orders = [];
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    if (_isLoading || (!_hasMoreData && !refresh)) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      print('Searching with text: ${_searchController.text}'); // Debug log

      final result = await _p2pService.getOrders(
        isBuy: _tabController.index == 0,
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        searchQuery: _searchController.text.trim(),
        page: _currentPage,
      );

      // print('Search result: $result'); // Debug log

      setState(() {
        if (refresh || _currentPage == 1) {
          _orders = List<Map<String, dynamic>>.from(result['orders']);
        } else {
          _orders.addAll(List<Map<String, dynamic>>.from(result['orders']));
        }

        _totalPages = result['pagination']['totalPages'];
        _hasMoreData = _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders'); // Debug log
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load orders. Please try again.';
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      await _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: P2PAppBar(
        title: 'Order History',
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const P2PDisputeHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.gavel_rounded),
          tooltip: 'Dispute History',
        ),
      ),
      body: Column(
        children: [
          // Buy/Sell Tabs
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: SafeJetColors.secondaryHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: isDark ? Colors.white : Colors.black,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('BUY'),
                    ),
                  ),
                  Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('SELL'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: Padding(
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
                    _orders = [];
                  });
                  _loadOrders(refresh: true);
                },
              ),
            ),
          ),

          // Status Filters
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: _buildStatusFilters(isDark),
          ),

          // Orders List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(isDark, isBuy: true),
                _buildOrdersList(isDark, isBuy: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                    _currentPage = 1; // Reset to first page
                    _orders = []; // Clear current orders
                  });
                  _loadOrders(refresh: true); // Reload with new status
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SafeJetColors.secondaryHighlight
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildOrdersList(bool isDark, {required bool isBuy}) {
    // Filter orders based on the current tab
    final filteredOrders = _orders
        .where((order) =>
            (isBuy && order['type'] == 'BUY') ||
            (!isBuy && order['type'] == 'SELL'))
        .toList();

    if (_isLoading && filteredOrders.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: SafeJetColors.secondaryHighlight,
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: SafeJetColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadOrders(refresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredOrders.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: SafeJetColors.secondaryHighlight,
              ),
            ),
          );
        }

        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 100),
          child: _buildOrderCard(filteredOrders[index], isDark),
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    // Format the date
    final orderDate = DateTime.parse(order['date']);
    final now = DateTime.now();
    final difference = now.difference(orderDate);

    // Format numbers
    final numberFormat = NumberFormat("#,##0.00", "en_US");
    final cryptoFormat = NumberFormat("#,##0.########", "en_US");

    // Format amount and price
    final formattedAmount =
        cryptoFormat.format(double.parse(order['amount'].toString()));
    final formattedPrice =
        numberFormat.format(double.parse(order['price']?.toString() ?? '0'));
    final currency = order['currency'] ?? 'NGN'; // Get currency from order data

    // Format date
    String formattedDate;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        formattedDate = '${difference.inMinutes}m ago';
      } else {
        formattedDate = '${difference.inHours}h ago';
      }
    } else if (difference.inDays < 7) {
      formattedDate = '${difference.inDays}d ago';
    } else {
      formattedDate = DateFormat('MMM d, y').format(orderDate);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => P2POrderConfirmationScreen(
                trackingId: order['id'],
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: order['type'] == 'BUY'
                                ? SafeJetColors.success.withOpacity(0.1)
                                : SafeJetColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order['type'],
                            style: TextStyle(
                              color: order['type'] == 'BUY'
                                  ? SafeJetColors.success
                                  : SafeJetColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${order['id']}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusTag(
                        order['buyerStatus'] ?? order['status'] ?? 'pending',
                        isDark,
                        order),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'Amount',
                      '$formattedAmount ${order['crypto']}',
                      isDark,
                    ),
                    _buildInfoColumn(
                      'Price',
                      '$currency$formattedPrice/${order['crypto']}',
                      isDark,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Counterparty',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['counterparty'] ?? 'Unknown',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (order['status'] == 'Pending')
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _openChat(order),
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('Chat'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white : Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _cancelOrder(order),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: SafeJetColors.error,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    bool isDark, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(
      String? status, bool isDark, Map<String, dynamic> order) {
    Color color;
    String displayStatus = order['type'] == 'SELL'
        ? (order['buyerStatus']?.toLowerCase() ?? 'pending')
        : (status?.toLowerCase() ?? 'pending');

    // If this is a sell order and status is 'paid', show as 'Awaiting Release'
    if (order['type'] == 'SELL' && displayStatus == 'paid') {
      displayStatus = 'Awaiting Release';
    }

    switch (displayStatus.toLowerCase()) {
      case 'pending':
        color = SafeJetColors.warning;
        break;
      case 'awaiting release':
        color = SafeJetColors.warning;
        break;
      case 'paid':
        color = order['type'] == 'SELL'
            ? SafeJetColors.warning
            : SafeJetColors.success;
        break;
      case 'completed':
        color = SafeJetColors.success;
        break;
      case 'cancelled':
        color = isDark ? Colors.grey : Colors.grey[600]!;
        break;
      case 'disputed':
        color = SafeJetColors.error;
        break;
      default:
        color = SafeJetColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayStatus.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _cancelOrder(Map<String, dynamic> order) {
    // Implement cancel order
  }

  void _openChat(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => P2PChatScreen(
          orderId: order['id'],
          trackingId: order['trackingId'],
          isBuyer: order['isBuyer'],
          userName: order['counterparty'],
        ),
      ),
    );
  }
}
