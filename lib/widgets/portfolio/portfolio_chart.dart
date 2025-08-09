import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/colors.dart';

class PortfolioChart extends StatelessWidget {
  final bool isDark;
  final String timeframe;
  final List<Map<String, dynamic>> chartData;

  const PortfolioChart({
    super.key,
    required this.isDark,
    required this.timeframe,
    this.chartData = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Performance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Last ${_getTimeframeText()}',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: chartData.isEmpty
                ? _buildEmptyChart(context)
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Text(
        'No data available',
        style: TextStyle(
          color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Process chart data
    final spots = _processChartData();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _bottomTitleWidgets,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
              interval: 1,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: spots.isEmpty ? 10 : (spots.length - 1).toDouble(),
        minY: spots.isEmpty ? 0 : _getMinY(spots),
        maxY: spots.isEmpty ? 100 : _getMaxY(spots),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                SafeJetColors.secondaryHighlight,
                SafeJetColors.secondaryHighlight.withOpacity(0.8),
              ],
            ),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  SafeJetColors.secondaryHighlight.withOpacity(0.3),
                  SafeJetColors.secondaryHighlight.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _processChartData() {
    if (chartData.isEmpty) return [];
    
    // Convert data to spots
    final spots = <FlSpot>[];
    for (int i = 0; i < chartData.length; i++) {
      final value = double.tryParse(chartData[i]['value'].toString()) ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }
    
    return spots;
  }

  double _getMinY(List<FlSpot> spots) {
    final values = spots.map((spot) => spot.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    // Return 95% of min value to give some padding to the chart
    return min * 0.95;
  }

  double _getMaxY(List<FlSpot> spots) {
    final values = spots.map((spot) => spot.y).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    // Return 105% of max value to give some padding to the chart
    return max * 1.05;
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (chartData.isEmpty) return Container();
    
    final style = TextStyle(
      color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    
    Widget text;
    final index = value.toInt();
    if (index < 0 || index >= chartData.length) {
      return Container();
    }
    
    String label = '';
    final timestamp = DateTime.parse(chartData[index]['timestamp']);
    
    switch (timeframe) {
      case '24h':
        // Show hours
        if (index % 6 == 0 || index == chartData.length - 1) {
          label = '${timestamp.hour}:00';
        }
        break;
      case '7d':
        // Show days
        if (index % 1 == 0 || index == chartData.length - 1) {
          label = '${timestamp.day}/${timestamp.month}';
        }
        break;
      case '30d':
        // Show days
        if (index % 5 == 0 || index == chartData.length - 1) {
          label = '${timestamp.day}/${timestamp.month}';
        }
        break;
      default:
        label = '';
    }
    
    text = Text(label, style: style);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    
    // Format value to K/M for better readability
    String text;
    if (value >= 1000000) {
      text = '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      text = '\$${value.toStringAsFixed(0)}';
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }
  
  String _getTimeframeText() {
    switch (timeframe) {
      case '24h':
        return '24 hours';
      case '7d':
        return '7 days';
      case '30d':
        return '30 days';
      default:
        return timeframe;
    }
  }
} 