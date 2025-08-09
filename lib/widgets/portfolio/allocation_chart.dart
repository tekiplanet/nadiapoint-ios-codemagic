import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme/colors.dart';

class AllocationChart extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> allocationData;

  const AllocationChart({
    super.key, 
    required this.isDark,
    this.allocationData = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (allocationData.isEmpty) {
      return _buildEmptyState();
    }

    // Process the data
    final sections = _createSections();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Allocation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Portfolio distribution',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              // Pie chart
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Handle touch events if needed
                      },
                    ),
                  ),
                ),
              ),
              
              // Legend
              Expanded(
                flex: 3,
                child: _buildLegend(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Asset Allocation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No assets found in your portfolio',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    // Only show top 5 assets, group others
    final List<Map<String, dynamic>> legendItems = [];
    
    // Process allocationData to create legend items
    if (allocationData.isNotEmpty) {
      // Take top 4 items
      final topItems = allocationData.length > 4 
          ? allocationData.sublist(0, 4) 
          : allocationData;
      
      // Add top items to legend
      legendItems.addAll(topItems);
      
      // If there are more than 4 items, add "Others" category
      if (allocationData.length > 4) {
        final otherPercentage = allocationData
            .sublist(4)
            .fold(0.0, (sum, item) => sum + (item['percentage'] as double));
        
        final otherValue = allocationData
            .sublist(4)
            .fold(0.0, (sum, item) => sum + (item['value'] as double));
        
        legendItems.add({
          'token': {'symbol': 'Others', 'name': 'Other Assets'},
          'percentage': otherPercentage,
          'value': otherValue,
        });
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: legendItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final symbol = item['token']['symbol'] as String;
        final percentage = (item['percentage'] as double).toStringAsFixed(1);
        final color = _getColor(index);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _createSections() {
    // Only process top 5 assets, group others
    final List<Map<String, dynamic>> chartItems = [];
    
    // Process allocationData to create chart items
    if (allocationData.isNotEmpty) {
      // Take top 4 items
      final topItems = allocationData.length > 4 
          ? allocationData.sublist(0, 4) 
          : allocationData;
      
      // Add top items to chart
      chartItems.addAll(topItems);
      
      // If there are more than 4 items, add "Others" category
      if (allocationData.length > 4) {
        final otherPercentage = allocationData
            .sublist(4)
            .fold(0.0, (sum, item) => sum + (item['percentage'] as double));
        
        chartItems.add({
          'token': {'symbol': 'Others'},
          'percentage': otherPercentage,
        });
      }
    }
    
    // Create chart sections
    return chartItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final double percentage = item['percentage'] as double;
      final color = _getColor(index);
      
      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '',
        radius: 50,
        badgeWidget: percentage < 5 ? null : _Badge(
          color,
          '${percentage.toStringAsFixed(0)}%',
          Icons.circle,
        ),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  Color _getColor(int index) {
    // Define a set of colors for the chart
    final colors = [
      SafeJetColors.secondaryHighlight,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.indigoAccent,
    ];
    
    // Return color based on index, cycle through colors if needed
    return colors[index % colors.length];
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final String text;
  final IconData icon;

  const _Badge(this.color, this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 