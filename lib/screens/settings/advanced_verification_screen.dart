import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/kyc_provider.dart';
import '../../widgets/verification_status_card.dart';
import '../../config/theme/colors.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../config/theme/theme_provider.dart';
import '../../screens/settings/advanced_sumsub_verification_screen.dart';
import '../support/support_screen.dart';

class AdvancedVerificationScreen extends StatefulWidget {
  const AdvancedVerificationScreen({super.key});

  @override
  State<AdvancedVerificationScreen> createState() => _AdvancedVerificationScreenState();
}

class _AdvancedVerificationScreenState extends State<AdvancedVerificationScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _startAdvancedVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await context.read<KYCProvider>().startAdvancedVerification();
      print('[AdvancedVerification] Received token:');
      print(token);
      if (token != null && token is String && token.isNotEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdvancedSumsubVerificationScreen(
                accessToken: token,
              ),
            ),
          );
        }
      } else {
        print('[AdvancedVerification] No token or empty response received.');
        setState(() {
          _error = _getFriendlyError('');
        });
      }
    } catch (e) {
      print('[AdvancedVerification] Error:');
      print(e);
      setState(() {
        _error = _getFriendlyError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _getFriendlyError(String error) {
    final err = error.toLowerCase();
    if (err.contains('level 2') || err.contains('complete level 2')) {
      return 'You need to complete identity verification before starting advanced verification.';
    }
    if (err.contains('not enough credit') || err.contains('automatic verification') || err.contains('402')) {
      return 'Automatic advanced verification is currently unavailable. Contact support for manual KYC verification.';
    }
    return 'Unable to start advanced verification. Please try again or contact support.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
      appBar: P2PAppBar(
        title: 'Advanced Verification',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VerificationStatusCard(type: 'Advanced'),
            const SizedBox(height: 24),
            if (_error != null) ...[
              _buildErrorCard(_error!, isDark),
              const SizedBox(height: 18),
            ],
            Card(
              color: isDark ? SafeJetColors.primaryAccent.withOpacity(0.1) : SafeJetColors.lightCardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark 
                      ? SafeJetColors.primaryAccent.withOpacity(0.2)
                      : SafeJetColors.lightCardBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Documents',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRequirementItem(
                      'Bank Statement (Last 3 months)',
                      'Recent bank statements showing your financial activity',
                      Icons.account_balance,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      'Proof of Income',
                      'Salary slips, tax returns, or other income proof',
                      Icons.description,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      'Tax Documents',
                      'Recent tax returns or tax assessment documents',
                      Icons.folder,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _startAdvancedVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SafeJetColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Start Verification',
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
            const SizedBox(height: 32),
            _buildSupportNotice(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isDark ? SafeJetColors.error.withOpacity(0.13) : SafeJetColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SafeJetColors.error.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: SafeJetColors.error.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: SafeJetColors.error, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? SafeJetColors.error : Colors.red[900],
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportNotice(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.10)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? SafeJetColors.secondaryHighlight.withOpacity(0.18)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: SafeJetColors.secondaryHighlight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Having trouble with verification?',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact support to complete your verification.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Contact Support',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String title, String description, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SafeJetColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: SafeJetColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 