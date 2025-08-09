import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import '../../widgets/p2p_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/kyc_provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';
import '../../screens/support/support_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _isChangingNumber = false;
  Country? _selectedCountry;
  String? _currentPhone;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _needsPhoneNumber = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    Provider.of<AuthProvider>(context, listen: false).setContext(context);
    _setDefaultCountryByIP();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _cooldownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _loadUserPhone() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = await authProvider.getCurrentUser();
      final phone = user['phone'];
      setState(() {
        _currentPhone = phone;
        _needsPhoneNumber = phone == null || phone.toString().isEmpty;
        if (_needsPhoneNumber) {
          _isChangingNumber = true;
        }
      });
    } catch (e) {
      print('Error loading user phone');
    }
  }

  Future<void> _setDefaultCountryByIP() async {
    if (_selectedCountry != null) return;
    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country'];
        if (countryCode != null && countryCode.isNotEmpty) {
          setState(() {
            _selectedCountry = Country.parse(countryCode);
          });
          return;
        }
      }
      if (_selectedCountry == null) {
        setState(() {
          _selectedCountry = Country.parse('US');
        });
      }
    } catch (e) {
      if (_selectedCountry == null) {
        setState(() {
          _selectedCountry = Country.parse('US');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const P2PAppBar(
        title: 'Phone Verification',
        hasNotification: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.1)
                    : SafeJetColors.lightCardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SafeJetColors.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: SafeJetColors.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Email Verified',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SafeJetColors.warning.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      color: SafeJetColors.warning,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Phone Verification',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!_codeSent) ...[
              if (_needsPhoneNumber || _isChangingNumber) ...[
                // Phone number input form (for new or changing number)
                Text(
                  'Enter New Phone Number',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
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
                      labelStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: GestureDetector(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: true,
                            countryListTheme: CountryListThemeData(
                              backgroundColor: SafeJetColors.primaryBackground,
                              textStyle: const TextStyle(color: Colors.white),
                              searchTextStyle:
                                  const TextStyle(color: Colors.white),
                              bottomSheetHeight: 500,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              inputDecoration: InputDecoration(
                                hintText: 'Search country',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white),
                                filled: true,
                                fillColor: SafeJetColors.primaryAccent
                                    .withOpacity(0.1),
                              ),
                            ),
                            onSelect: (Country country) {
                              setState(() {
                                _selectedCountry = country;
                              });
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
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
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (!_needsPhoneNumber) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isChangingNumber = false;
                              _phoneController.clear();
                              _selectedCountry = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                                color: SafeJetColors.secondaryHighlight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _updatePhoneNumber,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: SafeJetColors.secondaryHighlight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Show current phone number
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SafeJetColors.primaryAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Phone Number',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _currentPhone ?? 'Loading...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isChangingNumber = true;
                              });
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: SafeJetColors.secondaryHighlight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Send Code'),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit code',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.lock_clock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: SafeJetColors.secondaryHighlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: (_loading || _resendCooldown > 0)
                        ? null
                        : _sendVerificationCode,
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SafeJetColors.secondaryHighlight,
                              ),
                            ),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend',
                            style: TextStyle(
                              color: SafeJetColors.secondaryHighlight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            _buildSupportNotice(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportNotice(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 8),
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
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.10)
                : SafeJetColors.primaryAccent.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                      'Having trouble with phone verification?',
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
                    const SizedBox(height: 6),
                    Text(
                      'If you are using a non-Nigerian phone number, please contact support for faster verification.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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

  Future<void> _updatePhoneNumber() async {
    if (_selectedCountry == null || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country and enter phone number'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String phoneNumber = _phoneController.text;
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }

      final countryCode = '+${_selectedCountry!.phoneCode}';
      final countryName = _selectedCountry!.name;
      final fullPhoneNumber = '$countryCode$phoneNumber';

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updatePhone(
        phone: fullPhoneNumber,
        countryCode: countryCode,
        countryName: countryName,
        phoneWithoutCode: phoneNumber,
      );

      setState(() {
        _currentPhone = fullPhoneNumber;
        _isChangingNumber = false;
        _needsPhoneNumber = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number updated successfully'),
          backgroundColor: SafeJetColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendVerificationCode() async {
    if (_resendCooldown > 0) return;

    setState(() => _loading = true);
    try {
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .sendPhoneVerification();

      setState(() {
        _codeSent = true;
        _loading = false;
      });
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent successfully'),
          backgroundColor: SafeJetColors.success,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending code'),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    setState(() => _loading = true);
    try {
      final response = await Provider.of<AuthProvider>(context, listen: false)
          .verifyPhone(_otpController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully'),
          backgroundColor: SafeJetColors.success,
        ),
      );

      // Refresh KYC details
      await Provider.of<KYCProvider>(context, listen: false).loadKYCDetails();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying code'),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
