import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'p2p_offer_details_screen.dart';
import 'p2p_order_history_screen.dart';
import 'p2p_create_offer_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'p2p_my_offers_screen.dart';
import 'package:get_it/get_it.dart';
import '../../services/p2p_service.dart';
import 'package:shimmer/shimmer.dart';
import '../settings/kyc_levels_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/shimmer_loading.dart';

class P2PScreen extends StatefulWidget {
  const P2PScreen({super.key});

  @override
  State<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends State<P2PScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _p2pService = GetIt.I<P2PService>();

  // State variables
  String? _selectedCurrency;
  String? _selectedTokenId;
  String? _selectedPaymentMethodId;
  bool _isLoadingOffers = false;
  bool _isLoadingFilters = false;
  bool _isInitialLoading = true; // Track initial loading state

  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _tokens = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  // Add these state variables to _P2PScreenState
  double? _minAmount; // Add this state variable

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
    _checkKycLevel(); // Add KYC check before loading data
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkKycLevel() async {
    try {
      final kycData = await _p2pService.getUserKycLevel();
      if (!(kycData['features']['canUseP2P'] ?? false)) {
        if (!mounted) return;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Go back to previous screen
              return false;
            },
            child: Dialog.fullscreen(
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
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context); // Go back to previous screen
                    },
                  ),
                  title: Text(
                    'KYC Verification Required',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.verified_user,
                                      color: isDark
                                          ? SafeJetColors.secondaryHighlight
                                          : SafeJetColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Level',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          kycData['title'] ?? 'Unverified',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'P2P Trading Access',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'To access P2P trading features, you need to complete your KYC verification. This helps us maintain a secure trading environment for all users.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SafeJetColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: SafeJetColors.warning.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: SafeJetColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Verification usually takes less than 24 hours to complete.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 14,
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
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Pop dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const KYCLevelsScreen(),
                              ),
                            ).then((_) {
                              // Check KYC level again when returning from KYC screen
                              _checkKycLevel();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.secondaryHighlight,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Complete Verification',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return; // Add return here to prevent loading initial data
      } else {
        // Only load initial data if KYC check passes
        await _loadInitialData();
      }
    } catch (e) {
      print('Error checking KYC level');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
      Navigator.pop(context); // Keep this one for error handling
    }
  }

  Future<void> _loadInitialData() async {
    print('Setting loading states to true'); // Debug print
    setState(() {
      _isLoadingFilters = true;
      _isInitialLoading = true;
    });

    try {
      print('Loading filters in parallel'); // Debug print
      final futures = await Future.wait([
        _p2pService.getTraderSettings(),
        _p2pService.getActiveCurrencies(),
        _p2pService.getAvailableAssets(_tabController.index == 0),
        _p2pService.getActivePaymentMethodTypes(),
      ]);

      if (!mounted) return;

      final settings = futures[0] as Map<String, dynamic>;
      final currencies = futures[1] as List<Map<String, dynamic>>;
      final tokens = futures[2] as List<Map<String, dynamic>>;
      final paymentMethods = futures[3] as List<Map<String, dynamic>>;

      print('Setting data in state'); // Debug print
      setState(() {
        _selectedCurrency = settings['currency'] ??
            (currencies.isNotEmpty ? currencies[0]['symbol'] : null);
        _currencies = currencies;
        _tokens = tokens;
        _paymentMethods = paymentMethods;
        if (tokens.isNotEmpty) {
          _selectedTokenId = tokens[0]['id'];
        }
      });

      if (_selectedCurrency != null) {
        await _loadOffers();
      }
    } catch (e) {
      print('Error in _loadInitialData'); // Debug print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      if (mounted) {
        print('Setting loading states to false'); // Debug print
        setState(() {
          _isLoadingFilters = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadOffers({bool refresh = false}) async {
    if (refresh) {
      print('Loading offers with minAmount: $_minAmount');
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _offers = [];
        _isLoadingOffers = true;
      });
    }

    if (!_hasMoreData) return;

    try {
      print('Calling API with params:');
      print('isBuy: ${_tabController.index == 0}');
      print('currency: $_selectedCurrency');
      print('tokenId: $_selectedTokenId');
      print('paymentMethodId: $_selectedPaymentMethodId');
      print('minAmount: $_minAmount');
      print('page: $_currentPage');

      final result = await _p2pService.getPublicOffers(
        isBuy: _tabController.index == 0,
        currency: _selectedCurrency,
        tokenId: _selectedTokenId,
        paymentMethodId: _selectedPaymentMethodId,
        minAmount: _minAmount,
        page: _currentPage,
      );

      print('API Response:');
      print('Total offers: ${(result['offers'] as List).length}');
      print('Pagination: ${result['pagination']}');

      if (!mounted) return;

      final newOffers = (result['offers'] as List).cast<Map<String, dynamic>>();
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        if (refresh) {
          _offers = newOffers;
        } else {
          _offers.addAll(newOffers);
        }
        _totalPages = pagination['pages'] as int;
        _hasMoreData = _currentPage < _totalPages;
        _currentPage++;
      });
    } catch (e) {
      print('Error loading offers');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  void _handleTabChange() async {
    if (_tabController.indexIsChanging) {
      // Clear current tokens and show loading first
      setState(() {
        _tokens = [];
        _selectedTokenId = null;
        _isLoadingOffers = true; // Show loading state
        _offers = []; // Clear existing offers
      });

      try {
        if (_tabController.index == 1) {
          // Switching to Sell tab
          // Check funding balance first
          final balances = await _p2pService.getAvailableAssets(false);
          if (!mounted) return;

          if (balances.isEmpty) {
            await _showNoBalanceDialog();
            _tabController.animateTo(0);
            return; // Don't load offers for sell tab if no balance
          }

          // If we have balances, continue with loading tokens
          setState(() {
            _tokens = balances;
            if (balances.isNotEmpty) {
              _selectedTokenId = balances[0]['id'];
            }
          });
        } else {
          // For buy tab, load tokens normally
          final newTokens = await _p2pService.getAvailableAssets(true);
          if (!mounted) return;

          setState(() {
            _tokens = newTokens;
            if (newTokens.isNotEmpty) {
              _selectedTokenId = newTokens[0]['id'];
            }
          });
        }

        // Only load offers if we have a selected token
        if (_selectedTokenId != null) {
          await _loadOffers(refresh: true);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: SafeJetColors.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingOffers = false;
          });
        }
      }
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'P2P Trading',
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const P2POrderHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history_rounded),
        ),
      ),
      body: Column(
        children: [
          // Buy/Sell Tabs
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: SafeJetColors.secondaryHighlight,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: isDark ? Colors.white : Colors.black,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('BUY'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('SELL'),
                  ),
                ),
              ],
            ),
          ),

          // Quick Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Fiat Currency Filter
                SizedBox(
                  height: 40,
                  child: _isLoadingFilters
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currencies.isEmpty
                              ? _currencies.length
                              : 3, // Use actual length or minimum if empty
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Shimmer.fromColors(
                              baseColor: isDark
                                  ? Colors.grey[900]!
                                  : Colors.grey[300]!,
                              highlightColor: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: 60,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currencies.length,
                          itemBuilder: (context, index) {
                            final currency =
                                _currencies[index]['code'] as String;
                            final isSelected = currency == _selectedCurrency;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (!isSelected) {
                                      setState(
                                          () => _selectedCurrency = currency);
                                      _loadOffers(refresh: true);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? SafeJetColors.secondaryHighlight
                                          : isDark
                                              ? Colors.white.withOpacity(
                                                  0.05) // Very subtle white for dark mode
                                              : Colors.black.withOpacity(
                                                  0.05), // Very subtle black for light mode
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      currency,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : isDark
                                                ? Colors.white
                                                : SafeJetColors.lightText,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                // Filter Row
                Row(
                  children: [
                    // Crypto Dropdown
                    Expanded(
                      flex: 2,
                      child: _buildFilterButton(
                        _tokens.isEmpty
                            ? 'Select'
                            : _tokens.firstWhere(
                                (t) => t['id'] == _selectedTokenId,
                                orElse: () => {'symbol': 'Select'},
                              )['symbol'],
                        isDark,
                        onTap: () => _showFilterOptions(
                          context,
                          'Select Crypto',
                          _tokens,
                          _selectedTokenId,
                          (value) {
                            setState(() => _selectedTokenId = value);
                            _loadOffers(refresh: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Method Dropdown
                    Expanded(
                      flex: 3,
                      child: _buildFilterButton(
                        _selectedPaymentMethodId != null
                            ? _paymentMethods.firstWhere(
                                (pm) => pm['id'] == _selectedPaymentMethodId,
                                orElse: () => {'name': 'All Payment'},
                              )['name']
                            : 'All Payment',
                        isDark,
                        onTap: () => _showFilterOptions(
                          context,
                          'Payment Method',
                          _paymentMethods,
                          _selectedPaymentMethodId,
                          (value) {
                            setState(() => _selectedPaymentMethodId = value);
                            _loadOffers(refresh: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter Button
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: (_minAmount != null)
                            ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                            : isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: (_minAmount != null)
                                  ? SafeJetColors.secondaryHighlight
                                  : isDark
                                      ? Colors.white
                                      : SafeJetColors.lightText,
                            ),
                            onPressed: () => _showFilterSheet(context, isDark),
                          ),
                          if (_minAmount != null)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: SafeJetColors.secondaryHighlight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOffersList(isDark, isBuy: true),
                _buildOffersList(isDark, isBuy: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: SafeJetColors.secondaryHighlight,
        foregroundColor: Colors.black,
        activeBackgroundColor: SafeJetColors.error,
        activeForegroundColor: Colors.white,
        spacing: 3,
        childPadding: const EdgeInsets.all(5),
        spaceBetweenChildren: 4,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.create),
            backgroundColor: SafeJetColors.secondaryHighlight,
            foregroundColor: Colors.black,
            label: 'Create Offer',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => P2PCreateOfferScreen(
                    isBuyOffer: _tabController.index == 0,
                    selectedToken: null,
                    offer: null,
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.list_alt),
            backgroundColor: SafeJetColors.secondaryHighlight,
            foregroundColor: Colors.black,
            label: 'My Offers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const P2PMyOffersScreen(), // We'll create this screen
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList(bool isDark, {required bool isBuy}) {
    return RefreshIndicator(
      onRefresh: () => _loadOffers(refresh: true),
      child: _isInitialLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildOfferCardShimmer(isDark),
            )
          : _offers.isEmpty && !_isLoadingOffers
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _offers.length) {
                      return _buildOfferCardShimmer(isDark);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildOfferCard(isDark, isBuy, _offers[index]),
                    );
                  },
                ),
    );
  }

  Widget _buildOfferCard(bool isDark, bool isBuy, Map<String, dynamic> offer) {
    // print('Building offer card with data: ${offer.toString()}');

    final token = offer['token'] as Map<String, dynamic>;
    final symbol = token['symbol'] ?? 'Unknown';

    // Get payment methods
    final paymentMethodsData = offer['paymentMethods'] as List;
    final paymentMethods = paymentMethodsData.map((pm) {
      return (pm as Map<String, dynamic>)['name'] as String;
    }).toList();

    // Get price info
    final currentPrice =
        double.tryParse(offer['calculatedPrice']?.toString() ?? '0') ?? 0.0;
    final marketPrice =
        double.tryParse(offer['marketPrice']?.toString() ?? '0') ?? 0.0;
    final priceDelta = double.tryParse(offer['priceDelta'].toString()) ?? 0.0;
    final priceType = offer['priceType'] as String;

    // For percentage type, show the percentage
    // For fixed type, show the actual difference
    final displayDelta = priceType == 'percentage'
        ? '$priceDelta%' // Just show percentage
        : NumberFormat("#,##0.00").format(priceDelta); // Show fixed amount

    // Calculate the actual price difference
    final priceDifference = (currentPrice - marketPrice).abs();

    print('Calculated difference: $priceDifference');

    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onOfferSelected(offer, isBuy),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trader Info Row
              Row(
                children: [
                  // Avatar and Name
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey[200],
                          child: Text(
                            (offer['user']['name'] as String?)?.isNotEmpty ==
                                    true
                                ? (offer['user']['name'] as String)
                                    .substring(0, 1)
                                    .toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer['user']['name'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Online', // or "Last seen 2h ago"
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trader Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: SafeJetColors.secondaryHighlight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer['orderStats']?['completionRate'] ?? 98}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${offer['orderStats']?['totalOrders'] ?? 0} orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Price and Amount Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat("#,##0.00").format(currentPrice)} ${offer['currency']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _tabController.index == 0 ? 'Available' : 'Amount',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey[400]
                                : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatAmount(offer['amount']),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (paymentMethods.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: paymentMethods
                      .map((method) => _buildPaymentTag(method, isDark))
                      .toList(),
                ),
              ],
              Text(
                '$displayDelta ${priceType == 'fixed' ? offer['currency'] : ''} ${!isBuy ? 'below' : 'above'} market',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String? text, bool isDark,
      {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text ?? 'Select',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : SafeJetColors.lightText,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white : SafeJetColors.lightText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : SafeJetColors.lightText,
        ),
      ),
    );
  }

  void _showFilterOptions(
    BuildContext context,
    String title,
    List<dynamic> options,
    String? selectedValue,
    Function(String?) onSelect,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController searchController = TextEditingController();

    final isPaymentMethods = title.contains('Payment');
    List<dynamic> mappedOptions = options;

    if (isPaymentMethods) {
      mappedOptions = [
        {
          'id': null,
          'name': 'All Payment',
          'icon': 'payment',
        },
        ...mappedOptions,
      ];
    }

    List<dynamic> filteredOptions = List.from(mappedOptions);

    print('=== Filter Options Debug ===');
    print('Title: $title');
    print('Is Payment Methods: $isPaymentMethods');
    print('Selected Value: $selectedValue');
    print('Original Options: $options');
    print('Mapped Options: $mappedOptions');
    print('========================');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          print('Building bottom sheet...');
          print('Filtered Options: $filteredOptions');

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: isPaymentMethods
                            ? 'Search payment methods'
                            : 'Search crypto',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredOptions = options.where((option) {
                            if (isPaymentMethods) {
                              final name = option['name'] as String;
                              return name
                                  .toLowerCase()
                                  .contains(value.toLowerCase());
                            } else {
                              final symbol = option['symbol'] as String;
                              final name = option['name'] as String;
                              return symbol
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  name
                                      .toLowerCase()
                                      .contains(value.toLowerCase());
                            }
                          }).toList();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // List of options
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      print('Building item at index $index:');
                      print('Option data: $option');

                      if (isPaymentMethods) {
                        try {
                          final name = option['name'] as String;
                          final icon = option['icon'] as String? ?? 'payment';
                          final value = option[
                              'id']; // Don't cast to String, can be null for "All Payment"
                          final isSelected = value == selectedValue;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onSelect(
                                    value); // Can be null for "All Payment"
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Payment method icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _getPaymentMethodIcon(icon),
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Payment method name
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: SafeJetColors.secondaryHighlight,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error building payment method item');
                          print('Raw option data: $option');
                          return const SizedBox.shrink();
                        }
                      } else {
                        try {
                          final value = option['id'] as String;
                          final symbol = option['symbol'] as String;
                          final name = option['name'] as String;
                          print(
                              'Token - Symbol: $symbol, Name: $name, Value: $value');

                          final isSelected = value == selectedValue;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onSelect(value);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Token icon/letter
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: option['metadata']?['icon'] !=
                                                null
                                            ? Image.network(
                                                option['metadata']['icon'],
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Text(
                                                  symbol[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                symbol[0].toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Token details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            symbol,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (name.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Selection indicator
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: SafeJetColors.secondaryHighlight,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error building token item');
                          print('Raw option data: $option');
                          return const SizedBox
                              .shrink(); // Return empty widget on error
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getPaymentMethodIcon(String icon) {
    switch (icon.toLowerCase()) {
      // Make case-insensitive
      case 'bank':
        return Icons.account_balance;
      case 'qr_code':
        return Icons.qr_code;
      case 'payment':
        return Icons.payment;
      case 'mobile':
        return Icons.phone_android;
      case 'money':
        return Icons.attach_money;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _formatPrice(dynamic price, String currency) {
    if (price == null) return '$currency 0.00';

    // Convert to double and handle scientific notation
    final amount = double.tryParse(price.toString()) ?? 0.0;
    // Format with thousand separators and 2 decimal places
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return '$currency $formatted';
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // Add this widget to show when there are no offers
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Offers Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCardShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trader info row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Price and amount row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment methods
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to show the filter bottom sheet
  void _showFilterSheet(BuildContext context, bool isDark) {
    final TextEditingController minAmountController = TextEditingController();

    // Set initial value if it exists
    if (_minAmount != null) minAmountController.text = _minAmount.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Clear button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        if (_minAmount != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                minAmountController.clear();
                              });
                              this.setState(() {
                                _minAmount = null;
                              });
                              Navigator.pop(context);
                              _loadOffers(refresh: true);
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Minimum Amount Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum Amount (${_tokens.firstWhere((t) => t['id'] == _selectedTokenId, orElse: () => {
                            'symbol': ''
                          })['symbol']})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: minAmountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter minimum amount',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SafeJetColors.secondaryHighlight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final newMinAmount =
                          double.tryParse(minAmountController.text);
                      print('Setting min amount filter: $newMinAmount');

                      setState(() {
                        _minAmount = newMinAmount;
                      });
                      Navigator.pop(context);
                      _loadOffers(refresh: true);
                    },
                    child: const Text(
                      'Apply Filter',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<void> _showNoBalanceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get funding balances
    try {
      final balances =
          await _p2pService.getAvailableAssets(false); // false for sell
      final formattedBalances = balances.map((asset) {
        final amount =
            double.tryParse(asset['fundingBalance']?.toString() ?? '0') ?? 0;
        return '${amount.toStringAsFixed(2)} ${asset['symbol']}';
      }).join('\n');

      if (!mounted) return;

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
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
              ),
              title: Text(
                'Funding Balance Required',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: isDark
                                      ? SafeJetColors.warning
                                      : SafeJetColors.warning,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Funding Balances',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedBalances.isEmpty
                                          ? 'No assets in funding wallet'
                                          : formattedBalances,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sell Offer Requirements',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'To create a sell offer, you need to have assets in your funding wallet. This ensures that your offers are backed by actual assets and maintains a secure trading environment.',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SafeJetColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SafeJetColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: SafeJetColors.warning,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Transfer assets to your funding wallet to start selling.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700], // Lighter text color
                          ),
                          child: Text(
                            'Buy Instead',
                            style: TextStyle(
                              fontWeight: FontWeight.w500, // Slightly less bold
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeJetColors.secondaryHighlight,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add Funds',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      );
    } catch (e) {
      print('Error loading balances');
      // Show error snackbar if needed
    }
  }

  void _onOfferSelected(Map<String, dynamic> offer, bool isBuyTab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => P2POfferDetailsScreen(
          isBuy: isBuyTab,
          offerId: offer['id'],
          offerDetails: offer,
        ),
      ),
    );
  }
}
