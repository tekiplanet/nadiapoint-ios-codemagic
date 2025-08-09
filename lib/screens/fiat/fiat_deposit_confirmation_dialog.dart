import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/fiat_wallet_service.dart';
import '../../services/file_upload_service.dart';
import 'fiat_deposit_success_screen.dart';

class FiatDepositConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> accountDetails;
  final String instructions;
  final VoidCallback onConfirm;

  const FiatDepositConfirmationDialog({
    Key? key,
    required this.summary,
    required this.accountDetails,
    required this.instructions,
    required this.onConfirm,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> accountDetails,
    required String instructions,
    required VoidCallback onConfirm,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.95,
        minChildSize: 0.7,
        maxChildSize: 0.98,
        builder: (_, controller) => FiatDepositConfirmationDialog(
          summary: summary,
          accountDetails: accountDetails,
          instructions: instructions,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<FiatDepositConfirmationDialog> createState() =>
      _FiatDepositConfirmationDialogState();
}

class _FiatDepositConfirmationDialogState
    extends State<FiatDepositConfirmationDialog> {
  bool _isLoading = false;
  File? _proofFile;
  final FiatWalletService _fiatWalletService = FiatWalletService();
  final FileUploadService _fileUploadService = FileUploadService();

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _proofFile = File(picked.path);
      });
    }
  }

  Future<void> _submitDeposit() async {
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload proof of payment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload the proof of payment file
      final uploadResult = await _fileUploadService.uploadFile(
        _proofFile!,
        folder: 'proof-of-payment',
      );

      // Create the deposit
      final deposit = await _fiatWalletService.createFiatDeposit(
        fiatWalletId: widget.summary['fiatWalletId'],
        fiatPaymentMethodId: widget.summary['fiatPaymentMethodId'],
        amount: widget.summary['amount'],
        proofOfPaymentFileId: uploadResult['id'],
      );

      setState(() => _isLoading = false);

      // Navigate to success screen, replacing the deposit flow screens
      Navigator.of(context).pop(); // Close the dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FiatDepositSuccessScreen(
            deposit: deposit,
            summary: widget.summary,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting deposit: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = widget.summary;
    final accountDetails = widget.accountDetails;

    final amount = double.tryParse(summary['amount'].toString()) ?? 0.0;
    final fee = (summary['fee'] as double?) ?? 0.0;
    final totalAmount = amount + fee;
    final symbol = summary['symbol'] as String? ?? '';
    final currencyFormatter = NumberFormat('#,##0.00');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Scaffold(
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Header with drag indicator
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Deposit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Deposit Summary Card
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Title Row with Icon
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
                            '${summary['currency']} Deposit',
                            style: theme.textTheme.titleMedium?.copyWith(
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
                          color:
                              SafeJetColors.secondaryHighlight.withOpacity(0.8),
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
                            currencyFormatter.format(totalAmount),
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
                                  text: totalAmount.toStringAsFixed(2)));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Total amount copied to clipboard'),
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
                      _buildBreakdownRow('Amount to Deposit',
                          '$symbol${currencyFormatter.format(amount)}', isDark),
                      const SizedBox(height: 8),
                      _buildBreakdownRow('Processing Fee',
                          '$symbol${currencyFormatter.format(fee)}', isDark),
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
                                color:
                                    isDark ? Colors.white24 : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              summary['walletType'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
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
                                color:
                                    isDark ? Colors.white24 : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              summary['method'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Deposit Instructions
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
                              color: SafeJetColors.secondaryHighlight,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Deposit Instructions',
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
                const SizedBox(height: 20),
                // Account Details
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
                          Icon(Icons.credit_card_rounded,
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
                      ...accountDetails
                          .map((detail) =>
                              _buildDetailItem(context, detail, isDark))
                          .toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Upload Proof
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
                          Icon(Icons.upload_file_rounded,
                              color: SafeJetColors.secondaryHighlight,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Upload Proof of Payment',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _proofFile == null
                          ? InkWell(
                              onTap: _pickProof,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_rounded,
                                      size: 32,
                                      color: SafeJetColors.secondaryHighlight,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Tap to upload proof of payment',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG, PNG or PDF',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: FileImage(_proofFile!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(
                                          Icons.delete_outline_rounded),
                                      label: const Text('Remove'),
                                      onPressed: () =>
                                          setState(() => _proofFile = null),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red[400],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton.icon(
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Change'),
                                      onPressed: _pickProof,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            SafeJetColors.secondaryHighlight,
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
                // Confirm Button
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
                    onPressed: _isLoading ? null : _submitDeposit,
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
                                'Confirm Deposit',
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
      ),
    );
  }
}

Widget _buildBreakdownRow(String label, String value, bool isDark) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    ],
  );
}

Widget _buildDetailItem(
    BuildContext context, Map<String, dynamic> detail, bool isDark) {
  final label = detail['label'] as String? ?? '';
  final value = detail['value'] as String? ?? '';
  final type = detail['type'] as String? ?? 'text';

  Widget content;

  switch (type) {
    case 'image':
    case 'qr_code':
      content = Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            value,
            height: 150,
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stack) {
              return const Center(child: Icon(Icons.error_outline_rounded));
            },
          ),
        ),
      );
      break;
    case 'link':
      content = GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(value);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      );
      break;
    default:
      content = Row(
        children: [
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          )
        ],
      );
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        content,
      ],
    ),
  );
}
