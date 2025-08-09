import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme/colors.dart';
import '../main/home_screen.dart';
import 'fiat_screen.dart';

class FiatBuyCryptoSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final Map<String, dynamic> summary;

  const FiatBuyCryptoSuccessScreen({
    Key? key,
    required this.purchase,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionId = purchase['transactionId'] ?? 'N/A';
    final cryptoAmount =
        double.tryParse(summary['cryptoAmount'].toString()) ?? 0.0;
    final cryptoSymbol = summary['crypto'] ?? '';
    final fiatAmount = double.tryParse(summary['fiatAmount'].toString()) ?? 0.0;
    final fee = (summary['fee'] as double?) ?? 0.0;
    final totalDeduct = fiatAmount + fee;
    final fiatSymbol = summary['fiatSymbol'] as String? ?? '';
    final rate = summary['rateInFiat'] ?? 0.0;
    final rateFormatted = summary['rateInFiatFormatted'] ?? '';
    final walletType = summary['walletType'] ?? '';
    final numberFormat = NumberFormat.currency(symbol: fiatSymbol);

    String formatCryptoAmount(double amount) {
      if (amount >= 1) {
        return amount
            .toStringAsFixed(4)
            .replaceFirst(RegExp(r'([.]*0+)\$'), '');
      } else {
        return amount
            .toStringAsFixed(8)
            .replaceFirst(RegExp(r'([.]*0+)\$'), '');
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const FiatScreen(),
          ),
          (route) => false,
        );
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Success Animation and Icon
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Animated Success Circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SafeJetColors.success.withOpacity(0.2),
                              SafeJetColors.success.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: SafeJetColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: SafeJetColors.success.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Success Title
                      Text(
                        'Crypto Purchase Successful!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: SafeJetColors.success,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              SafeJetColors.secondaryHighlight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: SafeJetColors.secondaryHighlight
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: SafeJetColors.secondaryHighlight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Completed',
                              style: TextStyle(
                                color: SafeJetColors.secondaryHighlight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                  // Transaction Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          SafeJetColors.secondaryHighlight.withOpacity(0.1),
                          SafeJetColors.secondaryHighlight.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            SafeJetColors.secondaryHighlight.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crypto Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crypto Received',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatCryptoAmount(cryptoAmount)} $cryptoSymbol',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SafeJetColors.secondaryHighlight,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fiat Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount Paid',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              numberFormat.format(fiatAmount),
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fee
                        if (fee > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fee',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              Text(
                                numberFormat.format(fee),
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Divider
                        Container(
                          height: 1,
                          color:
                              SafeJetColors.secondaryHighlight.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),

                        // Rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rate',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Text(
                              '1 $cryptoSymbol = $rateFormatted',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Total Deducted
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Deducted',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              numberFormat.format(totalDeduct),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SafeJetColors.secondaryHighlight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Transaction ID
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isDark ? Colors.white24 : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction ID',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      transactionId,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: transactionId));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Transaction ID copied to clipboard'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: SafeJetColors
                                          .secondaryHighlight
                                          .withOpacity(0.1),
                                      foregroundColor:
                                          SafeJetColors.secondaryHighlight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Column(
                    children: [
                      // View Crypto Balance Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HomeScreen(initialIndex: 3),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.account_balance_wallet_rounded),
                          label: const Text('View Crypto Balance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.secondaryHighlight,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Back to Home Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const HomeScreen(initialIndex: 2),
                              ),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Back to Home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SafeJetColors.secondaryHighlight,
                            side: BorderSide(
                                color: SafeJetColors.secondaryHighlight),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        ),
      ),
    );
  }
}
