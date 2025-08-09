import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../services/p2p_service.dart';
import '../../models/kyc_level.dart';
import '../../screens/settings/kyc_levels_screen.dart';
import 'package:shimmer/shimmer.dart';

class P2PCreateOfferScreen extends StatefulWidget {
  final Map<String, dynamic>? offer; // This is for editing existing offers
  final Map<String, dynamic>? selectedToken;
  final bool isBuyOffer;

  const P2PCreateOfferScreen({
    super.key,
    this.offer,
    this.selectedToken,
    required this.isBuyOffer,
  });

  @override
  State<P2PCreateOfferScreen> createState() => _P2PCreateOfferScreenState();
}

class _P2PCreateOfferScreenState extends State<P2PCreateOfferScreen> {
  final _p2pService = GetIt.I<P2PService>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableAssets = [];
  bool _isBuyOffer = true;

  // Initialize with empty strings instead of using late
  String _selectedCrypto = '';
  String _selectedCurrency = '';
  String _userCurrency = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  List<String> _selectedPaymentMethods = [];
  double? _marketPrice;
  bool _isPriceLoading = false;

  List<Map<String, dynamic>> _availablePaymentMethods = [];
  bool _isLoadingPaymentMethods = false;

  String _selectedPriceType = 'fixed'; // 'fixed' or 'percentage'
  final _priceDeltaController = TextEditingController();

  final List<Map<String, dynamic>> _availablePaymentMethodsList = [
    {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'details': {'account': '', 'bank': '', 'name': ''},
    },
    {
      'name': 'PayPal',
      'icon': Icons.payment,
      'details': {'email': ''},
    },
    {
      'name': 'Cash App',
      'icon': Icons.attach_money,
      'details': {'cashtag': ''},
    },
    {
      'name': 'Wise',
      'icon': Icons.currency_exchange,
      'details': {'email': ''},
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredAssets = [];

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isBuyOffer = widget.isBuyOffer;
    _selectedCrypto = widget.selectedToken?['symbol'] ?? '';

    if (widget.offer != null) {
      _isBuyOffer = widget.offer!['type'] == 'buy';
      _selectedCrypto = widget.offer!['token']['symbol'] ?? '';
      _amountController.text = widget.offer!['amount'].toString();
      _termsController.text = widget.offer!['terms'] ?? '';
      _selectedPaymentMethods = (widget.offer!['paymentMethods'] as List)
          .map((m) => m['typeId'].toString())
          .toList();

      // Set min/max amounts from metadata
      final metadata = widget.offer!['metadata'] as Map<String, dynamic>?;
      if (metadata != null) {
        _minAmountController.text = metadata['minAmount']?.toString() ?? '';
        _maxAmountController.text = metadata['maxAmount']?.toString() ?? '';
      }
      _selectedPriceType = widget.offer!['priceType'] ?? 'fixed';
      _priceDeltaController.text =
          widget.offer!['priceDelta']?.toString() ?? '';
    }
    _loadInitialData();
    _checkKycLevel();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load trader settings first to get user currency
      final settings = await _p2pService.getTraderSettings();
      _userCurrency = settings['currency'];
      _selectedCurrency = _userCurrency; // Use user's preferred currency

      // Load available assets
      await _loadAssets();

      // If no crypto was selected, use first available
      if (_selectedCrypto.isEmpty && _availableAssets.isNotEmpty) {
        _selectedCrypto = _availableAssets[0]['symbol'];
      }

      // Load market price
      await _updateMarketPrice();

      // Load payment methods
      await _loadPaymentMethods();
    } catch (e) {
      print('Error in _loadInitialData');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final assets = await _p2pService.getAvailableAssets(_isBuyOffer);
      print('DEBUG: P2P Available Assets: ' +
          assets
              .map((a) => {
                    'symbol': a['symbol'],
                    'fundingBalance': a['fundingBalance']
                  })
              .toList()
              .toString());
      setState(() {
        _availableAssets = assets;
        if (widget.offer == null && assets.isNotEmpty) {
          _selectedCrypto = assets[0]['symbol'];
          _updateMarketPrice();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMarketPrice() async {
    if (_selectedCrypto.isEmpty) return;

    print('Updating market price for $_selectedCrypto in $_userCurrency');
    setState(() => _isPriceLoading = true);
    try {
      final price =
          await _p2pService.getMarketPrice(_selectedCrypto, _userCurrency);
      print('Received market price: $price');
      setState(() {
        _marketPrice = price;
        // Format price with commas and proper decimals
        // _priceController.text = price.toStringAsFixed(2).replaceAllMapped(
        //   RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        //   (Match m) => '${m[1]},'
        // );
      });
    } catch (e) {
      print('Error loading market price');
    } finally {
      setState(() => _isPriceLoading = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoadingPaymentMethods = true);
    try {
      final methods = await _p2pService.getPaymentMethods(_isBuyOffer);
      setState(() => _availablePaymentMethods = methods);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  Future<void> _checkKycLevel() async {
    try {
      final kycData = await _p2pService.getUserKycLevel();
      if (!(kycData['features']['canUseP2P'] ?? false)) {
        if (!mounted) return;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
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
                      Navigator.pop(context); // Go back to P2P screen
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
                                          kycData['title'] ?? 'Unverified',
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
                              'P2P Trading Access',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'To access P2P trading features, you need to complete your KYC verification. This helps us maintain a secure trading environment for all users.',
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Pop dialog
                                Navigator.pop(context); // Go back to P2P screen
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Go Back',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Pop dialog
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const KYCLevelsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    SafeJetColors.secondaryHighlight,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Start Verification',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
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
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
      Navigator.pop(context); // Keep this navigation for error cases
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _termsController.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _priceDeltaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: P2PAppBar(
          title: widget.offer != null ? 'Edit Offer' : 'Create Offer',
          hasNotification: false,
          onThemeToggle: () {
            themeProvider.toggleTheme();
          },
        ),
        body: _buildCreateOfferShimmer(isDark),
      );
    }

    return Scaffold(
      appBar: P2PAppBar(
        title: widget.offer != null ? 'Edit Offer' : 'Create Offer',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOfferTypeSelector(isDark),
                  const SizedBox(height: 24),
                  _buildCryptoSelector(isDark),
                  const SizedBox(height: 24),
                  _buildAmountInput(isDark),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price Setting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.info_outline,
                                size: 20,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog.fullscreen(
                                    child: Builder(
                                      builder: (context) {
                                        final isDark = Theme.of(context).brightness == Brightness.dark;
                                        return Scaffold(
                                          backgroundColor: isDark
                                              ? SafeJetColors.primaryBackground
                                              : SafeJetColors.lightBackground,
                                          appBar: AppBar(
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                            leading: IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                            ),
                                            title: Text(
                                              'How Price Settings Work',
                                              style: TextStyle(
                                                color: isDark ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          body: SingleChildScrollView(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'You can set your offer price as either a fixed amount or a percentage above or below the current market price.',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: isDark ? Colors.white : Colors.black),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  '• Fixed Amount:',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : Colors.black),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Set your offer price as a fixed amount above or below the market price.\n"
                                                  "Example (Buy): If market price is 1000 USD and you set a price difference of 10 USD, your buy price will be 990 USD.\n"
                                                  'Example (Sell): If market price is 1000 USD and you set a price difference of 10 USD, your sell price will be 1010 USD.',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDark ? Colors.grey[300] : Colors.grey[800]),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '• Percentage:',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : Colors.black),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Set your offer price as a percentage above or below the market price.\n'
                                                  'Example (Buy): If market price is 1000 USD and you set -2%, your buy price will be 980 USD.\n'
                                                  'Example (Sell): If market price is 1000 USD and you set +2%, your sell price will be 1020 USD.',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDark ? Colors.grey[300] : Colors.grey[800]),
                                                ),
                                              ],
                                            ),
                                          ),
                                          bottomNavigationBar: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
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
                                                  'Close',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String>(
                                value: _selectedPriceType,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                                dropdownColor: isDark
                                    ? SafeJetColors.primaryBackground
                                    : Colors.white,
                                items: [
                                  DropdownMenuItem(
                                    value: 'fixed',
                                    child: Text(
                                      'Fixed Amount',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'percentage',
                                    child: Text(
                                      'Percentage',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriceType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _priceDeltaController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: _selectedPriceType == 'fixed'
                                  ? 'Price Difference'
                                  : 'Price Percentage',
                              labelStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              suffixText: _selectedPriceType == 'percentage'
                                  ? '%'
                                  : _selectedCurrency,
                              suffixStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              helperText: _marketPrice != null
                                  ? 'Market Price: ${_marketPrice!.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} $_selectedCurrency'
                                  : _isPriceLoading
                                      ? 'Loading market price...'
                                      : null,
                              helperStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _minAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Minimum Order Amount',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        suffixText: _selectedCrypto,
                        suffixStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _maxAmountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Maximum Order Amount',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        suffixText: _selectedCrypto,
                        suffixStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPaymentMethods(isDark),
                  const SizedBox(height: 24),
                  _buildTermsInput(isDark),
                ],
              ),
            ),
          ),
          _buildBottomActions(isDark),
        ],
      ),
    );
  }

  Widget _buildOfferTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleOfferType(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _isBuyOffer ? SafeJetColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Buy',
                  style: TextStyle(
                    color: _isBuyOffer
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleOfferType(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !_isBuyOffer ? SafeJetColors.error : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sell',
                  style: TextStyle(
                    color: !_isBuyOffer
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOfferType() {
    setState(() {
      _isBuyOffer = !_isBuyOffer;
      _selectedPaymentMethods.clear(); // Clear selected methods
    });
    _loadAssets(); // Keep these outside setState
    _loadPaymentMethods(); // Keep these outside setState
  }

  Widget _buildCryptoSelector(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_availableAssets.isEmpty) {
      return Center(
        child: Text(
          'No assets available',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    final selectedAsset = _availableAssets.firstWhere(
      (asset) => asset['symbol'] == _selectedCrypto,
      orElse: () => _availableAssets.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCryptoSelector(isDark),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  selectedAsset['symbol'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCryptoSelector(bool isDark) {
    _filteredAssets = _availableAssets;
    _searchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? SafeJetColors.darkGradientStart : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Asset',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search assets...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (query) {
                setState(() {
                  _filteredAssets = _availableAssets.where((asset) {
                    final symbol = asset['symbol'].toString().toLowerCase();
                    final name = asset['name'].toString().toLowerCase();
                    return symbol.contains(query.toLowerCase()) ||
                        name.contains(query.toLowerCase());
                  }).toList();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredAssets.length,
                itemBuilder: (context, index) {
                  final asset = _filteredAssets[index];
                  final isSelected = asset['symbol'] == _selectedCrypto;

                  return ListTile(
                    onTap: () {
                      setState(() => _selectedCrypto = asset['symbol']);
                      _updateMarketPrice();
                      Navigator.pop(context);
                    },
                    leading: Image.network(
                      asset['metadata']['icon'],
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error),
                    ),
                    title: Text(
                      asset['name'],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: !_isBuyOffer && asset['fundingBalance'] != null
                        ? Text(
                            'Balance: ${asset['fundingBalance'].toStringAsFixed(6)} ${asset['symbol']}',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: _isBuyOffer
                                ? SafeJetColors.success
                                : SafeJetColors.error,
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    // Get balance for the selected crypto
    final selectedAsset = _availableAssets.firstWhere(
      (asset) => asset['symbol'] == _selectedCrypto,
      orElse: () => {'fundingBalance': '0'},
    );
    final balance = !_isBuyOffer
        ? double.tryParse(selectedAsset['fundingBalance']?.toString() ?? '0') ??
            0
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount',
              style: TextStyle(
                color: isDark
                    ? Colors.grey[400]
                    : SafeJetColors.lightTextSecondary,
              ),
            ),
            if (!_isBuyOffer) ...[
              const SizedBox(width: 8),
              Text(
                'Available: ${selectedAsset['fundingBalance']?.toString() ?? '0'} $_selectedCrypto',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter amount',
            suffixText: _selectedCrypto,
            errorText: !_isBuyOffer &&
                    _amountController.text.isNotEmpty &&
                    (double.tryParse(_amountController.text) ?? 0) >
                        (double.tryParse(
                                selectedAsset['fundingBalance']?.toString() ??
                                    '0') ??
                            0)
                ? 'Insufficient balance'
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            if (!_isBuyOffer && value.isNotEmpty) {
              final amount = double.tryParse(value) ?? 0;
              if (amount >
                  (double.tryParse(
                          selectedAsset['fundingBalance']?.toString() ?? '0') ??
                      0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Amount cannot exceed available balance'),
                    backgroundColor: SafeJetColors.error,
                  ),
                );
              }
            }
            setState(() {}); // Trigger rebuild to update error text
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethods(bool isDark) {
    if (_isLoadingPaymentMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (_availablePaymentMethods.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isBuyOffer
                    ? 'No payment methods configured. Please add payment methods in your profile.'
                    : 'No payment methods available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePaymentMethods.map((method) {
              // Get the correct icon and name based on whether it's a buy or sell offer
              final String icon = _isBuyOffer
                  ? method['icon']
                  : method['paymentMethodType']['icon'];
              final String name = _isBuyOffer
                  ? method['name']
                  : '${method['name']} (${method['paymentMethodType']['name']})';
              final String id = method['id'];

              final isSelected = _selectedPaymentMethods.contains(id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPaymentMethods.remove(id);
                    } else {
                      _selectedPaymentMethods.add(id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (_isBuyOffer
                                ? SafeJetColors.success
                                : SafeJetColors.error)
                            .withOpacity(0.1)
                        : isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? (_isBuyOffer
                              ? SafeJetColors.success
                              : SafeJetColors.error)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForName(icon),
                        size: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTermsInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Instructions',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _termsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter your payment instructions and terms...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: _handleCreateOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isBuyOffer ? SafeJetColors.success : SafeJetColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(_isBuyOffer ? 'Create Buy Offer' : 'Create Sell Offer'),
          ),
        ),
      ),
    );
  }

  void _handleCreateOffer() async {
    if (_selectedPaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one payment method'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    // Check balance for sell offers
    if (!_isBuyOffer) {
      final selectedAsset = _availableAssets.firstWhere(
        (asset) => asset['symbol'] == _selectedCrypto,
        orElse: () => {'fundingBalance': '0'},
      );
      final balance =
          double.tryParse(selectedAsset['fundingBalance']?.toString() ?? '0') ??
              0;

      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount > balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance'),
            backgroundColor: SafeJetColors.error,
          ),
        );
        return;
      }
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final actualAmount = double.tryParse(_amountController.text);
    if (actualAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (_minAmountController.text.isEmpty ||
        _maxAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum and maximum amounts are required'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final minAmount = double.tryParse(_minAmountController.text);
    final maxAmount = double.tryParse(_maxAmountController.text);

    if (minAmount == null || maxAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid minimum and maximum amounts'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (minAmount > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum amount cannot be greater than maximum amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (minAmount > actualAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Minimum order amount cannot be greater than total amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (maxAmount > actualAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Maximum order amount cannot be greater than total amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (_priceDeltaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the price difference'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final priceDelta = double.tryParse(_priceDeltaController.text);
    if (priceDelta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price difference'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    if (_selectedPriceType == 'percentage' &&
        (priceDelta < -100 || priceDelta > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price percentage must be between -100% and 100%'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool isSubmitting = false;
    final response = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog.fullscreen(
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
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Preview Offer',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please confirm your offer details:',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildDetailCard(
                          title: 'Type',
                          value: _isBuyOffer ? 'Buy' : 'Sell',
                          icon: _isBuyOffer
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          isDark: isDark,
                          highlight: true,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'Asset',
                          value:
                              '${_availableAssets.firstWhere((a) => a['symbol'] == _selectedCrypto)['name']} ($_selectedCrypto)',
                          icon: Icons.currency_bitcoin,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'Amount',
                          value: '${_amountController.text} $_selectedCrypto',
                          icon: Icons.account_balance_wallet,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          title: 'Payment Methods',
                          value: _selectedPaymentMethods
                              .map((id) => _availablePaymentMethods.firstWhere(
                                  (method) => method['id'].toString() == id,
                                  orElse: () =>
                                      {'name': 'Unknown Method'})['name'])
                              .join(', '),
                          icon: Icons.payment,
                          isDark: isDark,
                        ),
                        if (_termsController.text.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(
                            'Terms & Instructions',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _termsController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? () {}
                          : () async {
                              setState(() => isSubmitting = true);
                              try {
                                // Get the selected asset details
                                final selectedAsset =
                                    _availableAssets.firstWhere(
                                  (asset) => asset['symbol'] == _selectedCrypto,
                                );

                                final tokenId = selectedAsset['id'] ??
                                    selectedAsset['token']?['id'];
                                if (tokenId == null) {
                                  throw Exception(
                                      'Could not determine token ID');
                                }

                                final minAmount =
                                    double.tryParse(_minAmountController.text);
                                final maxAmount =
                                    double.tryParse(_maxAmountController.text);

                                if (minAmount != null &&
                                    maxAmount != null &&
                                    minAmount > maxAmount) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Minimum amount cannot be greater than maximum amount'),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                  return;
                                }

                                final actualAmount =
                                    double.tryParse(_amountController.text);
                                if (actualAmount == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please enter a valid amount'),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                  return;
                                }

                                if (minAmount! > actualAmount) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Minimum order amount cannot be greater than total amount'),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                  return;
                                }

                                if (maxAmount! < actualAmount) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Maximum order amount cannot be less than total amount'),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                  return;
                                }

                                // Add method to calculate price
                                double calculatePrice(
                                    double marketPrice,
                                    String priceType,
                                    double priceDelta,
                                    bool isBuyOffer) {
                                  if (priceType == 'percentage') {
                                    final multiplier = isBuyOffer
                                        ? (1 - priceDelta / 100)
                                        : (1 + priceDelta / 100);
                                    return marketPrice * multiplier;
                                  } else {
                                    return isBuyOffer
                                        ? marketPrice - priceDelta
                                        : marketPrice + priceDelta;
                                  }
                                }

                                // Calculate price
                                final marketPrice = _marketPrice!;
                                final calculatedPrice = calculatePrice(
                                    marketPrice,
                                    _selectedPriceType,
                                    priceDelta,
                                    _isBuyOffer);

                                // Create the offer
                                final offerData = {
                                  'tokenId': tokenId,
                                  'amount':
                                      double.parse(_amountController.text),
                                  'currency': _userCurrency,
                                  'isBuyOffer': _isBuyOffer,
                                  'terms': _termsController.text,
                                  'paymentMethods': _selectedPaymentMethods
                                      .map((id) => ({
                                            'typeId': id,
                                            'methodId': _isBuyOffer ? null : id,
                                          }))
                                      .toList(),
                                  'minAmount': minAmount,
                                  'maxAmount': maxAmount,
                                  'priceType': _selectedPriceType,
                                  'priceDelta': priceDelta,
                                  'price':
                                      calculatedPrice, // Add calculated price
                                  'priceUSD':
                                      _marketPrice, // Add market price in USD
                                };

                                final response =
                                    await _p2pService.createOffer(offerData);

                                Navigator.pop(context, response);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message']),
                                      backgroundColor: SafeJetColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e
                                        .toString()
                                        .replaceAll('Exception: ', '')),
                                    backgroundColor: SafeJetColors.error,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeJetColors.secondaryHighlight,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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

    if (response != null) {
      if (mounted) {
        Navigator.pop(context); // Close the create offer screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: SafeJetColors.success,
          ),
        );
      }
    }
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.1)
                : SafeJetColors.secondaryHighlight.withOpacity(0.05))
            : (isDark ? Colors.black.withOpacity(0.3) : Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: highlight
                  ? SafeJetColors.secondaryHighlight.withOpacity(0.1)
                  : (isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: highlight
                  ? SafeJetColors.secondaryHighlight
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _managePaymentMethod(Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup ${method['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: method['details'].entries.map<Widget>((entry) {
            return TextField(
              decoration: InputDecoration(
                labelText: entry.key.toUpperCase(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                method['details'][entry.key] = value;
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Validate and save payment method details
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForName(String iconName) {
    switch (iconName) {
      case 'bank':
        return Icons.account_balance;
      case 'mobile':
        return Icons.phone_android;
      case 'qr_code':
        return Icons.qr_code;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.payment; // Default icon
    }
  }

  Widget _buildCreateOfferShimmer(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buy/Sell toggle shimmer
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Asset selector shimmer
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Amount input shimmer
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Price settings shimmer
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Min/Max amount shimmer
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // Payment methods shimmer
            Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 100,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms input shimmer
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
