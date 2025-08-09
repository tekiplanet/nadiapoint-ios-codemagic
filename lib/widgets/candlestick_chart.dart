import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'dart:math' as math;

class CandlestickChart extends StatefulWidget {
  const CandlestickChart({super.key});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  final List<CandleData> _data = [];
  bool _showMA = true;
  bool _isLine = false;
  
  @override
  void initState() {
    super.initState();
    _generateDummyData();
  }

  void _generateDummyData() {
    final random = math.Random();
    double price = 42000.0;
    
    for (int i = 0; i < 50; i++) {
      final open = price;
      final close = price + (random.nextDouble() * 200 - 100);
      final high = math.max(open, close) + (random.nextDouble() * 50);
      final low = math.min(open, close) - (random.nextDouble() * 50);
      final volume = random.nextDouble() * 10;
      
      _data.add(CandleData(
        timestamp: DateTime.now().subtract(Duration(hours: 50 - i)),
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));
      
      price = close;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Chart Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildChartButton(
                    'MA',
                    _showMA,
                    () => setState(() => _showMA = !_showMA),
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildChartButton(
                    'Volume',
                    true,
                    () {},
                    isDark,
                  ),
                ],
              ),
              _buildChartButton(
                _isLine ? 'Candles' : 'Line',
                false,
                () => setState(() => _isLine = !_isLine),
                isDark,
              ),
            ],
          ),
        ),

        // Chart
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: CandlestickPainter(
              data: _data,
              isDark: isDark,
              isLine: _isLine,
              showMA: _showMA,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? SafeJetColors.secondaryHighlight
              : (isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? SafeJetColors.secondaryHighlight
                : (isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                    : SafeJetColors.lightCardBorder),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : (isDark ? Colors.white : SafeJetColors.lightText),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class CandleData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class CandlestickPainter extends CustomPainter {
  final List<CandleData> data;
  final bool isDark;
  final bool isLine;
  final bool showMA;

  CandlestickPainter({
    required this.data,
    required this.isDark,
    required this.isLine,
    required this.showMA,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width / data.length;
    final candleWidth = width * 0.8;
    
    // Find min and max values
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    for (final candle in data) {
      minPrice = math.min(minPrice, candle.low);
      maxPrice = math.max(maxPrice, candle.high);
    }
    
    final priceRange = maxPrice - minPrice;
    final heightRatio = size.height / priceRange;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    if (isLine) {
      _drawLineSeries(canvas, size, width, heightRatio, minPrice);
    } else {
      _drawCandles(canvas, size, width, candleWidth, heightRatio, minPrice);
    }

    if (showMA) {
      _drawMA(canvas, size, width, heightRatio, minPrice);
    }
  }

  void _drawCandles(Canvas canvas, Size size, double width, double candleWidth,
      double heightRatio, double minPrice) {
    for (var i = 0; i < data.length; i++) {
      final candle = data[i];
      final x = i * width + (width - candleWidth) / 2;
      
      final open = size.height - (candle.open - minPrice) * heightRatio;
      final close = size.height - (candle.close - minPrice) * heightRatio;
      final high = size.height - (candle.high - minPrice) * heightRatio;
      final low = size.height - (candle.low - minPrice) * heightRatio;

      final isUp = close < open;
      final color = isUp ? SafeJetColors.success : SafeJetColors.error;

      // Draw wick
      canvas.drawLine(
        Offset(x + candleWidth / 2, high),
        Offset(x + candleWidth / 2, low),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );

      // Draw body
      canvas.drawRect(
        Rect.fromLTRB(x, math.min(open, close), x + candleWidth, math.max(open, close)),
        Paint()
          ..color = isUp ? color : color.withOpacity(0.5)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawLineSeries(Canvas canvas, Size size, double width, double heightRatio,
      double minPrice) {
    final path = Path();
    final paint = Paint()
      ..color = SafeJetColors.secondaryHighlight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < data.length; i++) {
      final candle = data[i];
      final x = i * width + width / 2;
      final y = size.height - (candle.close - minPrice) * heightRatio;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawMA(Canvas canvas, Size size, double width, double heightRatio,
      double minPrice) {
    final period = 20;
    if (data.length < period) return;

    final path = Path();
    final paint = Paint()
      ..color = SafeJetColors.secondaryHighlight.withOpacity(0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = period - 1; i < data.length; i++) {
      double sum = 0;
      for (var j = 0; j < period; j++) {
        sum += data[i - j].close;
      }
      final ma = sum / period;
      final x = i * width + width / 2;
      final y = size.height - (ma - minPrice) * heightRatio;

      if (i == period - 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 