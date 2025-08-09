import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/auth_provider.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;
  String? _secretKey;
  String? _qrCodeUrl;
  List<String> _backupCodes = [];
  bool _setupComplete = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generate2FASecret() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.generate2FASecret();
      
      print('2FA Secret result: $result');
      
      if (mounted) {
        setState(() {
          _secretKey = result['secret'];
          _qrCodeUrl = result['qrCode'];
          _isLoading = false;
        });
        
        // Store the secret for verification
        await authProvider.storeTemp2FASecret(_secretKey!);
        
        setState(() {});
        
        print('Updated state - Secret: $_secretKey');
        print('Updated state - QR URL: $_qrCodeUrl');
      }
    } catch (e) {
      print('Generate 2FA secret error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _handleSetup() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit code'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.enable2FA(_codeController.text);
      
      // Update backup codes from response
      setState(() {
        _backupCodes = List<String>.from(response['backupCodes']);
        _isLoading = false;
      });

      if (!mounted) return;

      // Show success message but don't navigate back yet
      if (_backupCodes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('2FA enabled successfully. Please save your backup codes.'),
            backgroundColor: SafeJetColors.success,
          ),
        );
        
        // Change the "Enable 2FA" button to "Done"
        setState(() {
          _setupComplete = true;
        });
      } else {
        throw 'Failed to get backup codes';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Unable to enable 2FA. Please try again.'),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
  }

  Widget _buildQRStep(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_qrCodeUrl == null || _secretKey == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            print('Generating 2FA Secret...');
            _generate2FASecret();
          },
          child: const Text('Generate 2FA Secret'),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth * 0.6;

    // Create otpauth URL
    final otpauthUrl = 'otpauth://totp/SafeJet:${_secretKey}?secret=${_secretKey}&issuer=SafeJet';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: QrImageView(
              data: otpauthUrl,  // Use otpauth URL instead of base64 image
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Secret Key',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SelectableText(
                  _secretKey!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _secretKey != null ? () {
                    Clipboard.setData(ClipboardData(text: _secretKey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Secret key copied to clipboard'),
                        backgroundColor: SafeJetColors.success,
                      ),
                    );
                  } : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Key'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: '2FA Setup',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(isDark),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStepper(isDark),
              ),
            ),
          ],
        ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.security,
              color: SafeJetColors.secondaryHighlight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Enhance your account security',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () async {
        if (_currentStep == 0) {
          // When moving to step 2, generate the secret
          setState(() => _currentStep++);
          await _generate2FASecret();
        } else if (_currentStep < 2) {
          setState(() => _currentStep++);
        }
      },
      onStepCancel: () {
        setState(() {
          if (_currentStep > 0) _currentStep--;
        });
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.grey[600]!
                            : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading 
                    ? null 
                    : () {
                        if (_currentStep == 2) {
                          if (_setupComplete) {
                            Navigator.pop(context, true);
                          } else {
                            _handleSetup();
                          }
                        } else {
                          details.onStepContinue?.call();
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors.secondaryHighlight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_currentStep == 2 
                        ? (_setupComplete ? 'Done' : 'Enable 2FA') 
                        : 'Continue'),
                ),
              ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Install Authenticator'),
          content: _buildAuthenticatorStep(isDark),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Scan QR Code'),
          content: _buildQRStep(isDark),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Verify Setup'),
          content: _buildVerificationStep(isDark),
          isActive: _currentStep >= 2,
        ),
      ],
    );
  }

  Widget _buildAuthenticatorStep(bool isDark) {
    final apps = [
      {'name': 'Google Authenticator', 'icon': Icons.android},
      {'name': 'Microsoft Authenticator', 'icon': Icons.phone_iphone},
      {'name': 'Authy', 'icon': Icons.security},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Install one of these authenticator apps:',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...apps.map((app) => FadeInLeft(
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  app['icon'] as IconData,
                  color: SafeJetColors.secondaryHighlight,
                ),
                const SizedBox(width: 16),
                Text(
                  app['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildBackupCodes(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          Center(
            child: OutlinedButton.icon(
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
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show code input if 2FA is not yet enabled
        if (!_setupComplete) 
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ),

        // Show backup codes section after successful setup
        if (_backupCodes.isNotEmpty) ...[
          if (_setupComplete) ...[
            Text(
              'Backup Codes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save these backup codes in a secure place. You can use them to access your account if you lose your phone.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildBackupCodes(isDark),
        ],
      ],
    );
  }
} 