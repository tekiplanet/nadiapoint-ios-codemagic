import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import '../../models/fiat_transaction.dart';
import '../../services/fiat_transaction_service.dart';
import 'fiat_transaction_details_screen.dart';

class FiatTransactionHistoryScreen extends StatefulWidget {
  const FiatTransactionHistoryScreen({super.key});

  @override
  State<FiatTransactionHistoryScreen> createState() =>
      _FiatTransactionHistoryScreenState();
}

class _FiatTransactionHistoryScreenState
    extends State<FiatTransactionHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Deposit', 'Withdraw', 'Purchase'];

  // Data for each tab
  List<FiatTransaction> _deposits = [];
  List<FiatTransaction> _withdrawals = [];
  List<FiatTransaction> _purchases = [];

  int _depositPage = 1;
  int _withdrawalPage = 1;
  int _purchasePage = 1;
  bool _depositHasMore = true;
  bool _withdrawalHasMore = true;
  bool _purchaseHasMore = true;
  bool _isLoadingMore = false;
  bool _isLoading = true;
  String? _error;

  final int _pageLimit = 20;
  final ScrollController _scrollController = ScrollController();
  late FiatTransactionService _service;

  @override
  void initState() {
    super.initState();
    _service = FiatTransactionService();
    _fetchInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchDepositsPage(page: 1, limit: _pageLimit),
        _service.fetchWithdrawalsPage(page: 1, limit: _pageLimit),
        _service.fetchPurchasesPage(page: 1, limit: _pageLimit),
      ]);
      setState(() {
        _deposits = results[0].$1;
        _depositHasMore = results[0].$2;
        _depositPage = 1;
        _withdrawals = results[1].$1;
        _withdrawalHasMore = results[1].$2;
        _withdrawalPage = 1;
        _purchases = results[2].$1;
        _purchaseHasMore = results[2].$2;
        _purchasePage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });
    try {
      if (_selectedFilter == 'All') {
        // Load next page for all types
        final futures = <Future>[];
        if (_depositHasMore)
          futures.add(_service.fetchDepositsPage(
              page: _depositPage + 1, limit: _pageLimit));
        if (_withdrawalHasMore)
          futures.add(_service.fetchWithdrawalsPage(
              page: _withdrawalPage + 1, limit: _pageLimit));
        if (_purchaseHasMore)
          futures.add(_service.fetchPurchasesPage(
              page: _purchasePage + 1, limit: _pageLimit));
        final results = await Future.wait(futures);
        int i = 0;
        if (_depositHasMore) {
          final (txs, hasMore) = results[i++] as (List<FiatTransaction>, bool);
          _deposits.addAll(txs);
          _depositHasMore = hasMore;
          if (txs.isNotEmpty) _depositPage++;
        }
        if (_withdrawalHasMore) {
          final (txs, hasMore) = results[i++] as (List<FiatTransaction>, bool);
          _withdrawals.addAll(txs);
          _withdrawalHasMore = hasMore;
          if (txs.isNotEmpty) _withdrawalPage++;
        }
        if (_purchaseHasMore) {
          final (txs, hasMore) = results[i++] as (List<FiatTransaction>, bool);
          _purchases.addAll(txs);
          _purchaseHasMore = hasMore;
          if (txs.isNotEmpty) _purchasePage++;
        }
      } else if (_selectedFilter == 'Deposit' && _depositHasMore) {
        final (txs, hasMore) = await _service.fetchDepositsPage(
            page: _depositPage + 1, limit: _pageLimit);
        setState(() {
          _deposits.addAll(txs);
          _depositHasMore = hasMore;
          if (txs.isNotEmpty) _depositPage++;
        });
      } else if (_selectedFilter == 'Withdraw' && _withdrawalHasMore) {
        final (txs, hasMore) = await _service.fetchWithdrawalsPage(
            page: _withdrawalPage + 1, limit: _pageLimit);
        setState(() {
          _withdrawals.addAll(txs);
          _withdrawalHasMore = hasMore;
          if (txs.isNotEmpty) _withdrawalPage++;
        });
      } else if (_selectedFilter == 'Purchase' && _purchaseHasMore) {
        final (txs, hasMore) = await _service.fetchPurchasesPage(
            page: _purchasePage + 1, limit: _pageLimit);
        setState(() {
          _purchases.addAll(txs);
          _purchaseHasMore = hasMore;
          if (txs.isNotEmpty) _purchasePage++;
        });
      }
    } catch (e) {
      // Optionally handle error
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  List<FiatTransaction> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      final all = [..._deposits, ..._withdrawals, ..._purchases];
      all.sort((a, b) => b.date.compareTo(a.date));
      return all;
    }
    if (_selectedFilter == 'Deposit') return _deposits;
    if (_selectedFilter == 'Withdraw') return _withdrawals;
    if (_selectedFilter == 'Purchase') return _purchases;
    return [];
  }

  bool get _hasMore {
    if (_selectedFilter == 'All') {
      return _depositHasMore || _withdrawalHasMore || _purchaseHasMore;
    }
    if (_selectedFilter == 'Deposit') return _depositHasMore;
    if (_selectedFilter == 'Withdraw') return _withdrawalHasMore;
    if (_selectedFilter == 'Purchase') return _purchaseHasMore;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Fiat Transactions',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 40,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _filters[index] == _selectedFilter;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFilter = _filters[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SafeJetColors.secondaryHighlight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? SafeJetColors.secondaryHighlight
                            : (isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                                : SafeJetColors.lightCardBorder),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white : SafeJetColors.lightText),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48,
                                  color:
                                      isDark ? Colors.white24 : Colors.black26),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load transactions',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchInitial,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredTransactions.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 24, right: 24, top: 8, bottom: 24),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                color:
                                    isDark ? Colors.white10 : Colors.grey[100],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 36, horizontal: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_rounded,
                                          size: 40,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey[500]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Recent Transactions',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'You have not made any fiat transactions yet. Your recent activity will appear here.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black54),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification) {
                                _onScroll();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTransactions.length +
                                  (_isLoadingMore || _hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredTransactions.length) {
                                  return _hasMore || _isLoadingMore
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        )
                                      : const SizedBox.shrink();
                                }
                                final tx = _filteredTransactions[index];
                                Color statusColor;
                                IconData typeIcon;
                                String amountStr;
                                String currencySymbol =
                                    _getCurrencySymbol(tx.currency);
                                switch (tx.type) {
                                  case FiatTransactionType.deposit:
                                    typeIcon = Icons.add_circle_outline_rounded;
                                    statusColor = _getStatusColor(tx);
                                    amountStr =
                                        formatFiat(tx.amount, currencySymbol);
                                    break;
                                  case FiatTransactionType.withdraw:
                                    typeIcon =
                                        Icons.remove_circle_outline_rounded;
                                    statusColor = _getStatusColor(tx);
                                    amountStr =
                                        formatFiat(tx.amount, currencySymbol);
                                    break;
                                  case FiatTransactionType.purchase:
                                    typeIcon = Icons.currency_bitcoin_rounded;
                                    statusColor = _getStatusColor(tx);
                                    amountStr =
                                        formatFiat(tx.amount, currencySymbol);
                                    break;
                                }
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FiatTransactionDetailsScreen(
                                                transaction: tx),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? SafeJetColors.primaryAccent
                                              .withOpacity(0.08)
                                          : SafeJetColors.lightCardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? SafeJetColors.primaryAccent
                                                .withOpacity(0.12)
                                            : SafeJetColors.lightCardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(typeIcon,
                                              color: statusColor, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.type.name.toUpperCase(),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormat(
                                                        'MMM dd, yyyy • HH:mm')
                                                    .format(tx.date),
                                                style: TextStyle(
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                    fontSize: 11),
                                              ),
                                              if (tx.type ==
                                                      FiatTransactionType
                                                          .purchase &&
                                                  tx.cryptoAmount != null)
                                                Text(
                                                  '${formatCrypto(tx.cryptoAmount!)}${tx.cryptoSymbol != null && tx.cryptoSymbol!.isNotEmpty ? ' ${tx.cryptoSymbol}' : ''}',
                                                  style: TextStyle(
                                                      color: isDark
                                                          ? Colors.grey[300]
                                                          : Colors.grey[800],
                                                      fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              amountStr,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.18),
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Text(
                                                tx.status.toUpperCase(),
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
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

  String formatFiat(double value, String symbol) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2)
        .format(value);
  }

  String formatCrypto(double value) {
    return NumberFormat("#,##0.########").format(value);
  }

  Color _getStatusColor(FiatTransaction tx) {
    final status = tx.status.toLowerCase();
    switch (tx.type) {
      case FiatTransactionType.deposit:
        switch (status) {
          case 'pending':
            return Colors.orange;
          case 'processing':
            return Colors.blue;
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'requires_action':
            return Colors.purple;
          default:
            return Colors.grey;
        }
      case FiatTransactionType.withdraw:
        switch (status) {
          case 'pending':
            return Colors.orange;
          case 'processing':
            return Colors.blue;
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'cancelled':
            return Colors.grey;
          case 'requires_action':
            return Colors.purple;
          default:
            return Colors.grey;
        }
      case FiatTransactionType.purchase:
        switch (status) {
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'cancelled':
            return Colors.grey;
          default:
            return Colors.grey;
        }
    }
  }
}
