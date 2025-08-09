import 'package:flutter/material.dart';
import '../config/theme/colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark 
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  SafeJetColors.primaryBackground.withOpacity(0.9),
                  SafeJetColors.primaryBackground,
                ]
              : [
                  SafeJetColors.lightBackground.withOpacity(0.9),
                  SafeJetColors.lightBackground,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, Icons.candlestick_chart_rounded, Icons.candlestick_chart_rounded, 'Markets', isDark),
                  _buildNavItem(1, Icons.sync_alt_rounded, Icons.sync_alt_rounded, 'Trade', isDark),
                  const SizedBox(width: 60),
                  _buildNavItem(3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_rounded, 'Wallets', isDark),
                  _buildNavItem(4, Icons.settings_rounded, Icons.settings_rounded, 'Settings', isDark),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SafeJetColors.secondaryHighlight,
                        SafeJetColors.secondaryHighlight.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SafeJetColors.secondaryHighlight.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Icon(
                    currentIndex == 2 ? Icons.home_rounded : Icons.home_outlined,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? SafeJetColors.primaryAccent.withOpacity(0.1) : SafeJetColors.lightCardBackground)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected 
                    ? SafeJetColors.secondaryHighlight
                    : (isDark ? Colors.grey[600] : SafeJetColors.lightTextSecondary),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? SafeJetColors.secondaryHighlight
                    : (isDark ? Colors.grey[600] : SafeJetColors.lightTextSecondary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 