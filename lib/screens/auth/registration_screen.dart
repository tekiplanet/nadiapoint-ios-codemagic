import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import 'email_verification_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../support/webview_screen.dart';
import '../../services/home_service.dart';
import 'two_factor_auth_screen.dart';
import '../main/home_screen.dart';
import '../../services/firebase_google_sign_in_service.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  Country? _selectedCountry;
  bool _isFormFilled = false;

  @override
  void initState() {
    super.initState();
    _setDefaultCountryByIP();
    _nameController.addListener(_checkFormFilled);
    _emailController.addListener(_checkFormFilled);
    _phoneController.addListener(_checkFormFilled);
    _passwordController.addListener(_checkFormFilled);
    _confirmPasswordController.addListener(_checkFormFilled);
  }

  void _checkFormFilled() {
    final isFilled = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedCountry != null &&
        _acceptedTerms &&
        _passwordController.text == _confirmPasswordController.text;
    if (_isFormFilled != isFilled) {
      setState(() {
        _isFormFilled = isFilled;
      });
    }
  }

  Future<void> _setDefaultCountryByIP() async {
    try {
      print('[GeoIP] Fetching country from ipinfo.io...');
      final response = await http.get(Uri.parse('https://ipinfo.io/json'));
      print('[GeoIP] Response status: \\${response.statusCode}');
      print('[GeoIP] Response body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[GeoIP] Decoded data: \\${data}');
        final countryCode = data['country'];
        print('[GeoIP] Extracted country code: \\${countryCode}');
        if (countryCode != null && countryCode.isNotEmpty) {
          setState(() {
            _selectedCountry = Country.parse(countryCode);
          });
          print('[GeoIP] Set _selectedCountry to: \\${_selectedCountry}');
          return;
        }
      }
      // Fallback if countryCode is missing/empty or status is not 200
      if (_selectedCountry == null) {
        setState(() {
          _selectedCountry = Country.parse('US');
        });
        print(
            '[GeoIP] Fallback to US (missing/empty country code or bad status)');
      }
    } catch (e) {
      print('[GeoIP] Error occurred: \\${e}');
      // Fallback to default (US) if API call fails
      if (_selectedCountry == null) {
        setState(() {
          _selectedCountry = Country.parse('US');
        });
        print('[GeoIP] Fallback to US (exception)');
      }
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkFormFilled);
    _emailController.removeListener(_checkFormFilled);
    _phoneController.removeListener(_checkFormFilled);
    _passwordController.removeListener(_checkFormFilled);
    _confirmPasswordController.removeListener(_checkFormFilled);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SafeJetColors.primaryBackground,
              SafeJetColors.secondaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: SafeJetColors.textHighlight,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your crypto journey today',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildPhoneField(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordField: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isConfirmPassword: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTermsCheckbox(),
                        const SizedBox(height: 24),
                        _buildRegisterButton(),
                        const SizedBox(height: 24),
                        // Or Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[700])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Social Login Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label: 'Google',
                              onPressed: _isLoading
                                  ? () {}
                                  : () async {
                                      setState(() => _isLoading = true);
                                      try {
                                        final firebaseGoogleSignInService =
                                            FirebaseGoogleSignInService();
                                        final userCredential =
                                            await firebaseGoogleSignInService
                                                .signInWithGoogle();
                                        if (userCredential == null) {
                                          setState(() => _isLoading = false);
                                          return;
                                        }
                                        final idToken = await userCredential
                                            .user
                                            ?.getIdToken();
                                        if (idToken == null) {
                                          throw Exception(
                                              'Failed to get ID token from Firebase');
                                        }
                                        // Send the idToken to your backend for registration/login
                                        final authProvider =
                                            Provider.of<AuthProvider>(context,
                                                listen: false);
                                        final response = await authProvider
                                            .socialLoginWithFirebaseIdToken(
                                                idToken,
                                                provider: 'google');

                                        if (!mounted) return;

                                        // Check if 2FA is required
                                        if (response['requires2FA'] == true) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TwoFactorAuthScreen(
                                                email: response['email'] ?? '',
                                              ),
                                            ),
                                          );
                                        } else {
                                          // Check if email verification is required
                                          if (response['user'] != null &&
                                              response['user']
                                                      ['emailVerified'] ==
                                                  false) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EmailVerificationScreen(
                                                  email: response['user']
                                                      ['email'],
                                                ),
                                              ),
                                            );
                                          } else {
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const HomeScreen()),
                                              (route) => false,
                                            );
                                          }
                                        }
                                      } catch (e, stack) {
                                        print(
                                            'Firebase Google Sign-In Error: $e');
                                        print('Stack trace: $stack');
                                        if (!mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                _getFriendlyErrorMessage(e)),
                                            backgroundColor:
                                                SafeJetColors.error,
                                          ),
                                        );
                                      } finally {
                                        if (mounted)
                                          setState(() => _isLoading = false);
                                      }
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Having trouble? ',
                        style: TextStyle(color: Colors.grey[400]),
                        children: [
                          TextSpan(
                            text: 'Contact support',
                            style: TextStyle(
                              color: SafeJetColors.secondaryHighlight,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                print('Contact support tapped');
                                try {
                                  print('Showing loading indicator');
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  print('Creating HomeService');
                                  final homeService = HomeService();
                                  print('Fetching contact info...');
                                  final contactInfo =
                                      await homeService.getContactInfo();
                                  print('Contact info received: $contactInfo');

                                  // Close loading indicator
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  final liveChatUrl =
                                      contactInfo['supportLinks']['liveChat'];
                                  print('Live chat URL: $liveChatUrl');

                                  if (liveChatUrl == null ||
                                      liveChatUrl.isEmpty) {
                                    throw Exception('Live chat URL not found');
                                  }

                                  if (context.mounted) {
                                    print('Navigating to WebView');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebViewScreen(
                                          url: liveChatUrl,
                                          title: 'Live Chat',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error occurred: $e');
                                  // Close loading indicator if it's still showing
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  // Show error message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Unable to open live chat. Please try again later.'),
                                        backgroundColor: SafeJetColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordField = false,
    bool isConfirmPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: SafeJetColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SafeJetColors.primaryAccent.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword &&
            (isPasswordField
                ? !_isPasswordVisible
                : !_isConfirmPasswordVisible),
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: SafeJetColors.secondaryHighlight,
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isPasswordField
                            ? _isPasswordVisible
                            : _isConfirmPasswordVisible)
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: SafeJetColors.secondaryHighlight,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPasswordField) {
                        _isPasswordVisible = !_isPasswordVisible;
                      } else {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (isPasswordField && value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          if (isConfirmPassword && value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() => _acceptedTerms = value ?? false);
            _checkFormFilled();
          },
          fillColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? SafeJetColors.secondaryHighlight
                : Colors.transparent,
          ),
          side: BorderSide(color: Colors.grey[400]!),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(color: Colors.grey[400]),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: SafeJetColors.secondaryHighlight,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse('https://nadiapoint.com/terms'));
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: SafeJetColors.secondaryHighlight,
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse('https://nadiapoint.com/privacy'));
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to get user-friendly error message
  String _getFriendlyErrorMessage(dynamic error) {
    // Log the technical error for debugging
    print('Registration error: $error');

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
        case 409:
          return 'This email is already registered. Please login instead.';
        case 400:
          return 'Invalid registration data. Please check your information.';
        case 500:
          return 'Server error. Please try again later.';
      }
    }

    // If it's a string error, check for specific patterns
    if (error is String) {
      if (error.toLowerCase().contains('already exists')) {
        return 'This email is already registered. Please login instead.';
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
    return 'Unable to create account. Please check your internet connection and try again.';
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (!_isFormFilled || _isLoading)
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    String fullPhoneNumber = '';
                    String countryCode = '';
                    String countryName = '';

                    if (_selectedCountry != null) {
                      String phoneNumber = _phoneController.text;
                      if (phoneNumber.startsWith('0')) {
                        phoneNumber = phoneNumber.substring(1);
                      }

                      countryCode = '+${_selectedCountry!.phoneCode}';
                      countryName = _selectedCountry!.name;
                      fullPhoneNumber = '$countryCode$phoneNumber';
                    } else {
                      fullPhoneNumber = _phoneController.text;
                    }

                    await authProvider.register(
                      _nameController.text,
                      _emailController.text,
                      fullPhoneNumber,
                      _passwordController.text,
                      countryCode,
                      countryName,
                    );

                    if (!mounted) return;

                    if (authProvider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              _getFriendlyErrorMessage(authProvider.error!)),
                          backgroundColor: SafeJetColors.error,
                        ),
                      );
                      return;
                    }

                    // Navigate to email verification
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailVerificationScreen(
                          email: _emailController.text,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getFriendlyErrorMessage(e)),
                        backgroundColor: SafeJetColors.error,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: SafeJetColors.secondaryHighlight,
          disabledBackgroundColor:
              SafeJetColors.secondaryHighlight.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SafeJetColors.primaryBackground,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(color: Colors.grey[400]),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Login',
              style: TextStyle(
                color: SafeJetColors.secondaryHighlight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    // No need to set default here; handled in initState/_setDefaultCountryByIP

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: SafeJetColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SafeJetColors.primaryAccent.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          // New prefix: flag + country code + dropdown arrow, all tappable
          prefixIcon: GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: true,
                countryListTheme: CountryListThemeData(
                  backgroundColor: SafeJetColors.primaryBackground,
                  textStyle: const TextStyle(color: Colors.white),
                  searchTextStyle: const TextStyle(color: Colors.white),
                  bottomSheetHeight: 500,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  inputDecoration: InputDecoration(
                    hintText: 'Search country',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: SafeJetColors.primaryAccent.withOpacity(0.1),
                  ),
                ),
                onSelect: (Country country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  _checkFormFilled();
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry?.flagEmoji ?? '🌍',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${_selectedCountry?.phoneCode ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          // Remove the old prefix logic
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Phone number is required';
          }
          if (_selectedCountry == null) {
            return 'Please select a country';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        color: SafeJetColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SafeJetColors.primaryAccent.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
