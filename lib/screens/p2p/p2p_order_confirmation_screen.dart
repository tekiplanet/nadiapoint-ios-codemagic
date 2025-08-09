import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'p2p_chat_screen.dart';
import 'package:flutter/services.dart';
import '../../widgets/p2p_app_bar.dart';
import 'p2p_dispute_screen.dart';
import 'p2p_order_history_screen.dart';
import 'p2p_dispute_history_screen.dart';
import 'p2p_dispute_details_screen.dart';
import '../../services/p2p_service.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'p2p_screen.dart';
import '../main/home_screen.dart';
import '../../widgets/shimmer_loading.dart';

// Add this enum at the top of the file after the imports
enum DisputeReasonType {
  PAYMENT_ISSUE('payment_issue'),
  FRAUD('fraud'),
  TECHNICAL_ISSUE('technical_issue'),
  BUYER_NOT_PAID('buyer_not_paid'),
  SELLER_NOT_RELEASED('seller_not_released'),
  WRONG_AMOUNT('wrong_amount'),
  OTHER('other');

  final String value;
  const DisputeReasonType(this.value);
}

// Move AnimatedDialog outside the state class
class AnimatedDialog extends StatelessWidget {
  final Widget child;

  const AnimatedDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }
}

// Move CustomPageRoute outside the state class
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.1);
            const end = Offset.zero;
            const curve = Curves.easeOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
}

// Add this class after the CustomPageRoute class
class PaymentConfirmationDialog extends StatefulWidget {
  final String trackingId;
  final Map<String, dynamic> orderDetails;
  final P2PService p2pService;
  final bool isDark;
  final Function formatAmount;
  final ValueNotifier<bool> hasAgreed;

  const PaymentConfirmationDialog({
    Key? key,
    required this.trackingId,
    required this.orderDetails,
    required this.p2pService,
    required this.isDark,
    required this.formatAmount,
    required this.hasAgreed,
  }) : super(key: key);

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> {
  bool isSubmitting = false;

  Widget _buildConfirmationDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor:
            widget.isDark ? SafeJetColors.primaryBackground : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Confirm Payment',
            style: TextStyle(
              color: widget.isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please confirm your payment details:',
                      style: TextStyle(
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildConfirmationDetailCard(
                      title: 'Amount',
                      value:
                          '${widget.formatAmount(widget.orderDetails['currencyAmount'])} ${widget.orderDetails['offer']['currency']}',
                      icon: Icons.account_balance_wallet,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildConfirmationDetailCard(
                      title: 'Beneficiary',
                      value: widget.orderDetails['seller']['fullName'],
                      icon: Icons.person_outline,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SafeJetColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: SafeJetColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: SafeJetColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please ensure you have made the payment before confirming. This action cannot be undone.',
                              style: TextStyle(
                                color:
                                    widget.isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: widget.hasAgreed.value,
                              onChanged: isSubmitting
                                  ? null
                                  : (newValue) {
                                      setState(() {
                                        widget.hasAgreed.value =
                                            newValue ?? false;
                                      });
                                    },
                              activeColor: SafeJetColors.secondaryHighlight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I confirm that I have paid the full amount to the beneficiary',
                              style: TextStyle(
                                color:
                                    widget.isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: widget.isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (!widget.hasAgreed.value || isSubmitting)
                          ? null
                          : () async {
                              setState(() {
                                isSubmitting = true;
                              });
                              try {
                                await widget.p2pService.confirmOrderPayment(
                                  widget.trackingId,
                                );
                                if (mounted) {
                                  Navigator.of(context).pop(true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Payment confirmed successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isSubmitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeJetColors.secondaryHighlight,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Payment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class P2POrderConfirmationScreen extends StatefulWidget {
  final String trackingId;

  const P2POrderConfirmationScreen({super.key, required this.trackingId});

  @override
  State<P2POrderConfirmationScreen> createState() =>
      _P2POrderConfirmationScreenState();
}

class _P2POrderConfirmationScreenState
    extends State<P2POrderConfirmationScreen> {
  final ValueNotifier<bool> hasAgreed = ValueNotifier<bool>(false);
  bool isSubmitting = false;
  bool _isPaymentConfirmed = false;
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  String _errorMessage = '';
  Timer? _timer;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  String? _userId;
  final P2PService _p2pService = P2PService();
  StreamSubscription? _orderUpdateSubscription;
  bool _isWebSocketConnected = false;

  // Add this getter for isDark
  bool get isDark =>
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchOrderDetails();
    _p2pService.startOrderUpdates(widget.trackingId);
    _orderUpdateSubscription = _p2pService.orderUpdates.listen(
      (update) {
        // print('Received order update: $update');
        if (!mounted) return;
        _handleOrderUpdate(update);
      },
      onError: (error) {
        print('Order update error: $error');
      },
    );
  }

  @override
  void dispose() {
    _orderUpdateSubscription?.cancel();
    _p2pService.stopOrderUpdates();
    _timer?.cancel();
    super.dispose();
  }

  void _handleOrderUpdate(Map<String, dynamic> newOrderDetails) {
    final oldStatus = _orderDetails?['buyerStatus']?.toLowerCase();
    final newStatus = newOrderDetails['buyerStatus']?.toLowerCase();

    setState(() {
      _orderDetails = newOrderDetails;
    });

    if (oldStatus != null && oldStatus != newStatus) {
      String message = '';
      switch (newStatus) {
        case 'paid':
          message = 'Buyer has confirmed payment';
          break;
        case 'completed':
          message = 'Order completed successfully';
          break;
        case 'disputed':
          message = 'Order has been disputed';
          break;
        case 'cancelled':
          message = 'Order has been cancelled';
          break;
      }

      if (message.isNotEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _loadUserIdAndFetchOrderDetails() async {
    try {
      // Get the user ID from the stored user object
      final storage = const FlutterSecureStorage();
      final userJson = await storage.read(key: 'user');

      if (userJson != null) {
        final userData = json.decode(userJson);
        final userId = userData['id'];

        print('Loaded user ID from storage: $userId');

        // Set the user ID
        setState(() {
          _userId = userId;
        });
      } else {
        print('No user data found in storage');
      }

      // Then fetch order details
      await _fetchOrderDetails();
    } catch (e) {
      print('Error loading user ID');
      // Still try to fetch order details even if user ID loading fails
      _fetchOrderDetails();
    }
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final orderDetails = await _p2pService.getOrderDetails(widget.trackingId);

      // print('Order details received: $orderDetails');

      // Get the payment method ID from the metadata
      final paymentMetadata = orderDetails['paymentMetadata'] ?? {};
      final methodId = paymentMetadata['methodId'];

      // Fetch the complete payment method details if methodId is available
      if (methodId != null) {
        try {
          final paymentMethodDetails =
              await _p2pService.getPaymentMethodDetails(methodId);
          // print('Payment method details: $paymentMethodDetails');

          // Merge the payment method details with the order details
          orderDetails['completePaymentDetails'] = paymentMethodDetails;
        } catch (e) {
          print('Error fetching payment method details');
          // Continue even if payment details fetch fails
        }
      }

      setState(() {
        _orderDetails = orderDetails;
        _remainingMinutes = orderDetails['timeRemaining']['minutes'] ?? 15;
        _remainingSeconds = orderDetails['timeRemaining']['seconds'] ?? 0;
        _isLoading = false;
      });

      // Start timer to update countdown
      _startTimer();
    } catch (e) {
      print('Error in _fetchOrderDetails');
      setState(() {
        _errorMessage = 'Failed to load order details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now();
        final deadline = _orderDetails?['buyerStatus'] == 'paid'
            ? DateTime.parse(_orderDetails!['confirmationDeadline'])
            : DateTime.parse(_orderDetails!['paymentDeadline']);

        final difference = deadline.difference(now);

        if (difference.isNegative) {
          _remainingMinutes = 0;
          _remainingSeconds = 0;
          _timer?.cancel();
        } else {
          _remainingMinutes = difference.inMinutes;
          _remainingSeconds = difference.inSeconds % 60;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Check if order is completed or cancelled
    final String buyerStatus =
        _orderDetails?['buyerStatus']?.toString().toLowerCase() ?? '';
    final String sellerStatus =
        _orderDetails?['sellerStatus']?.toString().toLowerCase() ?? '';
    final bool isOrderCompletedOrCancelled = buyerStatus == 'completed' ||
        sellerStatus == 'completed' ||
        buyerStatus == 'cancelled' ||
        sellerStatus == 'cancelled';

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Order Confirmation',
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
        trailing: !isOrderCompletedOrCancelled
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CustomPageRoute(
                          child: P2PChatScreen(
                            orderId: _orderDetails?['id'] ?? '',
                            trackingId: _orderDetails?['trackingId'] ?? '',
                            isBuyer: _isCurrentUserBuyer(),
                            userName: _isCurrentUserBuyer()
                                ? _orderDetails?['seller']?['fullName'] ??
                                    'Seller'
                                : _orderDetails?['buyer']?['fullName'] ??
                                    'Buyer',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined),
                  ),
                ],
              )
            : null, // Hide chat button in completed/cancelled state
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: SafeJetColors.error),
                  ),
                )
              : isOrderCompletedOrCancelled
                  ? _buildCompletedOrCancelledScreen(isDark)
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Order Timer
                                FadeInDown(
                                  duration: const Duration(milliseconds: 400),
                                  child: _buildTimerSection(isDark),
                                ),
                                const SizedBox(height: 24),

                                // Order Details
                                FadeInDown(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 200),
                                  child: _buildOrderDetails(isDark),
                                ),
                                const SizedBox(height: 24),

                                // Buyer Information (new section)
                                if (_isCurrentUserSeller() &&
                                    _orderDetails?['buyer'] != null)
                                  FadeInDown(
                                    duration: const Duration(milliseconds: 400),
                                    delay: const Duration(milliseconds: 300),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: SafeJetColors.success
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                color: SafeJetColors.success,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Buyer Information',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: SafeJetColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildPaymentDetailRow(
                                            'Buyer Name',
                                            _orderDetails?['buyer']
                                                    ?['fullName'] ??
                                                'Unknown',
                                            isDark,
                                          ),
                                          if (_orderDetails?['buyer']
                                                  ?['email'] !=
                                              null)
                                            _buildPaymentDetailRow(
                                              'Email',
                                              _orderDetails!['buyer']['email'],
                                              isDark,
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'The buyer will send payment using the details you provided.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),

                                // Payment Instructions
                                FadeInDown(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 400),
                                  child: _buildPaymentInstructions(isDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom Actions
                        _buildBottomActions(isDark),
                      ],
                    ),
    );
  }

  Widget _buildCompletedOrCancelledScreen(bool isDark) {
    // Extract order information
    final tokenSymbol = _orderDetails?['offer']?['token']?['symbol'] ?? 'USDT';
    final assetAmount = _orderDetails?['assetAmount'];
    final formattedAssetAmount = _formatCryptoAmount(
      double.tryParse(assetAmount.toString()) ?? 0,
    );
    final String currency = _orderDetails?['offer']?['currency'] ?? '₦';
    final currencyAmount = _orderDetails?['currencyAmount'];
    final formattedCurrencyAmount = _formatFiatAmount(
      double.tryParse(currencyAmount.toString()) ?? 0,
    );
    final String buyerStatus =
        _orderDetails?['buyerStatus']?.toString().toLowerCase() ?? '';
    final bool isCompleted = buyerStatus == 'completed';
    final String trackingId = _orderDetails?['trackingId'] ?? '';

    // Format dates in a more readable way
    final String createdAt = _orderDetails?['createdAt'] != null
        ? _formatDateReadable(DateTime.parse(_orderDetails!['createdAt']))
        : 'Unknown';

    final String completedOrCancelledAt =
        _orderDetails?[isCompleted ? 'completedAt' : 'cancelledAt'] != null
            ? _formatDateReadable(
                DateTime.parse(
                  _orderDetails![isCompleted ? 'completedAt' : 'cancelledAt'],
                ),
              )
            : _formatDateReadable(DateTime.now());

    final String counterpartyName = _isCurrentUserBuyer()
        ? _orderDetails?['seller']?['fullName'] ?? 'Seller'
        : _orderDetails?['buyer']?['fullName'] ?? 'Buyer';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status illustration and heading
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? SafeJetColors.success.withOpacity(0.1)
                          : SafeJetColors.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 70,
                        color: isCompleted
                            ? SafeJetColors.success
                            : SafeJetColors.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    isCompleted ? 'Order Completed' : 'Order Cancelled',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    isCompleted
                        ? 'Transaction completed successfully!'
                        : 'This transaction has been cancelled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Transaction summary card
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.1)
                          : SafeJetColors.lightCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? SafeJetColors.primaryAccent.withOpacity(0.2)
                            : SafeJetColors.lightCardBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Summary',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Amount row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.currency_bitcoin,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$formattedAssetAmount $tokenSymbol',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Value row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.attach_money,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Value',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '$currency $formattedCurrencyAmount',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Order ID row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ID',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '#$trackingId',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: trackingId),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Order ID copied to clipboard',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dates row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Created',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    createdAt,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCompleted ? 'Completed' : 'Cancelled',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    completedOrCancelledAt,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Counter party
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: isDark ? Colors.white : Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isCurrentUserBuyer() ? 'Seller' : 'Buyer',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    counterpartyName,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status message
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? SafeJetColors.success.withOpacity(0.1)
                          : SafeJetColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? SafeJetColors.success.withOpacity(0.3)
                            : SafeJetColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.info_outline
                              : Icons.warning_amber_rounded,
                          color: isCompleted
                              ? SafeJetColors.success
                              : SafeJetColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isCompleted
                                ? _isCurrentUserBuyer()
                                    ? 'The coins have been released by the seller and added to your wallet.'
                                    : 'You have released the coins to the buyer. The transaction is now complete.'
                                : _getStatusMessage(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
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
        ),

        // Action buttons
        FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? SafeJetColors.primaryBackground
                  : SafeJetColors.lightBackground,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? SafeJetColors.primaryAccent.withOpacity(0.2)
                      : SafeJetColors.lightCardBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to wallet/assets screen (index 3 is Wallets tab)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomeScreen(initialIndex: 3),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.1)
                          : Colors.grey[200],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Assets',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to new trade screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const P2PScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? SafeJetColors.success
                          : SafeJetColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'New Trade',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusMessage() {
    final String buyerStatus =
        _orderDetails?['buyerStatus']?.toString().toLowerCase() ?? '';
    final bool isCurrentUserCanceller = _orderDetails?['cancellationMetadata']
            ?['cancelledBy'] ==
        (_isCurrentUserBuyer() ? 'buyer' : 'seller');
    final String reason = _orderDetails?['cancellationMetadata']?['reason'] ??
        'No reason provided';

    if (buyerStatus == 'cancelled') {
      if (isCurrentUserCanceller) {
        return 'You cancelled this order. Reason: $reason';
      } else {
        return _isCurrentUserBuyer()
            ? 'The seller cancelled this order. Reason: $reason'
            : 'The buyer cancelled this order. Reason: $reason';
      }
    }

    return 'This order has been cancelled.';
  }

  Widget _buildTimerSection(bool isDark) {
    final isPending = _orderDetails?['buyerStatus'] == 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SafeJetColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeJetColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: SafeJetColors.warning, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPending
                    ? 'Time remaining to pay'
                    : 'Time remaining for seller to release',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_remainingMinutes.toString().padLeft(2, '0')}:${_remainingSeconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: SafeJetColors.warning,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: TextStyle(color: SafeJetColors.error),
        ),
      );
    }

    final tokenSymbol = _orderDetails?['offer']?['token']?['symbol'] ?? 'USDT';
    final currency = _orderDetails?['offer']?['currency'] ?? '₦';

    // Format the numbers properly
    final assetAmount = _orderDetails?['assetAmount'];
    final price = _orderDetails?[
        'price']; // Use stored order price instead of offer price
    final currencyAmount = _orderDetails?['currencyAmount'];

    // Format asset amount (crypto) - up to 8 decimal places, no trailing zeros
    final formattedAssetAmount = assetAmount != null
        ? _formatCryptoAmount(double.tryParse(assetAmount.toString()) ?? 0)
        : '';

    // Format price - with thousand separators
    final formattedPrice = price != null
        ? _formatFiatAmount(double.tryParse(price.toString()) ?? 0)
        : '';

    // Format total amount - with thousand separators
    final formattedTotal = currencyAmount != null
        ? _formatFiatAmount(double.tryParse(currencyAmount.toString()) ?? 0)
        : '';

    final formattedCreatedAt = _orderDetails?['createdAt'] != null
        ? DateTime.parse(
            _orderDetails!['createdAt'],
          ).toLocal().toString().substring(0, 16)
        : 'Today, 12:30 PM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Amount:',
            '$formattedAssetAmount $tokenSymbol',
            isDark,
          ),
          _buildDetailRow(
            'Price:',
            '$currency$formattedPrice/$tokenSymbol',
            isDark,
          ),
          _buildDetailRow('Total:', '$currency$formattedTotal', isDark),
          _buildDetailRow(
            'Order Number:',
            '#${_orderDetails?['trackingId'] ?? ''}',
            isDark,
          ),
          _buildDetailRow('Created:', formattedCreatedAt, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  backgroundColor: SafeJetColors.success,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.grey[400]
                      : SafeJetColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(bool isDark) {
    if (_isLoading || _orderDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get the payment data from the order details
    final paymentMetadata = _orderDetails?['paymentMetadata'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Instructions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Use the payment metadata we have
          _buildPaymentDetails(paymentMetadata, isDark),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeJetColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: SafeJetColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isCurrentUserSeller()
                        ? 'The buyer must complete the payment within the time limit'
                        : 'Please make sure to complete the payment within the time limit',
                    style: TextStyle(
                      color: SafeJetColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(dynamic paymentData, bool isDark) {
    if (paymentData == null || (paymentData is Map && paymentData.isEmpty)) {
      return const Text('No payment details available');
    }

    // If paymentData is a string, try to parse it as JSON
    Map<String, dynamic> paymentMap;
    if (paymentData is String) {
      try {
        paymentMap = json.decode(paymentData);
      } catch (e) {
        print('Error parsing payment data');
        return Text('Invalid payment data: $paymentData');
      }
    } else if (paymentData is Map) {
      paymentMap = Map<String, dynamic>.from(paymentData);
    } else {
      return Text('Unsupported payment data type: ${paymentData.runtimeType}');
    }

    // Check if we have completePaymentDetails from the API
    final completeDetails = _orderDetails?['completePaymentDetails'];

    // Check if this is a sell order (we are the seller)
    final isSeller = _userId == _orderDetails?['sellerId'];

    // For sell orders, the payment metadata might contain the complete payment details
    if (paymentMap.containsKey('details') ||
        paymentMap.containsKey('paymentMethodType')) {
      // This is a complete payment method object (usually for sell orders)
      final paymentMethodType = paymentMap['paymentMethodType'] ?? {};
      final String typeName = paymentMethodType['name'] ?? 'Payment Method';
      final String typeIcon = paymentMethodType['icon'] ?? 'payment';
      final String accountOwner = paymentMap['name'] ?? '';

      // Extract the details field which contains the actual payment information
      final details = paymentMap['details'] ?? {};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method type header
          Row(
            children: [
              Icon(_getIconForPaymentType(typeIcon), size: 20),
              const SizedBox(width: 8),
              Text(
                typeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account owner
          if (accountOwner.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Account Owner: $accountOwner',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Display each payment field based on its type
          if (details is Map && details.isNotEmpty)
            ...details.entries.map<Widget>((entry) {
              final fieldName = entry.key;
              final fieldData = entry.value is Map
                  ? entry.value as Map<String, dynamic>
                  : {'value': entry.value, 'fieldType': 'text'};
              final fieldType = fieldData['fieldType'] as String? ?? 'text';
              final fieldValue = fieldData['value'];

              return _buildPaymentField(
                fieldName: fieldName,
                fieldLabel: _toTitleCase(fieldName),
                fieldType: fieldType,
                fieldValue: fieldValue,
                isDark: isDark,
              );
            }).toList(),

          // Add a message based on whether user is buyer or seller
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeJetColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: SafeJetColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCurrentUserSeller()
                          ? 'Payment Status'
                          : 'Payment Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SafeJetColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isCurrentUserSeller()
                      ? 'The buyer will send payment to your account. You will be notified when payment is made.'
                      : 'Please make the payment using the details above and click "I have paid" when done.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to chat screen with the correct parameters
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => P2PChatScreen(
                          orderId: _orderDetails?['id'] ?? '',
                          trackingId: _orderDetails?['trackingId'] ?? '',
                          isBuyer: _isCurrentUserBuyer(),
                          userName: _isCurrentUserBuyer()
                              ? _orderDetails?['seller']?['fullName'] ??
                                  'Seller'
                              : _orderDetails?['buyer']?['fullName'] ?? 'Buyer',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Open Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(120, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (completeDetails != null) {
      // Use the complete payment details from the API (usually for buy orders)
      final paymentMethodType = completeDetails['paymentMethodType'] ?? {};
      final String typeName = paymentMethodType['name'] ?? 'Payment Method';
      final String typeIcon = paymentMethodType['icon'] ?? 'payment';
      final String accountOwner = completeDetails['name'] ?? '';

      // Extract the details field which contains the actual payment information
      final details = completeDetails['details'] ?? {};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method type header
          Row(
            children: [
              Icon(_getIconForPaymentType(typeIcon), size: 20),
              const SizedBox(width: 8),
              Text(
                typeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account owner
          if (accountOwner.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Account Owner: $accountOwner',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // Display each payment field based on its type
          if (details is Map && details.isNotEmpty)
            ...details.entries.map<Widget>((entry) {
              final fieldName = entry.key;
              final fieldData = entry.value is Map
                  ? entry.value as Map<String, dynamic>
                  : {'value': entry.value, 'fieldType': 'text'};
              final fieldType = fieldData['fieldType'] as String? ?? 'text';
              final fieldValue = fieldData['value'];

              return _buildPaymentField(
                fieldName: fieldName,
                fieldLabel: _toTitleCase(fieldName),
                fieldType: fieldType,
                fieldValue: fieldValue,
                isDark: isDark,
              );
            }).toList(),

          // Add a message for the buyer
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeJetColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: SafeJetColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SafeJetColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isCurrentUserSeller()
                      ? 'The buyer will send payment to your account. You will be notified when payment is made.'
                      : 'Please make the payment using the details above and click "I have paid" when done.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to chat screen with the correct parameters
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => P2PChatScreen(
                          orderId: _orderDetails?['id'] ?? '',
                          trackingId: _orderDetails?['trackingId'] ?? '',
                          isBuyer: _isCurrentUserBuyer(),
                          userName: _isCurrentUserBuyer()
                              ? _orderDetails?['seller']?['fullName'] ??
                                  'Seller'
                              : _orderDetails?['buyer']?['fullName'] ?? 'Buyer',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Open Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(120, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Use the basic payment metadata (fallback)
      final String typeName = paymentMap['typeName'] ?? 'Payment Method';
      final String typeIcon = paymentMap['icon'] ?? 'payment';
      final String methodName = paymentMap['methodName'] ?? '';

      // For bank transfers, we need to display bank details
      final bool isBankTransfer = typeName.toLowerCase().contains('bank');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method type header
          Row(
            children: [
              Icon(_getIconForPaymentType(typeIcon), size: 20),
              const SizedBox(width: 8),
              Text(
                typeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account owner
          if (methodName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Account Owner: $methodName',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

          // For bank transfers, show a message to contact the seller
          if (isBankTransfer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SafeJetColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: SafeJetColors.info,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCurrentUserSeller()
                            ? 'Payment Status'
                            : 'Bank Account Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: SafeJetColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCurrentUserSeller()
                        ? 'The buyer will send payment to your account. You will be notified when payment is made.'
                        : 'Please contact the seller through chat to get the bank account details for payment.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to chat screen with the correct parameters
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => P2PChatScreen(
                            orderId: _orderDetails?['id'] ?? '',
                            trackingId: _orderDetails?['trackingId'] ?? '',
                            isBuyer: _isCurrentUserBuyer(),
                            userName: _isCurrentUserBuyer()
                                ? _orderDetails?['seller']?['fullName'] ??
                                    'Seller'
                                : _orderDetails?['buyer']?['fullName'] ??
                                    'Buyer',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Open Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeJetColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(120, 36),
                    ),
                  ),
                ],
              ),
            ),

          // Display other payment method details if available
          ...paymentMap.entries
              .where(
                (e) => ![
                  'paymentMethodType',
                  'name',
                  'methodName',
                  'icon',
                  'typeName',
                  'typeId',
                  'methodId',
                  'description',
                ].contains(e.key),
              )
              .map<Widget>(
                (entry) => _buildDetailRow(
                  _toTitleCase(entry.key),
                  entry.value.toString(),
                  isDark,
                ),
              )
              .toList(),
        ],
      );
    }
  }

  Widget _buildPaymentField({
    required String fieldName,
    required String fieldLabel,
    required String fieldType,
    required dynamic fieldValue,
    required bool isDark,
  }) {
    switch (fieldType) {
      case 'image':
        return _buildImageField(fieldLabel, fieldValue.toString(), isDark);
      case 'date':
        return _buildPaymentDetailRow(
          fieldLabel,
          fieldValue.toString(),
          isDark,
        );
      case 'email':
        return _buildPaymentDetailRow(
          fieldLabel,
          fieldValue.toString(),
          isDark,
        );
      case 'phone':
        return _buildPaymentDetailRow(
          fieldLabel,
          fieldValue.toString(),
          isDark,
        );
      case 'select':
        return _buildPaymentDetailRow(
          fieldLabel,
          fieldValue.toString(),
          isDark,
        );
      case 'text':
      default:
        return _buildPaymentDetailRow(
          fieldLabel,
          fieldValue.toString(),
          isDark,
        );
    }
  }

  Widget _buildImageField(String label, String imageValue, bool isDark) {
    // Get the base URL from environment variables
    final baseUrl = dotenv.get(
      'API_URL',
      fallback: 'https://encrypted.nadiapoint.com',
    );

    // Based on our testing, the working URL format is:
    final String imageUrl = imageValue.startsWith('http')
        ? imageValue
        : '$baseUrl/uploads/payment-methods/$imageValue';

    // Only log once during development
    // print('Loading image from: $imageUrl');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageValue.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // Use a cached network image or add a key to prevent rebuilding
                    child: RepaintBoundary(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        // Add a key based on the URL to prevent unnecessary reloading
                        key: ValueKey(imageUrl),
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
                          // Only log errors once
                          // print('Error loading image: $error');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: SafeJetColors.error,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: SafeJetColors.error),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  imageValue,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : const Center(child: Text('No image available')),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // New method specifically for payment details that handles long text
  Widget _buildPaymentDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  backgroundColor: SafeJetColors.success,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.grey[400]
                        : SafeJetColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to convert snake_case or camelCase to Title Case
  String _toTitleCase(String text) {
    if (text.isEmpty) return '';

    // Replace underscores and camelCase with spaces
    final spacedText = text
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll('_', ' ');

    // Capitalize first letter of each word
    return spacedText.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Helper method to get icon for payment type
  IconData _getIconForPaymentType(String iconName) {
    switch (iconName) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'qr_code':
        return Icons.qr_code;
      case 'mobile':
        return Icons.phone_android_outlined;
      case 'payment':
        return Icons.payment_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  Widget _buildBottomActions(bool isDark) {
    if (_orderDetails == null) return const SizedBox.shrink();

    // Check if current user is the buyer
    final currentUserId = _userId;
    final isBuyer = _orderDetails!['buyerId'] == currentUserId;
    final buyerStatus = _orderDetails!['buyerStatus']?.toLowerCase() ?? '';

    // print('Current user ID: $currentUserId');
    // print('Buyer ID: ${_orderDetails!['buyerId']}');
    // print('Is Buyer: $isBuyer');
    // print('Buyer Status: $buyerStatus');

    // For completed orders
    if (buyerStatus == 'completed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // View Transaction Logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Transaction'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const P2PScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('New Trade'),
              ),
            ),
          ],
        ),
      );
    }

    // For disputed orders
    if (buyerStatus == 'disputed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // For buyer: Cancel order
                  // For seller: Release coins
                  try {
                    if (isBuyer) {
                      _showCancelOrderDialog();
                    } else {
                      _showReleaseCoinDialog();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isBuyer ? SafeJetColors.warning : SafeJetColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isBuyer ? 'Cancel Order' : 'Release Coin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to dispute details screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          P2PDisputeDetailsScreen(orderId: widget.trackingId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Dispute'),
              ),
            ),
          ],
        ),
      );
    }

    // For buyer with pending status
    if (isBuyer && buyerStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  _showCancelOrderDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => PaymentConfirmationDialog(
                      trackingId: widget.trackingId,
                      orderDetails: _orderDetails!,
                      p2pService: _p2pService,
                      isDark: isDark,
                      formatAmount: _formatAmount,
                      hasAgreed: hasAgreed,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('I Have Paid'),
              ),
            ),
          ],
        ),
      );
    }

    // For buyer with paid status
    if (isBuyer && buyerStatus == 'paid') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  _showCancelOrderDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showDisputeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Raise Dispute'),
              ),
            ),
          ],
        ),
      );
    }

    // For seller with paid status
    if (!isBuyer && buyerStatus == 'paid') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    _showReleaseCoinDialog();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Release Coin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                // Enable only if payment time has expired
                onPressed: _isPaymentTimeExpired
                    ? () {
                        _showDisputeDialog();
                      }
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: SafeJetColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Raise Dispute'),
              ),
            ),
          ],
        ),
      );
    }

    // For seller with pending status
    if (!isBuyer && buyerStatus == 'pending') {
      final isPaymentDeadlinePassed = _orderDetails != null &&
          DateTime.now().isAfter(
            DateTime.parse(_orderDetails!['paymentDeadline']),
          );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: null, // Always disabled when pending
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Release Coins'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    isPaymentDeadlinePassed ? () => _showDisputeDialog() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Raise Dispute'),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink(); // Default case, no buttons
  }

  void _showDisputeDialog() {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;
    bool hasConfirmedDispute = false;
    DisputeReasonType selectedReasonType = DisputeReasonType.OTHER;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    // Determine available reasons based on user role
    List<DisputeReasonType> availableReasons = DisputeReasonType.values.where((
      reason,
    ) {
      if (_isCurrentUserBuyer() && reason == DisputeReasonType.BUYER_NOT_PAID) {
        return false;
      }
      if (!_isCurrentUserBuyer() &&
          reason == DisputeReasonType.SELLER_NOT_RELEASED) {
        return false;
      }
      return true;
    }).toList();

    showDialog<bool>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor:
              isDark ? SafeJetColors.primaryBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Raise Dispute',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please provide details about your dispute:',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SafeJetColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: SafeJetColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: SafeJetColors.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Please provide clear and accurate information about your dispute. False claims may result in account restrictions.',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Add dropdown for selecting dispute reason type
                          Text(
                            'Dispute Reason Type',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonFormField<DisputeReasonType>(
                              value: selectedReasonType,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              dropdownColor:
                                  isDark ? Colors.grey[800] : Colors.white,
                              items: availableReasons.map((reason) {
                                String displayText = '';
                                switch (reason) {
                                  case DisputeReasonType.PAYMENT_ISSUE:
                                    displayText = 'Payment Issue';
                                    break;
                                  case DisputeReasonType.FRAUD:
                                    displayText = 'Fraud';
                                    break;
                                  case DisputeReasonType.TECHNICAL_ISSUE:
                                    displayText = 'Technical Issue';
                                    break;
                                  case DisputeReasonType.BUYER_NOT_PAID:
                                    displayText = 'Buyer Has Not Paid';
                                    break;
                                  case DisputeReasonType.SELLER_NOT_RELEASED:
                                    displayText =
                                        'Seller Has Not Released Coin';
                                    break;
                                  case DisputeReasonType.WRONG_AMOUNT:
                                    displayText = 'Wrong Amount';
                                    break;
                                  case DisputeReasonType.OTHER:
                                    displayText = 'Other';
                                    break;
                                }

                                return DropdownMenuItem<DisputeReasonType>(
                                  value: reason,
                                  child: Text(
                                    displayText,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedReasonType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Keep existing text field for detailed reason
                          Text(
                            'Dispute Reason',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reasonController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Explain your issue in detail...',
                              filled: true,
                              fillColor: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: SafeJetColors.error,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: hasConfirmedDispute,
                                    onChanged: (newValue) {
                                      setState(() {
                                        hasConfirmedDispute = newValue ?? false;
                                      });
                                    },
                                    activeColor: SafeJetColors.error,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isCurrentUserBuyer()
                                        ? 'I confirm that the seller has breached the terms of this P2P trade and this order needs to be disputed'
                                        : 'I confirm that the buyer has breached the terms of this P2P trade and this order needs to be disputed',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ||
                                    reasonController.text.trim().isEmpty ||
                                    !hasConfirmedDispute
                                ? null
                                : () async {
                                    setState(() {
                                      isSubmitting = true;
                                    });
                                    try {
                                      await _p2pService.disputeOrder(
                                        widget.trackingId,
                                        selectedReasonType.value,
                                        reasonController.text.trim(),
                                      );
                                      if (mounted) {
                                        Navigator.of(context).pop(true);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Dispute raised successfully',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Submit Dispute',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCancelOrderDialog() {
    print('DEBUG: _showCancelOrderDialog method called');
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;
    bool hasConfirmedCancel = false;
    String selectedReason = 'Other';

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    // List of cancellation reasons
    final List<String> cancellationReasons = [
      'Changed my mind',
      'Found a better offer',
      'Payment issues',
      'Seller is unresponsive',
      'Need funds for another purpose',
      'Other',
    ];

    showDialog<bool>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor:
              isDark ? SafeJetColors.primaryBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Cancel Order',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please provide a reason for cancellation:',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SafeJetColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: SafeJetColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: SafeJetColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Cancelling an order may affect your completion rate. Are you sure you want to proceed?',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Add dropdown for selecting cancellation reason
                          Text(
                            'Reason for Cancellation',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedReason,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              dropdownColor:
                                  isDark ? Colors.grey[800] : Colors.white,
                              items: cancellationReasons.map((reason) {
                                return DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Text field for additional details
                          Text(
                            'Additional Details',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reasonController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText:
                                  'Please provide more details (optional)...',
                              filled: true,
                              fillColor: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: SafeJetColors.warning,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: hasConfirmedCancel,
                                    onChanged: (newValue) {
                                      setState(() {
                                        hasConfirmedCancel = newValue ?? false;
                                      });
                                    },
                                    activeColor: SafeJetColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'I understand that cancelling this order may affect my completion rate and confirm I want to proceed',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Text(
                              'Go Back',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting || !hasConfirmedCancel
                                ? null
                                : () async {
                                    setState(() {
                                      isSubmitting = true;
                                    });
                                    try {
                                      await _p2pService.cancelOrder(
                                        widget.trackingId,
                                        reason: selectedReason,
                                        additionalDetails:
                                            reasonController.text.trim(),
                                      );
                                      if (mounted) {
                                        Navigator.of(context).pop(true);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Order cancelled successfully',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.warning,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Cancel Order',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showReleaseCoinDialog() {
    print('DEBUG: _showReleaseCoinDialog method called');
    final TextEditingController passwordController = TextEditingController();
    bool isSubmitting = false;
    bool hasConfirmedReceipt = false;
    bool hasConfirmedTerms = false;
    bool isPasswordVisible = false;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    final tokenSymbol = _orderDetails?['offer']?['token']?['symbol'] ?? 'USDT';
    final formattedAssetAmount = _orderDetails?['assetAmount'] != null
        ? _formatCryptoAmount(
            double.tryParse(_orderDetails!['assetAmount'].toString()) ?? 0,
          )
        : '0';
    final formattedCurrencyAmount = _orderDetails?['currencyAmount'] != null
        ? _formatFiatAmount(
            double.tryParse(_orderDetails!['currencyAmount'].toString()) ?? 0,
          )
        : '0';
    final currency = _orderDetails?['offer']?['currency'] ?? '₦';
    final buyerName = _orderDetails?['buyer']?['fullName'] ?? 'the buyer';

    showDialog<bool>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor:
              isDark ? SafeJetColors.primaryBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Release Coins',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please confirm you want to release the coins:',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Order amount details card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Amount:',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '$formattedAssetAmount $tokenSymbol',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '$currency $formattedCurrencyAmount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Buyer:',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      buyerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Warning box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SafeJetColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: SafeJetColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: SafeJetColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Once you release coins, this action cannot be undone. Please ensure you have received the payment before proceeding.',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Confirmation checkboxes
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: hasConfirmedReceipt,
                                        onChanged: isSubmitting
                                            ? null
                                            : (newValue) {
                                                setState(() {
                                                  hasConfirmedReceipt =
                                                      newValue ?? false;
                                                });
                                              },
                                        activeColor: SafeJetColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'I confirm that I have received the full payment of $currency $formattedCurrencyAmount for this order',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: hasConfirmedTerms,
                                        onChanged: isSubmitting
                                            ? null
                                            : (newValue) {
                                                setState(() {
                                                  hasConfirmedTerms =
                                                      newValue ?? false;
                                                });
                                              },
                                        activeColor: SafeJetColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'I understand that releasing coins will complete this transaction and the crypto will be transferred to the buyer',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Password field
                          Text(
                            'Confirm Your Password',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              filled: true,
                              fillColor: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: SafeJetColors.success,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Text(
                              'Go Back',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting ||
                                    !hasConfirmedReceipt ||
                                    !hasConfirmedTerms ||
                                    passwordController.text.isEmpty
                                ? null
                                : () async {
                                    setState(() {
                                      isSubmitting = true;
                                    });
                                    try {
                                      if (passwordController.text.isEmpty) {
                                        throw Exception(
                                          'Password is required to release coins',
                                        );
                                      }

                                      // Debug output to see what ID we're sending
                                      print(
                                        'Releasing order with ID: ${_orderDetails!['id']}',
                                      );
                                      print(
                                        'Order tracking ID: ${_orderDetails!['trackingId']}',
                                      );

                                      // Use the trackingId instead of id
                                      await _p2pService.releaseOrder(
                                        _orderDetails!['trackingId'],
                                        passwordController.text.trim(),
                                      );
                                      if (mounted) {
                                        Navigator.of(context).pop(true);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Coins released successfully',
                                            ),
                                          ),
                                        );
                                        // Refresh order details
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        _fetchOrderDetails();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        String errorMessage =
                                            'Failed to release coins';
                                        if (e.toString().contains('password')) {
                                          errorMessage =
                                              'Invalid password. Please try again.';
                                        } else if (e.toString().contains(
                                              'network',
                                            )) {
                                          errorMessage =
                                              'Network error. Please check your connection.';
                                        } else if (e.toString().contains(
                                              'not found',
                                            )) {
                                          errorMessage =
                                              'Order not found or has been modified.';
                                        } else {
                                          // Extract the error message from the exception
                                          final errorString = e.toString();
                                          if (errorString.contains(
                                            'Exception: ',
                                          )) {
                                            final startIndex =
                                                errorString.indexOf(
                                                      'Exception: ',
                                                    ) +
                                                    'Exception: '.length;
                                            errorMessage = errorString
                                                .substring(startIndex);
                                          } else {
                                            errorMessage = errorString;
                                          }
                                        }

                                        // Stay on the dialog and show error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SafeJetColors.success,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Release Coins',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to determine if current user is the seller
  bool _isCurrentUserSeller() {
    // First check if we have the user ID
    if (_userId != null && _orderDetails != null) {
      return _userId == _orderDetails!['sellerId'];
    }

    // Fallback: Check if the payment metadata's userId matches the seller ID
    final paymentMetadata = _orderDetails?['paymentMetadata'];
    if (paymentMetadata != null && _orderDetails != null) {
      final metadataUserId = paymentMetadata['userId'];
      return metadataUserId == _orderDetails!['sellerId'];
    }

    // Default to false if we can't determine
    return false;
  }

  // Helper method to format crypto amounts (up to 8 decimal places, no trailing zeros)
  String _formatCryptoAmount(double amount) {
    if (amount == 0) return '0';

    // Format with up to 8 decimal places
    String formatted = amount.toStringAsFixed(8);

    // Remove trailing zeros
    while (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    // Remove decimal point if it's the last character
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted;
  }

  // Helper method to format fiat amounts (with thousand separators, 2 decimal places)
  String _formatFiatAmount(double amount) {
    // Use NumberFormat for proper thousand separators
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  bool get _isPaymentTimeExpired {
    if (_orderDetails == null) return false;

    final createdAt = DateTime.parse(_orderDetails!['createdAt']);
    final paymentTimeLimit = Duration(
      minutes: 30,
    ); // Or whatever your time limit is

    return DateTime.now().difference(createdAt) > paymentTimeLimit;
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';

    // Convert to double
    double value = amount is String ? double.parse(amount) : amount.toDouble();

    // Split into whole and decimal parts
    String valueStr = value.toString();
    List<String> parts = valueStr.split('.');

    // Format whole number part with commas
    String wholeNumber = NumberFormat('#,###').format(int.parse(parts[0]));

    // Handle decimal part if it exists
    if (parts.length > 1) {
      // Remove trailing zeros
      String decimal = parts[1].replaceAll(RegExp(r'0+$'), '');
      // Add decimal part only if it's not empty
      if (decimal.isNotEmpty) {
        return '$wholeNumber.$decimal';
      }
    }

    return wholeNumber;
  }

  bool _isCurrentUserBuyer() {
    return _orderDetails?['buyerId'] == _userId;
  }

  // Helper method to format dates in a more readable way
  String _formatDateReadable(DateTime date) {
    // Get today and yesterday dates for comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    // Format time with proper AM/PM
    final timeFormat = DateFormat('h:mm a'); // e.g., "2:30 PM"
    final timeStr = timeFormat.format(date);

    // Format full date with month name
    final dateFormat = DateFormat('MMM d, yyyy'); // e.g., "Jan 15, 2023"
    final dateStr = dateFormat.format(date);

    // Check if date is today, yesterday, or earlier
    if (dateToCheck == today) {
      return 'Today, $timeStr';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return '$dateStr, $timeStr';
    }
  }
}
