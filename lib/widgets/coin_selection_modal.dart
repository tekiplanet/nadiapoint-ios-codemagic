import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../models/coin.dart';
import 'package:get_it/get_it.dart';
import '../services/wallet_service.dart';
import 'package:shimmer/shimmer.dart';

class CoinSelectionModal extends StatefulWidget {
  const CoinSelectionModal({super.key});

  @override
  State<CoinSelectionModal> createState() => _CoinSelectionModalState();
}

class _CoinSelectionModalState extends State<CoinSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final _walletService = GetIt.I<WalletService>();
  List<Coin>? _coins;
  String _error = '';
  bool _isLoading = true;
  List<Coin> _filteredCoins = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCoins);
    _loadCoins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoins() async {
    try {
      setState(() => _isLoading = true);
      final coins = await _walletService.getAvailableCoins();
      setState(() {
        _coins = coins;
        _filteredCoins = coins;  // Initialize filtered coins
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load coins: $e';
        _isLoading = false;
      });
    }
  }

  void _filterCoins() {
    if (_coins == null) return;
    
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCoins = _coins!.where((coin) {
        return coin.name.toLowerCase().contains(query) ||
               coin.symbol.toLowerCase().contains(query);
      }).toList();
    });
  }

  Widget _buildShimmerList(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 8, // Show 8 shimmer items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                // Coin icon placeholder
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                // Title and subtitle placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Networks count placeholder
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Coin',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search coins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200],
              ),
            ),
          ),

          // Coin List with Shimmer
          Expanded(
            child: _isLoading 
              ? _buildShimmerList(isDark)  // Replace CircularProgressIndicator with shimmer
              : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCoins,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCoins.length,
                    itemBuilder: (context, index) {
                      final coin = _filteredCoins[index];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: coin.iconUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(coin.iconUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: coin.iconUrl == null
                              ? Center(
                                  child: Text(
                                    coin.symbol[0],
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          coin.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          coin.symbol,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Text(
                          '${coin.networks.length} ${coin.networks.length == 1 ? 'network' : 'networks'}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, coin),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 