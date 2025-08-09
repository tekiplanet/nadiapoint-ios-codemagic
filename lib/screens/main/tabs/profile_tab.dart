import 'package:flutter/material.dart';
import '../../../config/theme/colors.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/theme_provider.dart';
import '../../../services/biometric_service.dart';
import '../../../screens/p2p/p2p_payment_methods_screen.dart';
import '../../../screens/p2p/p2p_trading_preferences_screen.dart';
import '../../../screens/p2p/p2p_auto_response_screen.dart';
import '../../../screens/settings/notification_settings_screen.dart';
import '../../../screens/settings/change_password_screen.dart';
import '../../../screens/settings/two_factor_screen.dart';
import '../../../screens/settings/identity_verification_screen.dart';
import '../../../screens/settings/kyc_levels_screen.dart';
import '../../../screens/settings/language_settings_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../widgets/two_factor_dialog.dart';
import '../../../screens/settings/two_factor_manage_screen.dart';
import '../../../providers/kyc_provider.dart';
import '../../../providers/language_settings_provider.dart';
import '../../../providers/biometric_settings_provider.dart';
import '../../../screens/settings/biometric_settings_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import '../../../screens/settings/account_information_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _is2FAEnabled = false;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger loading state by fetching fresh data
      context.read<AuthProvider>().fetchFreshUserData();
      context.read<KYCProvider>().loadKYCDetails();
      context.read<BiometricSettingsProvider>().loadSettings();
    });
  }

  Future<void> _check2FAStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = await authProvider.getCurrentUser();
      setState(() {
        _is2FAEnabled = user['twoFactorEnabled'] ?? false;
      });
    } catch (e) {
      print('Error checking 2FA status');
    }
  }

  Future<void> _handle2FAToggle() async {
    if (_is2FAEnabled) {
      // Show 2FA verification dialog when disabling
      final dialogResult = await showDialog(
        context: context,
        builder: (context) => const TwoFactorDialog(),
      );

      final bool result = dialogResult as bool? ?? false;

      if (result) {
        setState(() {
          _is2FAEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2FA has been disabled'),
              backgroundColor: SafeJetColors.success,
            ),
          );
        }
      }
    } else {
      // Navigate to 2FA setup screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const TwoFactorScreen(),
        ),
      );

      if (result == true) {
        setState(() => _is2FAEnabled = true);
      }
    }
  }

  void _handleLogout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!mounted) return;

      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to logout: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: SafeJetColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getVerificationColor(int level) {
    switch (level) {
      case 3:
        return SafeJetColors.primary;
      case 2:
        return SafeJetColors.success;
      case 1:
        return SafeJetColors.warning;
      default:
        return SafeJetColors.error;
    }
  }

  IconData _getVerificationIcon(int level) {
    switch (level) {
      case 3:
        return Icons.verified;
      case 2:
        return Icons.check_circle;
      case 1:
        return Icons.pending;
      default:
        return Icons.cancel;
    }
  }

  String _getVerificationText(int level) {
    switch (level) {
      case 3:
        return 'Level 3';
      case 2:
        return 'Level 2';
      case 1:
        return 'Level 1';
      default:
        return 'Level 0';
    }
  }

  String _getVerificationStatus(int level) {
    switch (level) {
      case 3:
        return 'Completed';
      case 2:
        return 'Level 2';
      case 1:
        return 'Level 1';
      default:
        return 'Upgrade';
    }
  }

  Color _getVerificationStatusColor(int level) {
    switch (level) {
      case 3:
        return SafeJetColors.success;
      case 2:
        return SafeJetColors.primary;
      case 1:
        return SafeJetColors.warning;
      default:
        return SafeJetColors.error;
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Shimmer
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Settings Sections Shimmer
            ...List.generate(
                4,
                (sectionIndex) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 24,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                            3,
                            (itemIndex) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )),
                        const SizedBox(height: 32),
                      ],
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(
      BuildContext context, Map<String, dynamic> userDetails, bool isDark) {
    final theme = Theme.of(context);
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Card(
        margin: const EdgeInsets.only(bottom: 24),
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Information',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildInfoRow('Full Name', userDetails['fullName'] ?? '-'),
              _buildInfoRow('Email', userDetails['email'] ?? '-'),
              _buildInfoRow('Phone', userDetails['phone'] ?? '-'),
              _buildInfoRow('Country', userDetails['countryName'] ?? '-'),
              Row(
                children: [
                  Expanded(
                      child: _buildInfoRow(
                          'Trader ID', userDetails['traderId'] ?? '-',
                          noBottomPadding: true)),
                  if ((userDetails['traderId'] ?? '').toString().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy Trader ID',
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: userDetails['traderId']));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Trader ID copied to clipboard!'),
                                duration: Duration(seconds: 2)),
                          );
                        }
                      },
                    ),
                ],
              ),
              _buildInfoRow(
                  'Created',
                  userDetails['createdAt'] != null
                      ? DateTime.tryParse(userDetails['createdAt']) != null
                          ? DateTime.parse(userDetails['createdAt'])
                              .toLocal()
                              .toString()
                              .split('.')
                              .first
                          : userDetails['createdAt']
                      : '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool noBottomPadding = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: noBottomPadding ? 0 : 12),
      child: Row(
        children: [
          SizedBox(
              width: 110,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return _buildShimmer();
        }
        // final userDetails = authProvider.user?.toJson() ?? {}; // REMOVE old account info section
        return Scaffold(
          backgroundColor: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header with animation (always first)
                  FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: Consumer<KYCProvider>(
                      builder: (context, kycProvider, child) {
                        final kycDetails = kycProvider.kycDetails;
                        return Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: SafeJetColors.secondaryHighlight
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  kycDetails?.userDetails.fullName
                                          .substring(0, 2)
                                          .toUpperCase() ??
                                      'JD',
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: SafeJetColors.secondaryHighlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kycDetails?.userDetails.fullName ??
                                        'Loading...',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    kycDetails?.userDetails.email ??
                                        'Loading...',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : SafeJetColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getVerificationColor(
                                              kycDetails?.currentLevel ?? 0)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const KYCLevelsScreen(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getVerificationIcon(
                                                kycDetails?.currentLevel ?? 0),
                                            size: 14,
                                            color: _getVerificationColor(
                                                kycDetails?.currentLevel ?? 0),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getVerificationText(
                                                kycDetails?.currentLevel ?? 0),
                                            style: TextStyle(
                                              color: _getVerificationColor(
                                                  kycDetails?.currentLevel ??
                                                      0),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: _getVerificationColor(
                                                kycDetails?.currentLevel ?? 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Basic Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _buildSection(
                      context,
                      title: 'Basic',
                      children: [
                        _buildAnimatedSettingCard(
                          context,
                          icon: Icons.info_outline,
                          title: 'Account Information',
                          subtitle: 'View your basic profile details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AccountInformationScreen(),
                              ),
                            );
                          },
                          delay: 0,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Security Settings Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: _buildSection(
                      context,
                      title: 'Security',
                      children: [
                        _buildAnimatedSettingCard(
                          context,
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                          delay: 0,
                        ),
                        _buildAnimatedSettingCard(
                          context,
                          icon: Icons.fingerprint,
                          title: 'Biometric Authentication',
                          subtitle: context.select(
                              (BiometricSettingsProvider p) => p.isAvailable
                                  ? (p.isEnabled ? 'Enabled' : 'Disabled')
                                  : 'Not Available'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BiometricSettingsScreen(),
                              ),
                            );
                          },
                          delay: 300,
                        ),
                        _buildAnimatedSettingCard(
                          context,
                          icon: Icons.security,
                          title: 'Two-Factor Authentication',
                          subtitle: _is2FAEnabled ? 'Enabled' : 'Disabled',
                          trailing: _is2FAEnabled
                              ? Icon(
                                  Icons.chevron_right,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                )
                              : Switch(
                                  value: false,
                                  onChanged: (value) => _handle2FAToggle(),
                                  activeColor: SafeJetColors.secondaryHighlight,
                                ),
                          onTap: () async {
                            if (_is2FAEnabled) {
                              final disabled = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TwoFactorManageScreen(),
                                ),
                              );

                              if (disabled == true && mounted) {
                                setState(() => _is2FAEnabled = false);
                              }
                            } else {
                              _handle2FAToggle();
                            }
                          },
                          delay: 200,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Verification
                  Text(
                    'Verification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<KYCProvider>(
                    builder: (context, kycProvider, child) {
                      final kycLevel =
                          kycProvider.kycDetails?.currentLevel ?? 0;
                      return _buildSettingCard(
                        context,
                        icon: Icons.person_outline,
                        title: 'Identity Verification',
                        subtitle: 'Complete KYC to increase limits',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getVerificationStatusColor(kycLevel)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getVerificationStatus(kycLevel),
                            style: TextStyle(
                              color: _getVerificationStatusColor(kycLevel),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KYCLevelsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // // API Management
                  // Text(
                  //   'API Management',
                  //   style: theme.textTheme.titleMedium?.copyWith(
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // _buildSettingCard(
                  //   context,
                  //   icon: Icons.key,
                  //   title: 'API Keys',
                  //   subtitle: 'Manage your API keys',
                  //   onTap: () {
                  //     // TODO: Show API keys management
                  //   },
                  // ),

                  const SizedBox(height: 32),

                  // P2P Settings Section
                  Text(
                    'P2P Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    icon: Icons.payment,
                    title: 'Payment Methods',
                    subtitle: 'Manage your P2P payment methods',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const P2PPaymentMethodsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context,
                    icon: Icons.attach_money_outlined,
                    title: 'Trading Preferences',
                    subtitle: 'Set default currency and payment methods',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const P2PTradingPreferencesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context,
                    icon: Icons.message_outlined,
                    title: 'Auto-Response Messages',
                    subtitle: 'Manage quick responses for P2P chat',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const P2PAutoResponseScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Preferences
                  Text(
                    'Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage push notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context,
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: context.select((LanguageSettingsProvider p) {
                      final code = p.currentLanguage;
                      switch (code) {
                        case 'en':
                          return 'English';
                        case 'es':
                          return 'Español';
                        case 'fr':
                          return 'Français';
                        case 'de':
                          return 'Deutsch';
                        case 'zh':
                          return '中文';
                        case 'ja':
                          return '日本語';
                        case 'ko':
                          return '한국어';
                        case 'ru':
                          return 'Русский';
                        case 'ar':
                          return 'العربية';
                        default:
                          return 'English';
                      }
                    }),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context,
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    title: 'Theme',
                    subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        final themeProvider =
                            Provider.of<ThemeProvider>(context, listen: false);
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _handleLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeJetColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark
          ? SafeJetColors.primaryAccent.withOpacity(0.1)
          : SafeJetColors.lightCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildAnimatedSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required int delay,
  }) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: delay),
      child: _buildSettingCard(
        context,
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 32),
      ],
    );
  }
}
