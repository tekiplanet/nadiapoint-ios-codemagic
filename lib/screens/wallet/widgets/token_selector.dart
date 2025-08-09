import 'package:flutter/material.dart';
import '../../../config/theme/colors.dart';

class TokenSelector extends StatefulWidget {
  final List<Map<String, dynamic>> tokens;
  final Map<String, dynamic>? selectedToken;
  final Function(Map<String, dynamic>) onSelect;

  const TokenSelector({
    Key? key,
    required this.tokens,
    required this.selectedToken,
    required this.onSelect,
  }) : super(key: key);

  @override
  _TokenSelectorState createState() => _TokenSelectorState();
}

class _TokenSelectorState extends State<TokenSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTokens = [];

  @override
  void initState() {
    super.initState();
    _filteredTokens = widget.tokens;
  }

  void _filterTokens(String query) {
    setState(() {
      _filteredTokens = widget.tokens.where((token) {
        final symbol = token['token']['symbol'].toString().toLowerCase();
        final name = token['token']['name'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return symbol.contains(searchQuery) || name.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [SafeJetColors.darkGradientStart, SafeJetColors.darkGradientEnd]
              : [SafeJetColors.lightGradientStart, SafeJetColors.lightGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white38 : Colors.black38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Token',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterTokens,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search tokens',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Token list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredTokens.length,
              itemBuilder: (context, index) {
                final token = _filteredTokens[index]['token'];
                final isSelected = widget.selectedToken?['token']['id'] == token['id'];
                
                return InkWell(
                  onTap: () {
                    widget.onSelect(_filteredTokens[index]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white12 : Colors.black.withOpacity(0.05))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Token icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.black26 : Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              token['icon'] ?? '',
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.currency_bitcoin,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Token details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                token['symbol'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                token['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Selected indicator
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: SafeJetColors.warning,
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