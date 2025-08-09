import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class AccountInformationScreen extends StatelessWidget {
  const AccountInformationScreen({super.key});

  // Add AuthService instance
  AuthService get _authService => AuthService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: isDark
          ? SafeJetColors.primaryBackground
          : SafeJetColors.lightBackground,
      appBar: P2PAppBar(
        title: 'Account Information',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Profile Header
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildProfileHeader(context, user, isDark),
            ),
            // Account Details Card
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildAccountDetailsCard(context, user, isDark),
              ),
            ),
            // Action Buttons
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _modernActionButton(
                    context,
                    icon: Icons.edit_note,
                    label: 'Request Account Update',
                    color: SafeJetColors.secondaryHighlight,
                    onPressed: () => _showAccountUpdateDialog(context, isDark),
                    isDestructive: false,
                  ),
                  const SizedBox(height: 16),
                  _modernActionButton(
                    context,
                    icon: Icons.delete_forever,
                    label: 'Request Account Deletion',
                    color: SafeJetColors.error,
                    onPressed: () =>
                        _showAccountDeletionDialog(context, isDark),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, bool isDark) {
    final initials = (user?.fullName != null && user.fullName.isNotEmpty)
        ? user.fullName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '--';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  SafeJetColors.primaryAccent.withOpacity(0.18),
                  SafeJetColors.primaryBackground
                ]
              : [
                  SafeJetColors.lightCardBackground,
                  SafeJetColors.lightSecondaryBackground
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SafeJetColors.secondaryHighlight.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: SafeJetColors.secondaryHighlight,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '-',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVerificationBadge(user, isDark),
                // Trader ID pill/badge
                if (user?.traderId != null &&
                    (user.traderId?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildTraderIdPill(context, user.traderId!, isDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(user, bool isDark) {
    final verified = user?.emailVerified == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: verified
            ? SafeJetColors.success.withOpacity(0.12)
            : SafeJetColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.warning_amber_rounded,
            color: verified ? SafeJetColors.success : SafeJetColors.warning,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'Email Verified' : 'Email Not Verified',
            style: TextStyle(
              color: verified ? SafeJetColors.success : SafeJetColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard(BuildContext context, user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  SafeJetColors.primaryAccent.withOpacity(0.10),
                  SafeJetColors.primaryBackground
                ]
              : [
                  SafeJetColors.lightCardBackground,
                  SafeJetColors.lightSecondaryBackground
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.18)
              : SafeJetColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.08)
                : Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Personal Info', Icons.person_outline),
          const SizedBox(height: 12),
          _modernInfoRow(
              Icons.person_outline, 'Full Name', user?.fullName ?? '-'),
          _modernInfoRow(Icons.email_outlined, 'Email', user?.email ?? '-'),
          _modernInfoRow(Icons.phone_outlined, 'Phone', user?.phone ?? '-'),
          _modernInfoRow(
              Icons.location_on_outlined, 'Country', user?.countryName ?? '-'),
          const SizedBox(height: 24),
          _sectionHeader(context, 'Account Details', Icons.badge_outlined),
          const SizedBox(height: 12),
          // Trader ID row removed from here
          _modernInfoRow(
              Icons.calendar_today_outlined,
              'Joined',
              user != null && user.toJson()['createdAt'] != null
                  ? _formatDate(user.toJson()['createdAt'])
                  : '-'),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SafeJetColors.secondaryHighlight.withOpacity(0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: SafeJetColors.secondaryHighlight, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : SafeJetColors.lightText,
              ),
        ),
      ],
    );
  }

  Widget _modernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: SafeJetColors.secondaryHighlight, size: 20),
          const SizedBox(width: 14),
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

  Widget _buildTraderIdPill(
      BuildContext context, String traderId, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.13)
            : SafeJetColors.secondaryHighlight.withOpacity(0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: SafeJetColors.secondaryHighlight.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.badge_outlined,
              color: SafeJetColors.secondaryHighlight, size: 18),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                traderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: traderId));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trader ID copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Icon(Icons.copy,
                size: 16, color: isDark ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final month = _monthName(date.month);
      final day = date.day;
      final year = date.year;
      final suffix = _getDaySuffix(day);
      return '$month $day$suffix $year';
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }

  String _getDaySuffix(int day) {
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

  Widget _modernActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onPressed,
      bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon,
            size: 22, color: isDestructive ? Colors.white : Colors.black),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: isDestructive ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showAccountUpdateDialog(BuildContext context, bool isDark) async {
    await _handleAccountRequestDialog(context, isDark, 'update');
  }

  void _showAccountDeletionDialog(BuildContext context, bool isDark) async {
    await _handleAccountRequestDialog(context, isDark, 'deletion');
  }

  Future<void> _handleAccountRequestDialog(
      BuildContext context, bool isDark, String type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _authService.getAccountRequests(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _FullScreenDialog(
              title: 'Error',
              isDark: isDark,
              child: Center(
                  child: Text('Failed to load requests. Please try again.')),
            );
          }
          final requests = snapshot.data ?? [];
          final hasPending = requests
              .any((r) => r['type'] == type && r['status'] == 'pending');
          if (hasPending) {
            return _FullScreenDialog(
              title: 'Pending Request',
              isDark: isDark,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 48, color: SafeJetColors.warning),
                    const SizedBox(height: 24),
                    Text(
                      'You already have a pending ${type == 'update' ? 'account update' : 'account deletion'} request.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeJetColors.secondaryHighlight,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 32),
                      ),
                      child: const Text('OK',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }
          // Show the form as before, but pass type
          return _FullScreenDialog(
            title: type == 'update'
                ? 'Request Account Update'
                : 'Request Account Deletion',
            isDark: isDark,
            child: type == 'update'
                ? _AccountUpdateForm(type: type, authService: _authService)
                : _AccountDeletionForm(type: type, authService: _authService),
          );
        },
      ),
    );
  }
}

// --- Full Screen Dialog Widget ---
class _FullScreenDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _FullScreenDialog(
      {required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      child: SizedBox.expand(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close,
                    color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(title,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black)),
              centerTitle: true,
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Account Update Form ---
class _AccountUpdateForm extends StatefulWidget {
  final String type;
  final AuthService authService;
  const _AccountUpdateForm({required this.type, required this.authService});
  @override
  State<_AccountUpdateForm> createState() => _AccountUpdateFormState();
}

class _AccountUpdateFormState extends State<_AccountUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe what you want to update:',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'E.g. I want to update my phone number...',
              filled: true,
              fillColor: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.08)
                  : SafeJetColors.lightCardBackground,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter your request.'
                : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _submitting = true);
                        try {
                          await widget.authService.submitAccountRequest(
                              widget.type, _controller.text.trim());
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Account update request submitted!')),
                            );
                          }
                        } catch (e) {
                          setState(() => _submitting = false);
                          final msg = e.toString();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Request',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Account Deletion Form ---
class _AccountDeletionForm extends StatefulWidget {
  final String type;
  final AuthService authService;
  const _AccountDeletionForm({required this.type, required this.authService});
  @override
  State<_AccountDeletionForm> createState() => _AccountDeletionFormState();
}

class _AccountDeletionFormState extends State<_AccountDeletionForm> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _confirm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why do you want to delete your account?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'E.g. I no longer need the service...',
              filled: true,
              fillColor: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.08)
                  : SafeJetColors.lightCardBackground,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a reason.'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _confirm,
                onChanged: (v) => setState(() => _confirm = v ?? false),
                activeColor: SafeJetColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('I understand this action is irreversible.',
                    style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting || !_confirm
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _submitting = true);
                        try {
                          await widget.authService.submitAccountRequest(
                              widget.type, _controller.text.trim());
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Account deletion request submitted!')),
                            );
                          }
                        } catch (e) {
                          setState(() => _submitting = false);
                          final msg = e.toString();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Request',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
