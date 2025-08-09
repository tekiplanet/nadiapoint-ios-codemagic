import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'fiat_withdrawal_confirmation_dialog.dart';
import '../../services/fiat_wallet_service.dart';
import '../../screens/support/support_screen.dart';
import '../../widgets/two_factor_dialog.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'fiat_withdrawal_success_screen.dart';

class FiatWithdrawalScreen extends StatefulWidget {
  final Map<String, dynamic>? wallet;
  final List<Map<String, dynamic>>? wallets;
  const FiatWithdrawalScreen({Key? key, this.wallet, this.wallets})
      : super(key: key);

  @override
  State<FiatWithdrawalScreen> createState() => _FiatWithdrawalScreenState();
}

class _FiatWithdrawalScreenState extends State<FiatWithdrawalScreen> {
  late List<Map<String, dynamic>> _wallets;
  Map<String, dynamic>? _selectedWallet;
  List<Map<String, dynamic>> _withdrawalMethods = [];
  Map<String, dynamic>? _selectedMethod;
  bool _isLoadingMethods = false;
  final FiatWalletService _fiatWalletService = FiatWalletService();
  final TextEditingController _amountController = TextEditingController();
  late NumberFormat _numberFormat;
  int _currentWalletIndex = 0;
  double _calculatedFee = 0.0;
  String? _validationMessage;
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    assert(widget.wallets != null && widget.wallets!.isNotEmpty,
        'wallets must be provided to FiatWithdrawalScreen');
    _wallets = widget.wallets!;
    // Filter to only active wallets
    _wallets = _wallets.where((w) {
      final status = (w['status'] ?? 'active').toString().toLowerCase();
      return status == 'active';
    }).toList();
    _selectedWallet = widget.wallet ?? _wallets.first;
    final currencyField = _selectedWallet!['currency'];
    final currencyCode =
        currencyField is Map ? currencyField['code'] : currencyField;
    _numberFormat =
        NumberFormat.currency(symbol: _getCurrencySymbol(currencyCode));
    if (widget.wallet == null) {
      _currentWalletIndex = 0;
    } else {
      final selectedCurrencyCode =
          currencyField is Map ? currencyField['code'] : currencyField;
      _currentWalletIndex = _wallets.indexWhere((w) {
        final wCurrencyField = w['currency'];
        final wCurrencyCode =
            wCurrencyField is Map ? wCurrencyField['code'] : wCurrencyField;
        return wCurrencyCode == selectedCurrencyCode;
      });
    }
    _amountController.addListener(_validateAmount);
    _fetchWithdrawalMethods();
  }

  Future<void> _fetchWithdrawalMethods() async {
    setState(() => _isLoadingMethods = true);
    try {
      final currencyField = _selectedWallet?['currency'];
      final currencyId = (currencyField is Map) ? currencyField['id'] : '';
      if (currencyId.isEmpty) {
        throw Exception('Currency ID is missing');
      }
      final methods =
          await _fiatWalletService.getFiatWithdrawalMethods(currencyId);
      setState(() {
        _withdrawalMethods = methods;
        _selectedMethod =
            _withdrawalMethods.isNotEmpty ? _withdrawalMethods.first : null;
      });
      _validateAmount();
    } catch (e) {
      setState(() {
        _withdrawalMethods = [];
        _selectedMethod = null;
      });
    } finally {
      setState(() => _isLoadingMethods = false);
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
    _fetchWithdrawalMethods();
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text);
    final fee = _getFee(_selectedMethod?['feeType'], amount ?? 0.0);
    _calculatedFee = fee;
    final totalDeduct = (amount ?? 0.0) + fee;

    if (_selectedMethod == null) {
      setState(() {
        _validationMessage = 'Please select a withdrawal method.';
        _isAmountValid = false;
      });
      return;
    }

    final currencyData = _selectedWallet?['currency'];
    final methodData = _selectedMethod;

    if (currencyData == null || methodData == null) {
      setState(() {
        _validationMessage = 'Configuration error. Please contact support.';
        _isAmountValid = false;
      });
      return;
    }

    // Wallet min/max withdrawal
    double walletMin = 0.0;
    double walletMax = double.infinity;
    if (currencyData is Map) {
      walletMin = double.tryParse(
              currencyData['minWithdrawalAmount']?.toString() ?? '0') ??
          0.0;
      walletMax = double.tryParse(
              currencyData['maxWithdrawalAmount']?.toString() ?? 'Infinity') ??
          double.infinity;
    }
    // Method min/max
    final methodMin =
        double.tryParse(methodData['minAmount']?.toString() ?? '0') ?? 0.0;
    final methodMax =
        double.tryParse(methodData['maxAmount']?.toString() ?? 'Infinity') ??
            double.infinity;

    // Use the higher of the two minimums, and the lower of the two maximums
    final finalMin = walletMin > methodMin ? walletMin : methodMin;
    final finalMax = walletMax < methodMax ? walletMax : methodMax;

    // User's available balance
    final balanceRaw = _selectedWallet?['balance'];
    double balance;
    if (balanceRaw is String) {
      balance = double.tryParse(balanceRaw) ?? 0.0;
    } else if (balanceRaw is num) {
      balance = balanceRaw.toDouble();
    } else {
      balance = 0.0;
    }

    final String minText = _numberFormat.format(finalMin);
    final String maxText = finalMax == double.infinity
        ? 'unlimited'
        : _numberFormat.format(finalMax);
    final String limitsHint = 'Limits: $minText - $maxText';
    final String feeText = _numberFormat.format(fee);

    if (amount == null || _amountController.text.isEmpty) {
      setState(() {
        _validationMessage = limitsHint;
        _isAmountValid = false;
      });
      return;
    }

    // Check if amount alone is too high
    if (amount > balance) {
      setState(() {
        _validationMessage =
            'Your balance is insufficient for this withdrawal amount.';
        _isAmountValid = false;
      });
      return;
    }

    // Check if fee alone is the problem
    if (amount <= balance && totalDeduct > balance) {
      setState(() {
        _validationMessage =
            'Your balance cannot cover the processing fee of $feeText.';
        _isAmountValid = false;
      });
      return;
    }

    // Check if both are too high
    if (amount > balance && totalDeduct > balance) {
      setState(() {
        _validationMessage =
            'Your balance cannot cover the withdrawal amount and the processing fee.';
        _isAmountValid = false;
      });
      return;
    }

    if (totalDeduct < finalMin) {
      setState(() {
        _validationMessage = 'Total deduction is below minimum of $minText';
        _isAmountValid = false;
      });
    } else if (totalDeduct > finalMax && finalMax != double.infinity) {
      setState(() {
        _validationMessage = 'Total deduction is above maximum of $maxText';
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
        title: const Text('Withdraw Fiat',
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
                        return _WalletSelectionModalWithdraw(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (_isLoadingMethods)
                    Center(child: CircularProgressIndicator()),
                  if (!_isLoadingMethods && _withdrawalMethods.isEmpty)
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
                            'No withdrawal methods available',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no withdrawal methods for this currency. Please contact support for assistance.',
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
                      itemCount: _withdrawalMethods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final method = _withdrawalMethods[i];
                        final selected = _selectedMethod == method;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selectedMethod = method;
                            });
                            _validateAmount();
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
            // Amount Section (modern card-like input + full-width validation/limit label)
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
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final fee = _calculatedFee;
                  final totalDeduct = amount + fee;
                  final walletType = _selectedWallet?['type'] ?? 'Main Wallet';
                  String methodName = 'No method selected';
                  final selectedMethodName = _selectedMethod?['name'];
                  if (selectedMethodName != null &&
                      (selectedMethodName as String).isNotEmpty) {
                    methodName = selectedMethodName;
                  }
                  final icon = _selectedWallet?['icon'] ??
                      Icons.account_balance_wallet_rounded;
                  final currencyFormatter = NumberFormat('#,##0.00');
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
                                final balance =
                                    _selectedWallet?['balance'] ?? 0.0;
                                _amountController.text = balance.toString();
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
                      // Full-width validation/limit label
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
                      const SizedBox(height: 18),
                      // Summary card (matches confirmation dialog)
                      Container(
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
                                  '$currencyCode Withdrawal',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total to Deduct',
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
                                  currencyFormatter.format(totalDeduct),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    color:
                                        isDark ? Colors.white : Colors.black87,
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
                                    color:
                                        isDark ? Colors.white : Colors.black87,
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
                                    color:
                                        isDark ? Colors.white10 : Colors.white,
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
                                    color:
                                        isDark ? Colors.white10 : Colors.white,
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
                    if (_amountController.text.isEmpty ||
                        double.tryParse(_amountController.text) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid amount.')),
                      );
                      return;
                    }
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final fee = _getFee(_selectedMethod?['feeType'], amount);
                    final totalDeduct = amount + fee;
                    final currencyField = _selectedWallet?['currency'];
                    final currencyCode = currencyField is Map
                        ? currencyField['code']
                        : currencyField;
                    final summary = {
                      'icon': _selectedWallet?['icon'] ??
                          Icons.account_balance_wallet_rounded,
                      'currency': _selectedWallet?['currency'] ?? '',
                      'symbol': (currencyField is Map &&
                              currencyField['symbol'] != null &&
                              currencyField['symbol'].toString().isNotEmpty)
                          ? currencyField['symbol']
                          : currencyCode,
                      'amount': amount,
                      'totalDeduct': totalDeduct,
                      'walletType': _selectedWallet?['type'] ?? 'Main Wallet',
                      'method': _selectedMethod?['name'] ?? '',
                      'fee': fee,
                      'wallets': widget.wallets ?? _wallets,
                    };
                    final accountDetails = {
                      'Account Name': 'John Doe',
                      'Account Number': '1234567890',
                      'Bank': 'Sample Bank',
                    };
                    final instructions =
                        '1. Ensure your details are correct.\n2. Withdrawals may take up to 24 hours.\n3. Click confirm to proceed.';
                    // Show confirmation dialog (no password/2FA fields)
                    final confirmResult = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FiatWithdrawalConfirmationScreen(
                          summary: summary,
                          accountDetails: accountDetails,
                          instructions: instructions,
                          onConfirm: () {},
                          fields: List<Map<String, dynamic>>.from(
                              _selectedMethod?['fields'] ?? []),
                          selectedWallet: _selectedWallet!,
                          selectedMethod: _selectedMethod!,
                          amount: amount,
                        ),
                      ),
                    );
                    if (confirmResult == null) return;

                    // The withdrawal process is now handled in the confirmation dialog
                    // No need for additional logic here
                  },
            child: const Text(
              'Withdraw',
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
    final currencyField = wallet['currency'];
    final currencyCode =
        currencyField is Map ? currencyField['code'] : currencyField;
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
    if (currencyField is Map) {
      primaryColorHex = currencyField['primaryColor'] as String?;
      secondaryColorHex = currencyField['secondaryColor'] as String?;
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
    String symbol = '';
    if (currencyField is Map && currencyField['symbol'] != null) {
      symbol = currencyField['symbol'];
    } else {
      symbol = _getCurrencySymbol(currencyCode);
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
                    'Withdraw from',
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
                symbol + _numberFormat.format(balance).replaceAll(symbol, ''),
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

  double _getFee(String? feeType, double amount) {
    if (_selectedMethod == null) return 0.0;
    final feeType = _selectedMethod?['feeType'];
    final feeValue =
        double.tryParse(_selectedMethod?['feeValue']?.toString() ?? '0') ?? 0.0;
    if (feeType == 'percentage') {
      return amount * (feeValue / 100);
    } else if (feeType == 'fixed') {
      return feeValue;
    }
    return 0.0;
  }
}

class _WalletSelectionModalWithdraw extends StatefulWidget {
  final List<Map<String, dynamic>> wallets;
  final Map<String, dynamic>? selectedWallet;
  final ThemeData theme;
  final bool isDark;
  const _WalletSelectionModalWithdraw({
    required this.wallets,
    required this.selectedWallet,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_WalletSelectionModalWithdraw> createState() =>
      _WalletSelectionModalWithdrawState();
}

class _WalletSelectionModalWithdrawState
    extends State<_WalletSelectionModalWithdraw> {
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
        final currencyCode =
            currencyField is Map ? currencyField['code'] : currencyField;
        final type = wallet['type'] ?? '';
        final searchLower = query.toLowerCase();
        return currencyCode.toString().toLowerCase().contains(searchLower) ||
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
