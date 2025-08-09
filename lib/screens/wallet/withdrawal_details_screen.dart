import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/withdrawal.dart';
import 'package:intl/intl.dart';

class WithdrawalDetailsScreen extends StatelessWidget {
  final Withdrawal withdrawal;

  const WithdrawalDetailsScreen({
    super.key,
    required this.withdrawal,
  });

  Color _getStatusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.completed:
        return SafeJetColors.success;
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.processing:
        return Colors.blue;
      case WithdrawalStatus.failed:
        return SafeJetColors.error;
    }
  }

  String _getStatusText(WithdrawalStatus status) {
    return status.toString().split('.').last.toUpperCase();
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
        appBar: const CustomAppBar(title: 'Withdrawal Details'),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
                isDark ? SafeJetColors.primaryBackground.withOpacity(0.8) : SafeJetColors.lightBackground.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
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
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Amount',
                            '${withdrawal.amount} ${withdrawal.coin}',
                            theme,
                            isDark,
                            isLarge: true,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Status',
                            _getStatusText(withdrawal.status),
                            theme,
                            isDark,
                            valueColor: _getStatusColor(withdrawal.status),
                          ),
                          const Divider(height: 32),
                          _buildDetailRow(
                            'Date',
                            DateFormat('MMM dd, yyyy HH:mm').format(withdrawal.timestamp),
                            theme,
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Network',
                            withdrawal.network,
                            theme,
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildCopyableRow(
                            'Address',
                            withdrawal.address,
                            theme,
                            isDark,
                            context,
                          ),
                          if (withdrawal.status == WithdrawalStatus.completed) ...[
                            const SizedBox(height: 8),
                            _buildCopyableRow(
                              'Transaction ID',
                              withdrawal.txId,
                              theme,
                              isDark,
                              context,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: isLarge
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        Row(
          children: [
            Text(
              value.substring(0, 6) + '...' + value.substring(value.length - 6),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              iconSize: 16,
              color: SafeJetColors.secondaryHighlight,
              padding: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
} 