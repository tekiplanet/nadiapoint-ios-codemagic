import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../models/recent_address.dart';
import '../services/address_service.dart';

class AddressBookModal extends StatefulWidget {
  final String selectedCoin;
  final String selectedNetwork;
  final AddressService addressService;

  const AddressBookModal({
    super.key,
    required this.selectedCoin,
    required this.selectedNetwork,
    required this.addressService,
  });

  @override
  State<AddressBookModal> createState() => _AddressBookModalState();
}

class _AddressBookModalState extends State<AddressBookModal> {
  List<RecentAddress> _recentAddresses = [];
  List<RecentAddress> _whitelistedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    setState(() {
      _recentAddresses = widget.addressService.getRecentAddresses()
          .where((a) => a.coin == widget.selectedCoin && a.network == widget.selectedNetwork)
          .toList();
      
      _whitelistedAddresses = widget.addressService.getWhitelistedAddresses()
          .where((a) => a.coin == widget.selectedCoin && a.network == widget.selectedNetwork)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      constraints: BoxConstraints(
        maxHeight: size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Address Book',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_whitelistedAddresses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Whitelisted Addresses',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _whitelistedAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _whitelistedAddresses[index];
                        return _AddressItem(
                          address: address,
                          onTap: () => Navigator.pop(context, address),
                          onLongPress: () async {
                            // Show remove from whitelist dialog
                            final remove = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove from Whitelist'),
                                content: const Text('Are you sure you want to remove this address from your whitelist?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: SafeJetColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (remove == true) {
                              await widget.addressService.removeFromWhitelist(address.address);
                              setState(() => _loadAddresses());
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_recentAddresses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Addresses',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentAddresses.length,
                      itemBuilder: (context, index) {
                        final address = _recentAddresses[index];
                        return _AddressItem(
                          address: address,
                          onTap: () => Navigator.pop(context, address),
                          onLongPress: () async {
                            // Show add to whitelist dialog
                            final add = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Add to Whitelist'),
                                content: const Text('Would you like to add this address to your whitelist?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            );

                            if (add == true) {
                              await widget.addressService.addToWhitelist(address);
                              setState(() => _loadAddresses());
                            }
                          },
                        );
                      },
                    ),
                  ],
                  if (_recentAddresses.isEmpty && _whitelistedAddresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No saved addresses'),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressItem extends StatelessWidget {
  final RecentAddress address;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AddressItem({
    required this.address,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.label != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        address.label!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    address.address,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
} 