import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/notification_settings_provider.dart';
import 'package:shimmer/shimmer.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool get _masterToggle {
    if (context.read<NotificationSettingsProvider>().settings.isEmpty) {
      return false;
    }
    
    for (var category in context.read<NotificationSettingsProvider>().settings.values) {
      for (var enabled in category.values) {
        if (!enabled) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationSettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Notifications',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Consumer<NotificationSettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: _buildShimmerLoading(isDark),
                ),
              ],
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: TextStyle(color: SafeJetColors.error),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.loadSettings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  itemCount: provider.settings.length,
                  itemBuilder: (context, index) {
                    final category = provider.settings.keys.elementAt(index);
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: index * 100),
                      child: _buildCategory(
                        category,
                        provider.settings[category]!,
                        isDark,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: SafeJetColors.secondaryHighlight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Customize your notification preferences',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMasterToggle(isDark),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(bool isDark) {
    return Consumer<NotificationSettingsProvider>(
      builder: (context, provider, child) {
        final masterToggle = provider.settings.isNotEmpty && 
          !provider.settings.values
            .expand((map) => map.values)
            .contains(false);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                masterToggle 
                  ? Icons.notifications_active 
                  : Icons.notifications_off,
                color: masterToggle
                    ? SafeJetColors.success
                    : (isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: masterToggle
                            ? null
                            : (isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary),
                      ),
                    ),
                    Text(
                      masterToggle ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: masterToggle,
                onChanged: _onMasterToggleChanged,
                activeColor: SafeJetColors.secondaryHighlight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategory(String category, Map<String, bool> items, bool isDark) {
    final categoryIcon = _getCategoryIcon(category);
    final categoryColor = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SwitchListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                value: entry.value,
                onChanged: (value) {
                  _onCategoryToggleChanged(category, entry.key, value);
                },
                activeColor: SafeJetColors.secondaryHighlight,
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Trading':
        return Icons.trending_up;
      case 'P2P':
        return Icons.people;
      case 'Security':
        return Icons.security;
      case 'Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Trading':
        return const Color(0xFF4CAF50);
      case 'P2P':
        return const Color(0xFF2196F3);
      case 'Security':
        return const Color(0xFFE91E63);
      case 'Wallet':
        return const Color(0xFF9C27B0);
      default:
        return SafeJetColors.secondaryHighlight;
    }
  }

  void _onMasterToggleChanged(bool value) async {
    try {
      await context.read<NotificationSettingsProvider>().updateAllSettings(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update settings'),
            backgroundColor: SafeJetColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _onMasterToggleChanged(value),
            ),
          ),
        );
      }
    }
  }

  void _onCategoryToggleChanged(String category, String setting, bool value) async {
    try {
      await context.read<NotificationSettingsProvider>().updateSingleSetting(
        category,
        setting,
        value,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update setting'),
            backgroundColor: SafeJetColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _onCategoryToggleChanged(category, setting, value),
            ),
          ),
        );
      }
    }
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      itemCount: 4,  // Number of shimmer cards to show
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildShimmerCard(isDark),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Shimmer for list items
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
} 