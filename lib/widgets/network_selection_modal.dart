import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../models/coin.dart';

class NetworkSelectionModal extends StatelessWidget {
  final List<Network> networks;
  final Network selectedNetwork;
  final Function(Network) onNetworkSelected;

  const NetworkSelectionModal({
    super.key,
    required this.networks,
    required this.selectedNetwork,
    required this.onNetworkSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? SafeJetColors.primaryBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Select Network',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: networks.length,
            itemBuilder: (context, index) {
              final network = networks[index];
              final isSelected = network == selectedNetwork;

              return InkWell(
                onTap: () {
                  onNetworkSelected(network);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100])
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${network.blockchain.toUpperCase()} (${network.version})' +
                              (network.network == 'testnet' ? ' - TESTNET' : ''),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Average arrival time: ${network.arrivalTime}',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SafeJetColors.success.withOpacity(0.1)
                              : SafeJetColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSelected ? 'Selected' : 'Active',
                          style: TextStyle(
                            color: isSelected
                                ? SafeJetColors.success
                                : SafeJetColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 