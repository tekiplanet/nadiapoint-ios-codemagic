import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';

class P2PDisputeScreen extends StatefulWidget {
  final String orderId;
  final bool isBuyer;

  const P2PDisputeScreen({
    super.key,
    required this.orderId,
    required this.isBuyer,
  });

  @override
  State<P2PDisputeScreen> createState() => _P2PDisputeScreenState();
}

class _P2PDisputeScreenState extends State<P2PDisputeScreen> {
  final _reasonController = TextEditingController();
  String? _selectedReason;
  List<String> _attachments = [];

  final List<String> _disputeReasons = [
    'I have paid but seller hasn\'t released crypto',
    'Seller is unresponsive',
    'Wrong payment amount',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Raise Dispute',
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info Section
                  _buildOrderInfo(isDark),
                  const SizedBox(height: 24),

                  // Dispute Reason Section
                  _buildDisputeReason(isDark),
                  const SizedBox(height: 24),

                  // Evidence Section
                  _buildEvidenceSection(isDark),
                  const SizedBox(height: 24),

                  // Warning Section
                  _buildWarningSection(isDark),
                ],
              ),
            ),
          ),
          // Bottom Action
          _buildBottomAction(isDark),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(bool isDark) {
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
          Text(
            'Order #${widget.orderId}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Amount:', '1,234.56 USDT', isDark),
          _buildDetailRow('Price:', '750.00 NGN', isDark),
          _buildDetailRow('Total:', '925,920.00 NGN', isDark),
          _buildDetailRow(
            'Status:',
            widget.isBuyer ? 'Paid' : 'Payment Pending',
            isDark,
            statusColor:
                widget.isBuyer ? SafeJetColors.success : SafeJetColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeReason(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for Dispute',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: _disputeReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: SafeJetColors.secondaryHighlight,
              );
            }).toList(),
          ),
        ),
        if (_selectedReason == 'Other') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Please describe your issue...',
              filled: true,
              fillColor: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? SafeJetColors.primaryAccent.withOpacity(0.2)
                      : SafeJetColors.lightCardBorder,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenceSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement file picker
                },
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Add Evidence'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Supported: JPG, PNG, PDF (Max 5MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection(bool isDark) {
    return Container(
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
              'False disputes may result in account restrictions. Make sure you have valid evidence before proceeding.',
              style: TextStyle(
                color: SafeJetColors.warning,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  // TODO: Handle dispute submission
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Submit Dispute'),
                      content: const Text(
                        'Are you sure you want to submit this dispute? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            // TODO: Submit dispute
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dispute submitted successfully'),
                                backgroundColor: SafeJetColors.success,
                              ),
                            );
                            Navigator.pop(
                                context); // Go back to previous screen
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: SafeJetColors.warning,
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: SafeJetColors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text('Submit Dispute'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
