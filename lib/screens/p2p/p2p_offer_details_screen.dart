import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'p2p_chat_screen.dart';
import 'p2p_order_confirmation_screen.dart';
import '../../services/p2p_service.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import 'dart:convert';

class P2POfferDetailsScreen extends StatefulWidget {
  final bool isBuy;
  final String offerId;
  final Map<String, dynamic> offerDetails;

  const P2POfferDetailsScreen({
    super.key,
    required this.isBuy,
    required this.offerId,
    required this.offerDetails,
  });

  @override
  State<P2POfferDetailsScreen> createState() => _P2POfferDetailsScreenState();
}

class _P2POfferDetailsScreenState extends State<P2POfferDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  bool _termsAccepted = false;
  Map<String, dynamic>? offerDetails;

  // Add tab controller
  late TabController _tabController;
  bool _isCurrencyMode = true; // true for currency, false for asset

  // Add validation state
  String? _amountError;
  double _calculatedAssetAmount = 0.0;
  double _calculatedCurrencyAmount = 0.0;

  // Add these formatters
  final _currencyFormatter = NumberFormat("#,##0.00", "en_US");
  final _assetFormatter = NumberFormat("#,##0.######", "en_US");

  // Add selected payment method
  Map<String, dynamic>? _selectedPaymentMethod;

  // Add a loading state variable at the top of the class
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchOfferDetails();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _amountController.addListener(_validateAmount);
  }

  void _handleTabChange() {
    setState(() {
      _isCurrencyMode = _tabController.index == 0;
      // Clear input when switching tabs
      _amountController.clear();
      _amountError = null;
      _calculatedAssetAmount = 0.0;
      _calculatedCurrencyAmount = 0.0;
    });
  }

  void _validateAmount() {
    if (offerDetails == null) return;

    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() {
        _amountError = null;
        _calculatedAssetAmount = 0.0;
        _calculatedCurrencyAmount = 0.0;
      });
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null) {
      setState(() {
        _amountError = 'Please enter a valid number';
      });
      return;
    }

    final offer = offerDetails!;
    final price =
        double.tryParse(offer['calculatedPrice']?.toString() ?? '0') ?? 0.0;
    // These are in asset (USDT)
    final minAmount =
        double.tryParse(offer['metadata']['minAmount']?.toString() ?? '0') ??
            0.0;
    final maxAmount =
        double.tryParse(offer['metadata']['maxAmount']?.toString() ?? '0') ??
            0.0;
    final availableAmount =
        double.tryParse(offer['amount']?.toString() ?? '0') ?? 0.0;
    final currency = offer['currency'] ?? 'Unknown';
    final tokenSymbol = offer['token']?['symbol'] ?? 'Unknown';

    String? error;
    double calculatedAsset = 0.0;
    double calculatedCurrency = 0.0;

    if (_isCurrencyMode) {
      // User entered amount in currency (e.g., NGN)
      calculatedCurrency = amount;
      calculatedAsset = amount / price; // Convert to asset

      // Convert min/max to currency for comparison
      final minCurrency = minAmount * price;
      final maxCurrency = maxAmount * price;

      if (amount < minCurrency) {
        error =
            'Minimum amount is ${_currencyFormatter.format(minCurrency)} $currency';
      } else if (amount > maxCurrency) {
        error =
            'Maximum amount is ${_currencyFormatter.format(maxCurrency)} $currency';
      } else if (calculatedAsset > availableAmount) {
        final availableInCurrency = availableAmount * price;
        error =
            'Exceeds available amount (${_currencyFormatter.format(availableInCurrency)} $currency)';
      }
    } else {
      // User entered amount in asset (e.g., USDT)
      calculatedAsset = amount;
      calculatedCurrency = amount * price; // Convert to currency

      // Min/max are already in asset, so direct comparison
      if (amount < minAmount) {
        error =
            'Minimum amount is ${_assetFormatter.format(minAmount)} $tokenSymbol';
      } else if (amount > maxAmount) {
        error =
            'Maximum amount is ${_assetFormatter.format(maxAmount)} $tokenSymbol';
      } else if (amount > availableAmount) {
        error =
            'Exceeds available amount (${_assetFormatter.format(availableAmount)} $tokenSymbol)';
      }
    }

    setState(() {
      _amountError = error;
      _calculatedAssetAmount = calculatedAsset;
      _calculatedCurrencyAmount = calculatedCurrency;
    });
  }

  Future<void> _fetchOfferDetails() async {
    try {
      final p2pService = P2PService();
      final details = await p2pService.getOfferDetails(widget.offerId);
      setState(() {
        offerDetails = details;
      });
    } catch (e) {
      print('Error fetching offer details');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (offerDetails == null) {
      return _buildLoadingShimmer(isDark);
    }

    // Extract offer details
    final offer = offerDetails!;
    final token = offer['token'] ?? {};
    final tokenSymbol = token['symbol'] ?? 'Unknown';
    final availableAmount = double.tryParse(offer['amount'].toString()) ?? 0.0;
    final currency = offer['currency'] ?? 'Unknown';
    final minAmount = offer['metadata']['minAmount'] ?? 0;
    final maxAmount = offer['metadata']['maxAmount'] ?? 0;
    final paymentMethods = offer['paymentMethods'] ?? [];
    final terms = offer['terms'] ?? 'No terms provided';

    // Extract user details
    final user = offer['user'] ?? {};
    final userName = user['fullName'] ?? 'Unknown User';
    final userInitials =
        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';
    final kycLevel = user['kycLevel'] ?? 'Unverified';

    print('User details: Name: $userName, KYC Level: $kycLevel');

    // Use the calculated price from the backend
    final price = offer['calculatedPrice'] ?? '0.00';

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isBuy ? 'Buy $tokenSymbol' : 'Sell $tokenSymbol',
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
                  // Seller/Buyer Profile Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _buildProfileSection(
                        isDark, userName, userInitials, kycLevel),
                  ),
                  const SizedBox(height: 24),

                  // Price & Amount Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: _buildPriceSection(isDark, price, availableAmount,
                        currency, tokenSymbol, minAmount, maxAmount),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 400),
                    child: _buildPaymentSection(isDark, paymentMethods),
                  ),
                  const SizedBox(height: 24),

                  // Terms & Conditions
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 600),
                    child: _buildTermsSection(isDark, terms),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Action Section
          _buildActionSection(isDark, currency),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isBuy ? 'Buy' : 'Sell',
        onThemeToggle: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section Shimmer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar shimmer
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name shimmer
                                Container(
                                  width: 120,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Stats shimmer
                                Container(
                                  width: 150,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Status shimmer
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price Section Shimmer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Price label shimmer
                                  Container(
                                    width: 40,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Price value shimmer
                                  Container(
                                    width: 120,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              // Buy/Sell tag shimmer
                              Container(
                                width: 60,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Available shimmer
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 80,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              // Limit shimmer
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 100,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Methods Section Shimmer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title shimmer
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Payment method 1
                          _buildPaymentMethodShimmer(),
                          const SizedBox(height: 12),
                          // Payment method 2
                          _buildPaymentMethodShimmer(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Terms Section Shimmer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title shimmer
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Terms content shimmer
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
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
          // Bottom Action Section Shimmer
          Container(
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
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodShimmer() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(
      bool isDark, String userName, String userInitials, String kycLevel) {
    // Get the user order stats from the user object
    final user = offerDetails?['user'] ?? {};
    final orderStats = user['orderStats'] ??
        {'totalOrders': 0, 'completedOrders': 0, 'completionRate': 98};
    final totalOrders = orderStats['totalOrders'] ?? 0;
    final completionRate = orderStats['completionRate'] ?? 98;

    return Container(
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
          CircleAvatar(
            radius: 24,
            backgroundColor: SafeJetColors.secondaryHighlight,
            child: Text(userInitials),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kycLevel == 'Verified'
                            ? SafeJetColors.success.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: kycLevel == 'Verified'
                                ? SafeJetColors.success
                                : Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kycLevel,
                            style: TextStyle(
                              color: kycLevel == 'Verified'
                                  ? SafeJetColors.success
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalOrders orders • $completionRate% completion',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SafeJetColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online now',
                      style: TextStyle(
                        color: SafeJetColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
      bool isDark,
      String price,
      double availableAmount,
      String currency,
      String tokenSymbol,
      dynamic minAmount,
      dynamic maxAmount) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : SafeJetColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency ${_currencyFormatter.format(double.tryParse(price) ?? 0.0)}/$tokenSymbol',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isBuy
                      ? SafeJetColors.success.withOpacity(0.2)
                      : SafeJetColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.isBuy ? 'BUYING' : 'SELLING',
                  style: TextStyle(
                    color: widget.isBuy
                        ? SafeJetColors.success
                        : SafeJetColors.warning,
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
              _buildInfoItem('Available',
                  '${availableAmount.toStringAsFixed(2)} $tokenSymbol', isDark),
              _buildInfoItem(
                  'Limit',
                  '${minAmount.toStringAsFixed(2)} - ${maxAmount.toStringAsFixed(2)} $tokenSymbol',
                  isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(bool isDark, List<dynamic> paymentMethods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isBuy
              ? 'Seller\'s Payment Methods'
              : 'Select Your Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.isBuy) ...[
          // Display seller's payment methods
          ...paymentMethods.map((method) {
            final methodName = method['typeName'] ?? 'Unknown';
            final description =
                method['description'] ?? 'No description available';
            final isSelected = _selectedPaymentMethod != null &&
                _selectedPaymentMethod!['methodId'] == method['methodId'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? SafeJetColors.secondaryHighlight.withOpacity(0.1)
                          : SafeJetColors.secondaryHighlight.withOpacity(0.05))
                      : (isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.05)
                          : SafeJetColors.lightCardBackground),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? SafeJetColors.secondaryHighlight
                        : (isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.1)
                            : SafeJetColors.lightCardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.1)
                            : SafeJetColors.lightCardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? SafeJetColors.primaryAccent.withOpacity(0.2)
                              : SafeJetColors.lightCardBorder,
                        ),
                      ),
                      child: Icon(
                        _getPaymentIcon(method['icon']),
                        color: isDark ? Colors.white : SafeJetColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            methodName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : SafeJetColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                            softWrap: true,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: SafeJetColors.secondaryHighlight,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else ...[
          // Allow seller to select their payment method
          GestureDetector(
            onTap: () {
              _showPaymentMethodsDialog(context, isDark);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.05)
                    : SafeJetColors.lightCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? SafeJetColors.primaryAccent.withOpacity(0.1)
                      : SafeJetColors.lightCardBorder,
                ),
              ),
              child: Row(
                children: [
                  if (_selectedPaymentMethod != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.1)
                            : SafeJetColors.lightCardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? SafeJetColors.primaryAccent.withOpacity(0.2)
                              : SafeJetColors.lightCardBorder,
                        ),
                      ),
                      child: Icon(
                        _getPaymentIcon(
                            _selectedPaymentMethod!['paymentMethodType']
                                ['icon']),
                        color: isDark ? Colors.white : SafeJetColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPaymentMethod!['paymentMethodType']
                                    ['name'] ??
                                _selectedPaymentMethod!['name'] ??
                                'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildPaymentMethodDescription(
                                _selectedPaymentMethod!),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : SafeJetColors.lightTextSecondary,
                              fontSize: 12,
                            ),
                            softWrap: true,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.add, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a payment method to receive funds',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to build payment method description
  String _buildPaymentMethodDescription(Map<String, dynamic> method) {
    final details = method['details'] as Map<String, dynamic>?;
    final paymentMethodType = method['paymentMethodType'] ?? {};
    final methodName = method['name'] ?? '';

    // Start with the payment method name
    String description = methodName;

    if (details != null) {
      // Build the details part
      String detailsText = details.entries
          .map((entry) {
            final fieldType = entry.value['fieldType'];
            final value = entry.value['value'];
            final fieldName = entry.value['fieldName'];

            if (fieldType == 'date') {
              return value.toString();
            } else if (fieldType == 'image') {
              return '';
            } else if (fieldName == 'instructions') {
              // Allow longer instructions
              final text = value.toString();
              return text.length > 30 ? '${text.substring(0, 30)}...' : text;
            } else {
              return value.toString();
            }
          })
          .where((value) => value.isNotEmpty)
          .join(' - ');

      // Add details if available
      if (detailsText.isNotEmpty) {
        if (description.isNotEmpty) {
          description += ': ';
        }
        description += detailsText;
      }
    }

    // Increase the overall description length limit
    if (description.length > 120) {
      description = '${description.substring(0, 117)}...';
    }

    return description.isNotEmpty
        ? description
        : paymentMethodType['description'] ?? 'No description available';
  }

  // Add back the _getPaymentIcon method
  IconData _getPaymentIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'qr_code':
      case 'qr':
        return Icons.qr_code;
      case 'mobile':
        return Icons.phone_android;
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection(bool isDark, String terms) {
    return Container(
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
          const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            terms,
            style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() => _termsAccepted = value ?? false);
                  },
                  activeColor: SafeJetColors.secondaryHighlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I have read and agree to the terms & conditions',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isDark, String currency) {
    final tokenSymbol = offerDetails?['token']?['symbol'] ?? 'Unknown';
    final price = offerDetails?['calculatedPrice'] ?? '0.00';

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
      child: Column(
        children: [
          // Modern currency/asset selection tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CurrencyTab(
                  label: currency,
                  isSelected: _isCurrencyMode,
                  onSelected: (selected) {
                    if (selected && !_isCurrencyMode) {
                      setState(() {
                        _isCurrencyMode = true;
                        _tabController.animateTo(0);
                        _amountController.clear();
                        _amountError = null;
                        _calculatedAssetAmount = 0.0;
                        _calculatedCurrencyAmount = 0.0;
                      });
                    }
                  },
                ),
                _CurrencyTab(
                  label: tokenSymbol,
                  isSelected: !_isCurrencyMode,
                  onSelected: (selected) {
                    if (selected && _isCurrencyMode) {
                      setState(() {
                        _isCurrencyMode = false;
                        _tabController.animateTo(1);
                        _amountController.clear();
                        _amountError = null;
                        _calculatedAssetAmount = 0.0;
                        _calculatedCurrencyAmount = 0.0;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: _isCurrencyMode
                        ? 'Enter amount in $currency'
                        : 'Enter amount in $tokenSymbol',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey[600]
                          : SafeJetColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _amountError != null
                            ? SafeJetColors.error
                            : isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                                : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _amountError != null
                            ? SafeJetColors.error
                            : SafeJetColors.secondaryHighlight,
                      ),
                    ),
                    errorText: _amountError,
                    errorStyle: TextStyle(
                      color: SafeJetColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  // Set max amount based on available and limits
                  if (offerDetails != null) {
                    // These are in asset (USDT)
                    final maxAmount = double.tryParse(offerDetails!['metadata']
                                    ['maxAmount']
                                ?.toString() ??
                            '0') ??
                        0.0;
                    final availableAmount = double.tryParse(
                            offerDetails!['amount']?.toString() ?? '0') ??
                        0.0;
                    final price = double.tryParse(
                            offerDetails!['calculatedPrice']?.toString() ??
                                '0') ??
                        0.0;

                    if (_isCurrencyMode) {
                      // In currency mode, convert max and available to currency
                      final maxInCurrency = maxAmount * price;
                      final availableInCurrency = availableAmount * price;

                      // Use the smaller of max limit or available
                      final maxValue = maxInCurrency < availableInCurrency
                          ? maxInCurrency
                          : availableInCurrency;
                      // Use raw number instead of formatted number
                      _amountController.text = maxValue.toString();
                    } else {
                      // In asset mode, use the smaller of max limit or available
                      final maxValue = maxAmount < availableAmount
                          ? maxAmount
                          : availableAmount;
                      // Use raw number instead of formatted number
                      _amountController.text = maxValue.toString();
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: SafeJetColors.secondaryHighlight,
                ),
                child: const Text('MAX'),
              ),
            ],
          ),
          if (_amountError == null &&
              (_calculatedAssetAmount > 0 ||
                  _calculatedCurrencyAmount > 0)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  widget.isBuy
                      ? (_isCurrencyMode
                          ? 'You will recieve:'
                          : 'You will pay:')
                      : (_isCurrencyMode
                          ? 'You will receive:'
                          : 'You will pay:'),
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.isBuy
                      ? (_isCurrencyMode
                          ? '${_assetFormatter.format(_calculatedAssetAmount)} $tokenSymbol'
                          : '${_currencyFormatter.format(_calculatedCurrencyAmount)} $currency')
                      : (_isCurrencyMode
                          ? '${_currencyFormatter.format(_calculatedCurrencyAmount)} $currency'
                          : '${_assetFormatter.format(_calculatedAssetAmount)} $tokenSymbol'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _termsAccepted &&
                      _amountError == null &&
                      (_calculatedAssetAmount > 0 ||
                          _calculatedCurrencyAmount > 0) &&
                      _selectedPaymentMethod != null &&
                      !_isSubmitting
                  ? () {
                      _submitOrder();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isBuy
                    ? SafeJetColors.success
                    : SafeJetColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor:
                    isDark ? Colors.grey[800] : Colors.grey[300],
                disabledForegroundColor:
                    isDark ? Colors.grey[600] : Colors.grey[500],
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isBuy ? 'Buy $tokenSymbol' : 'Sell $tokenSymbol',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _showPaymentMethodsDialog method
  void _showPaymentMethodsDialog(BuildContext context, bool isDark) {
    // Show dialog immediately
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? SafeJetColors.primaryBackground : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Use FutureBuilder to handle loading state
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchUserPaymentMethods(),
                    builder: (context, snapshot) {
                      // Show shimmer loading while waiting
                      if (!snapshot.hasData) {
                        return _buildPaymentMethodsShimmer(isDark);
                      }

                      // Show empty state if no payment methods
                      final userPaymentMethods = snapshot.data ?? [];
                      if (userPaymentMethods.isEmpty) {
                        return Center(
                          child: Text(
                            'No payment methods available',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : SafeJetColors.lightTextSecondary,
                            ),
                          ),
                        );
                      }

                      // Show payment methods list
                      return Column(
                        children: userPaymentMethods.map((method) {
                          final paymentMethodType =
                              method['paymentMethodType'] ?? {};
                          final details =
                              method['details'] as Map<String, dynamic>?;
                          final methodName = method['name'] ?? '';

                          // Build description
                          String description =
                              _buildPaymentMethodDescription(method);

                          return GestureDetector(
                            onTap: () {
                              this.setState(() {
                                _selectedPaymentMethod = method;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SafeJetColors.primaryAccent
                                        .withOpacity(0.05)
                                    : SafeJetColors.lightCardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? SafeJetColors.primaryAccent
                                          .withOpacity(0.1)
                                      : SafeJetColors.lightCardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? SafeJetColors.primaryAccent
                                              .withOpacity(0.1)
                                          : SafeJetColors.lightCardBackground,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? SafeJetColors.primaryAccent
                                                .withOpacity(0.2)
                                            : SafeJetColors.lightCardBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      _getPaymentIcon(method['icon']),
                                      color: isDark
                                          ? Colors.white
                                          : SafeJetColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          methodName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : SafeJetColors
                                                    .lightTextSecondary,
                                            fontSize: 12,
                                          ),
                                          softWrap: true,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add a shimmer loading widget for payment methods
  Widget _buildPaymentMethodsShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Add this method to fetch user payment methods
  Future<List<Map<String, dynamic>>> _fetchUserPaymentMethods() async {
    try {
      final p2pService = P2PService();
      // Use the existing getPaymentMethods method with isBuy=false for sell offers
      final paymentMethods = await p2pService.getPaymentMethods(false);
      print('Fetched payment methods: $paymentMethods');
      return paymentMethods;
    } catch (e) {
      print('Error fetching user payment methods');
      // Return empty list on error
      return [];
    }
  }

  // Update the _submitOrder method to manage the loading state
  Future<void> _submitOrder() async {
    if (_selectedPaymentMethod == null) {
      // Show an error if no payment method is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a payment method.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state to true
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the current user ID from AuthService
      final authService = GetIt.I<AuthService>();
      final currentUser = await authService.getCurrentUser();

      if (currentUser == null || currentUser['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not authenticated. Please log in.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final currentUserId = currentUser['id'];

      final orderData = {
        'offerId': widget.offerId,
        'buyerId': widget.isBuy ? currentUserId : offerDetails!['userId'],
        'sellerId': widget.isBuy ? offerDetails!['userId'] : currentUserId,
        'paymentMetadata': _selectedPaymentMethod,
        'assetAmount': _isCurrencyMode
            ? _calculatedAssetAmount
            : double.parse(_amountController.text),
        'currencyAmount': _isCurrencyMode
            ? double.parse(_amountController.text)
            : _calculatedCurrencyAmount,
        'calculatedPrice': offerDetails!['calculatedPrice'],
        'buyerStatus': 'pending',
        'sellerStatus': 'pending',
      };

      print('Order data being sent: $orderData');

      // Make sure widget.offerId is not null or empty
      if (widget.offerId == null || widget.offerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid offer ID. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final p2pService = P2PService();
      final response = await p2pService.submitOrder(orderData);

      // Navigate to confirmation screen with the tracking ID from the response
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => P2POrderConfirmationScreen(
              trackingId: response['trackingId'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      // Log complete error
      print('Error submitting order');
      print('Error type: ${e.runtimeType}');
      print('Full error toString: ${e.toString()}');

      // Extract the error message
      String errorMessage = 'Failed to submit order';

      // Get raw error string
      final errorString = e.toString();

      // Extract the message based on common error formats
      if (errorString.contains('Exception: ')) {
        final parts = errorString.split('Exception: ');
        errorMessage = parts.length > 1 ? parts[1].trim() : errorString;
        print('Extracted error message: $errorMessage');
      } else {
        // Use the full error string if it's not too long
        errorMessage = errorString.length < 100 ? errorString : errorMessage;
        print('Using error string: $errorMessage');
      }

      // Show the error message to user
      if (mounted) {
        print('Showing snackbar with message: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Move the _CurrencyTab class outside of _P2POfferDetailsScreenState
class _CurrencyTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _CurrencyTab({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onSelected(true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                  : SafeJetColors.secondaryHighlight.withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
