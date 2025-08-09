import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:provider/provider.dart';
import '../config/theme/theme_provider.dart';
import '../providers/notification_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onThemeToggle;
  final String? title;
  final Widget? trailing;

  const CustomAppBar({
    super.key,
    this.onThemeToggle,
    this.title,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // Logo
              SizedBox(
                height: 40,
                width: 120,
                child: Image.asset(
                  isDark
                      ? 'assets/images/logo/logo-2c.png'
                      : 'assets/images/logo/logo-2b.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              // Action buttons in a Row with minimum size
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) trailing!,
                  if (trailing != null) const SizedBox(width: 8),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final hasNotification =
                          notificationProvider.unreadCount > 0;
                      return IconButton(
                        onPressed: () {
                          final theme = Theme.of(context);
                          final isDark = theme.brightness == Brightness.dark;
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Dialog.fullscreen(
                              child: Consumer<NotificationProvider>(
                                builder:
                                    (context, notificationProvider, child) {
                                  final notifications =
                                      notificationProvider.notifications;
                                  return Scaffold(
                                    backgroundColor: isDark
                                        ? SafeJetColors.primaryBackground
                                        : SafeJetColors.lightBackground,
                                    appBar: AppBar(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      leading: IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      title: Text(
                                        'Notifications',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      actions: [
                                        if (notifications.isNotEmpty) ...[
                                          TextButton(
                                            onPressed: () async {
                                              print(
                                                  '🔔 Mark all as read button pressed');
                                              await notificationProvider
                                                  .markAllAsRead();
                                              print(
                                                  '🔔 Mark all as read completed, updating UI');
                                            },
                                            child: Text(
                                              'Mark all as read',
                                              style: TextStyle(
                                                color: isDark
                                                    ? SafeJetColors
                                                        .secondaryHighlight
                                                    : SafeJetColors
                                                        .secondaryHighlight,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              print(
                                                  '🔴 CLEAR ALL BUTTON PRESSED!');
                                              print(
                                                  '🗑️ Clear all notifications button pressed');
                                              await notificationProvider
                                                  .deleteAllNotifications();
                                              print(
                                                  '🗑️ Clear all notifications completed');
                                            },
                                            child: Text(
                                              'Clear all',
                                              style: TextStyle(
                                                color: Colors.red[400],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    body: notifications.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .notifications_none_outlined,
                                                  size: 64,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.black26,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No notifications yet',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'You\'ll see your notifications here',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black45,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: notifications.length,
                                            itemBuilder: (context, index) {
                                              final n = notifications[index];
                                              final isUnread =
                                                  n['isRead'] != true;

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? SafeJetColors
                                                          .primaryAccent
                                                          .withOpacity(0.08)
                                                      : SafeJetColors
                                                          .lightCardBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    onTap: () async {
                                                      // Show full notification details in a beautiful dialog
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            _buildNotificationDetailDialog(
                                                                context,
                                                                n,
                                                                isDark),
                                                      );
                                                      // Mark as read if unread
                                                      if (isUnread) {
                                                        await notificationProvider
                                                            .markAsRead(
                                                                n['id']);
                                                      }
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Notification icon with status indicator
                                                          Stack(
                                                            children: [
                                                              Container(
                                                                width: 40,
                                                                height: 40,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: isUnread
                                                                      ? SafeJetColors
                                                                          .secondaryHighlight
                                                                          .withOpacity(
                                                                              0.1)
                                                                      : (isDark
                                                                          ? Colors.white.withOpacity(
                                                                              0.1)
                                                                          : Colors
                                                                              .black
                                                                              .withOpacity(0.05)),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Icon(
                                                                  _getNotificationIcon(
                                                                      n['type']),
                                                                  size: 20,
                                                                  color: isUnread
                                                                      ? SafeJetColors
                                                                          .secondaryHighlight
                                                                      : (isDark
                                                                          ? Colors
                                                                              .white60
                                                                          : Colors
                                                                              .black54),
                                                                ),
                                                              ),
                                                              if (isUnread)
                                                                Positioned(
                                                                  right: 0,
                                                                  top: 0,
                                                                  child:
                                                                      Container(
                                                                    width: 8,
                                                                    height: 8,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: SafeJetColors
                                                                          .secondaryHighlight,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border:
                                                                          Border
                                                                              .all(
                                                                        color: isDark
                                                                            ? SafeJetColors.secondaryBackground
                                                                            : SafeJetColors.lightSecondaryBackground,
                                                                        width:
                                                                            1.5,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          // Notification content
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        n['title'] ??
                                                                            '',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight: isUnread
                                                                              ? FontWeight.w600
                                                                              : FontWeight.w500,
                                                                          color: isDark
                                                                              ? Colors.white
                                                                              : Colors.black,
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      _formatTime(
                                                                          n['createdAt']),
                                                                      style:
                                                                          TextStyle(
                                                                        color: isDark
                                                                            ? Colors.white54
                                                                            : Colors.black45,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  n['body'] ??
                                                                      '',
                                                                  style:
                                                                      TextStyle(
                                                                    color: isDark
                                                                        ? Colors
                                                                            .white70
                                                                        : Colors
                                                                            .black87,
                                                                    fontSize:
                                                                        14,
                                                                    height: 1.3,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // Delete button
                                                          IconButton(
                                                            onPressed:
                                                                () async {
                                                              print(
                                                                  '🔴 DELETE BUTTON PRESSED!');
                                                              // Show confirmation dialog
                                                              final shouldDelete =
                                                                  await showDialog<
                                                                      bool>(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  backgroundColor: isDark
                                                                      ? SafeJetColors
                                                                          .primaryBackground
                                                                      : SafeJetColors
                                                                          .lightBackground,
                                                                  title: Text(
                                                                    'Delete Notification',
                                                                    style:
                                                                        TextStyle(
                                                                      color: isDark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                    ),
                                                                  ),
                                                                  content: Text(
                                                                    'Are you sure you want to delete this notification?',
                                                                    style:
                                                                        TextStyle(
                                                                      color: isDark
                                                                          ? Colors
                                                                              .white70
                                                                          : Colors
                                                                              .black87,
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(false),
                                                                      child:
                                                                          Text(
                                                                        'Cancel',
                                                                        style:
                                                                            TextStyle(
                                                                          color: isDark
                                                                              ? Colors.white70
                                                                              : Colors.black54,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(true),
                                                                      child:
                                                                          Text(
                                                                        'Delete',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.red[400],
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );

                                                              if (shouldDelete ==
                                                                  true) {
                                                                await notificationProvider
                                                                    .deleteNotification(
                                                                        n['id']);
                                                              }
                                                            },
                                                            icon: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              size: 20,
                                                              color: isDark
                                                                  ? Colors
                                                                      .white54
                                                                  : Colors
                                                                      .black45,
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            constraints:
                                                                const BoxConstraints(
                                                              minWidth: 32,
                                                              minHeight: 32,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: Stack(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            if (hasNotification)
                              Positioned(
                                right: 0,
                                top: 0,
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
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: onThemeToggle,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'admin_message':
        return Icons.admin_panel_settings_outlined;
      case 'transaction':
        return Icons.account_balance_wallet_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'kyc':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNotificationDetailDialog(
      BuildContext context, Map<String, dynamic> notification, bool isDark) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    SafeJetColors.primaryBackground.withOpacity(0.98),
                    SafeJetColors.primaryBackground.withOpacity(0.98),
                  ]
                : [
                    SafeJetColors.lightBackground.withOpacity(0.98),
                    SafeJetColors.lightBackground.withOpacity(0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with type badge and close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getNotificationTypeLabel(notification['type']),
                      style: TextStyle(
                        color: SafeJetColors.secondaryHighlight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification icon and title
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: SafeJetColors.secondaryHighlight
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification['type']),
                            size: 24,
                            color: SafeJetColors.secondaryHighlight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['title'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(notification['createdAt']),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Notification body
                    Text(
                      notification['body'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: SafeJetColors.secondaryHighlight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationTypeLabel(String? type) {
    switch (type) {
      case 'admin_message':
        return 'ADMIN MESSAGE';
      case 'transaction':
        return 'TRANSACTION';
      case 'security':
        return 'SECURITY';
      case 'kyc':
        return 'KYC';
      case 'welcome':
        return 'WELCOME';
      default:
        return 'NOTIFICATION';
    }
  }
}
