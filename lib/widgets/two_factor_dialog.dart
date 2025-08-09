import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:NadiaPoint/providers/auth_provider.dart';

class TwoFactorDialog extends StatefulWidget {
  final String? action;
  final String? title;
  final String? message;

  const TwoFactorDialog({
    super.key,
    this.action,
    this.title,
    this.message,
  });

  @override
  State<TwoFactorDialog> createState() => _TwoFactorDialogState();
}

class _TwoFactorDialogState extends State<TwoFactorDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: const Color(0xFF1A1F2E),
      child: Container(
        width: 280,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title ?? '2FA Verification',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message ??
                  'Enter the 6-digit code from your authenticator app',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  width: 32,
                  height: 32,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (value) => _onCodeChanged(value, index),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blue[300],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? () {}
                      : () async {
                          if (_code.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please enter a valid 6-digit code'),
                                backgroundColor: SafeJetColors.error,
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);

                          try {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);

                            switch (widget.action) {
                              case 'disable2fa':
                                print('=== TwoFactorDialog Debug ===');
                                print('Action: ${widget.action}');
                                print('Code: $_code');
                                print('Calling disable2FA...');
                                await authProvider.disable2FA(
                                  _code,
                                  'authenticator',
                                );
                                print('disable2FA completed');
                                break;
                              case 'changePassword':
                              case 'updatePaymentMethod':
                              case 'createPaymentMethod':
                              case 'deletePaymentMethod':
                              case 'withdraw':
                              case 'transfer':
                                print('=== TwoFactorDialog Debug ===');
                                print('Action: ${widget.action}');
                                print('Code: $_code');
                                print('Calling verify2FAForAction...');
                                await authProvider.verify2FAForAction(_code);
                                print('verify2FAForAction completed');
                                break;
                              default:
                                await authProvider.verify2FA(
                                    _code, authProvider.user?.email);
                            }

                            if (!mounted) return;
                            Navigator.pop(context, true);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e
                                      .toString()
                                      .replaceAll('Exception: ', '')
                                      .replaceAll('Error: ', ''),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: SafeJetColors.error,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            setState(() => _isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(widget.action == 'disable2fa'
                          ? 'Disable 2FA'
                          : 'Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getActionButtonText() {
    switch (widget.action) {
      case 'disable2fa':
        return 'Disable 2FA';
      case 'changePassword':
        return 'Verify';
      default:
        return 'Verify';
    }
  }
}
