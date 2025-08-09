import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import '../../services/fiat_crypto_purchase_service.dart';
import '../../screens/fiat/fiat_buy_crypto_success_screen.dart';

class FiatBuyCryptoConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> summary;
  final VoidCallback onConfirm;

  const FiatBuyCryptoConfirmationDialog(
      {Key? key, required this.summary, required this.onConfirm})
      : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> summary,
    required VoidCallback onConfirm,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => FiatBuyCryptoConfirmationDialog(
          summary: summary,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  @override
  State<FiatBuyCryptoConfirmationDialog> createState() =>
      _FiatBuyCryptoConfirmationDialogState();
}

class _FiatBuyCryptoConfirmationDialogState
    extends State<FiatBuyCryptoConfirmationDialog> {
  bool _isProcessing = false;
  String? _errorMessage;
  final FiatCryptoPurchaseService _purchaseService =
      FiatCryptoPurchaseService();

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Extract data from summary
      final fiatWalletId = widget.summary['fiatWalletId'] as String?;
      final tokenId = widget.summary['tokenId'] as String?;
      final fiatAmount = widget.summary['fiatAmount'] as double?;

      if (fiatWalletId == null || tokenId == null || fiatAmount == null) {
        throw Exception('Missing required purchase data');
      }

      // Call the API
      final result = await _purchaseService.createPurchase(
        fiatWalletId: fiatWalletId,
        tokenId: tokenId,
        fiatAmount: fiatAmount,
      );

      setState(() {
        _isProcessing = false;
      });

      // Show success screen
      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FiatBuyCryptoSuccessScreen(
              purchase: result,
              summary: widget.summary,
            ),
          ),
        );
      }

      // Call the onConfirm callback
      widget.onConfirm();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: SafeJetColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging for summary values
    print('--- FiatBuyCryptoConfirmationDialog summary debug ---');
    widget.summary.forEach((key, value) {
      print('  $key: value=$value, type=${value.runtimeType}');
    });
    print('---------------------------------------------------');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double fiatAmount = widget.summary['fiatAmount'] is double
        ? widget.summary['fiatAmount']
        : double.tryParse(widget.summary['fiatAmount'].toString()) ?? 0.0;
    double fee = widget.summary['fee'] is double
        ? widget.summary['fee']
        : double.tryParse(widget.summary['fee'].toString()) ?? 0.0;
    double rate = widget.summary['rateInFiat'] is double
        ? widget.summary['rateInFiat']
        : double.tryParse(widget.summary['rateInFiat'].toString()) ?? 0.0;
    double cryptoAmount = widget.summary['cryptoAmount'] is double
        ? widget.summary['cryptoAmount']
        : double.tryParse(widget.summary['cryptoAmount'].toString()) ?? 0.0;
    final fiatSymbol = widget.summary['fiatSymbol'] ?? '';
    final crypto = widget.summary['crypto'] ?? '';
    final cryptoName = widget.summary['cryptoName'] ?? '';
    final wallet = widget.summary['wallet'] ?? '';
    final walletType = widget.summary['walletType'] ?? '';
    final icon = widget.summary['icon'];
    final fiatAmountFormatted =
        widget.summary['fiatAmountFormatted'] ?? fiatAmount.toStringAsFixed(2);
    final feeFormatted =
        widget.summary['feeFormatted'] ?? fee.toStringAsFixed(2);
    final rateInFiatFormatted =
        widget.summary['rateInFiatFormatted'] ?? rate.toStringAsFixed(2);

    return Material(
      color: isDark ? SafeJetColors.primaryBackground : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirm Purchase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  if (!_isProcessing)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Error message if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SafeJetColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SafeJetColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: SafeJetColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: SafeJetColors.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                    Row(
                      children: [
                        if (icon is String && icon.isNotEmpty)
                          Image.network(
                            icon,
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.currency_bitcoin_rounded,
                              color: SafeJetColors.secondaryHighlight,
                              size: 28,
                            ),
                          )
                        else if (icon is IconData)
                          Icon(
                            icon,
                            color: SafeJetColors.secondaryHighlight,
                            size: 28,
                          )
                        else
                          Icon(
                            Icons.currency_bitcoin_rounded,
                            color: SafeJetColors.secondaryHighlight,
                            size: 28,
                          ),
                        const SizedBox(width: 16),
                        Text(
                          '$cryptoName ($crypto)',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSummaryRow('From Wallet', wallet),
                    _buildSummaryRow(
                        'Amount', '$fiatSymbol$fiatAmountFormatted'),
                    _buildSummaryRow('Fee', '$fiatSymbol$feeFormatted'),
                    _buildSummaryRow(
                        'Rate', '1 $crypto = $fiatSymbol$rateInFiatFormatted'),
                    _buildSummaryRow('You Receive',
                        '${cryptoAmount.toStringAsFixed(8)} $crypto'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    backgroundColor: _isProcessing
                        ? Colors.grey
                        : SafeJetColors.secondaryHighlight,
                    elevation: 1,
                  ),
                  onPressed: _isProcessing ? null : _processPurchase,
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Processing...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Purchase',
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
