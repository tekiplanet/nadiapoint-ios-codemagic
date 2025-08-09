import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'fiat_buy_crypto_confirmation_dialog.dart';
import '../../services/fiat_wallet_service.dart';
import '../../services/wallet_service.dart';
import '../../services/exchange_service.dart';

class FiatBuyCryptoScreen extends StatefulWidget {
  final Map<String, dynamic>? wallet;
  final List<Map<String, dynamic>>? wallets;
  const FiatBuyCryptoScreen({Key? key, this.wallet, this.wallets})
      : super(key: key);

  @override
  State<FiatBuyCryptoScreen> createState() => _FiatBuyCryptoScreenState();
}

class _FiatBuyCryptoScreenState extends State<FiatBuyCryptoScreen> {
  late List<Map<String, dynamic>> _wallets;
  Map<String, dynamic>? _selectedWallet;
  String? _selectedCrypto;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cryptoSearchController = TextEditingController();
  NumberFormat? _numberFormat;
  int _currentWalletIndex = 0;
  double _calculatedFee = 0.0;
  double _cryptoAmount = 0.0;

  List<Map<String, dynamic>> _cryptos = [];
  bool _isLoading = true;
  String? _errorMessage;

  final FiatWalletService _fiatWalletService = FiatWalletService();
  final WalletService _walletService = WalletService();
  final ExchangeService _exchangeService = ExchangeService();

  String? _validationMessage;
  bool _isAmountValid = false;
  bool _listenerAdded = false;

  String _userCurrency = 'USD';
  double _userCurrencyRate = 1.0;
  bool _showInUSD = true;

  double? _selectedCryptoPrice;
  bool _isFetchingPrice = false;

  double _getFee(double amount) {
    // Get the crypto buying fee from the selected wallet's currency
    final currencyField = _selectedWallet?['currency'];
    double feePercentage = 1.2; // Default fee

    print('[DEBUG] _getFee called with amount: $amount');
    print('[DEBUG] _selectedWallet: $_selectedWallet');
    print('[DEBUG] currencyField: $currencyField');

    if (currencyField is Map && currencyField['cryptoBuyingFee'] != null) {
      feePercentage =
          double.tryParse(currencyField['cryptoBuyingFee'].toString()) ?? 1.2;
    }

    final currencyCode =
        currencyField is Map ? currencyField['code'] : 'unknown';
    print(
        '[DEBUG] Crypto buying fee: ${feePercentage}% for currency: $currencyCode');

    return amount * (feePercentage / 100);
  }

  double _getCryptoAmount(String crypto, double fiatAmount) {
    if (_cryptos.isEmpty) return 0.0;
    final cryptoData = _cryptos.firstWhere(
      (c) => c['symbol'] == crypto,
      orElse: () => <String, dynamic>{},
    );
    if (cryptoData.isEmpty) return 0.0;
    final rate = double.tryParse(cryptoData['rate'].toString()) ?? 0.0;
    return fiatAmount > 0 && rate > 0
        ? (fiatAmount - _getFee(fiatAmount)) / rate
        : 0.0;
  }

  void _updateEstimates() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _calculatedFee = _getFee(amount);
      if (_selectedCrypto != null && _cryptos.isNotEmpty) {
        final selectedCryptoData = _cryptos.firstWhere(
          (c) => c['symbol'] == _selectedCrypto,
          orElse: () => <String, dynamic>{},
        );
        if (selectedCryptoData.isNotEmpty) {
          final rate =
              double.tryParse(selectedCryptoData['rate'].toString()) ?? 0.0;
          print(
              '[DEBUG] Using price for $_selectedCrypto: $rate (from tokens list)');
          _cryptoAmount =
              amount > 0 && rate > 0 ? (amount - _getFee(amount)) / rate : 0.0;
        } else {
          print('[DEBUG] Crypto $_selectedCrypto not found in tokens list');
          _cryptoAmount = 0.0;
        }
      } else {
        print('[DEBUG] No crypto selected or tokens list empty');
        _cryptoAmount = 0.0;
      }
    });
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text);
    final fee = _getFee(amount ?? 0.0);
    _calculatedFee = fee;
    final balanceRaw = _selectedWallet?['balance'];
    double balance;
    if (balanceRaw is String) {
      balance = double.tryParse(balanceRaw) ?? 0.0;
    } else if (balanceRaw is num) {
      balance = balanceRaw.toDouble();
    } else {
      balance = 0.0;
    }
    // Get minCryptoConversion from currency
    final currencyField = _selectedWallet?['currency'];
    print('[DEBUG] currencyField: $currencyField');
    double min = 0.0;
    if (currencyField is Map && currencyField['minCryptoConversion'] != null) {
      min = double.tryParse(currencyField['minCryptoConversion'].toString()) ??
          0.0;
    }
    print('[DEBUG] minCryptoConversion from currency: $min');
    final String minText = _numberFormat?.format(min) ?? min.toString();
    if (amount == null || _amountController.text.isEmpty) {
      setState(() {
        _validationMessage = 'Minimum: $minText';
        _isAmountValid = false;
      });
      return;
    }
    if (amount < min) {
      setState(() {
        _validationMessage = 'Amount is below minimum of $minText';
        _isAmountValid = false;
      });
    } else if ((amount + fee) > balance + 1e-6) {
      setState(() {
        _validationMessage = 'Insufficient balance to cover amount and fee.';
        _isAmountValid = false;
      });
    } else {
      setState(() {
        _validationMessage = 'Minimum: $minText';
        _isAmountValid = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserCurrencyAndRates();
  }

  Future<void> _fetchUserCurrencyAndRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch user settings (simulate or use your actual settings service)
      // For now, default to USD if not available
      final settings = {
        'currency': 'USD'
      }; // TODO: Replace with real settings fetch
      final rates =
          await _exchangeService.getRates(settings['currency'] ?? 'USD');
      _userCurrency = settings['currency'] ?? 'USD';
      _userCurrencyRate =
          double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
      await _fetchData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _fiatWalletService.getUserFiatWallets(),
        _walletService
            .getAvailableCoinsWithPrices(), // Use new method that includes currentPrice
      ]);
      final wallets = results[0] as List<Map<String, dynamic>>;
      final coins = results[1] as List<dynamic>;

      // Debug print to see the actual wallet structure
      print('[DEBUG] Raw wallets from API: $wallets');

      // Map wallets to expected structure - preserve the currency object
      _wallets = wallets
          .where((w) =>
              (w['status'] ?? 'active').toString().toLowerCase() == 'active')
          .map((w) {
        final currency = w['currency'];
        print('[DEBUG] Processing wallet: ${w['id']}, currency: $currency');
        return {
          'id': w['id'],
          'currency': currency, // Keep the full currency object as is
          'balance': double.tryParse(w['balance']?.toString() ?? '0.0') ?? 0.0,
          'icon': Icons.account_balance_wallet_rounded,
          'type': w['type'] ?? 'Main Wallet',
        };
      }).toList();

      print('[DEBUG] Mapped wallets: $_wallets');

      // Map cryptos to expected structure for modal (no balance/price)
      _cryptos = coins
          .map((token) {
            String? iconUrl;
            if (token['iconUrl'] != null &&
                token['iconUrl'].toString().isNotEmpty) {
              iconUrl = token['iconUrl'];
            } else if (token['metadata'] != null &&
                token['metadata']['icon'] != null &&
                token['metadata']['icon'].toString().isNotEmpty) {
              iconUrl = token['metadata']['icon'];
            }
            return {
              'symbol': token['symbol'] ?? '',
              'name': token['name'] ?? '',
              'icon': iconUrl,
              'tokenId': token['id'],
              'token': token,
              'rate':
                  token['currentPrice'] ?? 0.0, // Use currentPrice from backend
            };
          })
          .where((c) => c['symbol'] != '')
          .toList();
      // Sort cryptos alphabetically by name
      _cryptos.sort((a, b) => (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase()));
      // Set defaults robustly
      if (_wallets.isNotEmpty && _cryptos.isNotEmpty) {
        _selectedWallet = widget.wallet ?? _wallets.first;
        _selectedCrypto = _cryptos.first['symbol'];
      } else {
        _selectedWallet = null;
        _selectedCrypto = null;
      }
      // Only update estimates and validate if both are set
      if (_selectedWallet != null && _selectedCrypto != null) {
        final currencyField = _selectedWallet!['currency'];
        print('[DEBUG] Selected wallet currency field: $currencyField');

        final currencyCode =
            currencyField is Map ? currencyField['code'] : currencyField;
        print('[DEBUG] Extracted currency code: $currencyCode');

        if (currencyCode != null) {
          setState(() {
            _isLoading = true;
          });
          _exchangeService.getRates(currencyCode).then((rates) {
            final userCurrencyRate =
                double.tryParse(rates['rate']?.toString() ?? '1') ?? 1.0;
            setState(() {
              _selectedWallet = _selectedWallet;
              _currentWalletIndex = _wallets.indexOf(_selectedWallet!);
              _userCurrency = currencyCode;
              _userCurrencyRate = userCurrencyRate;
              _numberFormat = NumberFormat.currency(
                  symbol: currencyField is Map &&
                          currencyField['symbol'] != null &&
                          currencyField['symbol'].toString().isNotEmpty
                      ? currencyField['symbol']
                      : currencyCode);
              _isLoading = false;
            });
            _updateEstimates();
            _validateAmount();
            // Add listener after data is loaded
            if (!_listenerAdded) {
              _amountController.addListener(_onSelectionOrAmountChanged);
              _listenerAdded = true;
            }
          });
        } else {
          _numberFormat = NumberFormat.currency(
              symbol: _selectedWallet != null
                  ? (() {
                      final currencyField = _selectedWallet!['currency'];
                      final currencyCode = currencyField is Map
                          ? currencyField['code']
                          : currencyField;
                      return currencyField is Map &&
                              currencyField['symbol'] != null &&
                              currencyField['symbol'].toString().isNotEmpty
                          ? currencyField['symbol']
                          : currencyCode;
                    })()
                  : '0');
          _currentWalletIndex = _selectedWallet != null
              ? _wallets.indexWhere(
                  (w) => w['currency'] == _selectedWallet!['currency'])
              : 0;
          _updateEstimates();
          _validateAmount();
          // Add listener after data is loaded
          if (!_listenerAdded) {
            _amountController.addListener(_onSelectionOrAmountChanged);
            _listenerAdded = true;
          }
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Error in _fetchData: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }

  void _onSelectionOrAmountChanged() {
    _updateEstimates();
    _validateAmount();
  }

  @override
  void dispose() {
    if (_listenerAdded) {
      _amountController.removeListener(_onSelectionOrAmountChanged);
    }
    _amountController.dispose();
    _cryptoSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_isLoading || _numberFormat == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: const Text('Buy Crypto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: const Text('Buy Crypto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_wallets.isEmpty || _cryptos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          title: const Text('Buy Crypto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Text('No wallets or crypto assets available.'),
        ),
      );
    }
    final selectedCryptoData = _cryptos.firstWhere(
        (c) => c['symbol'] == _selectedCrypto,
        orElse: () => _cryptos.first);
    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: const Text('Buy Crypto',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildHeaderCard(context, isDark),
            ),
            if (widget.wallet == null) ...[
              // Modern Select Wallet Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    final selected =
                        await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return _WalletSelectionModal(
                          wallets: _wallets,
                          selectedWallet: _selectedWallet,
                          theme: theme,
                          isDark: isDark,
                        );
                      },
                    );
                    if (selected != null && selected != _selectedWallet) {
                      final currencyField = selected['currency'];
                      final currencyCode = currencyField is Map
                          ? currencyField['code']
                          : currencyField;
                      setState(() {
                        _isLoading = true;
                        _amountController.text = '';
                        _validationMessage = null;
                        _isAmountValid = false;
                      });
                      _exchangeService.getRates(currencyCode).then((rates) {
                        final userCurrencyRate =
                            double.tryParse(rates['rate']?.toString() ?? '1') ??
                                1.0;
                        setState(() {
                          _selectedWallet = selected;
                          _currentWalletIndex = _wallets.indexOf(selected);
                          _userCurrency = currencyCode;
                          _userCurrencyRate = userCurrencyRate;
                          _numberFormat = NumberFormat.currency(symbol: (() {
                            return currencyField is Map &&
                                    currencyField['symbol'] != null &&
                                    currencyField['symbol']
                                        .toString()
                                        .isNotEmpty
                                ? currencyField['symbol']
                                : currencyCode;
                          })());
                          _isLoading = false;
                        });
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey[200]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.04)
                              : Colors.grey.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        final currencyField = _selectedWallet!['currency'];
                        final currencyCode = currencyField is Map
                            ? currencyField['code']
                            : currencyField;
                        final currencySymbol = currencyField is Map &&
                                currencyField['symbol'] != null &&
                                currencyField['symbol'].toString().isNotEmpty
                            ? currencyField['symbol']
                            : currencyCode;
                        final balanceRaw = _selectedWallet!['balance'];
                        final balance = balanceRaw is String
                            ? double.tryParse(balanceRaw) ?? 0.0
                            : (balanceRaw ?? 0.0);
                        return Row(
                          children: [
                            // Currency symbol in a circle
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: SafeJetColors.secondaryHighlight
                                    .withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  currencySymbol,
                                  style: TextStyle(
                                    color: SafeJetColors.secondaryHighlight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            // Currency code and wallet type
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currencyCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _selectedWallet!['type'] ?? 'Main Wallet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Balance
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencySymbol +
                                      NumberFormat.compact().format(balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: SafeJetColors.secondaryHighlight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 32),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            // Exchange icon already present
            const SizedBox(height: 18),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.13),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SafeJetColors.secondaryHighlight.withOpacity(0.10),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: SafeJetColors.secondaryHighlight,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Modern Select Crypto Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return _CryptoSelectModal(
                        cryptos: _cryptos,
                        selected: _selectedCrypto ?? '',
                        searchController: _cryptoSearchController,
                      );
                    },
                  );
                  if (selected != null && selected != _selectedCrypto) {
                    final currencyField = _selectedWallet?['currency'];
                    final currencyCode = currencyField is Map
                        ? currencyField['code']
                        : currencyField;
                    setState(() {
                      _isLoading = true;
                      _amountController.text = '';
                      _validationMessage = null;
                      _isAmountValid = false;
                    });
                    _exchangeService.getRates(currencyCode).then((rates) {
                      final userCurrencyRate =
                          double.tryParse(rates['rate']?.toString() ?? '1') ??
                              1.0;
                      setState(() {
                        _selectedCrypto = selected;
                        _userCurrency = currencyCode;
                        _userCurrencyRate = userCurrencyRate;
                        _isLoading = false;
                      });
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey[200]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.04)
                            : Colors.grey.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final selectedCryptoData = _cryptos.firstWhere(
                        (c) => c['symbol'] == _selectedCrypto,
                        orElse: () => _cryptos.first,
                      );
                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: SafeJetColors.secondaryHighlight
                                  .withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: (selectedCryptoData['icon'] is String &&
                                      (selectedCryptoData['icon'] as String)
                                          .isNotEmpty)
                                  ? Image.network(
                                      selectedCryptoData['icon'],
                                      width: 26,
                                      height: 26,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                              Icons.currency_bitcoin_rounded,
                                              color: SafeJetColors
                                                  .secondaryHighlight,
                                              size: 26),
                                    )
                                  : Icon(
                                      Icons.currency_bitcoin_rounded,
                                      color: SafeJetColors.secondaryHighlight,
                                      size: 26,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Expanded column for name, symbol, and rate
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedCryptoData['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final usdPrice = double.tryParse(
                                            selectedCryptoData['rate']
                                                .toString()) ??
                                        1.0;
                                    final rateInFiat =
                                        usdPrice * _userCurrencyRate;
                                    final currencyField =
                                        _selectedWallet?['currency'];
                                    final currencyCode = currencyField is Map
                                        ? currencyField['code']
                                        : currencyField;
                                    final currencySymbol = currencyField
                                                is Map &&
                                            currencyField['symbol'] != null &&
                                            currencyField['symbol']
                                                .toString()
                                                .isNotEmpty
                                        ? currencyField['symbol']
                                        : currencyCode;
                                    final formattedRate =
                                        NumberFormat('#,##0.00')
                                            .format(rateInFiat);
                                    return Text(
                                      '1 ${selectedCryptoData['symbol']} = $currencySymbol$formattedRate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black38,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: isDark ? Colors.white : Colors.black,
                              size: 32),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Amount input section (restored if missing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final currencyField = _selectedWallet!['currency'];
                  final currencyCode = currencyField is Map
                      ? currencyField['code']
                      : currencyField;
                  final currencySymbol = currencyField is Map &&
                          currencyField['symbol'] != null &&
                          currencyField['symbol'].toString().isNotEmpty
                      ? currencyField['symbol']
                      : currencyCode;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Modern card-like input
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  isDark ? Colors.white24 : Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.03)
                                  : Colors.grey.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 14, right: 6),
                              child: Text(
                                currencySymbol,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: SafeJetColors.secondaryHighlight,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter amount',
                                  hintStyle: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
                                    color: Colors.grey[500],
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 0),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Always parse balance as double
                                var balanceRaw = _selectedWallet?['balance'];
                                print('[DEBUG][MAX] balanceRaw: $balanceRaw');
                                double balance;
                                if (balanceRaw is String) {
                                  balance = double.tryParse(balanceRaw) ?? 0.0;
                                } else if (balanceRaw is num) {
                                  balance = balanceRaw.toDouble();
                                } else {
                                  balance = 0.0;
                                }
                                print('[DEBUG][MAX] parsed balance: $balance');

                                final currencyField =
                                    _selectedWallet?['currency'];
                                double feePercentage = 1.2; // Default fee
                                if (currencyField is Map &&
                                    currencyField['cryptoBuyingFee'] != null) {
                                  feePercentage = double.tryParse(
                                          currencyField['cryptoBuyingFee']
                                              .toString()) ??
                                      1.2;
                                }
                                print(
                                    '[DEBUG][MAX] feePercentage: $feePercentage');

                                // Calculate max amount: amount + (amount * fee%) = balance => amount = balance / (1 + fee%/100)
                                double maxAmount =
                                    balance / (1 + (feePercentage / 100));
                                print(
                                    '[DEBUG][MAX] calculated maxAmount before min check: $maxAmount');

                                // Get minCryptoConversion
                                double min = 0.0;
                                if (currencyField is Map &&
                                    currencyField['minCryptoConversion'] !=
                                        null) {
                                  min = double.tryParse(
                                          currencyField['minCryptoConversion']
                                              .toString()) ??
                                      0.0;
                                }
                                print('[DEBUG][MAX] minCryptoConversion: $min');

                                // If maxAmount is below min, set to min
                                if (maxAmount < min) {
                                  maxAmount = min;
                                  print(
                                      '[DEBUG][MAX] maxAmount was below min, set to min: $maxAmount');
                                }

                                // Round DOWN to 2 decimals
                                double maxAmountRounded =
                                    (maxAmount * 100).floorToDouble() / 100;
                                _amountController.text =
                                    maxAmountRounded.toStringAsFixed(2);
                                print(
                                    '[DEBUG][MAX] final amount set in input: ${_amountController.text}');
                                _updateEstimates();
                                _validateAmount();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0),
                                minimumSize: Size(0, 36),
                              ),
                              child: const Text('Max',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: SafeJetColors.secondaryHighlight,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Always show the limit/validation label
                      Builder(
                        builder: (context) {
                          String? label = _validationMessage;
                          bool isValid = _isAmountValid;
                          if (label == null || label.isEmpty) {
                            // Compute default limits hint
                            double balance = _selectedWallet?['balance'] ?? 0.0;
                            double min = balance > 0 ? 10.0 : 0.0;
                            final minText =
                                _numberFormat?.format(min) ?? min.toString();
                            label = 'Minimum: $minText';
                            isValid = false;
                          }
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isValid
                                  ? SafeJetColors.success.withOpacity(0.13)
                                  : SafeJetColors.error.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isValid
                                    ? SafeJetColors.success
                                    : SafeJetColors.error,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  isValid
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.info_outline_rounded,
                                  color: isValid
                                      ? SafeJetColors.success
                                      : SafeJetColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label!,
                                    style: TextStyle(
                                      color: isValid
                                          ? SafeJetColors.success
                                          : SafeJetColors.error,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final selectedCryptoData = _cryptos.firstWhere(
                    (c) => c['symbol'] == _selectedCrypto,
                    orElse: () => _cryptos.first,
                  );
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final fee = _getFee(amount);
                  final usdPrice =
                      double.tryParse(selectedCryptoData['rate'].toString()) ??
                          1.0;
                  final rateInFiat = usdPrice * _userCurrencyRate;
                  final cryptoAmount = (amount > 0 && rateInFiat > 0)
                      ? (amount - fee) / rateInFiat
                      : 0.0;
                  print('[DEBUG][SUMMARY] amount: '
                      '[33m$amount[0m, fee: [33m$fee[0m, usdPrice: [33m$usdPrice[0m, rateInFiat: [33m$rateInFiat[0m, cryptoAmount: [32m$cryptoAmount[0m');
                  final cryptoSymbol = selectedCryptoData['symbol'] ?? '';
                  final cryptoName = selectedCryptoData['name'] ?? '';
                  final icon = selectedCryptoData['icon'] ??
                      Icons.currency_bitcoin_rounded;
                  final fiatSymbol = _numberFormat?.currencySymbol ?? '';
                  final walletType = _selectedWallet?['type'] ?? 'Main Wallet';
                  final currencyField = _selectedWallet?['currency'];
                  final currencyCode = currencyField is Map
                      ? currencyField['code']
                      : currencyField;
                  final currencySymbol = currencyField is Map &&
                          currencyField['symbol'] != null &&
                          currencyField['symbol'].toString().isNotEmpty
                      ? currencyField['symbol']
                      : currencyCode;
                  final currencyFormatter = NumberFormat('#,##0.00');
                  String walletCode = '';
                  if (_selectedWallet?['currency'] is Map) {
                    walletCode = _selectedWallet?['currency']['code'] ?? '';
                  } else {
                    walletCode = _selectedWallet?['currency']?.toString() ?? '';
                  }
                  final summary = {
                    'icon': selectedCryptoData['icon'],
                    'crypto': _selectedCrypto ?? '',
                    'cryptoName': selectedCryptoData['name'],
                    'cryptoAmount':
                        double.tryParse(cryptoAmount.toString()) ?? 0.0,
                    'fiatSymbol': _numberFormat?.currencySymbol ?? '',
                    'fiatAmount': double.tryParse(amount.toString()) ?? 0.0,
                    'fiatAmountFormatted': currencyFormatter.format(amount),
                    'wallet': walletCode,
                    'walletType': _selectedWallet?['type'] ?? 'Main Wallet',
                    'fee': double.tryParse(fee.toString()) ?? 0.0,
                    'feeFormatted': currencyFormatter.format(fee),
                    'rate': double.tryParse(
                            selectedCryptoData['rate'].toString()) ??
                        0.0,
                    'rateInFiat': rateInFiat,
                    'rateInFiatFormatted': currencyFormatter.format(rateInFiat),
                    'fiatWalletId': _selectedWallet?['id'],
                    'tokenId': selectedCryptoData['tokenId'],
                  };

                  // Debug logging for tokenId
                  print('[DEBUG] selectedCryptoData: $selectedCryptoData');
                  print(
                      '[DEBUG] tokenId from selectedCryptoData: ${selectedCryptoData['tokenId']}');
                  print('[DEBUG] summary tokenId: ${summary['tokenId']}');
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SafeJetColors.secondaryHighlight.withOpacity(0.15),
                          SafeJetColors.secondaryHighlight.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            SafeJetColors.secondaryHighlight.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row with Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SafeJetColors.secondaryHighlight
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: (icon is String && icon.isNotEmpty)
                                  ? Image.network(
                                      icon,
                                      width: 20,
                                      height: 20,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                              Icons.currency_bitcoin_rounded,
                                              color: SafeJetColors
                                                  .secondaryHighlight,
                                              size: 20),
                                    )
                                  : Icon(
                                      Icons.currency_bitcoin_rounded,
                                      color: SafeJetColors.secondaryHighlight,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$cryptoName ($cryptoSymbol)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total to Receive',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: SafeJetColors.secondaryHighlight
                                .withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              cryptoAmount > 0
                                  ? cryptoAmount.toStringAsFixed(8)
                                  : '--',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 34,
                                color: SafeJetColors.secondaryHighlight,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              cryptoSymbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: SafeJetColors.secondaryHighlight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(
                            color: SafeJetColors.secondaryHighlight
                                .withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              '$fiatSymbol${currencyFormatter.format(amount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fee',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            Text(
                              '$fiatSymbol${currencyFormatter.format(fee)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white24
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                walletType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white24
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                '$cryptoName ($cryptoSymbol)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              backgroundColor: SafeJetColors.secondaryHighlight,
              elevation: 2,
              alignment: Alignment.center,
            ),
            onPressed: (_selectedCrypto == null ||
                    _amountController.text.isEmpty ||
                    double.tryParse(_amountController.text) == null ||
                    !_isAmountValid)
                ? null
                : () async {
                    final selectedCryptoData = _cryptos.firstWhere(
                        (c) => c['symbol'] == _selectedCrypto,
                        orElse: () => _cryptos.first);
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final fee = _getFee(amount);
                    final usdPrice = double.tryParse(
                            selectedCryptoData['rate'].toString()) ??
                        1.0;
                    final rateInFiat = usdPrice * _userCurrencyRate;
                    final cryptoAmount = (amount > 0 && rateInFiat > 0)
                        ? (amount - fee) / rateInFiat
                        : 0.0;
                    String walletCode = '';
                    if (_selectedWallet?['currency'] is Map) {
                      walletCode = _selectedWallet?['currency']['code'] ?? '';
                    } else {
                      walletCode =
                          _selectedWallet?['currency']?.toString() ?? '';
                    }
                    final currencyFormatter = NumberFormat('#,##0.00');
                    final summary = {
                      'icon': selectedCryptoData['icon'],
                      'crypto': _selectedCrypto ?? '',
                      'cryptoName': selectedCryptoData['name'],
                      'cryptoAmount':
                          double.tryParse(cryptoAmount.toString()) ?? 0.0,
                      'fiatSymbol': _numberFormat?.currencySymbol ?? '',
                      'fiatAmount': double.tryParse(amount.toString()) ?? 0.0,
                      'fiatAmountFormatted': currencyFormatter.format(amount),
                      'wallet': walletCode,
                      'walletType': _selectedWallet?['type'] ?? 'Main Wallet',
                      'fee': double.tryParse(fee.toString()) ?? 0.0,
                      'feeFormatted': currencyFormatter.format(fee),
                      'rate': double.tryParse(
                              selectedCryptoData['rate'].toString()) ??
                          0.0,
                      'rateInFiat': rateInFiat,
                      'rateInFiatFormatted':
                          currencyFormatter.format(rateInFiat),
                      'fiatWalletId': _selectedWallet?['id'],
                      'tokenId': selectedCryptoData['tokenId'],
                    };
                    await FiatBuyCryptoConfirmationDialog.show(
                      context,
                      summary: summary,
                      onConfirm: () {
                        // Refresh data after successful purchase
                        _fetchData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Crypto purchase completed successfully!')),
                        );
                      },
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Buy',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    size: 20, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    final wallet = _selectedWallet!;
    final currencyData = wallet['currency'];
    final currencyCode = (currencyData is Map)
        ? currencyData['code']
        : currencyData as String? ?? '';
    var balanceRaw = wallet['balance'];
    double balance;
    if (balanceRaw is String) {
      balance = double.tryParse(balanceRaw) ?? 0.0;
    } else if (balanceRaw is num) {
      balance = balanceRaw.toDouble();
    } else {
      balance = 0.0;
    }
    final icon = wallet['icon'] ?? Icons.account_balance_wallet_rounded;
    // Use primary/secondary color from wallet/currency if available
    Color? primaryColor;
    Color? secondaryColor;
    String? primaryColorHex;
    String? secondaryColorHex;
    if (currencyData is Map) {
      primaryColorHex = currencyData['primaryColor'] as String?;
      secondaryColorHex = currencyData['secondaryColor'] as String?;
    }
    if (wallet['primaryColor'] != null && wallet['secondaryColor'] != null) {
      try {
        primaryColor = Color(int.parse(
            wallet['primaryColor'].toString().replaceAll('#', '0xff')));
        secondaryColor = Color(int.parse(
            wallet['secondaryColor'].toString().replaceAll('#', '0xff')));
      } catch (_) {}
    } else if (primaryColorHex != null && secondaryColorHex != null) {
      try {
        primaryColor =
            Color(int.parse(primaryColorHex.replaceAll('#', '0xff')));
        secondaryColor =
            Color(int.parse(secondaryColorHex.replaceAll('#', '0xff')));
      } catch (_) {}
    }
    List<Color> gradientColors;
    if (primaryColor != null && secondaryColor != null) {
      gradientColors = [primaryColor, secondaryColor];
    } else {
      switch (currencyCode) {
        case 'USD':
          gradientColors = [const Color(0xFF1A237E), const Color(0xFF0D47A1)];
          break;
        case 'EUR':
          gradientColors = [const Color(0xFF004D40), const Color(0xFF00695C)];
          break;
        case 'NGN':
          gradientColors = [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];
          break;
        case 'GBP':
          gradientColors = [const Color(0xFF283593), const Color(0xFF1565C0)];
          break;
        default:
          gradientColors = [const Color(0xFF1A237E), const Color(0xFF0D47A1)];
      }
    }
    // Prefer symbol from backend if available
    String symbol = (currencyData is Map &&
            currencyData['symbol'] != null &&
            currencyData['symbol'].toString().isNotEmpty)
        ? currencyData['symbol']
        : currencyCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left column: Icon+Currency and badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      currencyCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Buy with',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right column: Balance and Available Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ((_numberFormat?.format(balance)) ?? balance.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
}

class _CryptoSelectModal extends StatefulWidget {
  final List<Map<String, dynamic>> cryptos;
  final String selected;
  final TextEditingController searchController;
  const _CryptoSelectModal(
      {required this.cryptos,
      required this.selected,
      required this.searchController});

  @override
  State<_CryptoSelectModal> createState() => _CryptoSelectModalState();
}

class _CryptoSelectModalState extends State<_CryptoSelectModal> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    widget.searchController.clear();
    widget.searchController.addListener(() {
      setState(() {
        _search = widget.searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = widget.cryptos.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final symbol = (c['symbol'] as String).toLowerCase();
      return _search.isEmpty ||
          name.contains(_search) ||
          symbol.contains(_search);
    }).toList();
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: isDark ? SafeJetColors.primaryBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Search crypto',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey[300]!),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length.toInt(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final isSelected = c['symbol'] == widget.selected;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(c['symbol']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SafeJetColors.secondaryHighlight
                                .withOpacity(isDark ? 0.18 : 0.13)
                            : (isDark ? Colors.white10 : Colors.white),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: SafeJetColors.secondaryHighlight
                                      .withOpacity(0.08),
                                  blurRadius: 7,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [],
                        border: Border.all(
                          color: isSelected
                              ? SafeJetColors.secondaryHighlight
                              : (isDark ? Colors.white24 : Colors.grey[200]!),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: SafeJetColors.secondaryHighlight
                                  .withOpacity(0.13),
                              shape: BoxShape.circle,
                            ),
                            child: (c['icon'] is String &&
                                    (c['icon'] as String).isNotEmpty)
                                ? Image.network(
                                    c['icon'],
                                    width: 20,
                                    height: 20,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.currency_bitcoin_rounded,
                                            color: SafeJetColors
                                                .secondaryHighlight,
                                            size: 20),
                                  )
                                : Icon(
                                    Icons.currency_bitcoin_rounded,
                                    color: SafeJetColors.secondaryHighlight,
                                    size: 20,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name'],
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: SafeJetColors.secondaryHighlight,
                                size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WalletSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selectedWallet;
  final ThemeData theme;
  final bool isDark;
  const _WalletSelectionModal({
    required this.wallets,
    required this.selectedWallet,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_WalletSelectionModal> createState() => _WalletSelectionModalState();
}

class _WalletSelectionModalState extends State<_WalletSelectionModal> {
  String _search = '';
  late List<Map<String, dynamic>> _filteredWallets;

  @override
  void initState() {
    super.initState();
    _filteredWallets = widget.wallets;
  }

  void _filterWallets(String query) {
    setState(() {
      _search = query;
      _filteredWallets = widget.wallets.where((wallet) {
        final currencyField = wallet['currency'];
        final currency =
            currencyField is Map ? currencyField['code'] : currencyField;
        final type = wallet['type'] ?? '';
        final searchLower = query.toLowerCase();
        return currency.toString().toLowerCase().contains(searchLower) ||
            type.toString().toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final theme = widget.theme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? SafeJetColors.primaryBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  onChanged: _filterWallets,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search wallets',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey[100],
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filteredWallets.isEmpty
                    ? Center(
                        child: Text(
                          'No wallets found',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _filteredWallets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final wallet = _filteredWallets[index];
                          final currencyField = wallet['currency'];
                          final currencyCode = currencyField is Map
                              ? currencyField['code']
                              : currencyField;
                          final currencySymbol = currencyField is Map &&
                                  currencyField['symbol'] != null &&
                                  currencyField['symbol'].toString().isNotEmpty
                              ? currencyField['symbol']
                              : currencyCode;
                          // Debug print for wallet and symbol
                          print(
                              'WALLET DEBUG: wallet=$wallet, currencySymbol=$currencySymbol');
                          var balanceRaw = wallet['balance'];
                          double balance;
                          if (balanceRaw is String) {
                            balance = double.tryParse(balanceRaw) ?? 0.0;
                          } else if (balanceRaw is num) {
                            balance = balanceRaw.toDouble();
                          } else {
                            balance = 0.0;
                          }
                          final isSelected = widget.selectedWallet == wallet;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context, wallet),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SafeJetColors.secondaryHighlight
                                        .withOpacity(0.13)
                                    : (isDark ? Colors.white10 : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? SafeJetColors.secondaryHighlight
                                      : (isDark
                                          ? Colors.white24
                                          : Colors.grey[300]!),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: SafeJetColors.secondaryHighlight
                                          .withOpacity(0.10),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Currency symbol in a circle
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: SafeJetColors.secondaryHighlight
                                          .withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        currencySymbol,
                                        style: TextStyle(
                                          color:
                                              SafeJetColors.secondaryHighlight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Currency code and wallet type
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        currencyCode,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        wallet['type'] ?? 'Main Wallet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Balance
                                  Text(
                                    currencySymbol +
                                        NumberFormat.compact().format(balance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: SafeJetColors.secondaryHighlight,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 10),
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.black, size: 22),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
