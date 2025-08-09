import 'package:flutter/material.dart';
import '../config/theme/colors.dart';

class OrderBook extends StatelessWidget {
  const OrderBook({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        // Padding(
        //   padding: const EdgeInsets.all(16),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         'Order Book',
        //         style: theme.textTheme.titleMedium?.copyWith(
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //       Row(
        //         children: [
        //           _buildPrecisionButton('0.1', true, isDark),
        //           const SizedBox(width: 8),
        //           _buildPrecisionButton('0.01', false, isDark),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),

        // Column Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Price',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Sell Orders (Red)
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: 8,
            itemBuilder: (context, index) => _buildOrderRow(
              42384.21 + (index * 10),
              0.12345,
              SafeJetColors.error.withOpacity(0.1),
              SafeJetColors.error,
              isDark,
              theme,
            ),
          ),
        ),

        // Spread
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Spread: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                ),
              ),
              Text(
                '\$12.45 (0.03%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white : SafeJetColors.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Buy Orders (Green)
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => _buildOrderRow(
              42384.21 - (index * 10),
              0.12345,
              SafeJetColors.success.withOpacity(0.1),
              SafeJetColors.success,
              isDark,
              theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrecisionButton(String text, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? SafeJetColors.secondaryHighlight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected
              ? Colors.black
              : (isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildOrderRow(
    double price,
    double amount,
    Color bgColor,
    Color textColor,
    bool isDark,
    ThemeData theme,
  ) {
    final total = price * amount;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              price.toStringAsFixed(2),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              amount.toStringAsFixed(5),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : SafeJetColors.lightText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              total.toStringAsFixed(2),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : SafeJetColors.lightText,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
} 