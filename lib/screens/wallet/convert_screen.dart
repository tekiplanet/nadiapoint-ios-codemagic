import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/colors.dart';
import '../../services/wallet_service.dart';
import 'package:intl/intl.dart';
import 'widgets/token_selector.dart';

class ConvertScreen extends StatefulWidget {
  final Map<String, dynamic> fromAsset; // Initial asset to convert from
  final bool showInUSD;
  final double userCurrencyRate;
  final String userCurrency;

  const ConvertScreen({
    super.key,
    required this.fromAsset,
    required this.showInUSD,
    required this.userCurrencyRate,
    required this.userCurrency,
  });

  @override
  _ConvertScreenState createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final _walletService = GetIt.I<WalletService>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Available balances
  Map<String, double> _fundingBalances = {};
  List<Map<String, dynamic>> _availableTokens = [];
  Map<String, dynamic>? _selectedToToken;

  // Exchange rate and fee info
  double _exchangeRate = 0.0;
  double _conversionFee = 0.0;
  String _feeType = '';

  // Add loading state
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    print('Received fromAsset data: ${widget.fromAsset}');
    _loadFundingBalance();
    _loadAvailableTokens();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFundingBalance() async {
    setState(() => _isLoading = true);
    try {
      final data = await _walletService.getBalances(
        type: 'funding',
        currency: widget.showInUSD ? 'USD' : widget.userCurrency,
      );

      if (!mounted) return;

      // Update funding balances map
      _fundingBalances = {};
      for (var token in data['balances']) {
        final fundingBalance =
            double.tryParse(token['balance']?.toString() ?? '0') ?? 0.0;
        if (fundingBalance > 0) {
          _fundingBalances[token['token']['id']] = fundingBalance;
        }
      }

      // Find and update the current token's balance
      final fundingAsset = data['balances'].firstWhere(
        (b) => b['token']['id'] == widget.fromAsset['token']['id'],
        orElse: () => widget.fromAsset,
      );

      setState(() {
        widget.fromAsset['balance'] = fundingAsset['balance'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading funding balance');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateExchangeRate() async {
    if (_selectedToToken == null) return;

    setState(() => _isLoading = true);
    try {
      // Get exchange rate
      final rate = await _walletService.getExchangeRate(
        fromTokenId: widget.fromAsset['token']['id'],
        toTokenId: _selectedToToken!['token']['id'],
      );

      if (rate <= 0) {
        throw Exception('Invalid exchange rate');
      }

      // Get conversion fee
      final feeResponse = await _walletService.getConversionFee(
        tokenId: widget.fromAsset['token']['id'],
        amount: double.tryParse(_amountController.text) ?? 0,
      );

      setState(() {
        _exchangeRate = rate;
        _conversionFee = double.tryParse(feeResponse['value'] ?? '0') ?? 0;
        _feeType = feeResponse['type'] ?? 'percentage';
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update exchange rate';
        _isLoading = false;
        _exchangeRate = 0;
      });
      print('Error updating exchange rate');
    }
  }

  void _setMaxAmount() {
    final fundingBalance =
        _fundingBalances[widget.fromAsset['token']['id']] ?? 0.0;
    _amountController.text = fundingBalance.toString();
  }

  String _formatBalance(double balance) {
    return NumberFormat.decimalPattern().format(balance);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final token = widget.fromAsset['token'];

    return Scaffold(
      backgroundColor: isDark
          ? SafeJetColors.primaryBackground
          : SafeJetColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Convert ${token['symbol']}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    SafeJetColors.darkGradientStart,
                    SafeJetColors.darkGradientEnd,
                  ]
                : [
                    SafeJetColors.lightGradientStart,
                    SafeJetColors.lightGradientEnd,
                  ],
          ),
        ),
        child: _isLoading
            ? _buildShimmerLoading()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SafeJetColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: SafeJetColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: SafeJetColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // From Asset Section
                    Text(
                      'From',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  SafeJetColors.darkGradientStart,
                                  SafeJetColors.darkGradientEnd,
                                ]
                              : [
                                  SafeJetColors.lightGradientStart,
                                  SafeJetColors.lightGradientEnd,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            token['metadata']['icon'],
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                token['symbol'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                'Available: ${_formatBalance(_getFundingBalance())} ${widget.fromAsset['token']['symbol']}',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount Input Section
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    SafeJetColors.darkGradientStart,
                                    SafeJetColors.darkGradientEnd,
                                  ]
                                : [
                                    SafeJetColors.lightGradientStart,
                                    SafeJetColors.lightGradientEnd,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _setMaxAmount,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    backgroundColor: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'MAX',
                                    style: TextStyle(
                                      color: SafeJetColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                              decimal: true),
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      token['symbol'],
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
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

                    // To Token Selection
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    SafeJetColors.darkGradientStart,
                                    SafeJetColors.darkGradientEnd,
                                  ]
                                : [
                                    SafeJetColors.lightGradientStart,
                                    SafeJetColors.lightGradientEnd,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (context) => SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.75,
                                        child: TokenSelector(
                                          tokens: _availableTokens,
                                          selectedToken: _selectedToToken,
                                          onSelect: (token) {
                                            setState(() {
                                              _selectedToToken = token;
                                            });
                                            _updateExchangeRate();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        if (_selectedToToken != null) ...[
                                          Image.network(
                                            _selectedToToken!['token']
                                                    ['icon'] ??
                                                '',
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.currency_bitcoin,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedToToken!['token']
                                                ['symbol'],
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ] else
                                          Text(
                                            'Select Token',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Conversion Details
                    if (_selectedToToken != null &&
                        _amountController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
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
                              'Conversion Details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              'Exchange Rate',
                              '1 ${token['symbol']} = ${_formatBalance(_exchangeRate)} ${_selectedToToken!['token']['symbol']}',
                              theme,
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Conversion Fee',
                              '${_conversionFee} ${_feeType == 'percentage' ? '%' : (_feeType == 'usd' ? 'USD' : token['symbol'])}',
                              theme,
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'You Will Receive',
                              '${_formatBalance(_calculateAmountToReceive())} ${_selectedToToken!['token']['symbol']}',
                              theme,
                              isDark,
                              isHighlighted: true,
                            ),
                          ],
                        ),
                      ),

                    // Convert Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SafeJetColors.warning,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLoading ? 'Processing...' : 'Convert',
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
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Add more shimmer placeholders as needed
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeData theme, bool isDark,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isHighlighted ? FontWeight.bold : null,
            color: isHighlighted
                ? SafeJetColors.warning
                : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  double _calculateAmountToReceive() {
    if (_amountController.text.isEmpty) return 0;
    final amount = double.tryParse(_amountController.text) ?? 0;

    // First calculate fee in source token amount
    double feeInSourceToken = 0;
    if (_feeType == 'percentage') {
      feeInSourceToken = amount * (_conversionFee / 100);
    } else if (_feeType == 'usd') {
      // Convert USD fee to source token amount
      final tokenPrice = double.tryParse(
              widget.fromAsset['token']['currentPrice']?.toString() ?? '0') ??
          0.0;

      if (tokenPrice > 0) {
        feeInSourceToken = _conversionFee / tokenPrice;
      }
    } else {
      // Fee is already in token amount
      feeInSourceToken = _conversionFee;
    }

    // Calculate amount after fee
    final amountAfterFee = amount - feeInSourceToken;
    if (amountAfterFee <= 0) return 0;

    // Apply exchange rate to get final amount
    return amountAfterFee * _exchangeRate;
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark
              ? SafeJetColors
                  .darkGradientStart // Use the same gradient start color
              : SafeJetColors.lightGradientStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Conversion',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            // Added to handle overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'From',
                  '${_formatAmount(_amountController.text)} ${widget.fromAsset['token']['symbol']}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'To',
                  '${_formatAmount(_getToAmount().toString())} ${_selectedToToken?['token']['symbol'] ?? ''}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Exchange Rate',
                  '1 ${widget.fromAsset['token']['symbol']} = ${_formatAmount(_exchangeRate.toString())} ${_selectedToToken?['token']['symbol'] ?? ''}',
                  isWrapped: true, // Allow wrapping for long text
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Fee',
                  '${_formatAmount(_conversionFee.toString())} ${widget.fromAsset['token']['symbol']}',
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Please confirm the conversion details above.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            StatefulBuilder(
              builder: (context, setState) {
                return ElevatedButton(
                  onPressed: _isConfirming
                      ? () {}
                      : () async {
                          setState(() => _isConfirming = true);
                          try {
                            await _handleConversion();
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                              Navigator.pop(context);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isConfirming = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafeJetColors
                        .warning, // Changed to warning (yellow) color
                    disabledBackgroundColor:
                        SafeJetColors.warning.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isConfirming
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors
                                .black), // Changed to black for yellow button
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors
                                .black, // Changed to black for yellow button
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWrapped = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          isWrapped ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        if (isWrapped)
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  String _formatAmount(String amount) {
    try {
      final value = double.parse(amount);
      if (value == value.roundToDouble()) {
        return value.toStringAsFixed(0);
      }
      return value
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } catch (e) {
      return amount;
    }
  }

  Future<void> _handleConversion() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    final fundingBalance = _getFundingBalance();
    if (amount > fundingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient ${widget.fromAsset['token']['symbol']} balance'),
          backgroundColor: SafeJetColors.error,
        ),
      );
      return;
    }

    try {
      await _walletService.convertToken(
        fromTokenId: widget.fromAsset['token']['id'],
        toTokenId: _selectedToToken!['token']['id'],
        amount: amount,
      );

      // Add success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully converted ${amount} ${widget.fromAsset['token']['symbol']} to ${_selectedToToken!['token']['symbol']}'),
          backgroundColor: SafeJetColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
      rethrow;
    }
  }

  Future<void> _loadAvailableTokens() async {
    try {
      final response = await _walletService.getAvailableCoins();

      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        _availableTokens = response
            .where((coin) => coin.id != widget.fromAsset['token']['id'])
            .map((coin) => {
                  'token': {
                    'id': coin.id,
                    'symbol': coin.symbol,
                    'icon': coin.iconUrl,
                    'name': coin.name,
                  }
                })
            .toList();

        // Just set the selected token, don't update exchange rate yet
        if (_selectedToToken == null && _availableTokens.isNotEmpty) {
          _selectedToToken = _availableTokens.first;
        }
      });

      // Update exchange rate only if we have a selected token and widget is still mounted
      if (_selectedToToken != null && mounted) {
        await _updateExchangeRate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load available tokens';
        });
      }
    }
  }

  double _getFundingBalance() {
    // First try the funding balance from the map
    final mapBalance = _fundingBalances[widget.fromAsset['token']['id']] ?? 0.0;
    if (mapBalance > 0) return mapBalance;

    // If not found in map, use the passed balance
    return double.tryParse(widget.fromAsset['balance'].toString()) ?? 0.0;
  }

  double _getToAmount() {
    if (_selectedToToken == null) return 0;
    return _calculateAmountToReceive();
  }
}
