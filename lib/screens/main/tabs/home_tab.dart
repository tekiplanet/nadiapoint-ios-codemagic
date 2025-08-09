import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math' show sin;
import '../../../config/theme/colors.dart';
import '../../../widgets/mini_chart_painter.dart';
import '../../../widgets/mini_sparkline_painter.dart';
import '../../../widgets/portfolio/portfolio_summary_card.dart';
import '../../../widgets/news/news_carousel.dart';
import '../../../services/home_service.dart';
import '../../../screens/main/home_screen.dart';
import '../../../screens/p2p/p2p_screen.dart';
import './markets_tab.dart';
import 'package:shimmer/shimmer.dart';
import '../../../screens/support/support_screen.dart';
import '../../../screens/fiat/fiat_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = [
    'All',
    'Favorites',
    'Gainers',
    'Losers',
    'Volume'
  ];
  int _selectedCategoryIndex = 0;
  bool _isRefreshing = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _homeService = HomeService();

  Map<String, dynamic>? _marketData;
  List<double> _chartPoints = [];
  List<Map<String, dynamic>> _trendingTokens = [];
  List<Map<String, dynamic>> _marketTokens = [];
  List<Map<String, dynamic>> _filteredMarketTokens = [];
  bool _isLoadingMarketTokens = false;
  String? _marketTokensError;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
    _loadTrendingTokens();
    _loadMarketTokens();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData() async {
    try {
      final data = await _homeService.getMarketOverview();
      if (mounted) {
        setState(() {
          _marketData = data;
          // Convert chart data to simple points array
          _chartPoints = (data['chartData'] as List<dynamic>?)
                  ?.map((point) => (point[1] as num).toDouble())
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      print('Error loading market data');
    }
  }

  Future<void> _loadTrendingTokens() async {
    try {
      final response = await _homeService.getTrending();
      if (mounted) {
        setState(() {
          _trendingTokens =
              List<Map<String, dynamic>>.from(response['tokens'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading trending tokens');
    }
  }

  Future<void> _loadMarketTokens() async {
    try {
      setState(() {
        _isLoadingMarketTokens = true;
        _marketTokensError = null;
      });

      final response = await _homeService.getMarketTokens();
      if (mounted) {
        final tokens =
            List<Map<String, dynamic>>.from(response['tokens'] ?? []);
        // Sort tokens alphabetically by baseSymbol
        tokens.sort((a, b) =>
            (a['baseSymbol'] as String).compareTo(b['baseSymbol'] as String));

        setState(() {
          _marketTokens = tokens;
          _filteredMarketTokens = tokens;
          _isLoadingMarketTokens = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marketTokensError = e.toString();
          _isLoadingMarketTokens = false;
        });
      }
    }
  }

  void _filterMarketTokens(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMarketTokens = _marketTokens;
      } else {
        _filteredMarketTokens = _marketTokens.where((token) {
          final baseSymbol = (token['baseSymbol'] as String).toLowerCase();
          final name = (token['name'] as String?)?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return baseSymbol.contains(searchQuery) || name.contains(searchQuery);
        }).toList();
      }
    });
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

  String _formatVolume(String value) {
    final number = double.tryParse(value) ?? 0;
    if (number >= 1e12) {
      return '\$${(number / 1e12).toStringAsFixed(1)}T';
    } else if (number >= 1e9) {
      return '\$${(number / 1e9).toStringAsFixed(1)}B';
    } else if (number >= 1e6) {
      return '\$${(number / 1e6).toStringAsFixed(1)}M';
    } else if (number >= 1e3) {
      return '\$${(number / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${number.toStringAsFixed(1)}';
    }
  }

  String _formatLargeNumber(String value) {
    final number = double.tryParse(value) ?? 0;
    if (number >= 1e12) {
      return '\$${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '\$${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '\$${(number / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${number.toStringAsFixed(2)}';
    }
  }

  String _formatSupply(String value) {
    final supply = double.tryParse(value) ?? 0;
    if (supply >= 1e6) {
      return '${(supply / 1e6).toStringAsFixed(1)}M BTC';
    } else if (supply >= 1e3) {
      return '${(supply / 1e3).toStringAsFixed(1)}K BTC';
    } else {
      return '${supply.toStringAsFixed(1)} BTC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        key: _refreshKey,
        color: SafeJetColors.secondaryHighlight,
        backgroundColor:
            isDark ? SafeJetColors.primaryBackground : Colors.white,
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await Future.wait([
            _loadMarketData(),
            _loadTrendingTokens(),
            _loadMarketTokens(),
          ]);
          setState(() => _isRefreshing = false);
        },
        child: CustomScrollView(
          slivers: [
            // Portfolio Summary Card
            SliverToBoxAdapter(
              child: PortfolioSummaryCard(),
            ),

            // Quick Actions Section
            SliverToBoxAdapter(
              child: _buildQuickActions(isDark),
            ),

            // Market Overview Card
            SliverToBoxAdapter(
              child: _buildMarketOverviewCard(isDark),
            ),

            // News & Updates Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: NewsCarousel(isDark: isDark),
              ),
            ),

            // Trending Section
            SliverToBoxAdapter(
              child: _buildTrendingSection(),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                    onChanged: _filterMarketTokens,
                    decoration: InputDecoration(
                      hintText: 'Search tokens',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey[600]
                            : SafeJetColors.lightTextSecondary,
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
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterMarketTokens('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Market List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildMarketList(),
            ),

            // Bottom Padding for nav bar
            const SliverPadding(
              padding: EdgeInsets.only(bottom: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: MiniChartPainter(points: _chartPoints),
      ),
    );
  }

  Widget _buildMarketOverviewCard(bool isDark) {
    final price = _marketData?['price'] ?? '0';
    final priceChange = _marketData?['priceChange24h'] ?? 0.0;
    final volume = _marketData?['volume24h'] ?? '0';
    final marketCap = _marketData?['marketCap'] ?? '0';
    final supply = _marketData?['circulatingSupply'] ?? '0';
    final isPositiveChange = priceChange >= 0;

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    SafeJetColors.secondaryHighlight.withOpacity(0.15),
                    SafeJetColors.primaryAccent.withOpacity(0.05),
                  ]
                : [
                    SafeJetColors.lightCardBackground,
                    SafeJetColors.lightCardBackground,
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                : SafeJetColors.lightCardBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bitcoin Price',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isPositiveChange
                                      ? SafeJetColors.success
                                      : SafeJetColors.error)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositiveChange
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: isPositiveChange
                                      ? SafeJetColors.success
                                      : SafeJetColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isPositiveChange ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositiveChange
                                        ? SafeJetColors.success
                                        : SafeJetColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatPrice(double.parse(price)),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildMiniChart(),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Market Cap',
                    _formatLargeNumber(marketCap),
                    Icons.pie_chart_rounded,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    '24h Vol.',
                    _formatVolume(volume),
                    Icons.bar_chart_rounded,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    'Supply',
                    _formatSupply(supply),
                    Icons.currency_bitcoin_rounded,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: SafeJetColors.secondaryHighlight,
            size: 20,
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : SafeJetColors.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.grey[400]
                    : SafeJetColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MarketsTab(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: SafeJetColors.secondaryHighlight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: SafeJetColors.secondaryHighlight,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: _trendingTokens.isEmpty
                ? _buildTrendingShimmer()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _trendingTokens.length,
                    itemBuilder: (context, index) =>
                        _buildTrendingCoinCard(_trendingTokens[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                : SafeJetColors.lightCardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.2)
                  : SafeJetColors.lightCardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCoinCard(Map<String, dynamic> token) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priceChange =
        double.tryParse(token['priceChange24h'].toString()) ?? 0.0;
    final currentPrice =
        double.tryParse(token['currentPrice'].toString()) ?? 0.0;
    final metadata = token['metadata'] as Map<String, dynamic>? ?? {};
    final iconUrl = metadata['icon'] as String? ?? '';
    final baseSymbol = token['baseSymbol'] as String? ?? token['symbol'];
    final variants = (token['variants'] as List<dynamic>?)
            ?.map((v) => v as Map<String, dynamic>)
            .toList() ??
        [];

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: iconUrl.isNotEmpty
                      ? Image.network(
                          iconUrl,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.currency_bitcoin,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.currency_bitcoin,
                          color: Colors.black,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baseSymbol,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      token['name'] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : SafeJetColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${_formatPrice(currentPrice)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SafeJetColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${priceChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: SafeJetColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (variants.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${variants.length}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? SafeJetColors.secondaryHighlight
              : (isDark
                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                  : SafeJetColors.lightCardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? SafeJetColors.secondaryHighlight
                : (isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                    : SafeJetColors.lightCardBorder),
          ),
        ),
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
  }

  Widget _buildMarketListItem(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final token = _filteredMarketTokens[index];
    final priceChange =
        double.tryParse(token['priceChange24h'].toString()) ?? 0.0;
    final metadata = token['metadata'] as Map<String, dynamic>? ?? {};
    final iconUrl = metadata['icon'] as String? ?? '';
    final baseSymbol = token['baseSymbol'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Coin Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: SafeJetColors.secondaryHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            baseSymbol.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: SafeJetColors.secondaryHighlight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          baseSymbol.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Coin Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baseSymbol,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  token['name'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Price Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${_formatPrice(double.parse(token['currentPrice'].toString()) ?? 0)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (priceChange >= 0
                            ? SafeJetColors.success
                            : SafeJetColors.error)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: priceChange >= 0
                          ? SafeJetColors.success
                          : SafeJetColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketListShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 80,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 10,
      ),
    );
  }

  Widget _buildMarketList() {
    if (_isLoadingMarketTokens || _marketTokensError != null) {
      return _buildMarketListShimmer();
    }

    if (_filteredMarketTokens.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(_searchController.text.isEmpty
                ? 'No market data available'
                : 'No tokens found matching "${_searchController.text}"'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMarketListItem(index),
        childCount: _filteredMarketTokens.length,
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all quick actions
                },
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: SafeJetColors.secondaryHighlight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: SafeJetColors.secondaryHighlight,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionCard(
                  'Gift Cards',
                  Icons.card_giftcard_rounded,
                  SafeJetColors.success,
                  isDark,
                  onTap: () {
                    _showGiftCardComingSoonDialog();
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionCard(
                  'Fiat',
                  Icons.account_balance_rounded,
                  SafeJetColors.info,
                  isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FiatScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionCard(
                  'P2P',
                  Icons.people_alt_rounded,
                  SafeJetColors.secondaryHighlight,
                  isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const P2PScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionCard(
                  'Support',
                  Icons.headset_mic_rounded,
                  SafeJetColors.info,
                  isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color accentColor,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(isDark ? 0.15 : 0.1),
              accentColor.withOpacity(isDark ? 0.05 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.2 : 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftCardComingSoonDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor:
              isDark ? SafeJetColors.primaryBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  SafeJetColors.success.withOpacity(0.15),
                                  SafeJetColors.success.withOpacity(0.05),
                                ]
                              : [
                                  SafeJetColors.success.withOpacity(0.1),
                                  SafeJetColors.success.withOpacity(0.05),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: SafeJetColors.success.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SafeJetColors.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: SafeJetColors.success,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gift Cards Trading',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coming Soon',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Features Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Ready for Amazing Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureItem(
                          isDark,
                          Icons.swap_horiz_rounded,
                          'Instant Gift Card Trading',
                          'Trade gift cards seamlessly with other users',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          isDark,
                          Icons.verified_rounded,
                          'Verified Merchants',
                          'Trade with confidence using our verified merchant system',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          isDark,
                          Icons.security_rounded,
                          'Secure Escrow',
                          'Your trades are protected by our secure escrow service',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current Features Section
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meanwhile, Explore Our Current Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'While you wait for our gift card trading feature, you can enjoy:',
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCurrentFeatureItem(
                            isDark,
                            Icons.account_balance_wallet_rounded,
                            'Secure Wallet',
                            'Store and manage your digital assets safely',
                          ),
                          _buildCurrentFeatureItem(
                            isDark,
                            Icons.swap_vert_rounded,
                            'Asset Swapping',
                            'Convert between different cryptocurrencies instantly',
                          ),
                          _buildCurrentFeatureItem(
                            isDark,
                            Icons.people_rounded,
                            'P2P Trading',
                            'Trade directly with other users securely',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: FadeInUp(
            duration: const Duration(milliseconds: 1200),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SafeJetColors.secondaryHighlight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      bool isDark, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeJetColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SafeJetColors.success,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentFeatureItem(
      bool isDark, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SafeJetColors.secondaryHighlight,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
