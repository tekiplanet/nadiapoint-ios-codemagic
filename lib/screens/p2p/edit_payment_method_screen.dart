import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_method.dart';
import '../../models/payment_method_field.dart';
import '../../providers/payment_methods_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod method;

  const EditPaymentMethodScreen({
    Key? key,
    required this.method,
  }) : super(key: key);

  @override
  State<EditPaymentMethodScreen> createState() => _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isDefault;
  bool _isLoading = false;
  final Map<String, TextEditingController> _detailControllers = {};

  @override
  void initState() {
    super.initState();
    _isDefault = widget.method.isDefault;
    _initializeControllers();
    
    // Add this to handle unauthorized on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentMethodsProvider>().setContext(context);
      }
    });
  }

  void _initializeControllers() {
    for (var field in widget.method.paymentMethodType?.fields ?? []) {
      final existingValue = widget.method.details[field.name]?.value ?? '';
      _detailControllers[field.name] = TextEditingController(text: existingValue);
    }
  }

  @override
  void dispose() {
    _detailControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> pickAndCropImage(String fieldName) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 100,
          maxWidth: 1000,
          maxHeight: 1000,
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          setState(() {
            _detailControllers[fieldName]?.text = base64Image;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('Session expired')) {
        await Provider.of<AuthProvider>(context, listen: false)
            .handleUnauthorized(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
  }

  Widget _buildInputField(PaymentMethodField field, bool isDark) {
    switch (field.type) {
      case 'text':
        return _buildTextField(field, isDark);
      case 'textarea':
        return _buildTextAreaInput(field, isDark);
      case 'select':
        return _buildSelectInput(field, isDark);
      case 'email':
        return _buildTextField(field, isDark);
      case 'phone':
        return _buildPhoneInput(field, isDark);
      case 'date':
        return _buildDateInput(field, isDark);
      case 'image':
        return _buildImageInput(field, isDark);
      default:
        return _buildTextField(field, isDark);
    }
  }

  Widget _buildTextField(PaymentMethodField field, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          maxLines: field.validationRules?['maxLines'] ?? 1,
          maxLength: field.validationRules?['maxLength'],
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
            
            // Minimum length validation
            if (field.validationRules?['minLength'] != null) {
              final minLength = field.validationRules!['minLength'] as int;
              if ((value?.length ?? 0) < minLength) {
                return '${field.label} must be at least $minLength characters';
              }
            }

            // Maximum length validation
            if (field.validationRules?['maxLength'] != null) {
              final maxLength = field.validationRules!['maxLength'] as int;
              if ((value?.length ?? 0) > maxLength) {
                return '${field.label} must not exceed $maxLength characters';
              }
            }

            // Pattern validation
            if (field.validationRules?['pattern'] != null) {
              final pattern = RegExp(field.validationRules!['pattern']);
              if (!pattern.hasMatch(value ?? '')) {
                return field.validationRules?['patternError'] ?? 'Invalid format';
              }
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSelectInput(PaymentMethodField field, bool isDark) {
    final options = field.validationRules?['options'] as List<dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _detailControllers[field.name]?.text,
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Select ${field.label.toLowerCase()}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: options?.map((option) {
              final value = option['value'].toString();
              final label = option['label'].toString();
              return DropdownMenuItem(value: value, child: Text(label));
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

  Widget _buildPhoneInput(PaymentMethodField field, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          keyboardType: TextInputType.phone,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: _getInputDecoration(
            field.placeholder ?? 'Enter phone number',
            isDark,
            prefixIcon: Icon(
              Icons.phone,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          validator: (value) {
            if (field.isRequired && (value?.isEmpty ?? true)) {
              return '${field.label} is required';
            }

            // Phone pattern validation
            if (field.validationRules?['pattern'] != null) {
              final pattern = RegExp(field.validationRules!['pattern']);
              if (!pattern.hasMatch(value ?? '')) {
                return field.validationRules?['patternError'] ?? 'Invalid phone number format';
              }
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateInput(PaymentMethodField field, bool isDark) {
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
            suffixIcon: Icon(
              Icons.calendar_today,
              color: isDark ? Colors.white70 : Colors.black54,
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

  Widget _buildImageInput(PaymentMethodField field, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          readOnly: true,
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
          onTap: () => pickAndCropImage(field.name),
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
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (_detailControllers[field.name]?.text.startsWith('data:image') ?? false)
                      ? Image.memory(
                          base64Decode(_detailControllers[field.name]!.text.split(',')[1]),
                          fit: BoxFit.cover,
                        )
                      : _buildNetworkImage(_detailControllers[field.name]?.text ?? ''),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: SafeJetColors.primaryAccent,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _detailControllers[field.name]?.text = '';
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return FutureBuilder<String>(
      future: context.read<PaymentMethodsProvider>().getImageUrl(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('Image error: ${snapshot.error}');
          if (snapshot.error.toString().contains('401') || 
              snapshot.error.toString().contains('403')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<AuthProvider>(context, listen: false)
                  .handleUnauthorized(context);
            });
          }
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        }

        return Image.memory(
          base64Decode(snapshot.data!.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Image decode error: $error');
            return const Center(
              child: Icon(Icons.error_outline, color: Colors.red),
            );
          },
        );
      },
    );
  }

  TextStyle _getLabelStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white70 : Colors.black54,
    );
  }

  InputDecoration _getInputDecoration(String hint, bool isDark, {Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      filled: true,
      fillColor: isDark 
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
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
          color: SafeJetColors.primaryAccent,
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SafeJetColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: SafeJetColors.error,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // Print method ID and type for debugging
      print('Editing payment method:');
      print('ID: ${widget.method.id}');
      print('Type: ${widget.method.paymentMethodType?.name}');

      // Create details map from controllers
      final details = <String, Map<String, dynamic>>{};
      for (var field in widget.method.paymentMethodType?.fields ?? []) {
        details[field.name] = {
          'value': _detailControllers[field.name]?.text ?? '',
          'fieldId': field.id,
          'fieldName': field.name,
          'fieldType': field.type,
        };
        // Print each field for debugging
        print('Field ${field.name}: ${_detailControllers[field.name]?.text}');
      }

      final data = {
        'isDefault': _isDefault,
        'details': details,
        'paymentMethodTypeId': widget.method.paymentMethodType?.id,
      };

      await context.read<PaymentMethodsProvider>().updatePaymentMethod(
        widget.method.id,
        data,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method updated successfully'),
          backgroundColor: SafeJetColors.success,
        ),
      );

      await context.read<PaymentMethodsProvider>().loadPaymentMethods();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('Session expired')) {
        await Provider.of<AuthProvider>(context, listen: false)
            .handleUnauthorized(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextAreaInput(PaymentMethodField field, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: _getLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailControllers[field.name],
          maxLines: field.validationRules?['maxLines'] ?? 5,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: _getInputDecoration(
            field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
            isDark,
          ),
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
      initialDate: now,  // Start from today for future dates
      firstDate: now,  // Allow dates up to year 2100
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark 
          ? SafeJetColors.darkGradientStart
          : SafeJetColors.lightGradientStart,
      appBar: P2PAppBar(
        title: 'Edit Payment Method',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Payment Method Type Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SafeJetColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SafeJetColors.primaryAccent.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(widget.method.paymentMethodType?.icon ?? 'account_balance'),
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.method.paymentMethodType?.name ?? 'Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (widget.method.paymentMethodType?.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.method.paymentMethodType!.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Fields
                    ...widget.method.paymentMethodType?.fields.map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInputField(field, isDark),
                      );
                    }) ?? [],

                    const SizedBox(height: 8),

                    // Default Payment Method Switch
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Set as default payment method',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() => _isDefault = value);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SafeJetColors.secondaryHighlight,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Update Payment Method',
                                style: TextStyle(
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
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconString) {
    if (iconString == null || iconString.isEmpty) {
      return Icons.account_balance; // Default icon
    }

    // Map string names to Icons
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
} 