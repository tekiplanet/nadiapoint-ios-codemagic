import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../config/theme/theme_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/coin_selection_modal.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/network_selection_modal.dart';
import '../../models/coin.dart';
import 'package:get_it/get_it.dart';
import '../../services/wallet_service.dart';
import 'package:shimmer/shimmer.dart';

class DepositScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final bool showInUSD;
  final double userCurrencyRate;
  final String userCurrency;

  const DepositScreen({
    super.key,
    required this.asset,
    required this.showInUSD,
    required this.userCurrencyRate,
    required this.userCurrency,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _walletService = GetIt.I<WalletService>();
  String? _depositAddress;
  String? _networkVersion;
  bool _isLoading = false;
  late Coin _selectedCoin;
  late Network _selectedNetwork;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _initializeCoin();
  }

  void _initializeCoin() {
    final token = widget.asset['token'] as Map<String, dynamic>;
    final metadata = token['metadata'] as Map<String, dynamic>;

    // Initialize with current token data
    _selectedCoin = Coin(
      id: token['id'],
      symbol: token['symbol'],
      name: token['name'],
      networks: [
        Network(
          name: metadata['networks']?.first ?? 'mainnet',
          blockchain: token['blockchain'],
          version: token['networkVersion'],
          arrivalTime: '10-30 minutes',
          network: metadata['networks']?.first ?? 'mainnet',
        )
      ],
      iconUrl: metadata['icon'],
    );
    _selectedNetwork = _selectedCoin.networks[0];

    // Fetch complete network data
    _fetchNetworkVariants();
    _fetchDepositAddress();
  }

  Future<void> _fetchNetworkVariants() async {
    try {
      final token = widget.asset['token'] as Map<String, dynamic>;
      final response = await _walletService.getAvailableCoins();
      final availableCoins = response;

      final matchingCoin = availableCoins.firstWhere(
        (coin) =>
            coin.symbol.toUpperCase() ==
            token['baseSymbol'].toString().toUpperCase(),
        orElse: () => _selectedCoin,
      );

      if (mounted) {
        setState(() {
          _selectedCoin = matchingCoin;
          // Always use the first valid network from the backend's list
          _selectedNetwork = matchingCoin.networks[0];
        });
        // Fetch deposit address for the new default network
        await _fetchDepositAddress();
      }
    } catch (e) {
      debugPrint('Error fetching network variants');
      // Continue with current network data if fetch fails
    }
  }

  Future<void> _fetchDepositAddress() async {
    setState(() => _isLoading = true);
    try {
      final response = await _walletService.getDepositAddress(
        _selectedCoin.id,
        network: _selectedNetwork.network,
        blockchain: _selectedNetwork.blockchain,
        version: _selectedNetwork.version,
      );

      setState(() {
        _depositAddress = response['address'];
        _networkVersion = _selectedNetwork.version;
        _warningMessage =
            'Send only ${_selectedCoin.symbol} (${_selectedNetwork.version}) to this deposit address. ' +
                'Sending any other coin or token may result in permanent loss.';
      });
    } catch (e) {
      debugPrint('Error getting deposit address');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to get deposit address: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCoinSelection() async {
    final result = await Navigator.push<Coin>(
      context,
      MaterialPageRoute(
        builder: (context) => const CoinSelectionModal(),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCoin = result;
        // Reset to first available network
        _selectedNetwork = result.networks[0];
        _depositAddress = null; // Clear existing address
      });
      await _fetchDepositAddress(); // Fetch new address
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          onThemeToggle: () {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            themeProvider.toggleTheme();
          },
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? SafeJetColors.primaryBackground
                      : SafeJetColors.lightBackground,
                  isDark
                      ? SafeJetColors.primaryBackground.withOpacity(0.8)
                      : SafeJetColors.lightBackground.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coin Selection Card
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: GestureDetector(
                        onTap: _handleCoinSelection,
                        child: Container(
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
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: _selectedCoin.iconUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              _selectedCoin.iconUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _selectedCoin.iconUrl == null
                                    ? Center(
                                        child: Text(
                                          _selectedCoin.symbol[0],
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Coin Name and Symbol
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCoin.name,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedCoin.symbol,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : SafeJetColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.grey[400]
                                    : SafeJetColors.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Network Selection
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Select Network',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Network Card
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => NetworkSelectionModal(
                              networks: _selectedCoin.networks,
                              selectedNetwork: _selectedNetwork,
                              onNetworkSelected: (network) {
                                setState(() {
                                  _selectedNetwork = network;
                                  _fetchDepositAddress();
                                });
                                Navigator.pop(
                                    context); // Close the modal immediately after selection
                              },
                            ),
                          );
                        },
                        child: Container(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_selectedNetwork.blockchain.toUpperCase()} (${_selectedNetwork.version})',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Average arrival time: ${_selectedNetwork.arrivalTime}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey[400]
                                            : SafeJetColors.lightTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.grey[400]
                                    : SafeJetColors.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // QR Code Section
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                          children: [
                            // QR Code
                            _buildAddressSection(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Warning Notice
                    _buildWarningNotice(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningNotice() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SafeJetColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SafeJetColors.error.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: SafeJetColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _warningMessage ?? 'Loading warning...',
                style: TextStyle(
                  color: SafeJetColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _isLoading
        ? _buildShimmerLoading(isDark)
        : Column(
            children: [
              // QR Code
              if (_depositAddress != null)
                QrImageView(
                  data: _depositAddress!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              const SizedBox(height: 20),
              // Address with Copy/Share
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.black.withOpacity(0.2) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _depositAddress ?? 'Loading address...',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _depositAddress == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(
                                text: _depositAddress!,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy_rounded),
                      color: SafeJetColors.secondaryHighlight,
                    ),
                    IconButton(
                      onPressed: _depositAddress == null
                          ? null
                          : () {
                              Share.share(
                                'My ${widget.asset['token']['symbol']} deposit address:\n\n$_depositAddress\n\nNetwork: ${_selectedNetwork.name}${_networkVersion != null ? ' ($_networkVersion)' : ''}',
                                subject:
                                    'My ${widget.asset['token']['symbol']} Deposit Address',
                              );
                            },
                      icon: const Icon(Icons.share_rounded),
                      color: SafeJetColors.secondaryHighlight,
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Column(
        children: [
          // QR Code placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),
          // Address container placeholder
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Address text placeholder
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Copy button placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                // Share button placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
