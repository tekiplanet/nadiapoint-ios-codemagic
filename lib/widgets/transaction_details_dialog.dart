import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/colors.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';
import 'package:get_it/get_it.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class TransactionDetailsDialog extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailsDialog> createState() => _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends State<TransactionDetailsDialog> {
  final _walletService = GetIt.I<WalletService>();
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _error;
  final _numberFormat = NumberFormat("#,##0.####");

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    
    try {
      print('Original value: $value'); // Debug log
      
      // Convert to double, handling string inputs
      final number = double.tryParse(value.toString()) ?? 0;
      print('Parsed number: $number'); // Debug log
      
      // Special handling for very small numbers to preserve precision
      if (number != 0 && number.abs() < 0.01) {
        // Use fixed decimal places for small numbers
        final result = number.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '');
        print('Small number result: $result'); // Debug log
        return result;
      }
      
      // For regular numbers, use number format
      final result = _numberFormat.format(number);
      print('Regular number result: $result'); // Debug log
      return result;
    } catch (e) {
      print('Error formatting number: $e');
      return value.toString();
    }
  }

  Future<void> _loadDetails() async {
    try {
      final details = await _walletService.getTransactionDetails(widget.transaction.id);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load transaction details';
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false, bool highlight = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: highlight 
            ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02))
            : Colors.transparent,
        border: highlight 
            ? Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: isDark ? SafeJetColors.primaryAccent : SafeJetColors.primary,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Copied to clipboard'),
                            ],
                          ),
                          backgroundColor: SafeJetColors.success,
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 8,
        itemBuilder: (context, index) => FadeInDown(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 100 * index),
          child: _buildShimmerRow(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: SafeJetColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: SafeJetColors.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final details = _details!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Transaction Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark 
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBackground,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Icon and Status
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: widget.transaction.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        widget.transaction.typeIcon,
                        color: widget.transaction.statusColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 100),
                child: Column(
                  children: [
                    Text(
                      _formatNumber(widget.transaction.amount),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.transaction.statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.transaction.tokenSymbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status Badge
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.transaction.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.transaction.status.toLowerCase() == 'completed'
                            ? Icons.check_circle_rounded
                            : widget.transaction.status.toLowerCase() == 'pending'
                                ? Icons.pending_rounded
                                : Icons.error_rounded,
                        color: widget.transaction.statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.transaction.status,
                        style: TextStyle(
                          color: widget.transaction.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Transaction Details
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Transaction Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : SafeJetColors.lightText,
                  ),
                ),
              ),
              _buildDetailRow('Type', widget.transaction.displayType, highlight: true),
              _buildDetailRow('Date', widget.transaction.createdAt, highlight: true),
              if (details['network'] != null)
                _buildDetailRow('Network', details['network'], highlight: true),
              if (details['networkVersion'] != null)
                _buildDetailRow('Network Version', details['networkVersion'], highlight: true),
              if (details['blockchain'] != null)
                _buildDetailRow('Blockchain', details['blockchain'], highlight: true),
              if (details['blockNumber'] != null)
                _buildDetailRow('Block Number', details['blockNumber'].toString(), highlight: true),
              if (details['txHash'] != null)
                _buildDetailRow('Transaction Hash', details['txHash'], copyable: true, highlight: true),
              if (details['from'] != null)
                _buildDetailRow('From', details['from'], copyable: true, highlight: true),
              if (details['address'] != null)
                _buildDetailRow('To', details['address'], copyable: true, highlight: true),
              if (details['memo'] != null)
                _buildDetailRow('Memo', details['memo'], highlight: true),
              if (details['toAmount'] != null) ...[
                _buildDetailRow(
                  'To Amount',
                  '${_formatNumber(details['toAmount'])} ${details['toToken']}',
                  highlight: true,
                ),
                _buildDetailRow(
                  'Exchange Rate',
                  _formatNumber(details['exchangeRate']),
                  highlight: true,
                ),
              ],
              if (details['fromType'] != null && details['toType'] != null) ...[
                _buildDetailRow('From', details['fromType'].toUpperCase(), highlight: true),
                _buildDetailRow('To', details['toType'].toUpperCase(), highlight: true),
              ],
              if (details['fee'] != null)
                _buildDetailRow(
                  'Fee',
                  '${_formatNumber(details['fee'])} ${widget.transaction.tokenSymbol}',
                  highlight: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark 
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }
} 