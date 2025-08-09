import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../config/theme/theme_provider.dart';
import '../../services/wallet_service.dart';
import '../../models/transaction.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/transaction_details_dialog.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Deposits',
    'Withdrawals',
    'Conversions',
    'Transfers',
    'Internal Transfers'
  ];
  final _walletService = WalletService();

  bool _isLoading = false;
  List<Transaction> _transactions = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreTransactions();
    }
  }

  String? _getFilterType(String filter) {
    switch (filter.toLowerCase()) {
      case 'deposits':
        return 'deposit';
      case 'withdrawals':
        return 'withdrawal';
      case 'conversions':
        return 'conversion';
      case 'transfers':
        return 'transfer';
      case 'internal transfers':
        return 'internal_transfer';
      default:
        return null;
    }
  }

  Future<void> _loadTransactions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final type = _getFilterType(_selectedFilter);
      final result = await _walletService.getTransactionHistory(
        page: 1,
        limit: _pageSize,
        type: type,
      );

      setState(() {
        _transactions = (result['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
        _currentPage = 1;
        _hasMore = _transactions.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load transactions';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final type = _getFilterType(_selectedFilter);
      final result = await _walletService.getTransactionHistory(
        page: _currentPage + 1,
        limit: _pageSize,
        type: type,
      );

      final newTransactions = (result['transactions'] as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      setState(() {
        _transactions.addAll(newTransactions);
        _currentPage++;
        _hasMore = newTransactions.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load more transactions';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          onThemeToggle: () {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.toggleTheme();
          },
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? SafeJetColors.primaryBackground
                    : SafeJetColors.lightBackground,
                isDark
                    ? SafeJetColors.primaryBackground.withOpacity(0.8)
                    : SafeJetColors.lightBackground.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Filter Tabs
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _filters[index] == _selectedFilter;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedFilter = _filters[index]);
                            _loadTransactions();
                          },
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
                                        ? SafeJetColors.primaryAccent
                                            .withOpacity(0.2)
                                        : SafeJetColors.lightCardBorder),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : (isDark
                                        ? Colors.white
                                        : SafeJetColors.lightText),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Transactions List or Loading State
                Expanded(
                  child: _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: SafeJetColors.error,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _isLoading && _transactions.isEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: 5,
                              itemBuilder: (context, index) => FadeInDown(
                                duration: const Duration(milliseconds: 600),
                                delay: Duration(milliseconds: 100 * index),
                                child: ShimmerCard(height: 120, isDark: isDark),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              child: _transactions.isEmpty
                                  ? Center(
                                      child: FadeInUp(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        child: Container(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? SafeJetColors
                                                          .primaryAccent
                                                          .withOpacity(0.1)
                                                      : SafeJetColors
                                                          .lightCardBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? SafeJetColors
                                                            .primaryAccent
                                                            .withOpacity(0.2)
                                                        : SafeJetColors
                                                            .lightCardBorder,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 32,
                                                  color: isDark
                                                      ? SafeJetColors
                                                          .primaryAccent
                                                      : SafeJetColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'No Transactions Yet',
                                                style: theme
                                                    .textTheme.titleLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Your transaction history will appear here\nonce you start making transactions.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : SafeJetColors
                                                          .lightTextSecondary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              ElevatedButton.icon(
                                                onPressed: _loadTransactions,
                                                icon: const Icon(
                                                    Icons.refresh_rounded),
                                                label: const Text('Refresh'),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                  backgroundColor: isDark
                                                      ? SafeJetColors
                                                          .primaryAccent
                                                      : SafeJetColors.primary,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _transactions.length +
                                          (_hasMore ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (index == _transactions.length) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        final transaction =
                                            _transactions[index];
                                        return FadeInDown(
                                          duration:
                                              const Duration(milliseconds: 600),
                                          delay: Duration(
                                              milliseconds: 100 * index),
                                          child: _buildTransactionItem(
                                              transaction, isDark, theme),
                                        );
                                      },
                                    ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      Transaction transaction, bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => TransactionDetailsDialog(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.1)
              : SafeJetColors.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Row(
          children: [
            // Transaction Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.typeIcon,
                color: transaction.statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Transaction Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.displayType,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.createdAt,
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : SafeJetColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.displayAmount,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: transaction.statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.status,
                    style: TextStyle(
                      color: transaction.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
