import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';
import 'fiat_wallet_details_screen.dart';
import 'package:intl/intl.dart';

class AllWalletsModal extends StatefulWidget {
  final List<Map<String, dynamic>> wallets;

  const AllWalletsModal({super.key, required this.wallets});

  @override
  State<AllWalletsModal> createState() => _AllWalletsModalState();
}

class _AllWalletsModalState extends State<AllWalletsModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredWallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredWallets = widget.wallets;
    _searchController.addListener(_filterWallets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWallets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWallets = widget.wallets;
      } else {
        _filteredWallets = widget.wallets.where((wallet) {
          final currency = wallet['currency'];
          final currencyName = currency['name']?.toString().toLowerCase() ?? '';
          final currencyCode = currency['code']?.toString().toLowerCase() ?? '';
          final currencySymbol =
              currency['symbol']?.toString().toLowerCase() ?? '';

          return currencyName.contains(query) ||
              currencyCode.contains(query) ||
              currencySymbol.contains(query);
        }).toList();
      }
    });
  }

  Color _getWalletPrimaryColor(Map<String, dynamic> wallet) {
    final currency = wallet['currency'];
    final colorHex = currency['primary_color']?.toString() ?? '#6366F1';
    return _hexToColor(colorHex);
  }

  Color _getWalletSecondaryColor(Map<String, dynamic> wallet) {
    final currency = wallet['currency'];
    final colorHex = currency['secondary_color']?.toString() ?? '#8B5CF6';
    return _hexToColor(colorHex);
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return SafeJetColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SafeJetColors.success;
      case 'pending':
        return Colors.orange;
      case 'disabled':
      case 'suspended':
        return SafeJetColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: isDark
            ? SafeJetColors.primaryBackground
            : SafeJetColors.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
          ),
          leading: IconButton(
            icon: Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'All Fiat Wallets',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            Text(
              '${_filteredWallets.length} wallets',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Material(
                elevation: isDark ? 0 : 2,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? SafeJetColors.secondaryBackground.withOpacity(0.85)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.13)
                          : SafeJetColors.lightCardBorder,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    cursorColor: SafeJetColors.secondaryHighlight,
                    decoration: InputDecoration(
                      hintText: 'Search wallets...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? SafeJetColors.secondaryHighlight.withOpacity(0.8)
                            : SafeJetColors.secondaryHighlight,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 16,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),

            // Wallet List
            Expanded(
              child: _filteredWallets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No wallets found'
                                : 'No wallets match your search',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      itemCount: _filteredWallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _filteredWallets[index];
                        final currencyField = wallet['currency'];
                        String currency;
                        String symbol;
                        String? primaryColorHex;
                        String? secondaryColorHex;
                        if (currencyField is Map<String, dynamic>) {
                          currency = currencyField['code'] as String? ?? '';
                          symbol = currencyField['symbol'] as String? ?? '';
                          primaryColorHex =
                              currencyField['primaryColor'] as String? ??
                                  currencyField['primary_color'] as String?;
                          secondaryColorHex =
                              currencyField['secondaryColor'] as String? ??
                                  currencyField['secondary_color'] as String?;
                        } else if (currencyField is String) {
                          currency = currencyField;
                          symbol = '';
                          primaryColorHex = null;
                          secondaryColorHex = null;
                        } else {
                          currency = '';
                          symbol = '';
                          primaryColorHex = null;
                          secondaryColorHex = null;
                        }
                        if (symbol.isEmpty && currency.isNotEmpty) {
                          switch (currency.toUpperCase()) {
                            case 'USD':
                              symbol = ' 24';
                              break;
                            case 'EUR':
                              symbol = '€';
                              break;
                            case 'NGN':
                              symbol = '₦';
                              break;
                            case 'GBP':
                              symbol = '£';
                              break;
                            default:
                              symbol = currency;
                          }
                        }
                        Color parseColor(String? hex, Color fallback) {
                          if (hex == null || hex.isEmpty) return fallback;
                          try {
                            return Color(
                                int.parse(hex.replaceFirst('#', '0xff')));
                          } catch (_) {
                            return fallback;
                          }
                        }

                        final primaryColor = parseColor(
                            primaryColorHex, const Color(0xFF1A237E));
                        final secondaryColor = parseColor(
                            secondaryColorHex, const Color(0xFF0D47A1));
                        final balance = double.tryParse(
                                wallet['balance']?.toString() ??
                                    wallet['available_balance']?.toString() ??
                                    '0.0') ??
                            0.0;
                        final status =
                            (wallet['status'] as String?)?.toLowerCase() ??
                                'active';
                        List<Color> gradientColors;
                        if (status == 'pending') {
                          gradientColors = [
                            const Color(0xFFFFC107),
                            const Color(0xFFFF9800)
                          ];
                        } else if (status == 'suspended') {
                          gradientColors = [
                            Colors.grey.shade600,
                            Colors.grey.shade400
                          ];
                        } else {
                          gradientColors = [primaryColor, secondaryColor];
                        }
                        Color badgeColor;
                        String badgeText;
                        if (status == 'pending') {
                          badgeColor = const Color(0xFFFFC107);
                          badgeText = 'Pending';
                        } else if (status == 'suspended') {
                          badgeColor = Colors.grey;
                          badgeText = 'Suspended';
                        } else {
                          badgeColor = Colors.green;
                          badgeText = 'Active';
                        }
                        final isClickable = status == 'active';
                        return GestureDetector(
                          onTap: isClickable
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FiatWalletDetailsScreen(
                                        wallet: wallet,
                                        wallets: widget.wallets,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            constraints: const BoxConstraints(
                                minHeight: 90, maxHeight: 110),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.13),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Currency symbol (top right)
                                  Positioned(
                                    right: 16,
                                    top: 10,
                                    child: Text(
                                      symbol,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Status badge (bottom right)
                                  Positioned(
                                    right: 16,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Decorative circles
                                  Positioned(
                                    right: -40,
                                    top: -40,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.09),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -20,
                                    bottom: 30,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.09),
                                      ),
                                    ),
                                  ),
                                  // Wallet info
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 18, 16, 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              currencyField['name'] ?? currency,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              currency,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.85),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '$symbol${NumberFormat('#,##0.00').format(balance)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
