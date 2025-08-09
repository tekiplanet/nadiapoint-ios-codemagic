import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/colors.dart';

class TradeForm extends StatefulWidget {
  final bool isBuy;
  
  const TradeForm({
    super.key,
    required this.isBuy,
  });

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedOrderType = 'Limit';
  double _sliderValue = 0.0;
  
  final List<String> _orderTypes = ['Market', 'Limit', 'Stop-Limit'];

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainColor = widget.isBuy ? SafeJetColors.success : SafeJetColors.error;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Order Type Selector
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark 
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _orderTypes.length,
            itemBuilder: (context, index) {
              final isSelected = _orderTypes[index] == _selectedOrderType;
              return GestureDetector(
                onTap: () => setState(() => _selectedOrderType = _orderTypes[index]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? mainColor.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _orderTypes[index],
                    style: TextStyle(
                      color: isSelected ? mainColor : (isDark ? Colors.white70 : SafeJetColors.lightText),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Price Input
        if (_selectedOrderType != 'Market') ...[
          _buildInputField(
            'Price',
            _priceController,
            'USDT',
            isDark,
            theme,
          ),
          const SizedBox(height: 12),
        ],

        // Amount Input
        _buildInputField(
          'Amount',
          _amountController,
          'BTC',
          isDark,
          theme,
        ),
        const SizedBox(height: 12),

        // Percentage Slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                ),
                Text(
                  '${(_sliderValue * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: mainColor,
                inactiveTrackColor: mainColor.withOpacity(0.2),
                thumbColor: mainColor,
                overlayColor: mainColor.withOpacity(0.2),
              ),
              child: Slider(
                value: _sliderValue,
                onChanged: (value) => setState(() => _sliderValue = value),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPercentageButton('25%', 0.25, isDark, mainColor),
                _buildPercentageButton('50%', 0.50, isDark, mainColor),
                _buildPercentageButton('75%', 0.75, isDark, mainColor),
                _buildPercentageButton('100%', 1.0, isDark, mainColor),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Total
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : SafeJetColors.lightText,
                ),
              ),
              Text(
                '\$42,384.21',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white : SafeJetColors.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Buy/Sell Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement order placement
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.isBuy ? 'Buy BTC' : 'Sell BTC',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String suffix,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : SafeJetColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  suffix,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageButton(String text, double value, bool isDark, Color mainColor) {
    final isSelected = _sliderValue == value;
    return GestureDetector(
      onTap: () => setState(() => _sliderValue = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? mainColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? mainColor : Colors.transparent,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? mainColor : (isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 