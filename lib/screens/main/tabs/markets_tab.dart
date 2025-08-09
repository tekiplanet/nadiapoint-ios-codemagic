import 'package:flutter/material.dart';
import '../../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../../services/token_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../home_screen.dart';  // Import home screen

class MarketsTab extends StatefulWidget {
  const MarketsTab({super.key});

  @override
  State<MarketsTab> createState() => _MarketsTabState();
}

class _MarketsTabState extends State<MarketsTab> {
  String _selectedCategory = 'Spot';
  final List<String> _categories = ['Spot', 'Futures', 'New'];
  final TextEditingController _searchController = TextEditingController();
  
  late TokenService _tokenService;
  List<UnifiedToken> _allTokens = [];
  List<UnifiedToken> _filteredTokens = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenService = TokenService();
    _fetchTokens();
  }

  Future<void> _fetchTokens() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to use the market endpoint first
      try {
        _allTokens = await _tokenService.getMarketTokens();
      } catch (e) {
        // Fallback to admin endpoint if market endpoint doesn't exist yet
        _allTokens = await _tokenService.getAllTokens();
      }
      _filterTokens();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tokens. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTokens() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredTokens = _allTokens;
      } else {
        final searchTerm = _searchController.text.toLowerCase();
        _filteredTokens = _allTokens.where((token) {
          return token.baseSymbol.toLowerCase().contains(searchTerm) ||
              token.name.toLowerCase().contains(searchTerm);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    onChanged: (_) => _filterTokens(),
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
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterTokens();
                              },
                            )
                          : null,
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
            ),

            // Category Selector
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _categories[index] == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = _categories[index]),
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
                          _categories[index],
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
            ),
            const SizedBox(height: 16),

            // Column Headers
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Pair',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Price',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Container(
                      width: 70,
                      child: Text(
                        '24h Change',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Market Pairs List or Error/Loading State
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _errorMessage != null
                      ? _buildErrorState(_errorMessage!, isDark)
                      : _filteredTokens.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildTokenList(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? SafeJetColors.primaryAccent.withOpacity(0.1)
                      : SafeJetColors.lightCardBorder.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                // Coin Icon + Name
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 10,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Price
                Expanded(
                  child: Container(
                    width: 80,
                    height: 14,
                    color: Colors.grey[500],
                    alignment: Alignment.centerRight,
                  ),
                ),
                
                // Change
                Container(
                  width: 70,
                  height: 25,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? Colors.red[400] : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchTokens,
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeJetColors.secondaryHighlight,
              foregroundColor: Colors.black,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No tokens available'
                : 'No tokens match your search',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterTokens();
              },
              child: Text(
                'Clear Search',
                style: TextStyle(
                  color: SafeJetColors.secondaryHighlight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenList(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: _fetchTokens,
      color: SafeJetColors.secondaryHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredTokens.length,
        itemBuilder: (context, index) => FadeInDown(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 400 + (index * 50)),
          child: InkWell(
            onTap: () {
              // Navigate to trade tab by replacing current screen with HomeScreen with initialIndex set to 1
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 1),
                )
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                    flex: 2,
                    child: Row(
                      children: [
                        _filteredTokens[index].icon != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _filteredTokens[index].icon!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: SafeJetColors.secondaryHighlight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _filteredTokens[index].baseSymbol.substring(0, 1),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: SafeJetColors.secondaryHighlight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _filteredTokens[index].baseSymbol.substring(0, 1),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                '${_filteredTokens[index].baseSymbol}/USDT',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                minFontSize: 10,
                              ),
                              AutoSizeText(
                                _filteredTokens[index].name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Expanded(
                    child: Text(
                      '\$${_formatPrice(_filteredTokens[index].currentPrice)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  
                  // 24h Change
                  Container(
                    width: 70, // Fixed width instead of Expanded
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: (_filteredTokens[index].changePercent24h >= 0 
                            ? SafeJetColors.success 
                            : SafeJetColors.error)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatPercentage(_filteredTokens[index].changePercent24h),
                      style: TextStyle(
                        color: _filteredTokens[index].changePercent24h >= 0 
                            ? SafeJetColors.success 
                            : SafeJetColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else if (price >= 0.01) {
      return price.toStringAsFixed(4);
    } else if (price >= 0.0001) {
      return price.toStringAsFixed(6);
    } else {
      return price.toStringAsFixed(8);
    }
  }
  
  String _formatPercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) {
      return '0.00%';
    }
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }
}
