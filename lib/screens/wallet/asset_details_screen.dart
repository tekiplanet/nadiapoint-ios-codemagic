import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show min, max;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import '../../services/wallet_service.dart';
import 'deposit_screen.dart';
import '../../models/coin.dart';
import 'withdraw_screen.dart';
import 'transfer_screen.dart';
import 'convert_screen.dart';
import 'transaction_history_screen.dart';

class AssetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final bool showInUSD;
  final double userCurrencyRate;
  final String userCurrency;

  const AssetDetailsScreen({
    super.key,
    required this.asset,
    required this.showInUSD,
    required this.userCurrencyRate,
    required this.userCurrency,
  });

  @override
  _AssetDetailsScreenState createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  String _selectedTimeframe = '24H';
  final List<String> _timeframes = ['1H', '24H', '1W', '1M', '1Y', 'ALL'];
  bool _isLoadingChart = false;
  final _walletService = GetIt.I<WalletService>();

  String _formatBalance(bool showInUSD, double value) {
    final currencySymbol =
        showInUSD ? '\$' : _getCurrencySymbol(widget.userCurrency);

    // Format large numbers with T, B, M, K
    if (value >= 1000000000000) {
      return '$currencySymbol${(value / 1000000000000).toStringAsFixed(2)}T';
    } else if (value >= 1000000000) {
      return '$currencySymbol${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '$currencySymbol${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '$currencySymbol${(value / 1000).toStringAsFixed(2)}K';
    }

    // For smaller numbers, use regular currency format
    final numberFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    return numberFormat.format(value);
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(2)}T';
    } else if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
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

  String _formatExactBalance(double value) {
    final formatter = NumberFormat('#,##0.000000'); // Fixed 8 decimal places
    String formatted = formatter.format(value);

    // Trim trailing zeros but keep at least 2 decimal places
    while (formatted.endsWith('0') && formatted.split('.')[1].length > 2) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted;
  }

  String _formatFiatBalance(double value) {
    final formatter = NumberFormat('#,##0.000'); // 3 decimal places for fiat
    return formatter.format(value);
  }

  List<FlSpot> _getChartData() {
    final priceHistory =
        (widget.asset['token']['priceHistory'] as List?)?.cast<List>();
    if (priceHistory == null || priceHistory.isEmpty) {
      return [];
    }

    // Convert timestamp and price data to FlSpots
    return priceHistory.asMap().entries.map((entry) {
      final timestamp = entry.value[0] as int; // milliseconds timestamp
      final price = (entry.value[1] as num).toDouble();
      return FlSpot(entry.key.toDouble(), price);
    }).toList();
  }

  void _onTimeframeSelected(String timeframe) async {
    if (_selectedTimeframe == timeframe) return;

    setState(() {
      _isLoadingChart = true;
      _selectedTimeframe = timeframe;
    });

    try {
      final response = await _walletService.updateTokenMarketData(
        widget.asset['token']['id'],
        timeframe: timeframe,
      );

      if (response['success'] == true) {
        setState(() {
          widget.asset['token'] = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error updating chart data');
    } finally {
      setState(() {
        _isLoadingChart = false;
      });
    }
  }

  void _handleDepositTap() {
    final token = widget.asset['token'] as Map<String, dynamic>;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositScreen(
          asset: widget.asset,
          showInUSD: widget.showInUSD,
          userCurrencyRate: widget.userCurrencyRate,
          userCurrency: widget.userCurrency,
        ),
      ),
    );
  }

  void _handleWithdrawTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawScreen(
          asset: widget.asset,
          showInUSD: widget.showInUSD,
          userCurrencyRate: widget.userCurrencyRate,
          userCurrency: widget.userCurrency,
        ),
      ),
    );
  }

  void _handleTransferTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferScreen(
          asset: widget.asset,
          showInUSD: widget.showInUSD,
          userCurrencyRate: widget.userCurrencyRate,
          userCurrency: widget.userCurrency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Raw frozen value: ${widget.asset['frozen']}');
    final frozen =
        double.tryParse(widget.asset['frozen']?.toString() ?? '0') ?? 0.0;
    print('Parsed frozen value: $frozen');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final token = widget.asset['token'] as Map<String, dynamic>;
    final balance = double.tryParse(widget.asset['balance'].toString()) ?? 0.0;
    final usdValue =
        double.tryParse(widget.asset['usdValue'].toString()) ?? 0.0;
    final fiatValue =
        widget.showInUSD ? usdValue : usdValue * widget.userCurrencyRate;
    final changePercent24h =
        double.tryParse(token['changePercent24h']?.toString() ?? '0') ?? 0.0;
    final currencySymbol =
        widget.showInUSD ? '\$' : _getCurrencySymbol(widget.userCurrency);

    Future<void> _handleRefresh() async {
      try {
        // 1. Refresh token market data
        final marketResponse = await _walletService.updateTokenMarketData(
          widget.asset['token']['id'],
          timeframe: _selectedTimeframe,
        );
        if (marketResponse['success'] == true) {
          setState(() {
            widget.asset['token'] = marketResponse['data'];
          });
        }

        // 2. Refresh wallet balance for this asset
        final balancesResponse = await _walletService.getBalances();
        if (balancesResponse != null && balancesResponse['balances'] != null) {
          final List balances = balancesResponse['balances'];
          final updated = balances.firstWhere(
            (b) =>
                b['token'] != null &&
                b['token']['id'] == widget.asset['token']['id'],
            orElse: () => null,
          );
          if (updated != null) {
            setState(() {
              widget.asset['balance'] = updated['balance'];
              widget.asset['frozen'] = updated['frozen'];
              widget.asset['usdValue'] = updated['usdValue'];
              // Optionally update other fields if needed
            });
          }
        }
      } catch (e) {
        debugPrint('Error refreshing asset data: ${e.toString()}');
      }
    }

    return Scaffold(
      backgroundColor: isDark
          ? SafeJetColors.primaryBackground
          : SafeJetColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: token['metadata']?['icon'] != null
                    ? DecorationImage(
                        image: NetworkImage(token['metadata']['icon']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: token['metadata']?['icon'] == null
                  ? Center(
                      child: Text(
                        token['symbol'][0],
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              token['symbol'],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: SafeJetColors.secondaryHighlight,
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Main Balance Section with Gradient
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              SafeJetColors.primaryAccent.withOpacity(0.2),
                              SafeJetColors.secondaryHighlight
                                  .withOpacity(0.05),
                            ]
                          : [
                              SafeJetColors.secondaryHighlight.withOpacity(0.1),
                              SafeJetColors.primaryAccent.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.2)
                          : SafeJetColors.lightCardBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Price Change Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (changePercent24h >= 0
                                  ? SafeJetColors.success
                                  : SafeJetColors.error)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              changePercent24h >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: changePercent24h >= 0
                                  ? SafeJetColors.success
                                  : SafeJetColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${changePercent24h >= 0 ? '+' : ''}${changePercent24h.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: changePercent24h >= 0
                                    ? SafeJetColors.success
                                    : SafeJetColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Token Balance
                      Text(
                        _formatExactBalance(balance),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      Text(
                        '≈ ${currencySymbol}${_formatFiatBalance(fiatValue)}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : SafeJetColors.lightTextSecondary,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Available and Frozen Balance
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : SafeJetColors.lightTextSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatExactBalance(balance),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Frozen',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : SafeJetColors.lightTextSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatExactBalance(frozen),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
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
              ),

              // Market Info Card
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Info',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMarketInfoCard(
                              context,
                              'Current Price',
                              _formatBalance(
                                  widget.showInUSD,
                                  double.parse(
                                      token['currentPrice'].toString())),
                              Icons.attach_money,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMarketInfoCard(
                              context,
                              '24h Volume',
                              '\$1.2B',
                              Icons.bar_chart,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMarketInfoCard(
                              context,
                              '24h High',
                              _formatBalance(
                                  widget.showInUSD,
                                  double.parse(
                                          token['currentPrice'].toString()) *
                                      1.1),
                              Icons.arrow_upward,
                              isDark,
                              color: SafeJetColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMarketInfoCard(
                              context,
                              '24h Low',
                              _formatBalance(
                                  widget.showInUSD,
                                  double.parse(
                                          token['currentPrice'].toString()) *
                                      0.9),
                              Icons.arrow_downward,
                              isDark,
                              color: SafeJetColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chart Time Selection
              FadeInUp(
                duration: const Duration(milliseconds: 450),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _timeframes.map((timeframe) {
                      final isSelected = _selectedTimeframe == timeframe;
                      return Expanded(
                        child: GestureDetector(
                          onTap: _isLoadingChart
                              ? null
                              : () => _onTimeframeSelected(timeframe),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected
                                      ? SafeJetColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              timeframe,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? SafeJetColors.primary
                                    : isDark
                                        ? Colors.grey[400]
                                        : SafeJetColors.lightTextSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Price Chart Section
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  height: 200,
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
                  child: _isLoadingChart
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white : SafeJetColors.primary,
                            ),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (_getChartData().length - 1).toDouble(),
                            minY: _getChartData().isEmpty
                                ? 0
                                : _getChartData()
                                    .map((spot) => spot.y)
                                    .reduce(min),
                            maxY: _getChartData().isEmpty
                                ? 0
                                : _getChartData()
                                    .map((spot) => spot.y)
                                    .reduce(max),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getChartData(),
                                isCurved: true,
                                gradient: LinearGradient(
                                  colors: [
                                    changePercent24h >= 0
                                        ? SafeJetColors.success
                                        : SafeJetColors.error,
                                    (changePercent24h >= 0
                                            ? SafeJetColors.success
                                            : SafeJetColors.error)
                                        .withOpacity(0.3),
                                  ],
                                ),
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      (changePercent24h >= 0
                                              ? SafeJetColors.success
                                              : SafeJetColors.error)
                                          .withOpacity(0.2),
                                      (changePercent24h >= 0
                                              ? SafeJetColors.success
                                              : SafeJetColors.error)
                                          .withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: isDark
                                    ? SafeJetColors.primaryAccent
                                        .withOpacity(0.8)
                                    : Colors.white,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final price = spot.y;
                                    return LineTooltipItem(
                                      _formatBalance(widget.showInUSD, price),
                                      TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              handleBuiltInTouches: true,
                              touchCallback: (event, response) {
                                // Handle touch events if needed
                              },
                            ),
                          ),
                        ),
                ),
              ),

              // Price Statistics section
              FadeInUp(
                duration: const Duration(milliseconds: 550),
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Statistics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticItem(
                        'Market Cap',
                        _formatBalance(
                            widget.showInUSD,
                            double.tryParse(
                                    token['marketCap']?.toString() ?? '0') ??
                                0.0),
                        token['marketCapChange24h'] != null
                            ? '${_formatBalance(widget.showInUSD, double.tryParse(token['marketCapChange24h']?.toString() ?? '0') ?? 0.0)} (${(double.tryParse(token['marketCapChangePercent24h']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}%)'
                            : null,
                        token['marketCapChangePercent24h'] != null &&
                            (double.tryParse(token['marketCapChangePercent24h']
                                            ?.toString() ??
                                        '0') ??
                                    0.0) >=
                                0,
                        isDark,
                      ),
                      _buildStatisticItem(
                        'Fully Diluted Market Cap',
                        _formatBalance(
                            widget.showInUSD,
                            double.tryParse(token['fullyDilutedMarketCap']
                                        ?.toString() ??
                                    '0') ??
                                0.0),
                        null,
                        null,
                        isDark,
                      ),
                      _buildStatisticItem(
                        'Volume (24h)',
                        _formatBalance(
                            widget.showInUSD,
                            double.tryParse(
                                    token['volume24h']?.toString() ?? '0') ??
                                0.0),
                        token['volumeChangePercent24h'] != null
                            ? '${(double.tryParse(token['volumeChangePercent24h']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}%'
                            : null,
                        token['volumeChangePercent24h'] != null &&
                            (double.tryParse(token['volumeChangePercent24h']
                                            ?.toString() ??
                                        '0') ??
                                    0.0) >=
                                0,
                        isDark,
                      ),
                      _buildStatisticItem(
                        'Circulating Supply',
                        '${_formatLargeNumber(double.tryParse(token['circulatingSupply']?.toString() ?? '0') ?? 0)} ${token['symbol']}',
                        token['maxSupply'] != null
                            ? '${((double.tryParse(token['circulatingSupply']?.toString() ?? '0') ?? 0) / (double.tryParse(token['maxSupply']?.toString() ?? '0') ?? 1) * 100).toStringAsFixed(2)}%'
                            : null,
                        null,
                        isDark,
                        isSupply: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    SafeJetColors.primaryBackground.withOpacity(0.8),
                    SafeJetColors.primaryBackground,
                  ]
                : [
                    SafeJetColors.lightBackground.withOpacity(0.8),
                    SafeJetColors.lightBackground,
                  ],
          ),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAdvancedNavButton(
              context,
              'Deposit',
              Icons.download_rounded,
              SafeJetColors.success,
              _handleDepositTap,
              isDark,
            ),
            _buildAdvancedNavButton(
              context,
              'Withdraw',
              Icons.upload_rounded,
              SafeJetColors.error,
              _handleWithdrawTap,
              isDark,
            ),
            _buildAdvancedNavButton(
              context,
              'Transfer',
              Icons.swap_horiz_rounded,
              SafeJetColors.primary,
              _handleTransferTap,
              isDark,
            ),
            _buildAdvancedNavButton(
              context,
              'Convert',
              Icons.currency_exchange_rounded,
              SafeJetColors.secondaryHighlight,
              () {
                print('Asset data being passed: ${widget.asset}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConvertScreen(
                      fromAsset: {
                        'token': widget.asset['token'],
                        'balance': widget.asset['balance'],
                      },
                      showInUSD: widget.showInUSD,
                      userCurrencyRate: widget.userCurrencyRate,
                      userCurrency: widget.userCurrency,
                    ),
                  ),
                );
              },
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedNavButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? SafeJetColors.primaryAccent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color ?? (isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? Colors.grey[400]
                      : SafeJetColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(
    String label,
    String value,
    String? change,
    bool? isPositive,
    bool isDark, {
    bool isSupply = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive == true
                            ? SafeJetColors.success
                            : SafeJetColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: isPositive == true
                          ? SafeJetColors.success
                          : SafeJetColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (isSupply && change != null)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SafeJetColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                          double.tryParse(change.replaceAll('%', ''))! / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: SafeJetColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
