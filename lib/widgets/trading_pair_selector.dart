import 'package:flutter/material.dart';
import '../config/theme/colors.dart';

class TradingPairSelector extends StatefulWidget {
  const TradingPairSelector({super.key});

  @override
  State<TradingPairSelector> createState() => _TradingPairSelectorState();
}

class _TradingPairSelectorState extends State<TradingPairSelector> {
  final _searchController = TextEditingController();
  String _selectedQuote = 'USDT';
  String _searchQuery = '';
  
  final List<String> _quotes = ['USDT', 'BTC', 'ETH'];
  final List<Map<String, dynamic>> _pairs = [
    {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 42384.21, 'change': 2.34},
    {'symbol': 'ETH', 'name': 'Ethereum', 'price': 2284.15, 'change': 1.23},
    {'symbol': 'BNB', 'name': 'BNB', 'price': 312.45, 'change': -0.45},
    // Add more pairs as needed
  ];

  List<Map<String, dynamic>> get _filteredPairs {
    if (_searchQuery.isEmpty) return _pairs;
    
    return _pairs.where((pair) {
      final symbol = pair['symbol'].toString().toLowerCase();
      final name = pair['name'].toString().toLowerCase();
      final search = _searchQuery.toLowerCase();
      
      return symbol.contains(search) || name.contains(search);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle and Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Trading Pair',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
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
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search coin',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : SafeJetColors.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quote Selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quotes.length,
              itemBuilder: (context, index) {
                final isSelected = _quotes[index] == _selectedQuote;
                return GestureDetector(
                  onTap: () => setState(() => _selectedQuote = _quotes[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SafeJetColors.secondaryHighlight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? SafeJetColors.secondaryHighlight
                            : (isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.2)
                                : SafeJetColors.lightCardBorder),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _quotes[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white : SafeJetColors.lightText),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Trading Pairs List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPairs.length,
              itemBuilder: (context, index) {
                final pair = _filteredPairs[index];
                final isPositive = pair['change'] >= 0;
                
                return InkWell(
                  onTap: () {
                    // Return selected pair
                    Navigator.pop(context, {
                      ...pair,
                      'quote': _selectedQuote,
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? SafeJetColors.primaryAccent.withOpacity(0.2)
                              : SafeJetColors.lightCardBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Pair Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pair['symbol']}/$_selectedQuote',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pair['name'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Price Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${pair['price']}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isPositive ? SafeJetColors.success : SafeJetColors.error)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}${pair['change']}%',
                                style: TextStyle(
                                  color: isPositive ? SafeJetColors.success : SafeJetColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 