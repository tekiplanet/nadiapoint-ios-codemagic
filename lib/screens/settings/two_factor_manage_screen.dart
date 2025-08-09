import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../widgets/two_factor_dialog.dart';
import '../../config/theme/theme_provider.dart';

class TwoFactorManageScreen extends StatefulWidget {
  const TwoFactorManageScreen({super.key});

  @override
  State<TwoFactorManageScreen> createState() => _TwoFactorManageScreenState();
}

class _TwoFactorManageScreenState extends State<TwoFactorManageScreen> {
  List<String> _backupCodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to load data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackupCodes();
    });
  }

  Future<void> _loadBackupCodes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('Fetching backup codes...'); // Debug log
      
      final codes = await authProvider.getBackupCodes();
      print('Received backup codes: $codes'); // Debug log
      
      if (!mounted) return;
      setState(() {
        _backupCodes = codes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading backup codes'); // Debug log
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('not enabled') 
                ? '2FA is not enabled for this account'
                : e.toString().contains('Session expired')
                  ? 'Session expired. Please login again.'
                  : e.toString().contains('Connection')
                    ? 'Connection error. Please check your internet and try again.'
                    : 'Unable to retrieve backup codes. Please try again.',
            ),
            backgroundColor: SafeJetColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleDisable2FA() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TwoFactorDialog(
        action: 'disable2fa',
        title: 'Disable 2FA',
        message: 'Enter the 6-digit code from your authenticator app to disable 2FA',
      ),
    );

    if (result == true && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2FA has been disabled successfully'),
          backgroundColor: SafeJetColors.success,
        ),
      );
      
      // Add a small delay to allow the snackbar to be visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate 2FA was disabled
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: '2FA Management',
        hasNotification: false,
        onThemeToggle: () => themeProvider.toggleTheme(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _backupCodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No backup codes available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadBackupCodes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SafeJetColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SafeJetColors.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: SafeJetColors.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                '2FA is currently enabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Backup Codes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save these backup codes in a secure place. You can use them to access your account if you lose your phone.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? SafeJetColors.primaryAccent.withOpacity(0.1)
                              : SafeJetColors.lightCardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _backupCodes.length,
                              itemBuilder: (context, index) => Text(
                                _backupCodes[index],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                final codes = _backupCodes.join('\n');
                                Clipboard.setData(ClipboardData(text: codes));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Backup codes copied to clipboard'),
                                    backgroundColor: SafeJetColors.success,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy All Codes'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleDisable2FA,
                          icon: const Icon(Icons.no_encryption),
                          label: const Text('Disable 2FA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 