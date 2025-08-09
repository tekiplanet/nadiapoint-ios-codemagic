import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/fiat_wallet_service.dart';
import '../../widgets/two_factor_dialog.dart';
import 'package:dio/dio.dart';
import 'fiat_withdrawal_success_screen.dart';

class FiatWithdrawalConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> summary;
  final Map<String, dynamic> accountDetails;
  final String instructions;
  final VoidCallback onConfirm;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> selectedWallet;
  final Map<String, dynamic> selectedMethod;
  final double amount;

  const FiatWithdrawalConfirmationScreen({
    Key? key,
    required this.summary,
    required this.accountDetails,
    required this.instructions,
    required this.onConfirm,
    required this.fields,
    required this.selectedWallet,
    required this.selectedMethod,
    required this.amount,
  }) : super(key: key);

  @override
  State<FiatWithdrawalConfirmationScreen> createState() =>
      _FiatWithdrawalConfirmationScreenState();
}

class _FiatWithdrawalConfirmationScreenState
    extends State<FiatWithdrawalConfirmationScreen> {
  bool _isLoading = false;
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, String?> _fieldErrors = {};
  final FiatWalletService _fiatWalletService = FiatWalletService();

  @override
  void initState() {
    super.initState();
    // Initialize field values with empty or default
    for (final field in widget.fields) {
      _fieldValues[field['name']] = '';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildField(Map<String, dynamic> field) {
    final String name = field['name'] ?? '';
    final String label = field['label'] ?? name;
    final String type = field['type'] ?? 'text';
    final String placeholder = field['placeholder'] ?? '';
    final bool required = field['required'] == true;
    final Map<String, dynamic> validation = field['validation'] ?? {};
    final Map<String, dynamic> options = field['options'] ?? {};
    final String? error = _fieldErrors[name];
    final value = _fieldValues[name] ?? '';

    InputDecoration decoration = InputDecoration(
      labelText: label + (required ? ' *' : ''),
      hintText: placeholder,
      errorText: error,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: SafeJetColors.secondaryHighlight,
          width: 2,
        ),
      ),
      floatingLabelStyle: TextStyle(
        color: SafeJetColors.secondaryHighlight,
        fontWeight: FontWeight.bold,
      ),
    );

    switch (type) {
      case 'textarea':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            minLines: 3,
            maxLines: 6,
            decoration: decoration,
            onChanged: (val) => setState(() => _fieldValues[name] = val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        );
      case 'select':
        final List optionsList = options['list'] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            value: value.isNotEmpty ? value : null,
            decoration: decoration,
            items: optionsList.map<DropdownMenuItem<String>>((opt) {
              return DropdownMenuItem<String>(
                value: opt.toString(),
                child: Text(opt.toString()),
              );
            }).toList(),
            onChanged: (val) => setState(() => _fieldValues[name] = val ?? ''),
          ),
        );
      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: decoration,
            onChanged: (val) => setState(() => _fieldValues[name] = val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        );
      case 'email':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: decoration,
            onChanged: (val) => setState(() => _fieldValues[name] = val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        );
      case 'phone':
      case 'tel':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            keyboardType: TextInputType.phone,
            decoration: decoration,
            onChanged: (val) => setState(() => _fieldValues[name] = val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        );
      case 'text':
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            decoration: decoration,
            onChanged: (val) => setState(() => _fieldValues[name] = val),
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
          ),
        );
    }
  }

  bool _validateFields() {
    bool valid = true;
    _fieldErrors.clear();
    for (final field in widget.fields) {
      final String name = field['name'] ?? '';
      final String label = field['label'] ?? name;
      final String type = field['type'] ?? 'text';
      final bool required = field['required'] == true;
      final Map<String, dynamic> validation = field['validation'] ?? {};
      final value = _fieldValues[name]?.toString() ?? '';
      if (required && value.isEmpty) {
        _fieldErrors[name] = '$label is required';
        valid = false;
        continue;
      }
      if (type == 'email' &&
          value.isNotEmpty &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        _fieldErrors[name] = 'Invalid email address';
        valid = false;
      }
      if (type == 'number' && value.isNotEmpty) {
        final numValue = num.tryParse(value);
        if (numValue == null) {
          _fieldErrors[name] = '$label must be a number';
          valid = false;
        }
        if (validation['min'] != null &&
            numValue != null &&
            numValue < validation['min']) {
          _fieldErrors[name] = '$label must be at least ${validation['min']}';
          valid = false;
        }
        if (validation['max'] != null &&
            numValue != null &&
            numValue > validation['max']) {
          _fieldErrors[name] = '$label must be at most ${validation['max']}';
          valid = false;
        }
      }
      if (validation['minLength'] != null &&
          value.length < validation['minLength']) {
        _fieldErrors[name] =
            '$label must be at least ${validation['minLength']} characters';
        valid = false;
      }
      if (validation['maxLength'] != null &&
          value.length > validation['maxLength']) {
        _fieldErrors[name] =
            '$label must be at most ${validation['maxLength']} characters';
        valid = false;
      }
      if (validation['pattern'] != null && value.isNotEmpty) {
        final reg = RegExp(validation['pattern']);
        if (!reg.hasMatch(value)) {
          _fieldErrors[name] = '$label is invalid';
          valid = false;
        }
      }
    }
    setState(() {});
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = widget.summary;
    final account = widget.accountDetails;
    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: const Text('Confirm Withdrawal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
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
                    color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    // Extract and format values
                    final summary = widget.summary;
                    final amount =
                        (summary['amount'] as num?)?.toDouble() ?? 0.0;
                    final fee = (summary['fee'] as double?) ?? 0.0;
                    final totalDeduct =
                        (summary['totalDeduct'] as double?) ?? (amount + fee);
                    final symbol = summary['symbol'] as String? ?? '';
                    final currency = summary['currency'];
                    String currencyCode = '';
                    if (currency is Map && currency['code'] != null) {
                      currencyCode = currency['code'];
                    } else if (currency is String) {
                      currencyCode = currency;
                    } else {
                      currencyCode = '';
                    }
                    final currencyFormatter = NumberFormat('#,##0.00');
                    return Column(
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
                                summary['icon'],
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
                              symbol,
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
                            const Spacer(),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: totalDeduct.toStringAsFixed(2)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Total to deduct copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.copy_all_rounded,
                                  size: 22,
                                  color: SafeJetColors.secondaryHighlight,
                                ),
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
                              'Amount to Receive',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              '$symbol${currencyFormatter.format(amount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Processing Fee',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              '$symbol${currencyFormatter.format(fee)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
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
                                color: isDark ? Colors.white10 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                summary['walletType'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                summary['method'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey[300]!),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: SafeJetColors.secondaryHighlight, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Withdrawal Instructions',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.instructions,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.fields.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey[300]!),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_rounded,
                              color: SafeJetColors.secondaryHighlight,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Details',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...widget.fields.map(_buildField).toList(),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: SafeJetColors.secondaryHighlight,
                    elevation: 1,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_validateFields()) return;

                          setState(() => _isLoading = true);

                          try {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);

                            // Debug AuthProvider access
                            print('🔐 AuthProvider Debug:');
                            print(
                                '   - AuthProvider available: ${authProvider != null}');
                            print(
                                '   - AuthProvider type: ${authProvider.runtimeType}');

                            String? password;
                            String? twoFactorCode;

                            // Debug user status BEFORE any dialogs
                            print('🔐 User Debug (BEFORE dialogs):');
                            print(
                                '   - User: ${authProvider.user != null ? "loaded" : "null"}');
                            print(
                                '   - Biometric enabled: ${authProvider.user?.biometricEnabled}');
                            print(
                                '   - 2FA enabled: ${authProvider.user?.twoFactorEnabled}');
                            print(
                                '   - User email: ${authProvider.user?.email}');

                            // Add complete user object debug
                            if (authProvider.user != null) {
                              print('🔐 Complete User Object:');
                              print('   - User ID: ${authProvider.user!.id}');
                              print(
                                  '   - Full Name: ${authProvider.user!.fullName}');
                              print('   - Email: ${authProvider.user!.email}');
                              print(
                                  '   - Email Verified: ${authProvider.user!.emailVerified}');
                              print(
                                  '   - Phone Verified: ${authProvider.user!.phoneVerified}');
                              print(
                                  '   - 2FA Enabled: ${authProvider.user!.twoFactorEnabled}');
                              print(
                                  '   - Biometric Enabled: ${authProvider.user!.biometricEnabled}');
                              print(
                                  '   - KYC Level: ${authProvider.user!.kycLevel}');
                              print('   - Phone: ${authProvider.user!.phone}');
                              print(
                                  '   - Country: ${authProvider.user!.countryName}');
                            } else {
                              print('🔐 ERROR: User object is null!');
                            }

                            // Ensure user data is loaded
                            if (authProvider.user == null) {
                              print('🔐 User data not loaded, refreshing...');
                              await authProvider.refreshUserData();
                              print(
                                  '🔐 User data refreshed: ${authProvider.user != null ? "success" : "failed"}');
                              print(
                                  '🔐 After refresh - 2FA enabled: ${authProvider.user?.twoFactorEnabled}');

                              // Add complete user object debug after refresh
                              if (authProvider.user != null) {
                                print(
                                    '🔐 Complete User Object (AFTER refresh):');
                                print('   - User ID: ${authProvider.user!.id}');
                                print(
                                    '   - Full Name: ${authProvider.user!.fullName}');
                                print(
                                    '   - Email: ${authProvider.user!.email}');
                                print(
                                    '   - Email Verified: ${authProvider.user!.emailVerified}');
                                print(
                                    '   - Phone Verified: ${authProvider.user!.phoneVerified}');
                                print(
                                    '   - 2FA Enabled: ${authProvider.user!.twoFactorEnabled}');
                                print(
                                    '   - Biometric Enabled: ${authProvider.user!.biometricEnabled}');
                                print(
                                    '   - KYC Level: ${authProvider.user!.kycLevel}');
                                print(
                                    '   - Phone: ${authProvider.user!.phone}');
                                print(
                                    '   - Country: ${authProvider.user!.countryName}');
                              } else {
                                print(
                                    '🔐 ERROR: User object still null after refresh!');
                              }
                            }

                            // Password dialog (if not biometric user)
                            if (authProvider.user?.biometricEnabled != true) {
                              final passwordController =
                                  TextEditingController();
                              bool isVerifyingPassword = false;
                              final passwordConfirmed = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? SafeJetColors.primaryBackground
                                            : SafeJetColors.lightBackground,
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Icon
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: SafeJetColors
                                                  .secondaryHighlight
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.lock_rounded,
                                              color: SafeJetColors
                                                  .secondaryHighlight,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Title
                                          Text(
                                            'Confirm Withdrawal',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Message
                                          Text(
                                            'Enter your password to confirm withdrawal',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : SafeJetColors
                                                      .lightTextSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Password Input
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? SafeJetColors.primaryAccent
                                                      .withOpacity(0.1)
                                                  : SafeJetColors
                                                      .lightCardBackground,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: TextField(
                                              controller: passwordController,
                                              obscureText: true,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Enter your password',
                                                hintStyle: TextStyle(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[600]
                                                      : Colors.grey[400],
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.all(16),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: isVerifyingPassword
                                                      ? null
                                                      : () => Navigator.pop(
                                                          context, false),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: isVerifyingPassword
                                                      ? null
                                                      : () async {
                                                          setDialogState(() {
                                                            isVerifyingPassword =
                                                                true;
                                                          });
                                                          try {
                                                            final isValid =
                                                                await authProvider
                                                                    .verifyCurrentPassword(
                                                                        passwordController
                                                                            .text);

                                                            if (!isValid) {
                                                              setDialogState(
                                                                  () {
                                                                isVerifyingPassword =
                                                                    false;
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Invalid password. Please try again.'),
                                                                  backgroundColor:
                                                                      SafeJetColors
                                                                          .error,
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            password =
                                                                passwordController
                                                                    .text;
                                                            Navigator.pop(
                                                                context, true);
                                                          } catch (e) {
                                                            setDialogState(() {
                                                              isVerifyingPassword =
                                                                  false;
                                                            });
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(e
                                                                    .toString()
                                                                    .replaceAll(
                                                                        'Exception: ',
                                                                        '')),
                                                                backgroundColor:
                                                                    SafeJetColors
                                                                        .error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        SafeJetColors
                                                            .secondaryHighlight,
                                                    foregroundColor:
                                                        Colors.black,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  child: isVerifyingPassword
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .black),
                                                          ),
                                                        )
                                                      : const Text(
                                                          'Confirm',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
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
                              );
                              if (passwordConfirmed != true) {
                                setState(() => _isLoading = false);
                                return;
                              }
                            }

                            // 2FA dialog (if enabled)
                            if (authProvider.user?.twoFactorEnabled == true) {
                              print(
                                  '🔐 2FA is enabled, showing verification dialog');
                              final verified = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const TwoFactorDialog(
                                  action: 'withdraw',
                                  title: 'Verify 2FA',
                                  message:
                                      'Enter the 6-digit code to confirm withdrawal',
                                ),
                              );
                              print('🔐 2FA dialog result: $verified');
                              if (verified != true) {
                                setState(() => _isLoading = false);
                                return;
                              }

                              // Add a small delay to ensure token is set
                              await Future.delayed(
                                  const Duration(milliseconds: 100));

                              twoFactorCode =
                                  authProvider.getLastVerificationToken();
                              print('🔐 2FA code captured: $twoFactorCode');

                              // Validate 2FA code
                              if (twoFactorCode == null ||
                                  twoFactorCode.isEmpty) {
                                print('🔐 ERROR: 2FA code is null or empty!');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '2FA verification failed. Please try again.'),
                                    backgroundColor: SafeJetColors.error,
                                  ),
                                );
                                setState(() => _isLoading = false);
                                return;
                              }
                              print(
                                  '🔐 2FA code validation passed: ${twoFactorCode.length} characters');
                            }

                            // Debug: Print what we're sending to the API
                            print('🔐 Sending to API:');
                            print(
                                '   - Password: ${password != null ? "provided" : "null"}');
                            print(
                                '   - 2FA Code: ${twoFactorCode != null ? "provided" : "null"}');
                            print('   - 2FA Code value: $twoFactorCode');

                            try {
                              final withdrawalResponse = await _fiatWalletService.createFiatWithdrawal(
                                fiatWalletId: widget.selectedWallet['id'],
                                fiatPaymentMethodId:
                                    widget.selectedMethod['id'],
                                amount: widget.amount,
                                paymentMethodFields: _fieldValues,
                                password: password,
                                twoFactorCode: twoFactorCode,
                              );

                              // Use backend response data for success screen
                              final withdrawalData = {
                                'transactionId': withdrawalResponse['transactionId'] ?? 'N/A',
                                'status': withdrawalResponse['status'] ?? 'pending',
                                'createdAt': withdrawalResponse['createdAt'] ?? DateTime.now().toIso8601String(),
                              };

                              // Navigate to success screen
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FiatWithdrawalSuccessScreen(
                                      withdrawal: withdrawalData,
                                      summary: widget.summary,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('🔐 Caught exception: ${e.toString()}');
                              print('🔐 Exception type: ${e.runtimeType}');
                              print(
                                  '🔐 Exception contains "2FA code required": ${e.toString().contains('2FA code required')}');

                              // Handle DioException specifically
                              if (e is DioException) {
                                print('🔐 DioException detected');
                                print(
                                    '🔐 DioException response: ${e.response?.data}');
                                print(
                                    '🔐 DioException status code: ${e.response?.statusCode}');

                                final responseData = e.response?.data;
                                if (responseData is Map &&
                                    responseData['message'] ==
                                        '2FA code required') {
                                  print(
                                      '🔐 2FA required detected from response data');
                                }
                              }

                              // Check if the error is due to missing 2FA
                              if (e.toString().contains('2FA code required') ||
                                  (e is DioException &&
                                      e.response?.data is Map &&
                                      e.response?.data['message'] ==
                                          '2FA code required')) {
                                print(
                                    '🔐 Backend requires 2FA, showing 2FA dialog');

                                // Show 2FA dialog even if frontend shows it as disabled
                                final verified = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const TwoFactorDialog(
                                    action: 'withdraw',
                                    title: 'Verify 2FA',
                                    message:
                                        'Enter the 6-digit code to confirm withdrawal',
                                  ),
                                );

                                if (verified != true) {
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                // Add a small delay to ensure token is set
                                await Future.delayed(
                                    const Duration(milliseconds: 100));

                                twoFactorCode =
                                    authProvider.getLastVerificationToken();
                                print(
                                    '🔐 2FA code captured (retry): $twoFactorCode');

                                // Validate 2FA code
                                if (twoFactorCode == null ||
                                    twoFactorCode.isEmpty) {
                                  print('🔐 ERROR: 2FA code is null or empty!');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          '2FA verification failed. Please try again.'),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                  return;
                                }

                                // Retry the API call with 2FA code
                                try {
                                  print(
                                      '🔐 Retrying API call with 2FA code...');
                                  final withdrawalResponse = await _fiatWalletService.createFiatWithdrawal(
                                    fiatWalletId: widget.selectedWallet['id'],
                                    fiatPaymentMethodId:
                                        widget.selectedMethod['id'],
                                    amount: widget.amount,
                                    paymentMethodFields: _fieldValues,
                                    password: password,
                                    twoFactorCode: twoFactorCode,
                                  );

                                  // Use backend response data for success screen
                                  final withdrawalData = {
                                    'transactionId': withdrawalResponse['id'] ?? withdrawalResponse['transactionId'] ?? 'N/A',
                                    'status': withdrawalResponse['status'] ?? 'pending',
                                    'createdAt': withdrawalResponse['createdAt'] ?? DateTime.now().toIso8601String(),
                                  };

                                  // Navigate to success screen
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FiatWithdrawalSuccessScreen(
                                          withdrawal: withdrawalData,
                                          summary: widget.summary,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (retryError) {
                                  print(
                                      '🔐 Retry failed: ${retryError.toString()}');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(retryError
                                            .toString()
                                            .replaceAll('Exception: ', '')),
                                        backgroundColor: SafeJetColors.error,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                print(
                                    '🔐 Not a 2FA error, showing generic error');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceAll('Exception: ', '')),
                                      backgroundColor: SafeJetColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e
                                      .toString()
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
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Withdrawal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_rounded,
                                size: 20, color: Colors.black),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
