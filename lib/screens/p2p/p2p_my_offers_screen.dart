import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../services/p2p_service.dart';
import '../../screens/settings/kyc_levels_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../screens/p2p/p2p_create_offer_screen.dart';

class P2PMyOffersScreen extends StatefulWidget {
  const P2PMyOffersScreen({super.key});

  @override
  State<P2PMyOffersScreen> createState() => _P2PMyOffersScreenState();
}

class _P2PMyOffersScreenState extends State<P2PMyOffersScreen> {
  final _p2pService = GetIt.I<P2PService>();
  bool _isLoading = false;
  List<Map<String, dynamic>> _buyOffers = [];
  List<Map<String, dynamic>> _sellOffers = [];
  
  // Add filter states
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000000); // Adjust max as needed
  List<String> _selectedPaymentMethods = [];
  
  // Add filter options
  final List<String> _statusOptions = ['All', 'Active', 'Pending', 'Completed', 'Cancelled'];
  final List<String> _dateRangeOptions = ['All', 'Last 7 days', 'Last 30 days', 'Custom'];

  // Add KYC state
  bool _hasKycAccess = false;
  bool _isCheckingKyc = true;

  @override
  void initState() {
    super.initState();
    _checkKycLevel();
  }

  Future<void> _checkKycLevel() async {
    try {
      final kycData = await _p2pService.getUserKycLevel();
      
      setState(() {
        _hasKycAccess = kycData['features']['canUseP2P'] ?? false;
        _isCheckingKyc = false;
      });

      if (_hasKycAccess) {
        _loadOffers();
      } else if (!mounted) return;
      else {
        // Show KYC dialog if no access
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog.fullscreen(
              child: Scaffold(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? SafeJetColors.primaryBackground : Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(context); // Go back to P2P screen
                    },
                  ),
                  title: Text(
                    'KYC Verification Required',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.black.withOpacity(0.3) 
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.verified_user,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? SafeJetColors.secondaryHighlight 
                                          : SafeJetColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Level',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.grey[400] 
                                                : Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          kycData['title'] ?? 'Unverified',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'To access P2P trading features, you need to complete your KYC verification. This helps us maintain a secure trading environment for all users.',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
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
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Pop dialog
                                Navigator.pop(context); // Go back to P2P screen
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Go Back',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Pop dialog
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KYCLevelsScreen(),
                                  ),
                                );
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
                                'Start Verification',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingKyc = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    try {
      final buyOffers = await _p2pService.getMyOffers(true);
      final sellOffers = await _p2pService.getMyOffers(false);
      
      setState(() {
        _buyOffers = buyOffers;
        _sellOffers = sellOffers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: SafeJetColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredOffers(bool isBuy) {
    final offers = isBuy ? _buyOffers : _sellOffers;
    
    return offers.where((offer) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final symbol = offer['symbol']?.toString().toLowerCase() ?? '';
        final amount = offer['amount']?.toString().toLowerCase() ?? '';
        final price = offer['price']?.toString().toLowerCase() ?? '';
        final currency = offer['currency']?.toString().toLowerCase() ?? '';
        
        if (!(symbol.contains(searchLower) ||
            amount.contains(searchLower) ||
            price.contains(searchLower) ||
            currency.contains(searchLower))) {
          return false;
        }
      }

      // Status filter
      if (_selectedStatus != 'All' && 
          offer['status']?.toString().toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // Date range filter
      if (_selectedDateRange != 'All') {
        final createdAt = DateTime.parse(offer['createdAt'].toString());
        final now = DateTime.now();
        switch (_selectedDateRange) {
          case 'Last 7 days':
            if (now.difference(createdAt).inDays > 7) return false;
            break;
          case 'Last 30 days':
            if (now.difference(createdAt).inDays > 30) return false;
            break;
        }
      }

      // Price range filter
      final price = double.tryParse(offer['price'].toString()) ?? 0;
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }

      // Payment methods filter
      if (_selectedPaymentMethods.isNotEmpty) {
        final offerMethods = (offer['paymentMethods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final hasSelectedMethod = offerMethods.any(
          (method) => _selectedPaymentMethods.contains(method['name'])
        );
        if (!hasSelectedMethod) return false;
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  SafeJetColors.primaryBackground,
                  SafeJetColors.secondaryBackground,
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[300]!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title and Reset
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'All';
                      _selectedDateRange = 'All';
                      _selectedPaymentMethods = [];
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: SafeJetColors.secondaryHighlight,
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          // Subtle separator instead of divider
          Container(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.03)
                : Colors.grey[200]!.withOpacity(0.5),
          ),
          // Status filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark 
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: _statusOptions.map((status) => 
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStatus = status;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _selectedStatus == status
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    SafeJetColors.secondaryHighlight.withOpacity(0.8),
                                    SafeJetColors.secondaryHighlight,
                                  ],
                                )
                              : null,
                          color: _selectedStatus != status
                              ? isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100]
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedStatus == status
                                ? SafeJetColors.secondaryHighlight
                                : isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[300]!.withOpacity(0.5),
                          ),
                          boxShadow: _selectedStatus == status
                              ? [
                                  BoxShadow(
                                    color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _selectedStatus == status
                                ? Colors.white
                                : isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                            fontWeight: _selectedStatus == status
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isCheckingKyc) {
      return Scaffold(
        appBar: P2PAppBar(
          title: 'My Offers',
          hasNotification: false,
          onThemeToggle: () {
            themeProvider.toggleTheme();
          },
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: P2PAppBar(
        title: 'My Offers',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadOffers,
        color: SafeJetColors.secondaryHighlight,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Search and filter row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search offers...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? Colors.white.withOpacity(0.05) 
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,  // Remove the border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,  // Remove the border in enabled state
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,  // Remove the border in focused state
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterBottomSheet,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BUY (${_buyOffers.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sell_outlined,
                              size: 20,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SELL (${_sellOffers.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    indicator: BoxDecoration(
                      color: SafeJetColors.secondaryHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.all(4),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOffersList(isDark, isBuy: true),
                    _buildOffersList(isDark, isBuy: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffersList(bool isDark, {required bool isBuy}) {
    final offers = _getFilteredOffers(isBuy);

    if (_isLoading) {
      return _buildLoadingShimmer(isDark);
    }

    if (offers.isEmpty) {
      return _buildEmptyState(isDark, isBuy);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _buildOfferCard(isDark, offer);
      },
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, bool isBuy) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBuy ? Icons.shopping_cart_outlined : Icons.sell_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${isBuy ? 'Buy' : 'Sell'} Offers Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${isBuy ? 'buy' : 'sell'} offers will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(bool isDark, Map<String, dynamic> offer) {
    final isBuy = offer['type'] == 'buy';
    final paymentMethods = (offer['paymentMethods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    // Format amount and price
    final amount = double.tryParse(offer['amount'].toString()) ?? 0;
    final formattedAmount = amount.toStringAsFixed(2);
    final price = double.tryParse(offer['price'].toString()) ?? 0;
    final formattedPrice = NumberFormat("#,##0.00").format(price);
    
    // Get token symbol from offer data
    final tokenSymbol = offer['token']?['symbol'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  SafeJetColors.primaryAccent.withOpacity(0.15),
                  SafeJetColors.primaryAccent.withOpacity(0.05),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? SafeJetColors.primaryAccent.withOpacity(0.2)
              : SafeJetColors.lightCardBorder.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to offer details
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$formattedAmount $tokenSymbol',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedPrice ${offer['currency']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => P2PCreateOfferScreen(
                                  offer: offer,
                                  selectedToken: offer['token'],
                                  isBuyOffer: offer['type'] == 'buy',
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadOffers();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isBuy
                                  ? [
                                      SafeJetColors.success.withOpacity(0.8),
                                      SafeJetColors.success,
                                    ]
                                  : [
                                      SafeJetColors.warning.withOpacity(0.8),
                                      SafeJetColors.warning,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isBuy ? SafeJetColors.success : SafeJetColors.warning)
                                    .withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            isBuy ? 'BUY' : 'SELL',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(offer['status'] ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (offer['status'] ?? '').toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(offer['status'] ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (paymentMethods.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: paymentMethods
                        .map((method) => _buildPaymentTag(
                              isDark,
                              method['name'] ?? 'Unknown',
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTag(bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.05),
                ]
              : [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SafeJetColors.success;
      case 'pending':
        return SafeJetColors.warning;
      case 'completed':
        return SafeJetColors.primary;
      default:
        return SafeJetColors.error;
    }
  }
} 