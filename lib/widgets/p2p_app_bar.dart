import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:provider/provider.dart';
import '../config/theme/theme_provider.dart';

class P2PAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool hasNotification;
  final VoidCallback? onThemeToggle;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationTap;
  final Widget? trailing;

  const P2PAppBar({
    super.key,
    required this.title,
    this.hasNotification = false,
    this.onThemeToggle,
    this.onBack,
    this.onNotificationTap,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Check if we can go back (not on root screen)
    final canPop = Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // Back Button - show automatically if we can pop
              if (canPop)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),

              // Title with flex
              Expanded(
                child: Text(
                  title ?? 'NadiaPoint',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white : SafeJetColors.lightText,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action buttons with minimum size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  // IconButton(
                  //   onPressed: onNotificationTap,
                  //   icon: Stack(
                  //     children: [
                  //       const Icon(Icons.notifications_outlined),
                  //       if (hasNotification)
                  //         Positioned(
                  //           right: 0,
                  //           top: 0,
                  //           child: Container(
                  //             width: 8,
                  //             height: 8,
                  //             decoration: const BoxDecoration(
                  //               color: SafeJetColors.secondaryHighlight,
                  //               shape: BoxShape.circle,
                  //             ),
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  // ),
                  // IconButton(
                  //   onPressed: onThemeToggle,
                  //   icon: Icon(
                  //     isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
    bool hasNotification = false,
  }) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          color: isDark ? Colors.white : SafeJetColors.lightText,
          iconSize: 24,
          onPressed: onTap,
        ),
        if (hasNotification)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: SafeJetColors.secondaryHighlight,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
