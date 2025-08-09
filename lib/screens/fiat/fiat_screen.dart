import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'fiat_wallet_details_screen.dart';
import 'fiat_deposit_screen.dart';
import 'fiat_withdrawal_screen.dart';
import 'fiat_buy_crypto_screen.dart';
import 'fiat_transaction_history_screen.dart';
import '../../services/fiat_wallet_service.dart';
import '../../services/fiat_transaction_service.dart';
import 'package:get_it/get_it.dart';
import '../../config/env/env_config.dart';
import '../../services/exchange_service.dart';
import '../../services/p2p_settings_service.dart';
import '../../models/fiat_transaction.dart';
import 'all_wallets_modal.dart';
import '../../screens/settings/kyc_levels_screen.dart';
import '../../services/kyc_service.dart';
import '../../utils/error_utils.dart';
import 'package:shimmer/shimmer.dart';

class FiatScreen extends StatefulWidget {
  const FiatScreen({super.key});

  @override
  State<FiatScreen> createState() => _FiatScreenState();
}

class _FiatScreenState extends State<FiatScreen> {
  final FiatWalletService _fiatWalletService = GetIt.I<FiatWalletService>();
  final FiatTransactionService _fiatTransactionService =
      FiatTransactionService();
  final ExchangeService _exchangeService = GetIt.I<ExchangeService>();
  final P2PSettingsService _p2pSettingsService = GetIt.I<P2PSettingsService>();
  final KYCService _kycService = GetIt.I<KYCService>();
  List<Map<String, dynamic>> _fiatWallets = [];
  List<FiatTransaction> _recentTransactions = [];
  String _userCurrency = 'USD';
  double _userCurrencyRate = 1.0;
  String _selectedCurrency = 'USD';
  double _totalBalance = 0.0;
  Map<String, double> _currencyToUsdRate = {};
  Map<String, double> _currencyToUserRate = {};
  int _currentWalletIndex = 0;
  bool _isLoading = true;
  bool _showCreateSheet = false;
  bool _kycChecked = false;
  bool _hasKycAccess = true;
  Map<String, dynamic>? _kycData;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _checkKycLevel();
  }

  Future<void> _checkKycLevel() async {
    try {
      final kycDetails = await _kycService.getUserKYCDetails();
      // You may want to check a specific level or feature, adjust as needed
      final canUseFiat =
          kycDetails.levelDetails.features['canUseFiat'] ?? false;
      if (!canUseFiat) {
        if (!mounted) return;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Go back to previous screen
              return false;
            },
            child: Dialog.fullscreen(
              child: Scaffold(
                backgroundColor:
                    isDark ? SafeJetColors.primaryBackground : Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context); // Go back to previous screen
                    },
                  ),
                  title: Text(
                    'KYC Verification Required',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.verified_user,
                                      color: isDark
                                          ? SafeJetColors.secondaryHighlight
                                          : SafeJetColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Level',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          kycDetails.levelDetails.title ??
                                              'Unverified',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Fiat Wallet Access',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'To access fiat wallet features, you need to complete your KYC verification. This helps us maintain a secure environment for all users.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SafeJetColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SafeJetColors.warning.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: SafeJetColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Verification usually takes less than 24 hours to complete.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const KYCLevelsScreen(),
                              ),
                            );
                            Navigator.pop(context); // Now close the dialog
                            _checkKycLevel(); // Re-check KYC after returning
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.secondaryHighlight,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Complete Verification',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        setState(() {
          _hasKycAccess = false;
          _kycChecked = true;
        });
        return;
      } else {
        setState(() {
          _hasKycAccess = true;
          _kycChecked = true;
        });
        _loadUserSettingsAndWallets();
        _loadRecentTransactions();
      }
    } catch (e) {
      print('Error checking KYC level: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyErrorMessage(e)),
          backgroundColor: SafeJetColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _loadUserSettingsAndWallets() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      // Fetch user preferred currency
      final settings = await _p2pSettingsService.getSettings();
      final userCurrency = settings['currency'] ?? 'USD';
      double userCurrencyRate = 1.0;
      if (userCurrency != 'USD') {
        final rates = await _exchangeService.getRates(userCurrency);
        userCurrencyRate =
            double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
      }
      setState(() {
        _userCurrency = userCurrency;
        _userCurrencyRate = userCurrencyRate;
        _selectedCurrency = 'USD';
      });
      await _loadWalletsAndRates();
    } catch (e) {
      print('Error loading user settings or wallets: $e');
      setState(() {
        _fiatWallets = [];
        _isLoading = false;
        _loadError = getFriendlyErrorMessage(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyErrorMessage(e)),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
  }

  Future<void> _loadWalletsAndRates() async {
    setState(() {
      _loadError = null;
    });
    try {
      final wallets = await _fiatWalletService.getUserFiatWallets();
      setState(() {
        _fiatWallets = wallets;
      });
      await _loadRecentTransactions();
      // Get all unique active wallet currencies
      final activeWallets = wallets
          .where((w) => (w['status'] ?? '').toLowerCase() == 'active')
          .toList();
      final Set<String> walletCurrencies = activeWallets
          .map((w) {
            final c = w['currency'];
            return c is Map ? c['code'] : c;
          })
          .whereType<String>()
          .toSet();
      // Fetch rates for each currency to USD and to user currency
      Map<String, double> toUsd = {};
      Map<String, double> toUser = {};
      for (final code in walletCurrencies) {
        // To USD
        if (code == 'USD') {
          toUsd[code] = 1.0;
        } else {
          final rates = await _exchangeService.getRates(code);
          toUsd[code] =
              double.tryParse(rates['rate']?.toString() ?? '0') ?? 0.0;
        }
        // To user currency
        if (code == _userCurrency) {
          toUser[code] = 1.0;
        } else if (_userCurrency == 'USD') {
          toUser[code] = toUsd[code] ?? 0.0;
        } else {
          final rates = await _exchangeService.getRates(code);
          toUser[code] =
              double.tryParse(rates['rate']?.toString() ?? '0') ?? 0.0;
        }
      }
      setState(() {
        _currencyToUsdRate = toUsd;
        _currencyToUserRate = toUser;
      });
      _updateTotalBalance();
    } catch (e) {
      print('Error loading wallets or rates: $e');
      setState(() {
        _fiatWallets = [];
        _loadError = getFriendlyErrorMessage(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyErrorMessage(e)),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final results = await Future.wait([
        _fiatTransactionService.fetchDepositsPage(page: 1, limit: 10),
        _fiatTransactionService.fetchWithdrawalsPage(page: 1, limit: 10),
        _fiatTransactionService.fetchPurchasesPage(page: 1, limit: 10),
      ]);
      final deposits = results[0].$1;
      final withdrawals = results[1].$1;
      final purchases = results[2].$1;
      final all = [...deposits, ...withdrawals, ...purchases];
      all.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _recentTransactions = all.take(10).toList();
      });
    } catch (e) {
      print('Error loading recent transactions: $e');
      setState(() {
        _recentTransactions = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFriendlyErrorMessage(e)),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
  }

  void _updateTotalBalance() {
    final activeWallets = _fiatWallets
        .where((w) => (w['status'] ?? '').toLowerCase() == 'active')
        .toList();
    double totalUsd = 0.0;
    for (final wallet in activeWallets) {
      final c = wallet['currency'];
      final code = c is Map ? c['code'] : c;
      final balance = double.tryParse(wallet['balance'].toString()) ?? 0.0;
      double rateToUsd;
      if (code == 'USD') {
        rateToUsd = 1.0;
      } else {
        final rawRate = _currencyToUsdRate[code] ?? 1.0;
        rateToUsd = 1 / rawRate;
      }
      final usdValue = balance * rateToUsd;
      print(
          'Wallet: $code, Balance: $balance, RateToUsd: $rateToUsd, USD Value: $usdValue');
      totalUsd += usdValue;
    }
    double total;
    if (_selectedCurrency == 'USD') {
      total = totalUsd;
    } else {
      double selectedRateToUsd;
      if (_selectedCurrency == 'USD') {
        selectedRateToUsd = 1.0;
      } else {
        final rawSelectedRate = _currencyToUsdRate[_selectedCurrency] ?? 1.0;
        selectedRateToUsd = 1 / rawSelectedRate;
      }
      total = totalUsd / selectedRateToUsd;
      print(
          'Converting total USD $totalUsd to ${_selectedCurrency} using rate $selectedRateToUsd: $total');
    }
    print('Final Total: $total');
    setState(() {
      _totalBalance = total;
    });
  }

  void _onCurrencySelected(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
    _updateTotalBalance();
  }

  void _onWalletCreated() async {
    await _loadWalletsAndRates();
  }

  String getCurrencySymbol(String code) {
    // Try to get symbol from the first wallet with this code
    final wallet = _fiatWallets.firstWhere(
      (w) {
        final c = w['currency'];
        final walletCode = c is Map ? c['code'] : c;
        return walletCode == code;
      },
      orElse: () => <String, dynamic>{},
    );
    if (wallet.isNotEmpty) {
      final c = wallet['currency'];
      if (c is Map &&
          c['symbol'] != null &&
          c['symbol'].toString().isNotEmpty) {
        return c['symbol'];
      }
    }
    // Fallback to hardcoded
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_kycChecked) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasKycAccess) {
      // The dialog will already be shown, just return an empty container
      return const SizedBox.shrink();
    }

    // --- Error UI for network/server error ---
    if (!_isLoading && _loadError != null) {
      return Scaffold(
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Fiat',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.08)
                  : Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 64, color: SafeJetColors.error),
                    const SizedBox(height: 18),
                    Text('Unable to Load Wallets',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 10),
                    Text(
                      _loadError ?? 'An unknown error occurred.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: SafeJetColors.secondaryHighlight,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _loadUserSettingsAndWallets();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fiat',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FiatTransactionHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              setState(() => _showCreateSheet = true);
              final isDark = Theme.of(context).brightness == Brightness.dark;
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog.fullscreen(
                  backgroundColor:
                      isDark ? SafeJetColors.primaryBackground : Colors.white,
                  child: FiatWalletCreationFullScreenSheet(
                    existingWalletsStatus: Map.fromEntries(
                      _fiatWallets.map((wallet) {
                        final currency = wallet['currency'];
                        final code = (currency is Map
                                ? currency['code']
                                : currency) as String? ??
                            '';
                        final status =
                            (wallet['status'] as String?)?.toLowerCase() ??
                                'active';
                        return MapEntry(code, status);
                      }),
                    ),
                    onWalletCreated: (_) => _onWalletCreated(),
                  ),
                ),
              );
              setState(() => _showCreateSheet = false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _fiatWallets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.08)
                          : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 40, horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                size: 64,
                                color: SafeJetColors.secondaryHighlight),
                            const SizedBox(height: 18),
                            Text('No Fiat Wallets',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(
                              'You have not created any fiat wallet yet. Fiat wallets let you deposit, withdraw, and buy crypto with your local currency.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Fiat Wallet',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  backgroundColor:
                                      SafeJetColors.secondaryHighlight,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  setState(() => _showCreateSheet = true);
                                  final isDark = Theme.of(context).brightness ==
                                      Brightness.dark;
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Dialog.fullscreen(
                                      backgroundColor: isDark
                                          ? SafeJetColors.primaryBackground
                                          : Colors.white,
                                      child: FiatWalletCreationFullScreenSheet(
                                        existingWalletsStatus: Map.fromEntries(
                                            _fiatWallets.map((w) {
                                          final currencyField = w['currency'];
                                          String code = '';
                                          if (currencyField
                                              is Map<String, dynamic>) {
                                            code = currencyField['code']
                                                    as String? ??
                                                '';
                                          } else if (currencyField is String) {
                                            code = currencyField;
                                          }
                                          final status =
                                              (w['status'] as String?)
                                                      ?.toLowerCase() ??
                                                  'active';
                                          return MapEntry(code, status);
                                        })),
                                        onWalletCreated: (_) =>
                                            _onWalletCreated(),
                                      ),
                                    ),
                                  );
                                  setState(() => _showCreateSheet = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWalletsAndRates,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildBalanceOverview(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildQuickActions(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildFiatWalletsSection(isDark),
                      ),
                      // Add more space between wallet slider and recent transactions
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                      // Recent Transactions Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Transactions',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_recentTransactions.length >= 10)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FiatTransactionHistoryScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            SafeJetColors.secondaryHighlight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 0),
                                        minimumSize: Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        children: [
                                          Text('View All',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: SafeJetColors
                                                  .secondaryHighlight),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                color:
                                    isDark ? Colors.white10 : Colors.grey[100],
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 180,
                                    maxHeight: 320,
                                  ),
                                  width: double.infinity,
                                  child: _recentTransactions.isEmpty
                                      ? Padding(
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
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'You have not made any fiat transactions yet. Your recent activity will appear here.',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: isDark
                                                            ? Colors.white54
                                                            : Colors.black54),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount:
                                              _recentTransactions.length > 10
                                                  ? 10
                                                  : _recentTransactions.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 0),
                                          itemBuilder: (context, index) =>
                                              _buildCompactTransactionCard(
                                            _recentTransactions[index],
                                            isDark,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
    );
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
            // Balance Overview Shimmer
            Container(
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
                          SafeJetColors.lightCardBackground.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                      : SafeJetColors.lightCardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.08)
                        : SafeJetColors.secondaryHighlight.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick Actions Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == 2 ? 0 : 8,
                      ),
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Fiat Wallets Shimmer
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Recent Transactions Shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 20,
                    color: isDark ? Colors.grey[700] : Colors.white,
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    3,
                    (index) => Container(
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOverview(bool isDark) {
    final formattedTotal = NumberFormat('#,##0.00').format(_totalBalance);
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
                  SafeJetColors.lightCardBackground.withOpacity(0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.08)
                : SafeJetColors.secondaryHighlight.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${getCurrencySymbol(_selectedCurrency)}$formattedTotal',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCurrencyChip('USD', isDark),
              if (_userCurrency != 'USD') ...[
                const SizedBox(width: 8),
                _buildCurrencyChip(_userCurrency, isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String currency, bool isDark) {
    final isSelected = _selectedCurrency == currency;
    return GestureDetector(
      onTap: () => _onCurrencySelected(currency),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? SafeJetColors.secondaryHighlight
              : (isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SafeJetColors.secondaryHighlight
                : (isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                    : SafeJetColors.lightCardBorder),
          ),
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

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Deposit',
              Icons.add_circle_outline_rounded,
              SafeJetColors.success,
              isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiatDepositScreen(
                      wallets: _fiatWallets,
                      wallet: null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Withdraw',
              Icons.remove_circle_outline_rounded,
              SafeJetColors.error,
              isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiatWithdrawalScreen(
                      wallets: _fiatWallets,
                      wallet: null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Buy Crypto',
              Icons.currency_bitcoin_rounded,
              SafeJetColors.secondaryHighlight,
              isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiatBuyCryptoScreen(
                      wallets: _fiatWallets,
                      wallet: null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiatWalletsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Fiat Wallets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_fiatWallets.length > 4)
                TextButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          AllWalletsModal(wallets: _fiatWallets),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SafeJetColors.secondaryHighlight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: [
                      Text('View All',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: SafeJetColors.secondaryHighlight),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: FlutterCarousel(
            items: List.generate(
                _fiatWallets.length > 4 ? 4 : _fiatWallets.length, (index) {
              return _buildFiatWalletCard(_fiatWallets[index], isDark, index);
            }),
            options: CarouselOptions(
              height: 200,
              viewportFraction: 0.9,
              enableInfiniteScroll: false,
              enlargeCenterPage: true,
              showIndicator: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentWalletIndex = index;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiatWalletCard(
      Map<String, dynamic> wallet, bool isDark, int cardIndex) {
    // Support both Map and String for currency field for backward compatibility
    final currencyField = wallet['currency'];
    String currency;
    String symbol;
    String? primaryColorHex;
    String? secondaryColorHex;
    if (currencyField is Map<String, dynamic>) {
      currency = currencyField['code'] as String? ?? '';
      symbol = currencyField['symbol'] as String? ?? '';
      primaryColorHex = currencyField['primaryColor'] as String?;
      secondaryColorHex = currencyField['secondaryColor'] as String?;
    } else if (currencyField is String) {
      currency = currencyField;
      symbol = '';
      primaryColorHex = null;
      secondaryColorHex = null;
    } else {
      currency = '';
      symbol = '';
      primaryColorHex = null;
      secondaryColorHex = null;
    }
    // If symbol is still empty, fallback for legacy/test data only
    if (symbol.isEmpty && currency.isNotEmpty) {
      switch (currency.toUpperCase()) {
        case 'USD':
          symbol = '\$24';
          break;
        case 'EUR':
          symbol = '€';
          break;
        case 'NGN':
          symbol = '₦';
          break;
        case 'GBP':
          symbol = '£';
          break;
        default:
          symbol = currency;
      }
    }
    // Use primaryColor and secondaryColor from currency, fallback to defaults
    Color parseColor(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xff')));
      } catch (_) {
        return fallback;
      }
    }

    final primaryColor = parseColor(primaryColorHex, const Color(0xFF1A237E));
    final secondaryColor =
        parseColor(secondaryColorHex, const Color(0xFF0D47A1));
    final balance = double.tryParse(wallet['balance'].toString()) ?? 0.0;
    final pending =
        double.tryParse(wallet['pendingBalance']?.toString() ?? '0') ?? 0.0;
    final frozen = double.tryParse(wallet['frozen']?.toString() ?? '0') ?? 0.0;
    final status = (wallet['status'] as String?)?.toLowerCase() ?? 'active';
    final icon = _getWalletIcon(currency);
    List<Color> gradientColors;
    if (status == 'pending') {
      gradientColors = [
        const Color(0xFFFFC107),
        const Color(0xFFFF9800)
      ]; // yellow/orange
    } else if (status == 'suspended') {
      gradientColors = [Colors.grey.shade600, Colors.grey.shade400];
    } else {
      gradientColors = [primaryColor, secondaryColor];
    }
    Color badgeColor;
    String badgeText;
    if (status == 'pending') {
      badgeColor = const Color(0xFFFFC107);
      badgeText = 'Pending';
    } else if (status == 'suspended') {
      badgeColor = Colors.grey;
      badgeText = 'Suspended';
    } else {
      badgeColor = Colors.green;
      badgeText = 'Active';
    }
    final isClickable = status == 'active';
    return GestureDetector(
      onTap: isClickable
          ? () {
              if (_fiatWallets.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FiatWalletDetailsScreen(
                      wallet: wallet,
                      wallets: _fiatWallets,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Wallets are still loading. Please try again.')),
                );
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Currency symbol (top right)
              Positioned(
                right: 16,
                top: 8,
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Wallet info at the top
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 32, 16, 12), // extra top padding for badge
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 32), // placeholder for alignment
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$symbol${NumberFormat('#,##0.00').format(balance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Always show pending and frozen balances
                    const SizedBox(height: 4),
                    Text(
                      'Pending: $symbol${NumberFormat('#,##0.00').format(pending)}',
                      style: TextStyle(
                        color: Colors.orange[100],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Frozen: $symbol${NumberFormat('#,##0.00').format(frozen)}',
                      style: TextStyle(
                        color: Colors.red[100],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          EnvConfig.appName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
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
              // Indicator always at the bottom
              if (cardIndex == _currentWalletIndex)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _fiatWallets.length > 4 ? 4 : _fiatWallets.length,
                      (i) {
                        final isActive = i == _currentWalletIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 12 : 8,
                          height: isActive ? 12 : 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTransactionCard(FiatTransaction tx, bool isDark) {
    Color statusColor = _getStatusColor(tx);
    IconData typeIcon;
    switch (tx.type) {
      case FiatTransactionType.deposit:
        typeIcon = Icons.add_circle_outline_rounded;
        break;
      case FiatTransactionType.withdraw:
        typeIcon = Icons.remove_circle_outline_rounded;
        break;
      case FiatTransactionType.purchase:
        typeIcon = Icons.currency_bitcoin_rounded;
        break;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.08)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.12)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.type.name.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(tx.date),
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: _getCurrencySymbol(tx.currency))
                    .format(tx.amount),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  IconData _getWalletIcon(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return Icons.attach_money_rounded;
      case 'EUR':
        return Icons.euro_rounded;
      case 'NGN':
        return Icons.currency_pound_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String _getCurrencySymbol(String currency) {
    // Try to get symbol from the first wallet with this code
    final wallet = _fiatWallets.firstWhere(
      (w) {
        final c = w['currency'];
        final walletCode = c is Map ? c['code'] : c;
        return walletCode == currency;
      },
      orElse: () => <String, dynamic>{},
    );
    if (wallet.isNotEmpty) {
      final c = wallet['currency'];
      if (c is Map &&
          c['symbol'] != null &&
          c['symbol'].toString().isNotEmpty) {
        return c['symbol'];
      }
    }
    // Fallback to hardcoded
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }
}

class FiatWalletCreationFullScreenSheet extends StatefulWidget {
  final Map<String, String> existingWalletsStatus;
  final void Function(dynamic) onWalletCreated;
  const FiatWalletCreationFullScreenSheet(
      {Key? key,
      required this.existingWalletsStatus,
      required this.onWalletCreated})
      : super(key: key);

  @override
  State<FiatWalletCreationFullScreenSheet> createState() =>
      _FiatWalletCreationFullScreenSheetState();
}

class _FiatWalletCreationFullScreenSheetState
    extends State<FiatWalletCreationFullScreenSheet> {
  final FiatWalletService _fiatWalletService = GetIt.I<FiatWalletService>();
  List<Map<String, dynamic>> _availableCurrencies = [];
  String? _creatingCurrencyId;
  bool _created = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCurrencies();
  }

  Future<void> _loadAvailableCurrencies() async {
    setState(() => _isLoading = true);
    try {
      final currencies = await _fiatWalletService.getAvailableFiatCurrencies();
      setState(() => _availableCurrencies = currencies);
    } catch (e) {
      print('Error loading available currencies: $e');
      setState(() => _availableCurrencies = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createWallet(String currencyId) async {
    setState(() => _creatingCurrencyId = currencyId);
    try {
      await _fiatWalletService.createFiatWallet(currencyId);
      setState(() => _created = true);
      await Future.delayed(const Duration(milliseconds: 900));
      widget.onWalletCreated(null);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print('Error creating fiat wallet: $e');
      setState(() => _creatingCurrencyId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Debug prints for troubleshooting
    print('DEBUG: _availableCurrencies = \\n');
    for (var c in _availableCurrencies) {
      print('  ' + c.toString());
    }
    print('DEBUG: existingWalletsStatus = ' +
        widget.existingWalletsStatus.toString());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Cancel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: _creatingCurrencyId == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 38,
                              color: SafeJetColors.secondaryHighlight),
                          const SizedBox(height: 10),
                          Text('Add a Fiat Wallet',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              'Choose a currency to create a new wallet. You can only have one wallet per currency.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ..._availableCurrencies.map((c) {
                            final code = c['code'] as String? ?? '';
                            final status = widget.existingWalletsStatus[code];
                            final alreadyCreated = status != null;
                            String statusLabel = '';
                            Color statusColor = Colors.grey;
                            if (status == 'active') {
                              statusLabel = 'Active';
                              statusColor = Colors.green;
                            } else if (status == 'pending') {
                              statusLabel = 'Pending';
                              statusColor = Colors.orange;
                            } else if (status == 'suspended') {
                              statusLabel = 'Suspended';
                              statusColor = Colors.grey;
                            }
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: alreadyCreated ? 0.5 : 1.0,
                              child: GestureDetector(
                                onTap: alreadyCreated
                                    ? null
                                    : () => _createWallet(c['id']),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? SafeJetColors.primaryAccent
                                            .withOpacity(0.1)
                                        : SafeJetColors.lightCardBackground,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                            Icons
                                                .account_balance_wallet_rounded,
                                            color: isDark
                                                ? Colors.white
                                                : SafeJetColors
                                                    .secondaryHighlight,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c['name'],
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              code,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.grey[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (alreadyCreated)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                statusColor.withOpacity(0.18),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.18)
                                                : SafeJetColors
                                                    .secondaryHighlight
                                                    .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Create',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : SafeJetColors
                                                      .secondaryHighlight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      )
                    : _created
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.celebration_rounded,
                                  size: 48, color: Colors.amber),
                              const SizedBox(height: 18),
                              Text('Wallet Created!',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                  'Your new wallet is ready to use. You can now deposit, withdraw, and buy crypto with it.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                  textAlign: TextAlign.center),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: SafeJetColors.secondaryHighlight),
                              const SizedBox(height: 24),
                              Text('Creating your wallet…',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                  "Hang tight! We're setting up your wallet for you. This won't take long.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                  textAlign: TextAlign.center),
                            ],
                          ),
              ),
            ),
    );
  }
}
