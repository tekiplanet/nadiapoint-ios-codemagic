import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../services/wallet_service.dart';
import 'package:get_it/get_it.dart';

class SavedAddressesModal extends StatefulWidget {
  final String blockchain;
  final String network;

  const SavedAddressesModal({
    super.key,
    required this.blockchain,
    required this.network,
  });

  @override
  State<SavedAddressesModal> createState() => _SavedAddressesModalState();
}

class _SavedAddressesModalState extends State<SavedAddressesModal> {
  final _walletService = GetIt.I<WalletService>();
  bool _isLoading = true;
  List<dynamic> _addresses = [];
  List<dynamic> _filteredAddresses = [];
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _searchController.addListener(_filterAddresses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAddresses() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredAddresses = _addresses.where((address) {
        final name = (address['name'] ?? '').toString().toLowerCase();
        final addressText = address['address'].toString().toLowerCase();
        final memo = (address['memo'] ?? '').toString().toLowerCase();
        final tag = (address['tag'] ?? '').toString().toLowerCase();
        
        return name.contains(searchTerm) ||
               addressText.contains(searchTerm) ||
               memo.contains(searchTerm) ||
               tag.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() => _isLoading = true);
      final addresses = await _walletService.getAddressBook();
      final filteredAddresses = addresses.where((address) =>
        address['blockchain'].toString().toLowerCase() == widget.blockchain.toLowerCase() &&
        address['network'].toString().toLowerCase() == widget.network.toLowerCase()
      ).toList();
      setState(() {
        _addresses = filteredAddresses;
        _filteredAddresses = filteredAddresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load addresses';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground;
    final cardColor = isDark ? SafeJetColors.secondaryBackground : SafeJetColors.lightSecondaryBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Modern header with search bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Addresses',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : SafeJetColors.lightText,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? SafeJetColors.secondaryHighlight : SafeJetColors.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search addresses',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Address list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDark ? SafeJetColors.secondaryHighlight : SafeJetColors.primaryAccent,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, 
                              size: 48, 
                              color: SafeJetColors.error
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: SafeJetColors.error,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredAddresses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 48,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved addresses found',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _filteredAddresses.length,
                            itemBuilder: (context, index) {
                              final address = _filteredAddresses[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.pop(context, address),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isDark 
                                                ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
                                                : SafeJetColors.primaryAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.account_balance_wallet,
                                              color: isDark 
                                                ? SafeJetColors.secondaryHighlight
                                                : SafeJetColors.primaryAccent,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                                Text(
                                                  address['name'] ?? 'Unnamed Address',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : SafeJetColors.lightText,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                      Text(
                                        address['address'],
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                      ),
                                                if (address['memo'] != null || address['tag'] != null)
                                                  const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                      if (address['memo'] != null)
                                                      Container(
                                                        margin: const EdgeInsets.only(right: 8),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isDark 
                                                            ? Colors.black.withOpacity(0.3)
                                                            : Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                          'Memo: ${address['memo']}',
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                          ),
                                          ),
                                        ),
                                      if (address['tag'] != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isDark 
                                                            ? Colors.black.withOpacity(0.3)
                                                            : Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                          'Tag: ${address['tag']}',
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                    ),
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