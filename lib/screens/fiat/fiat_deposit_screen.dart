import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'fiat_deposit_confirmation_dialog.dart';
import '../../services/fiat_wallet_service.dart';
import '../support/support_screen.dart';

class FiatDepositScreen extends StatefulWidget {
  final Map<String, dynamic>? wallet;
  final List<Map<String, dynamic>>? wallets;
  const FiatDepositScreen({Key? key, this.wallet, this.wallets})
      : super(key: key);

  @override
  State<FiatDepositScreen> createState() => _FiatDepositScreenState();
}

class _FiatDepositScreenState extends State<FiatDepositScreen> {
  late List<Map<String, dynamic>> _wallets;
  Map<String, dynamic>? _selectedWallet;
  Map<String, dynamic>? _selectedMethod;
  List<Map<String, dynamic>> _depositMethods = [];
  final TextEditingController _amountController = TextEditingController();
  late NumberFormat _numberFormat;
  int _currentWalletIndex = 0;
  double _calculatedFee = 0.0;
  bool _isLoadingMethods = false;
  final FiatWalletService _fiatWalletService = FiatWalletService();
  String? _validationMessage;
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    assert(widget.wallets != null && widget.wallets!.isNotEmpty,
        'wallets must be provided to FiatDepositScreen');
    _wallets = widget.wallets!;
    // Filter to only active wallets
    _wallets = _wallets.where((w) {
      final status = (w['status'] ?? 'active').toString().toLowerCase();
      return status == 'active';
    }).toList();
    _selectedWallet = widget.wallet ?? _wallets.first;
    // Handle both String and Map for currency field
    final currencyField = _selectedWallet!['currency'];
    final currencyCode =
        currencyField is Map ? currencyField['code'] : currencyField;
    _numberFormat =
        NumberFormat.currency(symbol: _getCurrencySymbol(currencyCode));
    if (widget.wallet == null) {
      _currentWalletIndex = 0;
    } else {
      final selectedCurrencyCode =
          (currencyField is Map) ? currencyField['code'] : currencyField;
      _currentWalletIndex = _wallets.indexWhere((w) {
        final wCurrencyField = w['currency'];
        final wCurrencyCode =
            (wCurrencyField is Map) ? wCurrencyField['code'] : wCurrencyField;
        return wCurrencyCode == selectedCurrencyCode;
      });
    }
    _amountController.addListener(_validateAmount);
    _fetchDepositMethods();
  }

  Future<void> _fetchDepositMethods() async {
    setState(() => _isLoadingMethods = true);
    try {
      final currencyData = _selectedWallet?['currency'];
      final currencyId = (currencyData is Map) ? currencyData['id'] : '';
      if (currencyId.isEmpty) {
        throw Exception('Currency ID is missing');
      }
      final methods =
          await _fiatWalletService.getFiatPaymentMethods(currencyId);
      setState(() {
        _depositMethods = methods;
        if (_depositMethods.isNotEmpty) {
          _selectedMethod = _depositMethods.first;
        } else {
          _selectedMethod = null;
        }
      });
    } catch (e) {
      setState(() => _depositMethods = []);
    } finally {
      setState(() => _isLoadingMethods = false);
      _validateAmount();
    }
  }

  void _onWalletChanged(Map<String, dynamic> wallet, int index) {
    setState(() {
      _selectedWallet = wallet;
      _currentWalletIndex = index;
      final currencyField = _selectedWallet!['currency'];
      final currencyCode =
          currencyField is Map ? currencyField['code'] : currencyField;
      _numberFormat =
          NumberFormat.currency(symbol: _getCurrencySymbol(currencyCode));
      _amountController.clear();
    });
    _fetchDepositMethods();
  }

  double _getFee(Map<String, dynamic>? method, double amount) {
    if (method == null) return 0.0;
    final feeType = method['feeType'];
    final feeValue =
        double.tryParse(method['feeValue']?.toString() ?? '0') ?? 0.0;
    if (feeType == 'percentage') {
      return amount * (feeValue / 100);
    } else if (feeType == 'fixed') {
      return feeValue;
    }
    return 0.0;
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text);
    _calculatedFee = _getFee(_selectedMethod, amount ?? 0.0);

    if (_selectedMethod == null) {
      setState(() {
        _validationMessage = 'Please select a deposit method.';
        _isAmountValid = false;
      });
      return;
    }

    final currencyData = _selectedWallet?['currency'];
    final methodData = _selectedMethod;

    if (currencyData == null || currencyData is! Map || methodData == null) {
      setState(() {
        _validationMessage = 'Configuration error. Please contact support.';
        _isAmountValid = false;
      });
      return;
    }

    final currencyMin =
        double.tryParse(currencyData['minDepositAmount']?.toString() ?? '0') ??
            0.0;
    final currencyMax = double.tryParse(
            currencyData['maxDepositAmount']?.toString() ?? 'Infinity') ??
        double.infinity;
    final methodMin =
        double.tryParse(methodData['minAmount']?.toString() ?? '0') ?? 0.0;
    final methodMax =
        double.tryParse(methodData['maxAmount']?.toString() ?? 'Infinity') ??
            double.infinity;

    // Use the higher of the two minimums, and the higher of the two maximums
    final finalMin = max(currencyMin, methodMin);
    final finalMax = max(currencyMax, methodMax);

    // --- DEBUG PRINTS ---
    print('--- VALIDATION DEBUG ---');
    print(
        'Currency Limits (for reference): ${currencyData['minDepositAmount']} - ${currencyData['maxDepositAmount']}');
    print('Method Limits:   $methodMin - $methodMax');
    print('Final Limits:    $finalMin - $finalMax');
    print('------------------------');

    final String minText = _numberFormat.format(finalMin);
    final String maxText = finalMax == double.infinity
        ? 'unlimited'
        : _numberFormat.format(finalMax);
    final String limitsHint = 'Limits: $minText - $maxText';

    if (amount == null || _amountController.text.isEmpty) {
      setState(() {
        _validationMessage = limitsHint;
        _isAmountValid = false;
      });
      return;
    }

    if (amount < finalMin) {
      setState(() {
        _validationMessage = 'Amount is below minimum of $minText';
        _isAmountValid = false;
      });
    } else if (amount > finalMax && finalMax != double.infinity) {
      setState(() {
        _validationMessage = 'Amount is above maximum of $maxText';
        _isAmountValid = false;
      });
    } else {
      setState(() {
        _validationMessage = limitsHint;
        _isAmountValid = true;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: const Text('Deposit Fiat',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Gradient Header Card with Wallet Info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildHeaderCard(context, isDark),
            ),
            // Wallet selection section (Modal Bottom Sheet with Search)
            if (widget.wallet == null) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Text('Select Wallet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                      _onWalletChanged(selected, _wallets.indexOf(selected));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.04)
                              : Colors.grey.withOpacity(0.08),
                          blurRadius: 8,
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
                                    color: SafeJetColors.secondaryHighlight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Currency code and wallet type
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currencyCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedWallet!['type'] ?? 'Main Wallet',
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
                            const SizedBox(width: 10),
                            // Dropdown arrow
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 28),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Deposit Method Section (Modern, Compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (_isLoadingMethods)
                    Center(child: CircularProgressIndicator()),
                  if (!_isLoadingMethods && _depositMethods.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 48,
                              color: SafeJetColors.secondaryHighlight),
                          const SizedBox(height: 16),
                          Text(
                            'No deposit methods available',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no deposit methods for this currency. Please contact support for assistance.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isDark ? Colors.white70 : Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SupportScreen()),
                              );
                            },
                            icon: const Icon(Icons.support_agent,
                                color: Colors.white),
                            label: const Text('Contact Support',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.secondaryHighlight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_isLoadingMethods)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _depositMethods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final method = _depositMethods[i];
                        final selected = _selectedMethod == method;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selectedMethod = method;
                              _validateAmount();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? SafeJetColors.secondaryHighlight
                                      .withOpacity(0.13)
                                  : (isDark ? Colors.white10 : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? SafeJetColors.secondaryHighlight
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.grey[300]!),
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (selected)
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
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: SafeJetColors.secondaryHighlight
                                        .withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.account_balance_rounded,
                                      color: SafeJetColors.secondaryHighlight,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(method['name'] ?? '',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black)),
                                      Text(method['description'] ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? SafeJetColors.secondaryHighlight
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: SafeJetColors.secondaryHighlight,
                                        width: 2),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.black)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Amount Input (Modern, Compact)
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Modern badges for limit and fee (each on its own row)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_validationMessage != null &&
                              _validationMessage!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _isAmountValid
                                    ? SafeJetColors.success.withOpacity(0.13)
                                    : SafeJetColors.error.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isAmountValid
                                      ? SafeJetColors.success
                                      : SafeJetColors.error,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isAmountValid
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.info_outline_rounded,
                                    color: _isAmountValid
                                        ? SafeJetColors.success
                                        : SafeJetColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _validationMessage!,
                                      style: TextStyle(
                                        color: _isAmountValid
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
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Add summary card (copied from confirmation dialog)
                      Builder(
                        builder: (context) {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0.0;
                          final fee = _calculatedFee;
                          final totalAmount = amount + fee;
                          final currencyFormatter = NumberFormat('#,##0.00');
                          final walletType =
                              _selectedWallet?['type'] ?? 'Main Wallet';
                          final methodName = (() {
                            final name = _selectedMethod?['name'];
                            if (name != null && (name as String).isNotEmpty) {
                              return name;
                            }
                            return 'No method selected';
                          })();
                          final icon = _selectedWallet?['icon'] ??
                              Icons.account_balance_wallet_rounded;
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SafeJetColors.secondaryHighlight
                                      .withOpacity(0.15),
                                  SafeJetColors.secondaryHighlight
                                      .withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: SafeJetColors.secondaryHighlight
                                    .withOpacity(0.2),
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
                                      child: Icon(
                                        icon,
                                        color: SafeJetColors.secondaryHighlight,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$currencyCode Deposit',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Total to Pay',
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
                                      currencySymbol,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: SafeJetColors.secondaryHighlight,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      currencyFormatter.format(totalAmount),
                                      style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: SafeJetColors.secondaryHighlight,
                                        height: 1,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Amount',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$currencySymbol${currencyFormatter.format(amount)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
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
                                      'Fee',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '$currencySymbol${currencyFormatter.format(fee)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
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
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        walletType,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
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
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        methodName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
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
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
            onPressed: !_isAmountValid
                ? null
                : () async {
                    final currencyField = _selectedWallet!['currency'];
                    final currencyCode = (currencyField is Map)
                        ? currencyField['code']
                        : currencyField;
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final fee = _getFee(_selectedMethod, amount);
                    final summary = {
                      'icon': _selectedWallet?['icon'] ??
                          Icons.account_balance_wallet_rounded,
                      'currency': currencyCode,
                      'symbol': (currencyField is Map &&
                              currencyField['symbol'] != null &&
                              currencyField['symbol'].toString().isNotEmpty)
                          ? currencyField['symbol']
                          : currencyCode,
                      'amount': amount,
                      'walletType': _selectedWallet?['type'] ?? 'Main Wallet',
                      'method': _selectedMethod?['name'] ?? '',
                      'fee': fee,
                      'fiatWalletId': _selectedWallet!['id'],
                      'fiatPaymentMethodId': _selectedMethod!['id'],
                      'wallets': _wallets,
                    };

                    List<Map<String, dynamic>> accountDetails = [];
                    String instructions = '';
                    if (_selectedMethod != null) {
                      final method = await _fiatWalletService
                          .getFiatPaymentMethodById(_selectedMethod!['id']);

                      // Build account details from method.details
                      accountDetails = (method['details'] as List? ?? [])
                          .where((detail) => detail['isPublic'] == true)
                          .map((detail) => Map<String, dynamic>.from(detail))
                          .toList();

                      // Build instructions from method.instructions
                      if ((method['instructions'] ?? []).isNotEmpty) {
                        instructions = (method['instructions'] as List)
                            .map((ins) =>
                                '${ins['order'] + 1}. ${ins['content']}')
                            .join('\n');
                      }
                    }

                    print(
                        'DEBUG: Instructions string:\n---\n$instructions\n---');

                    await FiatDepositConfirmationDialog.show(
                      context,
                      summary: summary,
                      accountDetails: accountDetails,
                      instructions: instructions,
                      onConfirm: () {
                        // Refresh the wallet data after successful deposit
                        Navigator.of(context).pop();
                      },
                    );
                  },
            child: const Text(
              'Deposit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
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
          // Left column: Icon+Currency (aligned with badge below)
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
                    'Deposit to',
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
                _numberFormat.format(balance),
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

  Widget _buildWalletListTile(
      Map<String, dynamic> wallet, bool isDark, ThemeData theme) {
    // This replicates the details shown in the current select wallet implementation
    final currencyField = wallet['currency'];
    final currency =
        currencyField is Map ? currencyField['code'] : currencyField;
    final icon = wallet['icon'] ?? Icons.account_balance_wallet_rounded;
    var balanceRaw = wallet['balance'];
    double balance;
    if (balanceRaw is String) {
      balance = double.tryParse(balanceRaw) ?? 0.0;
    } else if (balanceRaw is num) {
      balance = balanceRaw.toDouble();
    } else {
      balance = 0.0;
    }
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SafeJetColors.secondaryHighlight.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getCurrencySymbol(currency),
              style: TextStyle(
                color: SafeJetColors.secondaryHighlight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currency,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black)),
            Text(wallet['type'] ?? 'Main Wallet',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black54)),
            Text(
                _getCurrencySymbol(currency) +
                    NumberFormat.compact().format(balance),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: SafeJetColors.secondaryHighlight)),
          ],
        ),
      ],
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

// Add the modal widget at the end of the file
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
