import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/coin_selection_modal.dart';
import '../../widgets/network_selection_modal.dart';
import '../../models/coin.dart';
import '../../widgets/two_factor_dialog.dart';
import '../../services/biometric_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../../services/service_locator.dart';
import '../../services/internal_transfer_service.dart';
import '../../services/wallet_service.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/saved_addresses_modal.dart';

class InternalTransferScreen extends StatefulWidget {
  final Map<String, dynamic>? asset;
  final bool showInUSD;
  final double userCurrencyRate;
  final String userCurrency;

  const InternalTransferScreen({
    super.key,
    this.asset,
    required this.showInUSD,
    required this.userCurrencyRate,
    required this.userCurrency,
  });

  @override
  State<InternalTransferScreen> createState() => _InternalTransferScreenState();
}

class _InternalTransferScreenState extends State<InternalTransferScreen> {
  final _internalTransferService = GetIt.I<InternalTransferService>();
  final _walletService = GetIt.I<WalletService>();
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _tagController = TextEditingController();

  late Coin? _selectedCoin;

  bool _isLoading = false;
  bool _isFiat = false;
  bool _maxAmount = false;

  String? _receiverError;
  String? _amountError;
  String? _warningMessage;

  Map<String, dynamic>? _feeDetails;
  double? _receiveAmount;

  String _selectedFiatCurrency = 'USD';
  bool get _showInUSD => widget.showInUSD;
  String get _userCurrency => widget.userCurrency;
  double get _userCurrencyRate => widget.userCurrencyRate;

  // Add proper formatting function for crypto amounts
  String _formatCryptoAmount(double amount, String symbol) {
    if (amount == 0) return '0 $symbol';

    // For very small amounts, show more decimals
    if (amount < 0.000001) {
      return '${amount.toStringAsFixed(12)} $symbol';
    } else if (amount < 0.001) {
      return '${amount.toStringAsFixed(8)} $symbol';
    } else if (amount < 1) {
      return '${amount.toStringAsFixed(6)} $symbol';
    } else if (amount < 1000) {
      return '${amount.toStringAsFixed(4)} $symbol';
    } else if (amount < 1000000) {
      return '${amount.toStringAsFixed(2)} $symbol';
    } else {
      return '${amount.toStringAsFixed(2)} $symbol';
    }
  }

  // Add number formatters
  final _numberFormat = NumberFormat("#,##0.00", "en_US");
  final _cryptoFormat = NumberFormat("#,##0.00######", "en_US");

  // Add local asset state
  late Map<String, dynamic> _currentAsset;

  // Add these at the top with other variables
  String? _verifiedPassword;
  String? _verifiedTwoFactorCode;

  bool _isReceiverValid = false;
  Map<String, dynamic>? _receiverData;

  // Add this helper function to format balance
  String _formatBalance(String? balanceStr) {
    final balance = double.tryParse(balanceStr ?? '0') ?? 0.0;
    final parts = balance.toString().split('.');

    if (parts.length == 1) return NumberFormat('#,##0').format(balance);

    var decimals = parts[1];
    if (decimals.length > 8) decimals = decimals.substring(0, 8);
    while (decimals.endsWith('0'))
      decimals = decimals.substring(0, decimals.length - 1);

    final wholeNumber = NumberFormat('#,##0').format(int.parse(parts[0]));
    return decimals.isEmpty ? wholeNumber : '$wholeNumber.$decimals';
  }

  // Add method to format amount input consistently
  String _formatAmountInput(String amount) {
    // Allow decimal point input without forcing formatting
    if (amount.endsWith('.') || amount.isEmpty) {
      return amount;
    }
    
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) return amount;

    if (_isFiat) {
      return parsedAmount.toStringAsFixed(2);
    } else {
      // For crypto, use the same formatting as balance
      return _formatBalance(amount);
    }
  }

  // Add the currency symbol helper
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'NGN':
        return '₦';
      default:
        return currencyCode;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAsset();
    _receiverController.addListener(_validateReceiver);
    _amountController.addListener(_onAmountChanged);
  }

  void _initializeAsset() {
    if (widget.asset != null) {
      _currentAsset = widget.asset!;
      final token = _currentAsset['token'] as Map<String, dynamic>?;
      if (token != null) {
        _selectedCoin = Coin(
          id: token['id']?.toString() ?? '',
          symbol: token['symbol']?.toString() ?? '',
          name: token['name']?.toString() ?? '',
          networks: [], // Use empty list instead of dynamic map
        );
      } else {
        // Fallback to default values
        _selectedCoin = Coin(
          id: _currentAsset['id']?.toString() ?? '',
          symbol: _currentAsset['symbol']?.toString() ?? '',
          name: _currentAsset['name']?.toString() ?? '',
          networks: [], // Use empty list instead of dynamic map
        );
      }
    } else {
      _currentAsset = {};
      _selectedCoin = null;
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _validateReceiver() async {
    if (_receiverController.text.isEmpty) {
      setState(() {
        _receiverError = null;
        _isReceiverValid = false;
        _receiverData = null;
      });
      return;
    }

    // Check if input is email or traderId
    final isEmail = _receiverController.text.contains('@');

    // Get current user info for self-transfer validation
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // Check for self-transfer
    if (isEmail &&
        currentUser?.email?.toLowerCase() ==
            _receiverController.text.toLowerCase()) {
      setState(() {
        _receiverError = 'You cannot transfer to yourself';
        _isReceiverValid = false;
        _receiverData = null;
      });
      return;
    }

    if (!isEmail && currentUser?.traderId == _receiverController.text) {
      setState(() {
        _receiverError = 'You cannot transfer to yourself';
        _isReceiverValid = false;
        _receiverData = null;
      });
      return;
    }

    try {
      final receiverData = await _internalTransferService.validateReceiver(
        _receiverController.text,
        isEmail ? 'email' : 'traderId',
      );

      setState(() {
        _receiverError = null;
        _isReceiverValid = true;
        _receiverData = receiverData;
      });
    } catch (e) {
      setState(() {
        // Safely handle error message
        final errorMessage = e?.toString() ?? 'Unknown error occurred';
        _receiverError = errorMessage.replaceAll('Exception: ', '');
        _isReceiverValid = false;
        _receiverData = null;
      });
    }
  }

  Future<void> _onAmountChanged() async {
    if (_amountController.text.isEmpty ||
        _selectedCoin == null ||
        !_isReceiverValid) {
      setState(() {
        _feeDetails = null;
        _receiveAmount = null;
      });
      return;
    }

    final inputAmount = double.tryParse(_amountController.text);
    if (inputAmount == null) return;

    try {
      final tokenAmount =
          _isFiat ? _convertAmount(_amountController.text, false) : inputAmount;

      // For internal transfers, we use percentage-based fees
      // Get the token ID from the selected coin
      final tokenId = _selectedCoin!.id;

      // Calculate fee using percentage-based fee calculation
      final feeDetails =
          await _internalTransferService.calculateInternalTransferFee(
        tokenId: tokenId,
        amount: tokenAmount,
        receiverId: _receiverData!['id'],
      );

      print('🔐 Fee calculation response:');
      print('   - feeDetails: $feeDetails');
      print('   - receiveAmount: ${feeDetails['receiveAmount']}');
      print('   - feeAmount: ${feeDetails['feeAmount']}');

      setState(() {
        _feeDetails = feeDetails;
        // Add null safety for receiveAmount
        final receiveAmountStr = feeDetails['receiveAmount']?.toString();
        if (receiveAmountStr != null) {
          _receiveAmount = double.tryParse(receiveAmountStr);
        } else {
          _receiveAmount = null;
        }
      });
    } catch (e) {
      print('Error calculating fee');
      setState(() {
        _feeDetails = null;
        _receiveAmount = null;
        // Safely handle error message
        final errorMessage = e?.toString() ?? 'Unknown error occurred';
        _amountError = errorMessage.replaceAll('Exception: ', '');
      });
    }
  }

  // Add validation methods
  bool _validateReceiverInput(String receiver) {
    if (receiver.isEmpty) {
      setState(() => _receiverError = 'Receiver is required');
      return false;
    }

    // Check if it's email or traderId
    final isEmail = receiver.contains('@');

    if (isEmail) {
      // Basic email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(receiver)) {
        setState(() => _receiverError = 'Invalid email format');
        return false;
      }
    } else {
      // TraderId validation (alphanumeric with hyphens, 6-20 characters)
      if (receiver.length < 6 || receiver.length > 20) {
        setState(() => _receiverError = 'Trader ID must be 6-20 characters');
        return false;
      }
      final traderIdRegex = RegExp(r'^[a-zA-Z0-9-]+$');
      if (!traderIdRegex.hasMatch(receiver)) {
        setState(() => _receiverError =
            'Trader ID can only contain letters, numbers, and hyphens');
        return false;
      }
    }

    setState(() => _receiverError = null);
    return true;
  }

  bool _validateAmount(String amount) {
    if (amount.isEmpty) {
      setState(() => _amountError = 'Amount is required');
      return false;
    }

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      setState(() => _amountError = 'Invalid amount');
      return false;
    }

    if (parsedAmount <= 0) {
      setState(() => _amountError = 'Amount must be greater than 0');
      return false;
    }

    // Use balance directly since this is already a funding wallet
    final fundingBalance =
        double.tryParse(_currentAsset['balance']?.toString() ?? '0') ?? 0.0;
    final coinAmount = _isFiat ? _convertAmount(amount, false) : parsedAmount;

    print('Attempting to transfer: $coinAmount');
    print('Available funding balance: $fundingBalance');

    if (coinAmount > fundingBalance) {
      setState(() => _amountError = 'Insufficient funding balance');
      return false;
    }

    setState(() => _amountError = null);
    return true;
  }

  // Add transfer confirmation dialog
  Future<bool> _showConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiverNameController = TextEditingController();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => Dialog.fullscreen(
              child: Scaffold(
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
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  title: Text(
                    'Confirm Internal Transfer',
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
                            Text(
                              'Please confirm your internal transfer details:',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildDetailCard(
                              title: 'Receiver',
                              value: _receiverData?['fullName'] ??
                                  _receiverController.text,
                              icon: Icons.person,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailCard(
                              title: 'Amount',
                              value: _formatCryptoAmount(
                                double.parse(_amountController.text),
                                _selectedCoin?.symbol ?? '',
                              ),
                              icon: Icons.account_balance_wallet,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailCard(
                              title: 'Network Fee',
                              value: _feeDetails != null
                                  ? _formatCryptoAmount(
                                      double.parse(_feeDetails!['feeAmount']),
                                      _selectedCoin?.symbol ?? '',
                                    )
                                  : '- ${_selectedCoin?.symbol}',
                              icon: Icons.local_gas_station,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailCard(
                              title: 'Receiver Gets',
                              value: _receiveAmount != null
                                  ? _formatCryptoAmount(
                                      _receiveAmount!,
                                      _selectedCoin?.symbol ?? '',
                                    )
                                  : '- ${_selectedCoin?.symbol}',
                              icon: Icons.receipt_long,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            if (_memoController.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildDetailCard(
                                title: 'Memo',
                                value: _memoController.text,
                                icon: Icons.note,
                                isDark: isDark,
                              ),
                            ],
                            if (_tagController.text.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildDetailCard(
                                title: 'Tag',
                                value: _tagController.text,
                                icon: Icons.tag,
                                isDark: isDark,
                              ),
                            ],
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This transfer will be processed immediately and cannot be cancelled once confirmed.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Removed save receiver functionality
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    SafeJetColors.secondaryHighlight,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Confirm Transfer',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
        ) ??
        false;
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

  double _convertAmount(String amount, bool toFiat) {
    if (amount.isEmpty) return 0;
    final parsedAmount = double.tryParse(amount) ?? 0;

    // Get token price from current asset data
    final tokenPrice = double.tryParse(
            _currentAsset['token']?['currentPrice']?.toString() ?? '0') ??
        0.0;

    if (toFiat) {
      // Converting from token to fiat (e.g., 1 BTC -> USD or EUR)
      final usdAmount = parsedAmount * tokenPrice;
      return _selectedFiatCurrency == 'USD'
          ? usdAmount
          : usdAmount * _userCurrencyRate;
    } else {
      // Converting from fiat to token (e.g., USD or EUR -> BTC)
      if (_selectedFiatCurrency == 'USD') {
        return tokenPrice > 0 ? parsedAmount / tokenPrice : 0;
      } else {
        // First convert user currency to USD, then to token
        final usdAmount = parsedAmount / _userCurrencyRate;
        return tokenPrice > 0 ? usdAmount / tokenPrice : 0;
      }
    }
  }

  String _getFormattedAmount() {
    if (_amountController.text.isEmpty) return '';
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (_isFiat) {
      // When input is in fiat, show crypto equivalent
      final cryptoAmount = _convertAmount(_amountController.text, false);
      return '≈ ${_cryptoFormat.format(cryptoAmount)} ${_selectedCoin?.symbol}';
    } else {
      // When input is in crypto, show fiat equivalent
      final fiatAmount = _convertAmount(_amountController.text, true);
      return '≈ ${_numberFormat.format(fiatAmount)} ${_selectedFiatCurrency}';
    }
  }

  Future<bool> _handleTransferConfirmation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    print('🔐 User data:');
    print('   - Email: ${authProvider.user?.email}');
    print('   - Biometric enabled: ${authProvider.user?.biometricEnabled}');
    print('   - 2FA enabled: ${authProvider.user?.twoFactorEnabled}');

    // First check if biometrics is enabled
    if (authProvider.user?.biometricEnabled == true) {
      print('🔐 Biometrics is enabled, using biometric authentication');
      // Use biometric authentication
      final authenticated = await BiometricService.authenticate();
      print('🔐 Biometric authentication result: $authenticated');

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: SafeJetColors.error,
            ),
          );
        }
        return false;
      }
    } else {
      print('🔐 Biometrics not enabled, using password authentication');
      // Only show password dialog if biometrics is not enabled
      final passwordController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your password to confirm transfer',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final isValid = await authProvider
                                .verifyCurrentPassword(passwordController.text);

                            if (!isValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Invalid password. Please try again.'),
                                  backgroundColor: SafeJetColors.error,
                                ),
                              );
                              return;
                            }

                            _verifiedPassword = passwordController.text;
                            Navigator.pop(context, true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    (e?.toString() ?? 'Unknown error occurred')
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
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      print('🔐 Password confirmation result: $confirmed');
      if (confirmed != true) return false;
    }

    print('🔐 Checking 2FA status: ${authProvider.user?.twoFactorEnabled}');
    // Then check 2FA if enabled
    if (authProvider.user?.twoFactorEnabled == true) {
      print('🔐 2FA is enabled, showing verification dialog');
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const TwoFactorDialog(
          action: 'transfer',
          title: 'Verify 2FA',
          message: 'Enter the 6-digit code to confirm transfer',
        ),
      );

      if (verified != true) return false;
      _verifiedTwoFactorCode = authProvider.getLastVerificationToken();
      print('🔐 2FA code captured: ${_verifiedTwoFactorCode != null}');
    }

    return true;
  }

  Future<void> _processTransfer() async {
    if (!_validateReceiverInput(_receiverController.text) ||
        !_validateAmount(_amountController.text)) {
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    final authenticated = await _handleTransferConfirmation();
    if (!authenticated) return;

    setState(() => _isLoading = true);

    try {
      // For internal transfers, we use the coin's token ID directly
      final tokenId = _selectedCoin!.id;

      // Convert amount to token value if using fiat
      final amount = _isFiat
          ? _convertAmount(_amountController.text, false).toString()
          : _amountController.text;

      final response = await _internalTransferService.createInternalTransfer(
        tokenId: tokenId,
        amount: amount,
        receiverEmail: _receiverController.text.contains('@')
            ? _receiverController.text
            : null,
        receiverTraderId: _receiverController.text.contains('@')
            ? null
            : _receiverController.text,
        memo: _memoController.text.isNotEmpty ? _memoController.text : null,
        tag: _tagController.text.isNotEmpty ? _tagController.text : null,
        password: _verifiedPassword,
        twoFactorCode: _verifiedTwoFactorCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internal transfer initiated successfully'),
            backgroundColor: SafeJetColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((e?.toString() ?? 'Unknown error occurred')
                .replaceAll('Exception: ', '')),
            backgroundColor: SafeJetColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCoinSelection(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final selectedCoin = await Navigator.push<Coin>(
          context,
          MaterialPageRoute(
            builder: (context) => const CoinSelectionModal(),
            fullscreenDialog: true,
          ),
        );

        if (selectedCoin != null) {
          // Fetch updated balance data for the selected coin
          final data = await _walletService.getBalances(
            type: 'funding',
            currency: widget.showInUSD ? 'USD' : widget.userCurrency,
          );

          if (data != null && data['balances'] != null) {
            // Find the asset that matches the selected coin symbol
            final newAsset = data['balances'].firstWhere(
              (b) => b['baseSymbol'] == selectedCoin.symbol,
              orElse: () => <String, dynamic>{},
            );

            if (newAsset.isNotEmpty) {
              setState(() {
                _currentAsset = newAsset;
                // Update selected coin with icon URL from the asset data
                _selectedCoin = Coin(
                  id: selectedCoin.id,
                  symbol: selectedCoin.symbol,
                  name: selectedCoin.name,
                  iconUrl:
                      newAsset['token']?['iconUrl'] ?? selectedCoin.iconUrl,
                  networks: selectedCoin.networks,
                );
                _feeDetails = null;
                _receiveAmount = null;
                _amountController.clear();
                _amountError = null;
                _maxAmount = false;
              });
            }
          }
        }
      },
      child: Container(
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: _selectedCoin?.iconUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_selectedCoin!.iconUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedCoin?.iconUrl == null
                  ? Center(
                      child: Text(
                        _selectedCoin?.symbol[0] ?? 'S',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCoin?.name ?? 'Select Coin',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCoin?.symbol ?? 'Choose a coin',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : SafeJetColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _CurrencyTab({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
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
        body: Column(
          children: [
            Expanded(
              child: DecoratedBox(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coin Selection
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Coin',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCoinSelection(theme, isDark),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Receiver Input
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receiver',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? SafeJetColors.primaryAccent
                                          .withOpacity(0.1)
                                      : SafeJetColors.lightCardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? SafeJetColors.primaryAccent
                                            .withOpacity(0.2)
                                        : SafeJetColors.lightCardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: SafeJetColors.secondaryHighlight
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: SafeJetColors.secondaryHighlight,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _receiverController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter email or Trader ID',
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_isReceiverValid)
                                      Icon(
                                        Icons.check_circle,
                                        color: SafeJetColors.success,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                              if (_receiverError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, left: 4),
                                  child: Text(
                                    _receiverError!,
                                    style: TextStyle(
                                      color: SafeJetColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (_receiverData != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, left: 4),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SafeJetColors.success
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: SafeJetColors.success,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Receiver found: ${_receiverData!['fullName']}',
                                          style: TextStyle(
                                            color: SafeJetColors.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Amount Input
                        if (_selectedCoin != null)
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 300),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Amount',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Available: ${_formatBalance(_currentAsset['balance']?.toString())} ${_selectedCoin?.symbol}',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : SafeJetColors
                                                      .lightTextSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[900]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _CurrencyTab(
                                            label: _selectedCoin?.symbol ?? '',
                                            isSelected: !_isFiat,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _isFiat = false;
                                                  _selectedFiatCurrency =
                                                      _showInUSD
                                                          ? 'USD'
                                                          : _userCurrency;
                                                  if (_amountController
                                                      .text.isNotEmpty) {
                                                    final cryptoAmount =
                                                        _convertAmount(
                                                            _amountController
                                                                .text,
                                                            false);
                                                    _amountController.text =
                                                        _formatBalance(
                                                            cryptoAmount
                                                                .toString());
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                          _CurrencyTab(
                                            label: 'USD',
                                            isSelected: _isFiat &&
                                                _selectedFiatCurrency == 'USD',
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _isFiat = true;
                                                  _selectedFiatCurrency = 'USD';
                                                  _amountController.clear();
                                                  _feeDetails = null;
                                                });
                                              }
                                            },
                                          ),
                                          _CurrencyTab(
                                            label: _userCurrency,
                                            isSelected: _isFiat &&
                                                _selectedFiatCurrency ==
                                                    _userCurrency,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _isFiat = true;
                                                  _selectedFiatCurrency =
                                                      _userCurrency;
                                                  _amountController.clear();
                                                  _feeDetails = null;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? SafeJetColors.primaryAccent
                                            .withOpacity(0.1)
                                        : SafeJetColors.lightCardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? SafeJetColors.primaryAccent
                                              .withOpacity(0.2)
                                          : SafeJetColors.lightCardBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _amountController,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '0.00',
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                                hintStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey[600]
                                                      : Colors.grey[400],
                                                ),
                                                prefixText: _isFiat
                                                    ? '${_getCurrencySymbol(_selectedFiatCurrency)} '
                                                    : '',
                                              ),
                                              onChanged: (value) {
                                                // Format the input as user types
                                                if (value.isNotEmpty) {
                                                  final formattedValue =
                                                      _formatAmountInput(value);
                                                  if (formattedValue != value) {
                                                    _amountController.text =
                                                        formattedValue;
                                                    _amountController
                                                            .selection =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset: formattedValue
                                                              .length),
                                                    );
                                                    return;
                                                  }
                                                }
                                                setState(() {
                                                  _validateAmount(value);
                                                });
                                              },
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _maxAmount = true;
                                                final balance = double.tryParse(
                                                        _currentAsset['balance']
                                                                ?.toString() ??
                                                            '0') ??
                                                    0.0;
                                                _amountController.text = _isFiat
                                                    ? _convertAmount(
                                                            balance.toString(),
                                                            true)
                                                        .toStringAsFixed(2)
                                                    : _formatBalance(
                                                        balance.toString());
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: SafeJetColors
                                                  .secondaryHighlight,
                                              foregroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'MAX',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_amountController.text.isNotEmpty &&
                                          _amountError == null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _getFormattedAmount(),
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : SafeJetColors
                                                      .lightTextSecondary,
                                            ),
                                          ),
                                        ),
                                      if (_amountError != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _amountError!,
                                            style: TextStyle(
                                              color: SafeJetColors.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Note/Description
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note (Optional)',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? SafeJetColors.primaryAccent
                                          .withOpacity(0.1)
                                      : SafeJetColors.lightCardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? SafeJetColors.primaryAccent
                                            .withOpacity(0.2)
                                        : SafeJetColors.lightCardBorder,
                                  ),
                                ),
                                child: TextField(
                                  controller: _memoController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Add a note or description for this transfer...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Fee Info
                        if (_selectedCoin != null && _feeDetails != null)
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 500),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? SafeJetColors.primaryAccent
                                        .withOpacity(0.1)
                                    : SafeJetColors.lightCardBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? SafeJetColors.primaryAccent
                                          .withOpacity(0.2)
                                      : SafeJetColors.lightCardBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Transfer Fee',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : SafeJetColors
                                                  .lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        _feeDetails != null
                                            ? _formatCryptoAmount(
                                                double.parse(
                                                    _feeDetails!['feeAmount']),
                                                _selectedCoin?.symbol ?? '',
                                              )
                                            : '- ${_selectedCoin?.symbol}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Receiver gets',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : SafeJetColors
                                                  .lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        _receiveAmount != null
                                            ? _formatCryptoAmount(
                                                _receiveAmount!,
                                                _selectedCoin?.symbol ?? '',
                                              )
                                            : '- ${_selectedCoin?.symbol}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 100), // Extra space for button
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Static Send Button
            Container(
              padding: const EdgeInsets.all(16),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_receiverError != null ||
                          _amountError != null ||
                          _receiverController.text.isEmpty ||
                          _amountController.text.isEmpty ||
                          _selectedCoin == null ||
                          !_isReceiverValid)
                      ? null
                      : _processTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors.secondaryHighlight,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
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
                          'Send Transfer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
