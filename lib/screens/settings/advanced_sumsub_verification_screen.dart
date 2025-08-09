import 'package:flutter/material.dart';
import 'package:flutter_idensic_mobile_sdk_plugin/flutter_idensic_mobile_sdk_plugin.dart';
import '../../config/theme/colors.dart';
import '../../widgets/p2p_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/kyc_provider.dart';

class AdvancedSumsubVerificationScreen extends StatefulWidget {
  final String accessToken;

  const AdvancedSumsubVerificationScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<AdvancedSumsubVerificationScreen> createState() => _AdvancedSumsubVerificationScreenState();
}

class _AdvancedSumsubVerificationScreenState extends State<AdvancedSumsubVerificationScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSumsubSDK();
  }

  Future<void> _initSumsubSDK() async {
    try {
      final onTokenExpiration = () async {
        // Get new token using existing KYC service
        final token = await context.read<KYCProvider>().startAdvancedVerification();
        return token;
      };

      final snsMobileSDK = SNSMobileSDK.init(widget.accessToken, onTokenExpiration)
        .withHandlers(
          onStatusChanged: _handleStatusChange,
          onEvent: _handleEvent,
        )
        .withDebug(true) // Remove in production
        .withLocale(const Locale("en"))
        .withAutoCloseOnApprove(3) // Auto close after 3 seconds on approval
        .build();

      setState(() => _isLoading = false);
      
      final result = await snsMobileSDK.launch();
      _handleSDKResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing verification'),
            backgroundColor: SafeJetColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _handleStatusChange(SNSMobileSDKStatus newStatus, SNSMobileSDKStatus prevStatus) {
    print("SDK Status changed: $prevStatus -> $newStatus");
    
    if (newStatus == SNSMobileSDKStatus.Approved ||
        newStatus == SNSMobileSDKStatus.FinallyRejected) {
      // Refresh KYC details to update UI
      if (mounted) {
        context.read<KYCProvider>().loadKYCDetails();
      }
    }
  }

  void _handleEvent(SNSMobileSDKEvent event) {
    print("SDK Event: ${event.eventType} - ${event.payload}");
  }

  void _handleSDKResult(SNSMobileSDKResult result) {
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMsg ?? 'Verification error'),
          backgroundColor: SafeJetColors.error,
        ),
      );
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const P2PAppBar(
        title: 'Advanced Verification',
        hasNotification: false,
      ),
      body: Center(
        child: _isLoading
          ? const CircularProgressIndicator()
          : const SizedBox(), // SDK will overlay its UI
      ),
    );
  }
} 