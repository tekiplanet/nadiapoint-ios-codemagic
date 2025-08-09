import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import '../../services/p2p_settings_service.dart';
import '../../widgets/timezone_selector_dialog.dart';

class P2PTradingPreferencesScreen extends StatefulWidget {
  const P2PTradingPreferencesScreen({super.key});

  @override
  State<P2PTradingPreferencesScreen> createState() => _P2PTradingPreferencesScreenState();
}

class _P2PTradingPreferencesScreenState extends State<P2PTradingPreferencesScreen> {
  final P2PSettingsService _settingsService = P2PSettingsService();
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = true;
  String _selectedCurrency = 'NGN';
  bool _autoAcceptOrders = false;
  bool _onlyVerifiedUsers = true;
  bool _showOnlineStatus = true;
  bool _enableInstantTrade = false;
  String _selectedTimeZone = 'UTC+1 (West Africa Time)';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load currencies
      final currencies = await _settingsService.getCurrencies();
      
      // Load user settings
      final settings = await _settingsService.getSettings();
      
      setState(() {
        _currencies = currencies;
        _selectedCurrency = settings['currency'] ?? 'NGN';
        _autoAcceptOrders = settings['autoAcceptOrders'] ?? false;
        _onlyVerifiedUsers = settings['onlyVerifiedUsers'] ?? true;
        _showOnlineStatus = settings['showOnlineStatus'] ?? true;
        _enableInstantTrade = settings['enableInstantTrade'] ?? false;
        _selectedTimeZone = settings['timezone'] ?? 'UTC+1 (West Africa Time)';
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      // Update UI immediately
      setState(() {
        switch (key) {
          case 'currency':
            _selectedCurrency = value;
            break;
          case 'autoAcceptOrders':
            _autoAcceptOrders = value;
            break;
          case 'onlyVerifiedUsers':
            _onlyVerifiedUsers = value;
            break;
          case 'showOnlineStatus':
            _showOnlineStatus = value;
            break;
          case 'enableInstantTrade':
            _enableInstantTrade = value;
            break;
          case 'timezone':
            _selectedTimeZone = value;
            break;
        }
      });

      // Send update to backend
      await _settingsService.updateSettings({key: value});
    } catch (e) {
      // If update fails, revert the UI
      setState(() {
        switch (key) {
          case 'currency':
            _selectedCurrency = _selectedCurrency;
            break;
          // ... similar for other settings
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  Widget _buildShimmerLoading(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Stats Card Shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) => 
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Settings Sections Shimmer
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              children: List.generate(3, (sectionIndex) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[800]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
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
                                      width: 180,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Section Content
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: List.generate(
                                sectionIndex == 0 ? 4 : (sectionIndex == 1 ? 4 : 1),
                                (index) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  height: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Trading Preferences',
        hasNotification: false,
        onThemeToggle: () => themeProvider.toggleTheme(),
      ),
      body: _isLoading 
        ? _buildShimmerLoading(isDark)
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
              const SizedBox(height: 16),
              // Stats Card
          FadeInDown(
            duration: const Duration(milliseconds: 600),
                child: _buildStatsCard(isDark),
              ),
              const SizedBox(height: 32),

              // Main Content Container
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  children: [
                    // Currency Section
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? SafeJetColors.primaryAccent.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildCurrencySection(isDark),
                      ),
                    ),

                    // Trading Settings
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? SafeJetColors.primaryAccent.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
            child: _buildTradingSettingsSection(isDark),
          ),
                    ),

                    // Time Zone Settings
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 600),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? SafeJetColors.primaryAccent.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildTimezoneSection(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SafeJetColors.secondaryHighlight,
            SafeJetColors.secondaryHighlight.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SafeJetColors.secondaryHighlight.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('30 Day Volume', '₦2.5M', Icons.bar_chart),
          _buildStatItem('Success Rate', '98%', Icons.verified),
          _buildStatItem('Total Trades', '145', Icons.swap_horiz),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Default Currency',
          'Set your preferred currency for P2P trading',
          Icons.currency_exchange,
          isDark,
        ),
        const SizedBox(height: 16),
        Container(
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
            children: _currencies.map((currency) {
              final isSelected = currency['code'] == _selectedCurrency;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _updateSetting('currency', currency['code']),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SafeJetColors.secondaryHighlight
                                : (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              currency['symbol'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency['code'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currency['name'],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : SafeJetColors.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: SafeJetColors.success,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTradingSettingsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Trading Settings',
          'Configure your trading preferences',
          Icons.settings_outlined,
          isDark,
        ),
        const SizedBox(height: 16),
        Container(
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
              _buildSettingTile(
                'Auto-accept Orders',
                'Automatically accept orders that match your preferences',
                Switch(
                  value: _autoAcceptOrders,
                  onChanged: (value) => _updateSetting('autoAcceptOrders', value),
                  activeColor: SafeJetColors.secondaryHighlight,
                ),
                isDark,
              ),
              _buildSettingTile(
                'Only Verified Users',
                'Only trade with KYC verified users',
                Switch(
                  value: _onlyVerifiedUsers,
                  onChanged: (value) => _updateSetting('onlyVerifiedUsers', value),
                  activeColor: SafeJetColors.secondaryHighlight,
                ),
                isDark,
              ),
              _buildSettingTile(
                'Show Online Status',
                'Let other traders see when you\'re online',
                Switch(
                  value: _showOnlineStatus,
                  onChanged: (value) => _updateSetting('showOnlineStatus', value),
                  activeColor: SafeJetColors.secondaryHighlight,
                ),
                isDark,
              ),
              _buildSettingTile(
                'Instant Trade',
                'Enable one-click trading for faster transactions',
                Switch(
                  value: _enableInstantTrade,
                  onChanged: (value) => _updateSetting('enableInstantTrade', value),
                  activeColor: SafeJetColors.secondaryHighlight,
                ),
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneSection(bool isDark) {
    Future<void> showTimezoneDialog() async {
      final selectedTimezone = await showDialog<String>(
        context: context,
        builder: (context) => TimezoneSelectorDialog(
          currentTimezone: _selectedTimeZone,
        ),
      );
      
      if (selectedTimezone != null) {
        setState(() => _isLoading = true);
        try {
          await _settingsService.updateSettings({
            'timezone': selectedTimezone,
          });
          await _loadData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    }

    return InkWell(
      onTap: showTimezoneDialog,
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
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Row(
                    children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                        Text(
                      'Time Zone',
                          style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.grey,
                  onPressed: showTimezoneDialog,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                _selectedTimeZone,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SafeJetColors.secondaryHighlight,
                  SafeJetColors.secondaryHighlight.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
          ),
          child: Icon(
            icon,
              color: Colors.black,
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
                  fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark 
                        ? Colors.grey[400] 
                        : SafeJetColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    Widget trailing,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
} 