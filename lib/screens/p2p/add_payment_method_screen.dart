import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../models/payment_method_type.dart';
import '../../providers/payment_methods_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../widgets/payment_method_type_picker.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import '../../models/payment_method_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({
    super.key,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;
  Map<String, TextEditingController> _detailControllers = {};
  PaymentMethodType? _selectedType;

  @override
  void initState() {
    super.initState();
    // Load user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get isDark directly from Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark 
          ? SafeJetColors.darkGradientStart
          : SafeJetColors.lightGradientStart,
      appBar: P2PAppBar(
        title: 'Add Payment Method',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Consumer<PaymentMethodsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [



 // Payment Method Type Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SafeJetColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SafeJetColors.primaryAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => PaymentMethodTypePicker(
                                types: provider.paymentMethodTypes,
                                isDark: isDark,
                                onSelect: (type) {
                                  setState(() {
                                    _selectedType = type;
                                    _detailControllers = {};
                                    for (var field in type.fields) {
                                      _detailControllers[field.name] = TextEditingController();
                                    }
                                  });
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (_selectedType != null) ...[
                                  Icon(
                                    _getIconData(_selectedType!.icon),
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedType!.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'Select payment method type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark 
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),



                  // Name Field Section (Always visible)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SafeJetColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SafeJetColors.primaryAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This payment method will be registered under your name',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            print('AuthProvider state: ${authProvider.toString()}');
                            print('User object: ${authProvider.user}');
                            print('User fullName: ${authProvider.user?.fullName}');

                            final fullName = authProvider.user?.fullName ?? '';
                            _nameController.text = fullName;
                            
                            return TextFormField(
                              controller: _nameController,
                              enabled: false,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark 
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: isDark 
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black.withOpacity(0.7),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                 
                  // Payment Method Details
                  if (_selectedType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: SafeJetColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: SafeJetColors.primaryAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._selectedType!.fields.map((field) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildFieldInput(field),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Set as Default Option
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: SafeJetColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: SafeJetColors.primaryAccent.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Set as Default',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Switch(
                            value: _isDefault,
                            onChanged: _handleDefaultToggle,
                            activeColor: SafeJetColors.secondaryHighlight,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeJetColors.secondaryHighlight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text(
                      'Add Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    Map<String, dynamic>? validationRules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
            ),
            filled: true,
            fillColor: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (validationRules?['required'] == true && (value?.isEmpty ?? true)) {
              return 'Please enter $label';
            }
            if (value != null && value.isNotEmpty) {
              final minLength = validationRules?['minLength'] as int?;
              if (minLength != null && value.length < minLength) {
                return '$label must be at least $minLength characters';
              }
              
              final maxLength = validationRules?['maxLength'] as int?;
              if (maxLength != null && value.length > maxLength) {
                return '$label must not exceed $maxLength characters';
              }
              
              final pattern = validationRules?['pattern'] as String?;
              if (pattern != null && !RegExp(pattern).hasMatch(value)) {
                return '$label format is invalid';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Get the current user's name
      final user = context.read<AuthProvider>().user;
      final userName = user?.fullName ?? 'Unnamed Payment Method';

      final details = <String, dynamic>{};
      
      for (final field in _selectedType!.fields) {
        final value = _detailControllers[field.name]?.text ?? '';
        
        if (field.type == 'image' && value.isNotEmpty) {
          // Make sure we have proper base64 format
          if (!value.startsWith('data:image/')) {
            details[field.name] = {
              'value': 'data:image/jpeg;base64,$value',
              'fieldId': field.id,
              'fieldType': field.type,
              'fieldName': field.name,
            };
          } else {
            details[field.name] = {
              'value': value,
              'fieldId': field.id,
              'fieldType': field.type,
              'fieldName': field.name,
            };
          }
        } else {
          details[field.name] = {
            'value': value,
            'fieldId': field.id,
            'fieldType': field.type,
            'fieldName': field.name,
          };
        }
      }

      final data = {
        'paymentMethodTypeId': _selectedType!.id,
        'isDefault': _isDefault,
        'name': userName,
        'details': details,
      };

      await context.read<PaymentMethodsProvider>().createPaymentMethod(data);

      await context.read<PaymentMethodsProvider>().loadPaymentMethods();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error submitting form');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDefaultToggle(bool value) async {
    if (!value) {
      setState(() => _isDefault = value);
      return;
    }

    _showSetDefaultDialog(context, Theme.of(context).brightness == Brightness.dark);
  }

  void _showSetDefaultDialog(BuildContext context, bool isDark) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark 
            ? SafeJetColors.darkGradientStart
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Set as Default',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'This will make this payment method your default option for all transactions. Continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeJetColors.secondaryHighlight,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Set as Default',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && mounted) {
        setState(() => _isDefault = true);
      }
    });
  }

  IconData _getIconData(String iconString) {
    switch (iconString) {
      case 'account_balance':
        return Icons.account_balance;
      case 'payment':
        return Icons.payment;
      case 'attach_money':
        return Icons.attach_money;
      case 'mobile_friendly':
        return Icons.mobile_friendly;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'qr_code':
        return Icons.qr_code;
      case 'phone_android':
        return Icons.phone_android;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'money':
        return Icons.money;
      default:
        return Icons.account_balance; // Default icon
    }
  }

  // Update _buildFieldInput to handle more types
  Widget _buildFieldInput(PaymentMethodField field) {
    switch (field.type.toLowerCase()) {
      case 'image':
        return _buildImageInput(field);
      case 'select':
        return _buildSelectInput(field);
      case 'date':
        return _buildDateInput(field);
      case 'number':
        return _buildNumberInput(field);
      case 'phone':
        return _buildPhoneInput(field);
      case 'email':
        return _buildEmailInput(field);
      case 'text':
      default:
        return _buildTextInput(field);
    }
  }

  // Add new field type widgets
  Widget _buildDateInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          readOnly: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: _getInputDecoration(
            field.placeholder ?? 'Select date',
            isDark,
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SafeJetColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: SafeJetColors.primaryAccent,
              ),
            ),
          ),
          onTap: () async {
            final controller = _detailControllers[field.name];
            if (controller != null) {
              await _selectDate(context, controller);
            }
          },
          validator: field.isRequired ? (value) {
            if (value?.isEmpty ?? true) return '${field.label} is required';
            return null;
          } : null,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,  // Start from today for future dates
      lastDate: DateTime(2100),  // Allow dates up to year 2100
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SafeJetColors.secondaryHighlight,
              onPrimary: Colors.black,
              surface: isDark ? SafeJetColors.darkGradientStart : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDark ? SafeJetColors.darkGradientStart : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      controller.text = formattedDate;
    }
  }

  Widget _buildNumberInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final min = field.validationRules?['min'] as num?;
    final max = field.validationRules?['max'] as num?;
    final format = NumberFormat("#,##0", "en_US");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: _getInputDecoration(
            field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
            isDark,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              // Remove any non-digit characters
              final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (numericValue.isNotEmpty) {
                final number = int.parse(numericValue);
                // Format the number with commas
                final formatted = format.format(number);
                // Update the text field without triggering onChanged
                _detailControllers[field.name]?.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            }
          },
          validator: (value) {
            if (field.isRequired && (value?.isEmpty ?? true)) {
              return '${field.label} is required';
            }
            if (value != null && value.isNotEmpty) {
              final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
              final number = int.tryParse(numericValue);
              if (number == null) {
                return 'Please enter a valid number';
              }
              if (min != null && number < min) {
                return '${field.label} must be at least ${format.format(min)}';
              }
              if (max != null && number > max) {
                return '${field.label} must not exceed ${format.format(max)}';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _detailControllers[field.name],
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Enter phone number',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                child: Icon(
                  Icons.phone_outlined,
                  color: SafeJetColors.primaryAccent,
                  size: 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (field.isRequired && (value?.isEmpty ?? true)) {
                return '${field.label} is required';
              }
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _detailControllers[field.name],
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Enter email address',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: SafeJetColors.primaryAccent,
                  size: 22,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (field.isRequired && (value?.isEmpty ?? true)) {
                return '${field.label} is required';
              }
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // Common input decoration for all fields
  InputDecoration _getInputDecoration(String hint, bool isDark, {Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark 
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SafeJetColors.primaryAccent.withOpacity(0.5),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SafeJetColors.error.withOpacity(0.5),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SafeJetColors.error.withOpacity(0.8),
          width: 2,
        ),
      ),
    );
  }

  // Common text style for field labels
  TextStyle _getLabelStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white70 : Colors.black87,
    );
  }

  // Update the input fields with new styling
  Widget _buildTextInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxLines = field.validationRules?['maxLines'] as int? ?? 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: _getInputDecoration(
            field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
            isDark,
          ),
          validator: (value) {
            if (field.isRequired && (value?.isEmpty ?? true)) {
              return '${field.label} is required';
            }
            // Add any additional validation from validationRules
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSelectInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = field.validationRules?['options'] as List<dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Select ${field.label.toLowerCase()}',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Remove the suffix icon since DropdownButtonFormField adds its own
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            value: _detailControllers[field.name]?.text.isEmpty ?? true 
                ? null 
                : _detailControllers[field.name]?.text,
            items: options?.map((option) {
              final value = option['value'].toString();
              final label = option['label'].toString();
              return DropdownMenuItem(
                value: value,
                child: Text(label),
              );
            }).toList() ?? [],
            onChanged: (value) {
              _detailControllers[field.name]?.text = value ?? '';
            },
            validator: field.isRequired ? (value) {
              if (value?.isEmpty ?? true) return '${field.label} is required';
              return null;
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildImageInput(PaymentMethodField field) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Future<void> pickAndCropImage() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: SafeJetColors.primaryAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              backgroundColor: isDark ? Colors.grey[900]! : Colors.white,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          // Check file size (max 5MB)
          if (bytes.length > 5 * 1024 * 1024) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: SafeJetColors.error,
              ),
            );
            return;
          }
          final base64Image = base64Encode(bytes);
          _detailControllers[field.name]?.text = base64Image;
          setState(() {});
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _detailControllers[field.name],
                readOnly: true,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: _getInputDecoration(
                  field.placeholder ?? 'Select image',
                  isDark,
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SafeJetColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image,
                      color: SafeJetColors.primaryAccent,
                    ),
                  ),
                ),
                onTap: pickAndCropImage,
                validator: field.isRequired ? (value) {
                  if (value?.isEmpty ?? true) return '${field.label} is required';
                  return null;
                } : null,
              ),
              if (_detailControllers[field.name]?.text.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(
                            base64Decode(_detailControllers[field.name]!.text),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _detailControllers[field.name]?.text = '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(PaymentMethodField field, bool isDark) {
    // Return original implementation for other field types
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          keyboardType: field.type == 'email' 
              ? TextInputType.emailAddress 
              : TextInputType.text,
          decoration: _getInputDecoration(
            field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
            isDark,
            prefixIcon: field.type == 'email' 
                ? Icon(
                    Icons.email_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                  )
                : null,
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return '${field.label} is required';
            }
            if (field.type == 'email' && value != null && value.isNotEmpty) {
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            if (field.validationRules != null) {
              final minLength = field.validationRules!['minLength'] as int?;
              final maxLength = field.validationRules!['maxLength'] as int?;
              
              if (minLength != null && value!.length < minLength) {
                return '${field.label} must be at least $minLength characters';
              }
              if (maxLength != null && value!.length > maxLength) {
                return '${field.label} must be at most $maxLength characters';
              }
            }
            return null;
          },
        ),
        if (field.helpText != null && field.helpText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              field.helpText!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
} 