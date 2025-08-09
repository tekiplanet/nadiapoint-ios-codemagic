import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../config/theme/colors.dart';
import '../../models/fiat_transaction.dart';

class FiatTransactionDetailsScreen extends StatelessWidget {
  final FiatTransaction transaction;

  const FiatTransactionDetailsScreen({Key? key, required this.transaction})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat =
        NumberFormat.currency(symbol: _getCurrencySymbol(transaction.currency));
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final transactionId = transaction.reference;
    final statusColor = _getStatusColor(transaction);
    final typeIcon = _getTypeIcon(transaction.type);

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text('Transaction Details',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
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
                            statusColor.withOpacity(0.2),
                            statusColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(typeIcon, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      _getTitle(transaction.type),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
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
                          color:
                              SafeJetColors.secondaryHighlight.withOpacity(0.3),
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
                            _getStatusLabel(transaction),
                            style: TextStyle(
                              color: statusColor,
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
                      color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                    ),
                  ),
                  child:
                      _buildDetails(context, transaction, numberFormat, isDark),
                ),
                const SizedBox(height: 32),
                // Transaction ID Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction ID',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transactionId,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Transaction ID copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: SafeJetColors.secondaryHighlight
                                  .withOpacity(0.1),
                              foregroundColor: SafeJetColors.secondaryHighlight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, FiatTransaction tx,
      NumberFormat numberFormat, bool isDark) {
    switch (tx.type) {
      case FiatTransactionType.deposit:
        return _buildDepositDetails(context, tx, numberFormat, isDark);
      case FiatTransactionType.withdraw:
        return _buildWithdrawalDetails(context, tx, numberFormat, isDark);
      case FiatTransactionType.purchase:
        return _buildPurchaseDetails(context, tx, numberFormat, isDark);
    }
  }

  Widget _buildDepositDetails(BuildContext context, FiatTransaction tx,
      NumberFormat numberFormat, bool isDark) {
    final amount = tx.amount;
    final fee = tx.fee ?? 0.0;
    final totalAmount = amount + fee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('Amount', numberFormat.format(amount), isDark),
        if (fee > 0) ...[
          const SizedBox(height: 12),
          _buildRow('Fee', numberFormat.format(fee), isDark),
        ],
        const SizedBox(height: 12),
        Container(
            height: 1,
            color: SafeJetColors.secondaryHighlight.withOpacity(0.2)),
        const SizedBox(height: 12),
        _buildRow('Total', numberFormat.format(totalAmount), isDark),
      ],
    );
  }

  Widget _buildWithdrawalDetails(BuildContext context, FiatTransaction tx,
      NumberFormat numberFormat, bool isDark) {
    final amount = tx.amount;
    final fee = tx.fee ?? 0.0;
    final totalDeduct = amount + fee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('Amount to Receive', numberFormat.format(amount), isDark),
        if (fee > 0) ...[
          const SizedBox(height: 12),
          _buildRow('Processing Fee', numberFormat.format(fee), isDark),
        ],
        const SizedBox(height: 12),
        Container(
            height: 1,
            color: SafeJetColors.secondaryHighlight.withOpacity(0.2)),
        const SizedBox(height: 12),
        _buildRow('Total Deducted', numberFormat.format(totalDeduct), isDark),
      ],
    );
  }

  Widget _buildPurchaseDetails(BuildContext context, FiatTransaction tx,
      NumberFormat numberFormat, bool isDark) {
    final fiatAmount = tx.amount;
    final fee = tx.fee ?? 0.0;
    final totalDeduct = fiatAmount + fee;
    final cryptoAmount = tx.cryptoAmount ?? 0.0;
    final cryptoSymbol = tx.cryptoSymbol ?? '';
    final rate = tx.exchangeRate ?? 0.0;
    final rateFormatted = rate > 0 ? numberFormat.format(rate) : '';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('Crypto Received',
            '${formatCryptoAmount(cryptoAmount)} $cryptoSymbol', isDark,
            isLarge: true),
        const SizedBox(height: 12),
        _buildRow('Amount Paid', numberFormat.format(fiatAmount), isDark),
        if (fee > 0) ...[
          const SizedBox(height: 12),
          _buildRow('Fee', numberFormat.format(fee), isDark),
        ],
        const SizedBox(height: 12),
        Container(
            height: 1,
            color: SafeJetColors.secondaryHighlight.withOpacity(0.2)),
        const SizedBox(height: 12),
        _buildRow('Rate', '1 $cryptoSymbol = $rateFormatted', isDark),
        const SizedBox(height: 12),
        _buildRow('Total Deducted', numberFormat.format(totalDeduct), isDark),
      ],
    );
  }

  Widget _buildRow(String label, String value, bool isDark,
      {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 22 : 16,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
            color: isLarge
                ? SafeJetColors.secondaryHighlight
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return '₦';
      case 'USD':
        return ' 24';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  Color _getStatusColor(FiatTransaction tx) {
    final status = tx.status.toLowerCase();
    switch (tx.type) {
      case FiatTransactionType.deposit:
        switch (status) {
          case 'pending':
            return Colors.orange;
          case 'processing':
            return Colors.blue;
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'requires_action':
            return Colors.purple;
          default:
            return Colors.grey;
        }
      case FiatTransactionType.withdraw:
        switch (status) {
          case 'pending':
            return Colors.orange;
          case 'processing':
            return Colors.blue;
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'cancelled':
            return Colors.grey;
          case 'requires_action':
            return Colors.purple;
          default:
            return Colors.grey;
        }
      case FiatTransactionType.purchase:
        switch (status) {
          case 'completed':
            return SafeJetColors.success;
          case 'failed':
            return SafeJetColors.error;
          case 'cancelled':
            return Colors.grey;
          default:
            return Colors.grey;
        }
    }
  }

  String _getStatusLabel(FiatTransaction tx) {
    final status = tx.status.toLowerCase();
    switch (tx.type) {
      case FiatTransactionType.deposit:
        switch (status) {
          case 'pending':
            return 'Pending';
          case 'processing':
            return 'Processing';
          case 'completed':
            return 'Completed';
          case 'failed':
            return 'Failed';
          case 'requires_action':
            return 'Requires Action';
          default:
            return status;
        }
      case FiatTransactionType.withdraw:
        switch (status) {
          case 'pending':
            return 'Pending';
          case 'processing':
            return 'Processing';
          case 'completed':
            return 'Completed';
          case 'failed':
            return 'Failed';
          case 'cancelled':
            return 'Cancelled';
          case 'requires_action':
            return 'Requires Action';
          default:
            return status;
        }
      case FiatTransactionType.purchase:
        switch (status) {
          case 'completed':
            return 'Completed';
          case 'failed':
            return 'Failed';
          case 'cancelled':
            return 'Cancelled';
          default:
            return status;
        }
    }
  }

  IconData _getTypeIcon(FiatTransactionType type) {
    switch (type) {
      case FiatTransactionType.deposit:
        return Icons.add_circle_outline_rounded;
      case FiatTransactionType.withdraw:
        return Icons.remove_circle_outline_rounded;
      case FiatTransactionType.purchase:
        return Icons.currency_bitcoin_rounded;
    }
  }

  String _getTitle(FiatTransactionType type) {
    switch (type) {
      case FiatTransactionType.deposit:
        return 'Deposit';
      case FiatTransactionType.withdraw:
        return 'Withdrawal';
      case FiatTransactionType.purchase:
        return 'Crypto Purchase';
    }
  }
}
