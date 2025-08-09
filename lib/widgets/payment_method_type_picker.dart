import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../models/payment_method_type.dart';

class PaymentMethodTypePicker extends StatefulWidget {
  final List<PaymentMethodType> types;
  final bool isDark;
  final Function(PaymentMethodType) onSelect;

  const PaymentMethodTypePicker({
    super.key,
    required this.types,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<PaymentMethodTypePicker> createState() => _PaymentMethodTypePickerState();
}

class _PaymentMethodTypePickerState extends State<PaymentMethodTypePicker> {
  final _searchController = TextEditingController();
  List<PaymentMethodType> _filteredTypes = [];

  @override
  void initState() {
    super.initState();
    _filteredTypes = widget.types;
  }

  void _filterTypes(String query) {
    setState(() {
      _filteredTypes = widget.types.where((type) {
        return type.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark 
            ? SafeJetColors.darkGradientStart
            : SafeJetColors.lightGradientStart,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Payment Method Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterTypes,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search payment methods...',
                  hintStyle: TextStyle(
                    color: widget.isDark 
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.isDark 
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Types list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredTypes.length,
              itemBuilder: (context, index) {
                final type = _filteredTypes[index];
                return InkWell(
                  onTap: () {
                    widget.onSelect(type);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: SafeJetColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SafeJetColors.primaryAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isDark 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(type.icon),
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              if (type.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  type.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isDark 
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
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
      default:
        return Icons.account_balance;
    }
  }
} 