import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/two_factor_dialog.dart';
import 'package:dio/dio.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Helper function to get user-friendly error message
  String _getFriendlyErrorMessage(dynamic error) {
    // Log the technical error for debugging
    print('Change password error: $error');

    // If it's a DioException, try to extract the message from response
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'];
      }

      // Handle specific network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please check your network.';
      }

      // Handle specific status codes
      switch (error.response?.statusCode) {
        case 401:
          return 'Current password is incorrect. Please try again.';
        case 400:
          return 'Invalid password data. Please check your information.';
        case 500:
          return 'Server error. Please try again later.';
      }
    }

    // If it's a string error, check for specific patterns
    if (error is String) {
      if (error.toLowerCase().contains('incorrect') ||
          error.toLowerCase().contains('invalid password')) {
        return 'Current password is incorrect. Please try again.';
      }
      if (error.toLowerCase().contains('network')) {
        return 'Network error. Please check your connection.';
      }
      if (error.toLowerCase().contains('timeout')) {
        return 'Connection timed out. Please try again.';
      }
      // If it's already a friendly message, return it
      if (!error.contains('Exception:') && !error.contains('Error:')) {
        return error;
      }
    }

    // Default friendly message for any other error
    return 'Unable to change password. Please check your internet connection and try again.';
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load user data if not already loaded
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      authProvider.loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final needsToSetPassword = authProvider.user?.needsToSetPassword ?? false;

    return Scaffold(
      appBar: P2PAppBar(
        title: needsToSetPassword ? 'Set Password' : 'Change Password',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          _buildHeader(isDark, needsToSetPassword),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Only show current password field for users who already have a password
                    if (!needsToSetPassword) ...[
                      FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: _buildPasswordField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          showPassword: _showCurrentPassword,
                          onToggleVisibility: () {
                            setState(() =>
                                _showCurrentPassword = !_showCurrentPassword);
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay:
                          Duration(milliseconds: needsToSetPassword ? 0 : 100),
                      child: _buildPasswordField(
                        controller: _newPasswordController,
                        label: needsToSetPassword
                            ? 'New Password'
                            : 'New Password',
                        showPassword: _showNewPassword,
                        onToggleVisibility: () {
                          setState(() => _showNewPassword = !_showNewPassword);
                        },
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          // Check for uppercase
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Password must contain at least one uppercase letter';
                          }
                          // Check for lowercase
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return 'Password must contain at least one lowercase letter';
                          }
                          // Check for numbers
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Password must contain at least one number';
                          }
                          // Check for special characters
                          if (!value.contains(
                              RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]'))) {
                            return 'Password must contain at least one special character';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(
                          milliseconds: needsToSetPassword ? 100 : 200),
                      child: _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        showPassword: _showConfirmPassword,
                        onToggleVisibility: () {
                          setState(() =>
                              _showConfirmPassword = !_showConfirmPassword);
                        },
                        isDark: isDark,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(
                          milliseconds: needsToSetPassword ? 200 : 300),
                      child: _buildPasswordRequirements(isDark),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(
                          milliseconds: needsToSetPassword ? 300 : 400),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.secondaryHighlight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  needsToSetPassword
                                      ? 'Set Password'
                                      : 'Change Password',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool needsToSetPassword) {
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
              Icons.lock_outline,
              color: SafeJetColors.secondaryHighlight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsToSetPassword ? 'Set Password' : 'Change Password',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  needsToSetPassword
                      ? 'Set your first password for your account'
                      : 'Keep your account secure',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required Function() onToggleVisibility,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    final requirements = [
      'At least 8 characters',
      'One uppercase letter',
      'One lowercase letter',
      'One number',
      'One special character',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...requirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: isDark
                          ? Colors.grey[400]
                          : SafeJetColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      req,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey[400]
                            : SafeJetColors.lightTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final needsToSetPassword = authProvider.user?.needsToSetPassword ?? false;

      if (!needsToSetPassword) {
        // For regular users, verify current password first
        final isCurrentPasswordValid = await authProvider
            .verifyCurrentPassword(_currentPasswordController.text);

        if (!isCurrentPasswordValid) {
          throw Exception('Current password is incorrect. Please try again.');
        }
      }

      // If 2FA is enabled, show verification dialog
      if (authProvider.user?.twoFactorEnabled == true) {
        if (!mounted) return;

        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => TwoFactorDialog(
            action: 'changePassword',
            title: 'Verify 2FA',
            message: needsToSetPassword
                ? 'Enter the 6-digit code to set your password'
                : 'Enter the 6-digit code to change password',
          ),
        );

        if (verified != true) {
          throw Exception('2FA verification failed. Please try again.');
        }
      }

      // Change or set password based on user type
      if (needsToSetPassword) {
        await authProvider.setInitialPassword(_newPasswordController.text);
      } else {
        await authProvider.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(needsToSetPassword
              ? 'Password set successfully'
              : 'Password changed successfully'),
          backgroundColor: SafeJetColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFriendlyErrorMessage(e),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: SafeJetColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
