import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String type;
  final String amount;
  final String tokenSymbol;
  final String status;
  final String createdAt;
  final Map<String, dynamic> metadata;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.tokenSymbol,
    required this.status,
    required this.createdAt,
    required this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      // Parse the date from the backend format "MM/dd/yyyy, HH:mm:ss"
      final inputFormat = DateFormat("MM/dd/yyyy, HH:mm:ss");
      final dateTime = inputFormat.parse(json['createdAt']);

      // Format the date in our desired format with day suffix
      final day = dateTime.day;
      final suffix = _getDaySuffix(day);
      final formattedDate =
          DateFormat("d'$suffix' MMM, yyyy. h:mm a").format(dateTime);

      // Format the amount
      String formattedAmount = json['amount'].toString();
      try {
        final double amountValue = double.parse(formattedAmount);
        if (amountValue == amountValue.truncateToDouble()) {
          // If it's a whole number, show no decimals
          formattedAmount = amountValue.toInt().toString();
        } else {
          // For decimals, limit to max 8 places and remove trailing zeros
          formattedAmount = amountValue
              .toStringAsFixed(8)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
        }
      } catch (e) {
        print('Error formatting amount: $formattedAmount');
      }

      return Transaction(
        id: json['id'],
        type: json['type'],
        amount: formattedAmount,
        tokenSymbol: json['tokenSymbol'],
        status: json['status'],
        createdAt: formattedDate,
        metadata: json['metadata'] ?? {},
      );
    } catch (e) {
      print('Error parsing date: ${json['createdAt']}');
      print('Error details');
      // Return the original date string if parsing fails
      return Transaction(
        id: json['id'],
        type: json['type'],
        amount: json['amount'].toString(),
        tokenSymbol: json['tokenSymbol'],
        status: json['status'],
        createdAt: json['createdAt'],
        metadata: json['metadata'] ?? {},
      );
    }
  }

  // Helper method to get day suffix (th, st, nd, rd)
  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String get displayAmount {
    final prefix = type == 'withdrawal'
        ? '-'
        : type == 'deposit'
            ? '+'
            : '';
    return '$prefix$amount $tokenSymbol';
  }

  String get displayType {
    switch (type) {
      case 'deposit':
        return 'Deposit $tokenSymbol';
      case 'withdrawal':
        return 'Withdraw $tokenSymbol';
      case 'conversion':
        final toToken = metadata['toToken'] ?? '';
        return 'Convert $tokenSymbol to $toToken';
      case 'transfer':
        final fromType = metadata['fromType'] ?? '';
        final toType = metadata['toType'] ?? '';
        return 'Transfer from $fromType to $toType';
      case 'internal_transfer':
        final trxId = metadata['trxId'] ?? '';
        return 'Internal Transfer $tokenSymbol';
      default:
        return type;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'withdrawal':
        return Icons.arrow_upward_rounded;
      case 'conversion':
        return Icons.swap_horiz_rounded;
      case 'transfer':
        return Icons.swap_vert_rounded;
      case 'internal_transfer':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return SafeJetColors.success;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return SafeJetColors.error;
      default:
        return Colors.blue;
    }
  }
}
