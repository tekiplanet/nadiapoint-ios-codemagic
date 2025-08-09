import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../models/payment_method.dart';
import '../models/payment_method_type.dart';
import 'package:provider/provider.dart';
import '../providers/payment_methods_provider.dart';

class PaymentMethodDialog extends StatefulWidget {
  final PaymentMethod? method;
  final PaymentMethodType? selectedType;
  final bool isDark;

  const PaymentMethodDialog({
    super.key,
    this.method,
    this.selectedType,
    required this.isDark,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;
  Map<String, TextEditingController> _detailControllers = {};
  PaymentMethodType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    
    if (widget.method != null) {
      _nameController.text = widget.method!.name ?? '';
      _isDefault = widget.method!.isDefault;
      
      // Initialize detail controllers with existing values
      widget.method!.details.forEach((key, value) {
        _detailControllers[key] = TextEditingController(text: value.toString());
      });
    } else if (_selectedType != null) {
      // Initialize controllers based on type fields
      for (var field in _selectedType!.fields) {
        _detailControllers[field.name] = TextEditingController();
      }
    }
  }

  Map<String, dynamic> get _details {
    final details = <String, dynamic>{};
    _detailControllers.forEach((key, controller) {
      details[key] = controller.text;
    });
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDark 
        ? SafeJetColors.darkGradientStart
        : SafeJetColors.lightGradientStart;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDark
                ? [SafeJetColors.darkGradientStart, SafeJetColors.darkGradientEnd]
                : [SafeJetColors.lightGradientStart, SafeJetColors.lightGradientEnd],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.method == null ? 'Add Payment Method' : 'Edit Payment Method',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: SafeJetColors.primaryAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: widget.isDark ? Colors.white70 : Colors.black87,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Method Type Dropdown
                if (widget.method == null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Payment Method Type',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Consumer<PaymentMethodsProvider>(
                        builder: (context, provider, child) {
                          final types = provider.paymentMethodTypes;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: SafeJetColors.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: SafeJetColors.primaryAccent.withOpacity(0.2),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedType?.id,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                              ),
                              items: types.map((type) {
                                return DropdownMenuItem(
                                  value: type.id,
                                  child: Text(type.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = types.firstWhere((t) => t.id == value);
                                    // Reset controllers and create new ones based on selected type
                                    _detailControllers = {};
                                    for (var field in _selectedType!.fields) {
                                      _detailControllers[field.name] = TextEditingController();
                                    }
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a payment method type';
                                }
                                return null;
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],

                // Name Field
                _buildInputField(
                  controller: _nameController,
                  label: 'Payment Method Name',
                  hint: 'e.g., Primary Bank Account',
                ),
                const SizedBox(height: 24),

                // Payment Details Section
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Detail Fields
                if (_selectedType != null) ...[
                  ..._selectedType!.fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildInputField(
                        controller: _detailControllers[field.name]!,
                        label: field.label,
                        hint: field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
                        validationRules: field.validationRules,
                      ),
                    );
                  }).toList(),
                ],

                // Set as Default Switch
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
                          color: widget.isDark ? Colors.white : Colors.black87,
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
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeJetColors.secondaryHighlight,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text(
                            widget.method == null ? 'Add' : 'Save',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
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
    Map<String, dynamic>? validationRules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 16,
            color: widget.isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: widget.isDark 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
            ),
            filled: true,
            fillColor: SafeJetColors.primaryAccent.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: SafeJetColors.primaryAccent.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: SafeJetColors.primaryAccent.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: SafeJetColors.secondaryHighlight,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
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

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'name': _nameController.text,
        'isDefault': _isDefault,
        'paymentMethodTypeId': _selectedType?.id,
        'details': _details,
      };
      Navigator.pop(context, data);
    }
  }

  Future<void> _handleDefaultToggle(bool value) async {
    if (!value) {
      setState(() => _isDefault = value);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Default'),
        content: const Text(
          'This will make this payment method your default option for all transactions. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeJetColors.secondaryHighlight,
              foregroundColor: Colors.black,
            ),
            child: const Text('Set as Default'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDefault = true);
    }
  }
} 