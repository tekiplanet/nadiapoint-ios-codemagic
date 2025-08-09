import 'package:flutter/material.dart';
import '../../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../wallet/deposit_screen.dart';
import '../../wallet/withdraw_screen.dart';
import '../../wallet/transaction_history_screen.dart';
import '../../p2p/p2p_screen.dart';
import '../../../services/p2p_settings_service.dart';
import '../../../services/exchange_service.dart';
import '../../../services/service_locator.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/wallet_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../wallet/asset_details_screen.dart';
import '../../wallet/internal_transfer_screen.dart';

class WalletsTab extends StatefulWidget {
  const WalletsTab({super.key});

  @override
  State<WalletsTab> createState() => _WalletsTabState();
}

class _WalletsTabState extends State<WalletsTab> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Spot', 'Funding'];
  bool _showInUSD = true;
  bool _showZeroBalances = true;

  String _userCurrency = 'USD';
  double _userCurrencyRate = 1.0;
  bool _isLoading = true;
  bool _isRetrying = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final _exchangeService = getIt<ExchangeService>();
  final _p2pSettingsService = getIt<P2PSettingsService>();
  final WalletService _walletService = getIt<WalletService>();
  List<Map<String, dynamic>> _balances = [];
  double _totalBalance = 0.0;
  Map<String, double> _tokenPrices = {};
  bool _hasError = false;
  String _errorMessage = '';
  double _change24h = 0.0;
  double _changePercent24h = 0.0;
  bool _isPriceLoading = false;
  Timer? _refreshTimer;
  bool _isInitialLoad = true;

  final int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  double _usdBalance = 0.0;
  double _usdChange24h = 0.0;

  Map<String, dynamic>? _selectedAsset;

  List<Map<String, dynamic>> _allCurrencies = [];

  // Add RefreshIndicator key
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>> _sortBalances(
      List<Map<String, dynamic>> balances) {
    // Create a copy of the list to sort
    final sortedBalances = List<Map<String, dynamic>>.from(balances);

    // Sort by USD value in descending order
    sortedBalances.sort((a, b) {
      final aUsdValue =
          double.tryParse(a['usdValue']?.toString() ?? '0') ?? 0.0;
      final bUsdValue =
          double.tryParse(b['usdValue']?.toString() ?? '0') ?? 0.0;
      return bUsdValue.compareTo(aUsdValue); // Descending order (highest first)
    });

    return sortedBalances;
  }

  @override
  void initState() {
    super.initState();
    _loadAllCurrencies();
    _loadUserSettings();
    _loadBalances();
    _setupScrollController();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _loadBalances(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCurrencies() async {
    try {
      final currencies = await P2PSettingsService().getCurrencies();
      setState(() {
        _allCurrencies = List<Map<String, dynamic>>.from(currencies);
      });
    } catch (e) {
      print('Error loading all currencies: $e');
      setState(() {
        _allCurrencies = [];
      });
    }
  }

  Future<void> _loadUserSettings() async {
    try {
      setState(() => _isLoading = true);

      print('Loading user settings...');

      final settings = await _p2pSettingsService.getSettings();
      print('Settings loaded: $settings');

      final rates =
          await _exchangeService.getRates(settings['currency'] ?? 'USD');
      print('Rates loaded: $rates');

      setState(() {
        _userCurrency = settings['currency'] ?? 'USD';
        _userCurrencyRate =
            double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
        _isLoading = false;
      });

      print(
          'Settings updated - Currency: $_userCurrency, Rate: $_userCurrencyRate');
    } catch (e, stackTrace) {
      print('Error loading settings');
      print('Stack trace: $stackTrace');

      setState(() {
        _userCurrency = 'USD';
        _userCurrencyRate = 1.0;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to load your preferences. Please check your internet connection and try again.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadUserSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadBalances(
      {bool showLoading = true, bool preserveState = false}) async {
    if (!mounted) return;

    try {
      if (showLoading && _isInitialLoad) {
        setState(() {
          _isLoading = true;
          _isPriceLoading = true;
        });
      }

      final type =
          _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
      final data = await _walletService.getBalances(
        type: type,
        currency: _showInUSD ? 'USD' : _userCurrency,
        page: preserveState ? _currentPage : 1,
        limit: _pageSize,
      );

      // Add null check for data
      if (data == null) {
        throw Exception('Failed to load balance data');
      }

      // Debug logging
      // print('Received balance data: $data');

      if (!mounted) return;

      if (_selectedFilter == 'All') {
        final Map<String, Map<String, dynamic>> combinedBalances = {};

        // Add null check for balances array
        final balancesArray = data['balances'] ?? [];
        if (balancesArray is! List) {
          throw Exception('Invalid balances data format');
        }

        for (final balance in List<Map<String, dynamic>>.from(balancesArray)) {
          final token = balance['token'] as Map<String, dynamic>?;
          if (token == null) {
            print('Warning: Token data missing for balance: $balance');
            continue;
          }

          final symbol = token['symbol'] as String?;
          if (symbol == null) {
            print('Warning: Symbol missing for token: $token');
            continue;
          }

          // Safely parse balance and USD value
          final currentBalance =
              double.tryParse(balance['balance'].toString()) ?? 0.0;
          final currentUsdValue =
              double.tryParse(balance['usdValue']?.toString() ?? '0') ?? 0.0;

          if (combinedBalances.containsKey(symbol)) {
            // Add to existing balance
            final existingBalance = double.tryParse(
                    combinedBalances[symbol]!['balance'].toString()) ??
                0.0;
            final existingUsdValue = double.tryParse(
                    combinedBalances[symbol]!['usdValue']?.toString() ?? '0') ??
                0.0;

            combinedBalances[symbol]!['balance'] =
                (existingBalance + currentBalance).toString();
            combinedBalances[symbol]!['usdValue'] =
                (existingUsdValue + currentUsdValue).toString();
          } else {
            combinedBalances[symbol] = {
              ...balance,
              'token': token,
            };
          }
        }

        setState(() {
          _balances = _sortBalances(combinedBalances.values.toList());
          print('DEBUG: WalletsTab Funding Balances: ' +
              _balances
                  .map((b) =>
                      {'symbol': b['token']['symbol'], 'balance': b['balance']})
                  .toList()
                  .toString());
          // Only reset pagination if not preserving state
          if (!preserveState) {
            _currentPage = 1;
            _hasMoreData = true;
          }
          // Store USD values
          _usdBalance =
              double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
          _usdChange24h =
              double.tryParse(data['change24h']?.toString() ?? '0') ?? 0.0;
          // Set displayed values based on current currency
          _totalBalance =
              _showInUSD ? _usdBalance : _usdBalance * _userCurrencyRate;
          _change24h =
              _showInUSD ? _usdChange24h : _usdChange24h * _userCurrencyRate;
          _changePercent24h =
              double.tryParse(data['changePercent24h']?.toString() ?? '0') ??
                  0.0;

          // Update token prices with safe parsing and null check
          _tokenPrices = Map<String, double>.fromEntries(
            _balances.where((b) => b['token'] != null).map((b) => MapEntry(
                  b['token']['symbol'] as String,
                  double.tryParse(b['price']?.toString() ?? '0') ?? 0.0,
                )),
          );

          _isLoading = false;
          _isPriceLoading = false;
          _isInitialLoad = false;
        });
      } else if (_selectedFilter == 'Funding') {
        setState(() {
          if (preserveState) {
            final newBalances =
                List<Map<String, dynamic>>.from(data['balances'] ?? []);
            _balances = _sortBalances([..._balances, ...newBalances]);
          } else {
            _balances = _sortBalances(
                List<Map<String, dynamic>>.from(data['balances'] ?? []));
            _currentPage = 1;
            _hasMoreData = true;
          }
          // Use API summary fields for Funding
          _usdBalance =
              double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
          _usdChange24h =
              double.tryParse(data['change24h']?.toString() ?? '0') ?? 0.0;
          _totalBalance =
              _showInUSD ? _usdBalance : _usdBalance * _userCurrencyRate;
          _change24h =
              _showInUSD ? _usdChange24h : _usdChange24h * _userCurrencyRate;
          _changePercent24h =
              double.tryParse(data['changePercent24h']?.toString() ?? '0') ??
                  0.0;
          // Update token prices
          _tokenPrices = Map<String, double>.fromEntries(
            _balances.where((b) => b['token'] != null).map((b) => MapEntry(
                  b['token']['symbol'] as String,
                  double.tryParse(b['price']?.toString() ?? '0') ?? 0.0,
                )),
          );
          _isLoading = false;
          _isPriceLoading = false;
          _isInitialLoad = false;
        });
      } else {
        setState(() {
          if (preserveState) {
            final newBalances =
                List<Map<String, dynamic>>.from(data['balances'] ?? []);
            _balances = _sortBalances([..._balances, ...newBalances]);
          } else {
            _balances = _sortBalances(
                List<Map<String, dynamic>>.from(data['balances'] ?? []));
            _currentPage = 1;
            _hasMoreData = true;
          }
          // Use API summary fields for Spot
          _usdBalance =
              double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
          _usdChange24h =
              double.tryParse(data['change24h']?.toString() ?? '0') ?? 0.0;
          _totalBalance =
              _showInUSD ? _usdBalance : _usdBalance * _userCurrencyRate;
          _change24h =
              _showInUSD ? _usdChange24h : _usdChange24h * _userCurrencyRate;
          _changePercent24h =
              double.tryParse(data['changePercent24h']?.toString() ?? '0') ??
                  0.0;
          _tokenPrices = Map<String, double>.fromEntries(
            _balances.where((b) => b['token'] != null).map((b) => MapEntry(
                  b['token']['symbol'] as String,
                  double.tryParse(b['price']?.toString() ?? '0') ?? 0.0,
                )),
          );
          _isLoading = false;
          _isPriceLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error in _loadBalances');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isPriceLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load balances: ${e.toString()}';
      });
    }
  }

  String _formatBalance(String balance, {bool showZero = true}) {
    final amount = double.tryParse(balance) ?? 0.0;

    if (amount == 0 && !showZero) {
      return '0';
    }

    if (amount == 0) {
      return '0.00';
    }

    // Special handling for BTC and similar low-quantity high-value tokens
    if (amount > 0 && amount < 1) {
      // Show more decimals for small numbers
      String formatted = amount.toStringAsFixed(6);
      // Trim trailing zeros but keep at least 2 decimal places
      while (formatted.endsWith('0') && formatted.split('.')[1].length > 2) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      return formatted;
    } else {
      // For numbers >= 1, show 2 decimal places with thousand separators
      final formatter = NumberFormat('#,##0.00');
      return formatter.format(amount);
    }
  }

  String _formatUsdValue(String value) {
    final amount = double.tryParse(value) ?? 0.0;
    if (amount == 0) {
      return '\$0.00';
    }

    final formatter = NumberFormat('\$#,##0.00');
    return formatter.format(amount);
  }

  String _formatCurrencyValue(String value, String currency) {
    final amount = double.tryParse(value) ?? 0.0;
    if (amount == 0) {
      return '${_getCurrencySymbol(currency)}0.00';
    }

    // The amount is already converted in _updateCurrencyDisplay,
    // so we don't need to convert it again
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _getCurrencySymbol(String currency) {
    final currencyObj = _allCurrencies.firstWhere(
      (c) => c['code'] == currency,
      orElse: () => <String, dynamic>{},
    );
    if (currencyObj['symbol'] != null &&
        currencyObj['symbol'].toString().isNotEmpty) {
      return currencyObj['symbol'];
    }
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

  List<int> _getFilteredAssets() {
    return List.generate(10, (index) {
      final hasBalance = index % 2 == 0;
      final assetName = 'Bitcoin'; // Replace with actual asset name
      final assetSymbol = 'BTC'; // Replace with actual asset symbol

      // Filter by balance
      if (!_showZeroBalances && !hasBalance) {
        return -1;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!assetName.toLowerCase().contains(query) &&
            !assetSymbol.toLowerCase().contains(query)) {
          return -1;
        }
      }

      return index;
    }).where((index) => index != -1).toList();
  }

  Widget _buildShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Value Shimmer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            color: isDark ? Colors.grey[700] : Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 32,
                            color: isDark ? Colors.grey[700] : Colors.white,
                          ),
                        ],
                      ),
                      // Currency Toggle Shimmer
                      Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 120,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Shimmer
            SizedBox(
              height: 100,
              child: Row(
                children: List.generate(
                    3,
                    (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 8,
                              right: index == 2 ? 0 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                          ),
                        )),
              ),
            ),

            const SizedBox(height: 24),

            // Assets List Shimmer
            ...List.generate(
                5,
                (index) => Container(
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return _buildShimmer();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    // Wrap CustomScrollView with RefreshIndicator
    return SafeArea(
      child: RefreshIndicator(
        key: _refreshKey,
        color: SafeJetColors.secondaryHighlight,
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        onRefresh: () async {
          await Future.wait([
            _loadUserSettings(),
            _loadAllCurrencies(),
            _loadBalances(showLoading: true),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern Header with Balance
            SliverToBoxAdapter(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              SafeJetColors.primaryAccent.withOpacity(0.15),
                              SafeJetColors.secondaryHighlight
                                  .withOpacity(0.05),
                            ]
                          : [
                              SafeJetColors.lightCardBackground,
                              SafeJetColors.lightCardBackground
                                  .withOpacity(0.8),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getBalanceTitle(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : SafeJetColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: _buildBalanceText(_showInUSD
                                      ? _formatUsdValue(
                                          _totalBalance.toString())
                                      : _formatCurrencyValue(
                                          _totalBalance.toString(),
                                          _userCurrency)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildCurrencyToggleButton(isDark),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildPriceChange(),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionHistoryScreen(),
                              ),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: Icon(
                              Icons.history_rounded,
                              color: isDark
                                  ? Colors.white
                                  : SafeJetColors.lightText,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildQuickActionCard(
                                    context,
                                    icon: Icons.add_rounded,
                                    label: 'Deposit',
                                    description: 'Add Crypto',
                                    color: SafeJetColors.success,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DepositScreen(
                                          asset: _balances.isEmpty
                                              ? {
                                                  'token': {
                                                    'symbol': 'BTC',
                                                    'name': 'Bitcoin'
                                                  }
                                                }
                                              : _balances.first,
                                          showInUSD: _showInUSD,
                                          userCurrencyRate: _userCurrencyRate,
                                          userCurrency: _userCurrency,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionCard(
                                    context,
                                    icon: Icons.arrow_upward_rounded,
                                    label: 'Withdraw',
                                    description: 'Crypto',
                                    color: isDark
                                        ? Colors.white
                                        : SafeJetColors.lightText,
                                    onTap: () async {
                                      // If we're not in funding tab, load funding balances first
                                      if (_selectedFilter != 'Funding') {
                                        setState(() => _isLoading = true);
                                        final data =
                                            await _walletService.getBalances(
                                          type: 'funding',
                                          currency: _showInUSD
                                              ? 'USD'
                                              : _userCurrency,
                                          page: 1,
                                          limit: _pageSize,
                                        );
                                        setState(() => _isLoading = false);

                                        // Find the funding balance for this token
                                        final fundingBalance =
                                            data['balances'].firstWhere(
                                          (b) =>
                                              b['token']['id'] ==
                                              _balances.first['token']['id'],
                                          orElse: () => _balances.first,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WithdrawScreen(
                                              asset: fundingBalance,
                                              showInUSD: _showInUSD,
                                              userCurrencyRate:
                                                  _userCurrencyRate,
                                              userCurrency: _userCurrency,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Already in funding tab, use current balance
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WithdrawScreen(
                                              asset: _balances.first,
                                              showInUSD: _showInUSD,
                                              userCurrencyRate:
                                                  _userCurrencyRate,
                                              userCurrency: _userCurrency,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionCard(
                                    context,
                                    icon: Icons.swap_horiz_rounded,
                                    label: 'P2P',
                                    description: 'Trade',
                                    color: SafeJetColors.secondaryHighlight,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const P2PScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildQuickActionCard(
                                    context,
                                    icon: Icons.send_rounded,
                                    label: 'Send',
                                    description: 'Internal',
                                    color: Colors.purple,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InternalTransferScreen(
                                          asset: _balances.isEmpty
                                              ? {
                                                  'token': {
                                                    'symbol': 'BTC',
                                                    'name': 'Bitcoin'
                                                  }
                                                }
                                              : _balances.first,
                                          showInUSD: _showInUSD,
                                          userCurrencyRate: _userCurrencyRate,
                                          userCurrency: _userCurrency,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Assets Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Assets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Show zero',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : SafeJetColors.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch.adaptive(
                              value: _showZeroBalances,
                              onChanged: (value) =>
                                  setState(() => _showZeroBalances = value),
                              activeColor: SafeJetColors.secondaryHighlight,
                              activeTrackColor: SafeJetColors.secondaryHighlight
                                  .withOpacity(0.2),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : SafeJetColors.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search assets',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedFilter = filter);
                                _loadBalances();
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? SafeJetColors.secondaryHighlight
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? SafeJetColors.secondaryHighlight
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : isDark
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Asset List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Get filtered balances
                  final filteredBalances = _getFilteredBalances();

                  if (filteredBalances.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Add loading indicator at the bottom
                  if (index == filteredBalances.length) {
                    if (_isLoadingMore) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    } else if (!_hasMoreData) {
                      return const SizedBox();
                    }
                    return const SizedBox();
                  }

                  if (index >= filteredBalances.length) return null;

                  final balance = filteredBalances[index];
                  // Add null check for token
                  final token = balance['token'] as Map<String, dynamic>?;
                  if (token == null) {
                    return const SizedBox(); // Skip rendering this item
                  }

                  final amount =
                      double.tryParse(balance['balance']?.toString() ?? '0') ??
                          0.0;
                  final symbol = token['symbol'] as String? ?? '';
                  final price = _tokenPrices[symbol] ?? 0.0;
                  final isLoading = balance['priceLoading'] ?? false;

                  // Get the change percent from the token data with null safety
                  final tokenChangePercent24h = double.tryParse(
                          token['changePercent24h']?.toString() ?? '0') ??
                      0.0;

                  return GestureDetector(
                    onTap: () {
                      print('Asset being passed to details: $balance');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetDetailsScreen(
                            asset: balance,
                            showInUSD: _showInUSD,
                            userCurrencyRate: _userCurrencyRate,
                            userCurrency: _userCurrency,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
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
                          // Token Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: token['metadata']?['icon'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          token['metadata']['icon']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: token['metadata']?['icon'] != null
                                ? null
                                : Center(
                                    child: Text(
                                      symbol[0],
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // Token Name and Symbol
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  token['name'].split(' (')[
                                      0], // Use clean name without network
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      symbol,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : SafeJetColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Price change indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (tokenChangePercent24h >= 0
                                                ? SafeJetColors.success
                                                : SafeJetColors.error)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            tokenChangePercent24h >= 0
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            color: tokenChangePercent24h >= 0
                                                ? SafeJetColors.success
                                                : SafeJetColors.error,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${tokenChangePercent24h >= 0 ? '+' : ''}${tokenChangePercent24h.abs().toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: tokenChangePercent24h >= 0
                                                  ? SafeJetColors.success
                                                  : SafeJetColors.error,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Use balance metadata to check network
                                    if (balance['metadata']?['network'] ==
                                        'testnet')
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SafeJetColors.warning
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Testnet',
                                          style: TextStyle(
                                            color: SafeJetColors.warning,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Balance
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatBalance(
                                    balance['balance']?.toString() ?? '0'),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildAssetBalance(
                                _showInUSD
                                    ? _formatUsdValue(
                                        balance['usdValue']?.toString() ?? '0')
                                    : _formatCurrencyValue(
                                        ((double.tryParse(balance['usdValue']
                                                            ?.toString() ??
                                                        '0') ??
                                                    0.0) *
                                                _userCurrencyRate)
                                            .toString(),
                                        _userCurrency),
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _getFilteredBalances().isEmpty
                    ? 1
                    : _getFilteredBalances().length + 1,
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
        width: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyToggleButton(bool isDark) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    // If user's currency is USD, don't show the toggle
    if (_userCurrency.toUpperCase() == 'USD') {
      return Container(
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
        child: _buildCurrencyToggle('USD', true, isDark),
      );
    }

    // Show toggle for other currencies
    return Container(
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCurrencyToggle('USD', true, isDark),
          _buildCurrencyToggle(_userCurrency, false, isDark),
        ],
      ),
    );
  }

  Widget _buildCurrencyToggle(String currency, bool isUSD, bool isDark) {
    final isSelected = _showInUSD == isUSD;

    return GestureDetector(
      onTap: () {
        if (_showInUSD != isUSD) {
          _updateCurrencyDisplay(isUSD);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? SafeJetColors.secondaryHighlight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          currency,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.white : SafeJetColors.lightText),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceText(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
      maxLines: 1, // Ensure single line
      overflow: TextOverflow.ellipsis, // Show ellipsis if needed
    );
  }

  Widget _buildAssetItem(
    bool isDark,
    ThemeData theme,
    String name,
    String symbol,
    double amount,
    String? iconUrl,
    Map<String, dynamic>? tokenMetadata,
    Map<String, dynamic> balance,
  ) {
    // Format balance with thousands separator
    String formattedBalance;
    final numberFormat = NumberFormat.decimalPattern('en_US');

    if (amount == 0) {
      formattedBalance = '0.00';
    } else if (amount < 0.00001) {
      // For very small numbers, use scientific notation
      formattedBalance = amount.toStringAsExponential(4);
    } else if (amount < 1) {
      // For small numbers, show more decimals without commas
      formattedBalance = amount.toStringAsFixed(8);
    } else {
      // For larger numbers, format with commas and 4 decimals
      final wholeNumber = amount.floor();
      final decimal = amount - wholeNumber;

      if (decimal == 0) {
        // If no decimals, just format the whole number
        formattedBalance = numberFormat.format(wholeNumber);
      } else {
        // Combine formatted whole number with decimals
        formattedBalance = numberFormat.format(wholeNumber) +
            decimal.toStringAsFixed(4).substring(1);
      }
    }

    final changePercent24h = double.tryParse(
            balance['token']['changePercent24h']?.toString() ?? '0') ??
        0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          // Token Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: iconUrl != null
                  ? DecorationImage(
                      image: NetworkImage(iconUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: iconUrl == null
                ? Center(
                    child: Text(
                      symbol[0],
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Token Name and Symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.split(' (')[0],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : SafeJetColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price change indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (changePercent24h >= 0
                                ? SafeJetColors.success
                                : SafeJetColors.error)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            changePercent24h >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: changePercent24h >= 0
                                ? SafeJetColors.success
                                : SafeJetColors.error,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${changePercent24h >= 0 ? '+' : ''}${changePercent24h.abs().toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changePercent24h >= 0
                                  ? SafeJetColors.success
                                  : SafeJetColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedBalance,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildAssetBalance(
                _showInUSD
                    ? _formatUsdValue(balance['usdValue']?.toString() ?? '0')
                    : _formatCurrencyValue(
                        ((double.tryParse(balance['usdValue']?.toString() ??
                                        '0') ??
                                    0.0) *
                                _userCurrencyRate)
                            .toString(),
                        _userCurrency),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetBalance(String text, bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: TextStyle(
          color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
        ),
      ),
    );
  }

  Future<void> _loadRates() async {
    try {
      final rates = await _exchangeService.getRates(_userCurrency);
      if (mounted) {
        setState(() {
          _userCurrencyRate =
              double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
        });
      }
    } catch (e) {
      print('Error loading rates');
      // Optionally show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to update exchange rates. Your balances may not show the correct currency conversion.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadRates,
            ),
          ),
        );
      }
    }
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.grey[400]
                    : SafeJetColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isRetrying
                  ? null
                  : () async {
                      setState(() {
                        _isRetrying = true;
                        _hasError = false;
                        _isLoading = true;
                      });
                      await Future.wait([
                        _loadUserSettings(),
                        _loadAllCurrencies(),
                        _loadBalances(showLoading: true),
                      ]);
                      if (mounted) {
                        setState(() {
                          _isRetrying = false;
                        });
                      }
                    },
              icon: _isRetrying
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isRetrying ? 'Loading...' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    if (_errorMessage.toLowerCase().contains('internet') ||
        _errorMessage.toLowerCase().contains('connection')) {
      return Icons.wifi_off_rounded;
    } else if (_errorMessage.toLowerCase().contains('unavailable')) {
      return Icons.engineering_rounded;
    } else {
      return Icons.error_outline_rounded;
    }
  }

  String _getErrorTitle() {
    if (_errorMessage.toLowerCase().contains('internet') ||
        _errorMessage.toLowerCase().contains('connection')) {
      return 'No Internet Connection';
    } else if (_errorMessage.toLowerCase().contains('unavailable')) {
      return 'Service Unavailable';
    } else {
      return 'Something Went Wrong';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : SafeJetColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Assets Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start by depositing some assets into your wallet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DepositScreen(
                      asset: _balances.isEmpty
                          ? {
                              'token': {'symbol': 'BTC', 'name': 'Bitcoin'}
                            }
                          : _balances.first,
                      showInUSD: _showInUSD,
                      userCurrencyRate: _userCurrencyRate,
                      userCurrency: _userCurrency,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Deposit Assets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBalanceTitle() {
    switch (_selectedFilter) {
      case 'Spot':
        return 'Spot Balance';
      case 'Funding':
        return 'Fund Balance';
      default:
        return 'Portfolio Value';
    }
  }

  String _formatPriceChange(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  Widget _buildPriceChange() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isPriceLoading
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: (_changePercent24h >= 0
                        ? SafeJetColors.success
                        : SafeJetColors.error)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _changePercent24h >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: _changePercent24h >= 0
                        ? SafeJetColors.success
                        : SafeJetColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_changePercent24h >= 0 ? '+' : ''}${_getCurrencySymbol(_showInUSD ? 'USD' : _userCurrency)}${_formatPriceChange(_change24h.abs())} '
                    '(${_changePercent24h.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: _changePercent24h >= 0
                          ? SafeJetColors.success
                          : SafeJetColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore &&
          _hasMoreData) {
        _loadMoreBalances();
      }
    });
  }

  Future<void> _loadMoreBalances() async {
    if (!mounted || _isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final type =
          _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
      final data = await _walletService.getBalances(
        type: type,
        currency: _showInUSD ? 'USD' : _userCurrency,
        page: _currentPage + 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      final newBalances =
          List<Map<String, dynamic>>.from(data['balances'] ?? []);
      final pagination = data['pagination'] as Map<String, dynamic>;

      // Check if we have more data based on pagination info
      final hasMore = pagination['hasMore'] as bool;

      setState(() {
        if (_selectedFilter == 'All') {
          // Handle combining balances for All filter
          final Map<String, Map<String, dynamic>> combinedBalances =
              Map.fromEntries(_balances
                  .map((b) => MapEntry(b['token']['symbol'] as String, b)));

          for (final balance in newBalances) {
            final token = balance['token'] as Map<String, dynamic>;
            final symbol = token['symbol'] as String;
            final currentBalance =
                double.tryParse(balance['balance'].toString()) ?? 0.0;

            if (combinedBalances.containsKey(symbol)) {
              final existingBalance = double.tryParse(
                      combinedBalances[symbol]!['balance'].toString()) ??
                  0.0;
              combinedBalances[symbol]!['balance'] =
                  (existingBalance + currentBalance).toString();
              // Update token data
              combinedBalances[symbol]!['token'] = token;
            } else {
              combinedBalances[symbol] = {
                ...balance,
                'token': token,
              };
            }
          }

          _balances = _sortBalances(combinedBalances.values.toList());
        } else if (_selectedFilter == 'Funding') {
          final Map<String, Map<String, dynamic>> combinedBalances =
              Map.fromEntries(_balances
                  .map((b) => MapEntry(b['token']['symbol'] as String, b)));

          for (final balance in newBalances) {
            final token = balance['token'] as Map<String, dynamic>;
            final symbol = token['symbol'] as String;
            final currentBalance =
                double.tryParse(balance['balance'].toString()) ?? 0.0;

            if (combinedBalances.containsKey(symbol)) {
              final existingBalance = double.tryParse(
                      combinedBalances[symbol]!['balance'].toString()) ??
                  0.0;
              combinedBalances[symbol]!['balance'] =
                  (existingBalance + currentBalance).toString();
              // Update token data
              combinedBalances[symbol]!['token'] = token;
            } else {
              combinedBalances[symbol] = {
                ...balance,
                'token': token,
              };
            }
          }

          _balances = _sortBalances(combinedBalances.values.toList());
        } else {
          _balances.addAll(newBalances);
          _balances = _sortBalances(_balances);
        }

        _currentPage++;
        _isLoadingMore = false;
        _hasMoreData = hasMore; // Update based on pagination info
      });

      // Update token prices for new balances
      final newPrices = Map<String, double>.fromEntries(
        newBalances.map((b) => MapEntry(
              b['token']['symbol'] as String,
              double.tryParse(b['price']?.toString() ?? '0') ?? 0.0,
            )),
      );
      _tokenPrices.addAll(newPrices);
    } catch (e) {
      print('Error loading more balances');
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        _hasMoreData = false;
      });
    }
  }

  // Add this method to handle immediate currency conversion
  void _updateCurrencyDisplay(bool showInUSD) {
    print('Current USD value: $_usdBalance');
    print('Current exchange rate: $_userCurrencyRate');

    setState(() {
      _showInUSD = showInUSD;
      // This is where we do the single conversion
      _totalBalance =
          _showInUSD ? _usdBalance : _usdBalance * _userCurrencyRate;
      _change24h =
          _showInUSD ? _usdChange24h : _usdChange24h * _userCurrencyRate;
    });
  }

  // Add this method to filter balances
  List<Map<String, dynamic>> _getFilteredBalances() {
    return _balances.where((balance) {
      // First check balance if zero balances are hidden
      if (!_showZeroBalances) {
        final amount =
            double.tryParse(balance['balance']?.toString() ?? '0') ?? 0.0;
        if (amount <= 0) return false;
      }

      // Then apply search filter if there's a search query
      if (_searchQuery.isNotEmpty) {
        final token = balance['token'] as Map<String, dynamic>;
        final name = (token['name'] as String).toLowerCase();
        final symbol = (token['symbol'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();

        // Check if either name or symbol contains the search query
        return name.contains(query) || symbol.contains(query);
      }

      return true;
    }).toList();
  }

  Future<void> _loadExchangeRate() async {
    try {
      final response = await _exchangeService.getRates(_userCurrency);
      setState(() {
        _userCurrencyRate = double.tryParse(response['rate']) ?? 1.0;
        print('Loaded exchange rate: $_userCurrencyRate for $_userCurrency');
      });
    } catch (e) {
      print('Error loading exchange rate');
      // Set a fallback rate
      _userCurrencyRate = 1.0;
    }
  }
}
