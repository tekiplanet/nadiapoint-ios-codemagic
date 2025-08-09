import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../config/theme/theme_provider.dart';
import '../../models/withdrawal.dart';
import './withdrawal_details_screen.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  WithdrawalStatus? _selectedStatus;
  List<Withdrawal> _filteredHistory = [];
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _filteredHistory = withdrawalHistory;
    _searchController.addListener(_filterHistory);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: SafeJetColors.secondaryHighlight,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterHistory();
      });
    }
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistory = withdrawalHistory.where((withdrawal) {
        final matchesQuery = withdrawal.address.toLowerCase().contains(query) ||
            withdrawal.coin.toLowerCase().contains(query) ||
            withdrawal.network.toLowerCase().contains(query) ||
            withdrawal.txId.toLowerCase().contains(query);

        final matchesStatus =
            _selectedStatus == null || withdrawal.status == _selectedStatus;

        final matchesDate = _selectedDateRange == null ||
            (withdrawal.timestamp.isAfter(_selectedDateRange!.start) &&
                withdrawal.timestamp.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1))));

        return matchesQuery && matchesStatus && matchesDate;
      }).toList();
    });
  }

  Color _getStatusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.completed:
        return SafeJetColors.success;
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.processing:
        return Colors.blue;
      case WithdrawalStatus.failed:
        return SafeJetColors.error;
    }
  }

  String _getStatusText(WithdrawalStatus status) {
    return status.toString().split('.').last.toUpperCase();
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
        body: DecoratedBox(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Withdrawal History',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by address, coin, network...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedStatus == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = null;
                                  _filterHistory();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...WithdrawalStatus.values.map((status) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(_getStatusText(status)),
                                  selected: _selectedStatus == status,
                                  selectedColor:
                                      _getStatusColor(status).withOpacity(0.2),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedStatus =
                                          selected ? status : null;
                                      _filterHistory();
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        onPressed: _selectDateRange,
                        icon: Stack(
                          children: [
                            const Icon(Icons.calendar_month),
                            if (_selectedDateRange != null)
                              Positioned(
                                right: 0,
                                top: 0,
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
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final withdrawal = _filteredHistory[index];
                      return FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        delay: Duration(milliseconds: 100 * index),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WithdrawalDetailsScreen(
                                  withdrawal: withdrawal,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                  : SafeJetColors.lightCardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? SafeJetColors.primaryAccent
                                        .withOpacity(0.2)
                                    : SafeJetColors.lightCardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${withdrawal.amount} ${withdrawal.coin}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(withdrawal.status)
                                                .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(withdrawal.status),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              withdrawal.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Network: ${withdrawal.network}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : SafeJetColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'To: ${withdrawal.address}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : SafeJetColors
                                                  .lightTextSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: withdrawal.address));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Address copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy_rounded),
                                      iconSize: 16,
                                      color: SafeJetColors.secondaryHighlight,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                if (withdrawal.status ==
                                    WithdrawalStatus.completed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'TxID: ${withdrawal.txId}',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : SafeJetColors
                                                      .lightTextSecondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                text: withdrawal.txId));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'TxID copied to clipboard'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.copy_rounded),
                                          iconSize: 16,
                                          color:
                                              SafeJetColors.secondaryHighlight,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
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
        ),
      ),
    );
  }
}
