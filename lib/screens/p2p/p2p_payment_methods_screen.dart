import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../providers/payment_methods_provider.dart';
import '../../models/payment_method.dart';
import '../../widgets/payment_method_dialog.dart';
import 'package:animate_do/animate_do.dart';
import 'add_payment_method_screen.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'edit_payment_method_screen.dart';
import 'package:collection/collection.dart';
import 'package:shimmer/shimmer.dart';

class P2PPaymentMethodsScreen extends StatefulWidget {
  const P2PPaymentMethodsScreen({super.key});

  @override
  State<P2PPaymentMethodsScreen> createState() => _P2PPaymentMethodsScreenState();
}

class _P2PPaymentMethodsScreenState extends State<P2PPaymentMethodsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentMethodsProvider>();
      provider.setContext(context);
      provider.loadPaymentMethods();
      provider.loadPaymentMethodTypes();
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Show 3 shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      height: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Payment Methods',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SafeJetColors.primaryAccent.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The payment method you add will be displayed to the buyer when you sell your crypto via P2P. Please utilize an account registered under your real name to ensure a successful transfer.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<PaymentMethodsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildShimmerLoading(); // Use shimmer loading instead of CircularProgressIndicator
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: TextStyle(color: SafeJetColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadPaymentMethods(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.paymentMethods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: SafeJetColors.primaryAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: isDark 
                                ? SafeJetColors.secondaryHighlight
                                : SafeJetColors.secondaryHighlight.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Payment Methods Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Add your preferred payment methods to start trading on SafeJet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 200,
                          height: 48,
                          child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddPaymentMethodScreen(),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.secondaryHighlight,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Add Method',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = provider.paymentMethods[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: index * 100),
                      child: SlideInLeft(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: index * 100),
                        child: _buildPaymentMethodCard(method, isDark),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPaymentMethodScreen(),
            ),
          );
        },
        backgroundColor: SafeJetColors.secondaryHighlight,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.02)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                        _getIconData(method.icon),
                  color: SafeJetColors.secondaryHighlight,
                  size: 24,
                      ),
                const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              method.paymentMethodType?.name ?? '',
                              style: TextStyle(
                              fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                              if (method.isDefault) ...[
                            const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                  ),
                              child: Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 12,
                                  color: SafeJetColors.secondaryHighlight,
                                  fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                      Text(
                        method.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                                ),
                            ],
                          ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPaymentMethodScreen(method: method),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () => _handleDelete(method),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Details section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...method.details.entries.map((entry) {
                  final detail = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildDetailValue(detail, isDark, method),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(PaymentMethod method) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark 
            ? SafeJetColors.darkGradientStart
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SafeJetColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: SafeJetColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delete Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this payment method?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              method.paymentMethodType?.name ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              method.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: SafeJetColors.error.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Close the dialog first
                    Navigator.pop(context);
                    
                    try {
                      // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Deleting payment method...'),
                            ],
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Delete the payment method
        await context
            .read<PaymentMethodsProvider>()
                          .deletePaymentMethod(method.id);
                      
                      // Show success message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
          const SnackBar(
                              content: Text('Payment method deleted successfully'),
            backgroundColor: SafeJetColors.success,
                              duration: Duration(seconds: 2),
          ),
        );
                      }
      } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: SafeJetColors.error,
                              duration: Duration(seconds: 3),
          ),
        );
      }
    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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

  Widget _buildDetailValue(PaymentMethodDetail detail, bool isDark, PaymentMethod method) {
    // Handle select type fields
    if (detail.fieldType == 'select') {
      // Find the corresponding field in payment method type using ID
      final field = method.paymentMethodType?.fields.firstWhereOrNull(
        (f) => f.id == detail.fieldId,
      );
      
      if (field != null) {
        final options = field.validationRules?['options'] as List<dynamic>?;
        if (options != null) {
          try {
            final selectedOption = options.firstWhere(
              (option) => option['value'].toString().toLowerCase() == detail.value.toLowerCase(),
              orElse: () => {'label': detail.value},
            );
            return Text(
              selectedOption['label'].toString(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            );
          } catch (e) {
            print('Error finding option');
            return Text(detail.value);
          }
        }
      }
    }

    // Handle other field types as before
    if (detail.fieldType == 'image') {
      final baseUrl = dotenv.get('API_URL', fallback: '');
      return Image.network(
        detail.getImageUrl(baseUrl),
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red),
          );
        },
      );
    } else if (detail.fieldType == 'date') {
      try {
        final date = DateTime.parse(detail.value);
        return Text(DateFormat('MMM dd, yyyy').format(date));
      } catch (e) {
        return Text(detail.value);
      }
    }
    return Text(detail.value);
  }
} 