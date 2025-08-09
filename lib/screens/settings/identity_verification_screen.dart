import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../widgets/verification_status_card.dart';
import 'package:provider/provider.dart';
import '../../providers/kyc_provider.dart';
import 'sumsub_verification_screen.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/location_picker/location_picker.dart';
import '../../providers/auth_provider.dart';
import 'start_identity_verification_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCountry = '';
  String _selectedState = '';
  String _selectedCity = '';
  bool _loading = false;
  bool _locationLoading = false;
  String? _locationError;
  bool _showForm = false;

  static const String _storageKey = 'identity_verification_form';

  Future<void> _loadKYCDetails() async {
    try {
      await Provider.of<KYCProvider>(context, listen: false).loadKYCDetails();
      final kycProvider = Provider.of<KYCProvider>(context, listen: false);
      final kycDetails = kycProvider.kycDetails;
      final identity = kycDetails?.kycData?['identityDetails'];
      if (identity != null) {
        setState(() {
          _firstNameController.text = identity['firstName'] ?? '';
          _lastNameController.text = identity['lastName'] ?? '';
          _dobController.text = identity['dateOfBirth'] != null && identity['dateOfBirth'].isNotEmpty
              ? _formatDateForInput(identity['dateOfBirth'])
              : '';
          _addressController.text = identity['address'] ?? '';
          _selectedCountry = identity['country'] ?? '';
          _selectedState = identity['state'] ?? '';
          _selectedCity = identity['city'] ?? '';
        });
      } else {
        await _loadUserDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading KYC details')),
        );
      }
    }
  }

  String _formatDateForInput(String date) {
    // Converts YYYY-MM-DD to DD/MM/YYYY for the input field
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (_) {
      return date;
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final provider = context.read<AuthProvider>();
      final user = await provider.getCurrentUser();
      final fullName = user['fullName'] as String;
      final names = fullName.split(' ');
      
      setState(() {
        _firstNameController.text = names.first;
        _lastNameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';
      });
    } catch (e) {
      print('Error loading user details');
    }
  }

  @override
  void initState() {
    super.initState();
    // Show form initially only if no verification attempt has been made
    final kycDetails = context.read<KYCProvider>().kycDetails;
    _showForm = kycDetails?.verificationStatus?.identity?.status == null;
    _loadSavedFormData().then((_) {
      // Then load other data
      _loadKYCDetails();
    });
    _setupAutoSave();
  }

  void _setupAutoSave() {
    // Set up listeners for text fields
    _firstNameController.addListener(_saveFormData);
    _lastNameController.addListener(_saveFormData);
    _dobController.addListener(_saveFormData);
    _addressController.addListener(_saveFormData);
  }

  Future<void> _loadSavedFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_storageKey);
      
      if (savedData != null) {
        final data = json.decode(savedData) as Map<String, dynamic>;
        print('Loading saved form data: $data'); // Debug log
        
        if (mounted) {
          setState(() {
            _firstNameController.text = data['firstName'] ?? '';
            _lastNameController.text = data['lastName'] ?? '';
            _dobController.text = data['dob'] ?? '';
            _addressController.text = data['address'] ?? '';
            _selectedCountry = data['country'] ?? '';
            _selectedState = data['state'] ?? '';
            _selectedCity = data['city'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading saved form data');
    }
  }

  Future<void> _saveFormData() async {
    if (!mounted) return;  // Don't save if widget is disposed
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
      };
      
      await prefs.setString(_storageKey, json.encode(data));
      print('Form data saved successfully: $data'); // Debug log
    } catch (e) {
      print('Error saving form data');
    }
  }

  Future<void> _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('Form data cleared successfully'); // Debug log
    } catch (e) {
      print('Error clearing saved form data');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime minAge = now.subtract(const Duration(days: 6570)); // 18 years ago
    final DateTime maxAge = now.subtract(const Duration(days: 36500)); // 100 years ago

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minAge,
      firstDate: maxAge,
      lastDate: minAge,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SafeJetColors.secondaryHighlight,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
            dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: SafeJetColors.secondaryHighlight,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Widget _buildLocationFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        CustomLocationPicker(
          isDark: isDark,
          selectedCountry: _selectedCountry,
          selectedState: _selectedState,
          selectedCity: _selectedCity,
          isLoading: _locationLoading,
          errorMessage: _locationError,
          onCountryChanged: _onCountryChanged,
          onStateChanged: _onStateChanged,
          onCityChanged: _onCityChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final kycProvider = Provider.of<KYCProvider>(context);
    final kycDetails = kycProvider.kycDetails;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.grey[100],
      appBar: P2PAppBar(
        title: 'Identity Verification',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1A1A1A)  // Dark card background
                      : Colors.white,            // Light card background
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: VerificationStatusCard(
                  type: 'Identity',
                  identityStatus: kycDetails?.verificationStatus?.identity,
                  onRetry: kycDetails?.verificationStatus?.identity?.status == 'failed'
                      ? _startVerification
                      : null,
                  isRetrying: _loading,
                ),
              ),
            ),
            if (_showForm || kycDetails?.verificationStatus?.identity?.status == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FadeInUp(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildFormField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildLocationFields(isDark),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submitIdentityDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.secondaryHighlight,
                              disabledBackgroundColor: SafeJetColors.secondaryHighlight.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Submit & Start Verification',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1A1A1A)  // Dark card background
            : Colors.white,            // Light card background
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: SafeJetColors.primary,
              width: 1,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        validator: (value) => value?.isEmpty == true ? 'Required' : null,
      ),
    );
  }

  Future<void> _submitIdentityDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCountry.isEmpty || _selectedState.isEmpty || _selectedCity.isEmpty) {
      setState(() {
        _locationError = 'Please select your location details';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      // Convert date from DD/MM/YYYY to YYYY-MM-DD
      final dateParts = _dobController.text.split('/');
      if (dateParts.length != 3) {
        throw Exception('Invalid date format');
      }
      final day = dateParts[0].padLeft(2, '0');
      final month = dateParts[1].padLeft(2, '0');
      final year = dateParts[2];
      final formattedDate = '$year-$month-$day';

      await context.read<KYCProvider>().submitIdentityDetails(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: formattedDate,  // Now in YYYY-MM-DD format
        address: _addressController.text.trim(),
        city: _selectedCity,
        state: _selectedState,
        country: _selectedCountry,
      );

      await _clearSavedData();

      if (!mounted) return;
      // Navigate to the new intermediate screen instead of starting verification immediately
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StartIdentityVerificationScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: SafeJetColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      print('Technical error details');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startVerification() async {
    setState(() => _loading = true);
    try {
      final result = await Provider.of<KYCProvider>(context, listen: false)
          .startDocumentVerification();

      if (!mounted) return;
      if (result['token'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SumsubVerificationScreen(
              accessToken: result['token']!,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Unable to start verification'),
            backgroundColor: SafeJetColors.info,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Technical error details'); // Keep technical details in logs
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to start verification process. Please try again later.',
          ),
          backgroundColor: SafeJetColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCountryChanged(String country) {
    setState(() {
      _selectedCountry = country;
      _selectedState = '';
      _selectedCity = '';
    });
    _saveFormData();  // Save when country changes
  }

  void _onStateChanged(String state) {
    setState(() {
      _selectedState = state;
      _selectedCity = '';
    });
    _saveFormData();  // Save when state changes
  }

  void _onCityChanged(String city) {
    setState(() {
      _selectedCity = city;
    });
    _saveFormData();  // Save when city changes
  }

  @override
  void dispose() {
    // Save form data one last time before disposing
    _saveFormData();
    
    // Clean up controllers and listeners
    _firstNameController.removeListener(_saveFormData);
    _lastNameController.removeListener(_saveFormData);
    _dobController.removeListener(_saveFormData);
    _addressController.removeListener(_saveFormData);
    
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }
} 