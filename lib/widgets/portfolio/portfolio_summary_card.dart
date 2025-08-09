import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../services/home_service.dart';
import '../../services/service_locator.dart';
import '../../services/p2p_settings_service.dart';
import '../../services/exchange_service.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

class PortfolioSummaryCard extends StatefulWidget {
  const PortfolioSummaryCard({super.key});

  @override
  State<PortfolioSummaryCard> createState() => _PortfolioSummaryCardState();
}

class _PortfolioSummaryCardState extends State<PortfolioSummaryCard> {
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'BTC', 'NGN'];
  bool _isBalanceHidden = false;

  // Add currency symbols map
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'NGN': '₦',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'KRW': '₩',
    'BTC': '₿',
  };

  final HomeService _homeService = getIt<HomeService>();
  final P2PSettingsService _p2pSettingsService = getIt<P2PSettingsService>();
  final ExchangeService _exchangeService = getIt<ExchangeService>();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _portfolioData = {};

  double _totalUsdValue = 0.0;
  double _spotUsdValue = 0.0;
  double _fundingUsdValue = 0.0;
  double _changePercent = 0.0;
  String _userCurrency = 'USD';
  double _userCurrencyRate = 1.0;
  bool _showInUSD = true;

  Timer? _refreshTimer;
  List<Map<String, dynamic>> _allCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadAllCurrencies();
    _loadUserSettings();
    _loadPortfolioData();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        _loadPortfolioData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      final settings = await _p2pSettingsService.getSettings();
      final currency = settings['currency'] ?? 'USD';

      if (currency != 'USD') {
        final rates = await _exchangeService.getRates(currency);
        setState(() {
          _userCurrency = currency;
          _currencies[2] = currency; // Replace NGN with user's currency
          _userCurrencyRate =
              double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
        });
      }
    } catch (e) {
      print('Error loading user settings');
      // Default to USD if there's an error
    }
  }

  Future<void> _loadPortfolioData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final data = await _homeService.getPortfolioSummary(
        currency: _selectedCurrency,
        timeframe: '24h',
      );

      if (mounted) {
        setState(() {
          _portfolioData = data;
          _isLoading = false;

          // Extract and store values for easy access
          final portfolio = data['portfolio'] ?? {};
          _totalUsdValue =
              double.tryParse(portfolio['usdValue']?.toString() ?? '0') ?? 0.0;

          final change = portfolio['change'] ?? {};
          _changePercent =
              double.tryParse(change['percent']?.toString() ?? '0') ?? 0.0;

          // Use the totals directly from the API response
          final spotBalances = data['spotBalances'] ?? {};
          final fundingBalances = data['fundingBalances'] ?? {};

          _spotUsdValue =
              double.tryParse(spotBalances['total']?.toString() ?? '0') ?? 0.0;
          _fundingUsdValue =
              double.tryParse(fundingBalances['total']?.toString() ?? '0') ??
                  0.0;
        });
      }
    } catch (e) {
      print('Error loading portfolio data');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateCurrencyDisplay(bool showInUSD) {
    setState(() {
      _showInUSD = showInUSD;
    });
  }

  String _formatCurrency(double value, {Map<String, dynamic>? currencyData}) {
    if (_isBalanceHidden) {
      return '∗∗∗∗∗∗';
    }

    final currency = _showInUSD ? 'USD' : _userCurrency;
    final amount = _showInUSD ? value : value * _userCurrencyRate;

    // Format with commas and 2 decimal places
    final formattedNumber = amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    // Prefer symbol from backend if available
    String? symbol;
    if (currencyData != null &&
        currencyData['symbol'] != null &&
        currencyData['symbol'].toString().isNotEmpty) {
      symbol = currencyData['symbol'];
    } else {
      symbol = _currencySymbols[currency] ?? currency;
    }

    // For EUR, symbol goes after with a space
    if (currency == 'EUR') {
      return '$formattedNumber €';
    }

    // For all other currencies, symbol goes before without a space
    return '$symbol$formattedNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_hasError) {
      return _buildErrorState(isDark);
    }

    // Find the currency object for the selected currency
    final selectedCode = _showInUSD ? 'USD' : _userCurrency;
    final currencyObj = _allCurrencies.firstWhere(
      (c) => c['code'] == selectedCode,
      orElse: () => <String, dynamic>{},
    );

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    SafeJetColors.secondaryHighlight.withOpacity(0.15),
                    SafeJetColors.primaryAccent.withOpacity(0.05),
                  ]
                : [
                    SafeJetColors.lightCardBackground,
                    SafeJetColors.lightCardBackground,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, isDark, currencyObj),
            const SizedBox(height: 20),
            _buildBalanceBreakdown(isDark, currencyObj),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      ThemeData theme, bool isDark, Map<String, dynamic> currencyObj) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Portfolio Balance',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                  child: Icon(
                    _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: isDark
                        ? Colors.white70
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            _buildCurrencySelector(isDark),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                _formatCurrency(_totalUsdValue, currencyData: currencyObj),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (_changePercent >= 0
                          ? SafeJetColors.success
                          : SafeJetColors.error)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _changePercent >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: _changePercent >= 0
                          ? SafeJetColors.success
                          : SafeJetColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_changePercent >= 0 ? '+' : ''}${_changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: _changePercent >= 0
                            ? SafeJetColors.success
                            : SafeJetColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector(bool isDark) {
    // If user currency is USD, don't show a toggle
    if (_userCurrency.toUpperCase() == 'USD') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: DropdownButton<String>(
          value: _selectedCurrency,
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 16,
          elevation: 16,
          style: TextStyle(
            color: isDark ? Colors.white : SafeJetColors.lightText,
            fontWeight: FontWeight.bold,
          ),
          underline: Container(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCurrency = newValue!;
              _loadPortfolioData();
            });
          },
          items: _currencies.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
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

  Widget _buildBalanceBreakdown(bool isDark, Map<String, dynamic> currencyObj) {
    return Column(
      children: [
        _buildBalanceRow('Spot Balance', _spotUsdValue, isDark, currencyObj),
        const SizedBox(height: 12),
        _buildBalanceRow(
            'Funding Balance', _fundingUsdValue, isDark, currencyObj),
      ],
    );
  }

  Widget _buildBalanceRow(String label, double value, bool isDark,
      Map<String, dynamic> currencyObj) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : SafeJetColors.lightTextSecondary,
            ),
          ),
          Text(
            _formatCurrency(value, currencyData: currencyObj),
            style: TextStyle(
              color: isDark ? Colors.white : SafeJetColors.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    SafeJetColors.secondaryHighlight.withOpacity(0.15),
                    SafeJetColors.primaryAccent.withOpacity(0.05),
                  ]
                : [
                    SafeJetColors.lightCardBackground,
                    SafeJetColors.lightCardBackground,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Balance shimmer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Balance breakdown shimmer
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildErrorState(bool isDark) {
    // Optionally log the technical error for debugging
    if (_errorMessage.isNotEmpty) {
      // ignore: avoid_print
      print('PortfolioSummaryCard error: $_errorMessage');
    }
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  SafeJetColors.secondaryHighlight.withOpacity(0.15),
                  SafeJetColors.primaryAccent.withOpacity(0.05),
                ]
              : [
                  SafeJetColors.lightCardBackground,
                  SafeJetColors.lightCardBackground,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: SafeJetColors.error, size: 40),
            const SizedBox(height: 16),
            Text(
              'Failed to load portfolio data',
              style: TextStyle(
                color: isDark ? Colors.white : SafeJetColors.lightText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your portfolio. Please check your internet connection or try again later.',
              style: TextStyle(
                color:
                    isDark ? Colors.white70 : SafeJetColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPortfolioData,
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
