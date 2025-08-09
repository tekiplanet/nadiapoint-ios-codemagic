import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';
import '../../../config/theme/colors.dart';
import '../../../widgets/candlestick_chart.dart';
import '../../../widgets/order_book.dart';
import '../../../widgets/trade_form.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../widgets/trading_pair_selector.dart';
import '../../../screens/p2p/p2p_screen.dart';

class TradeTab extends StatefulWidget {
  const TradeTab({super.key});

  @override
  State<TradeTab> createState() => _TradeTabState();
}

class _TradeTabState extends State<TradeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _timeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];
  int _selectedTimeframe = 3; // Default to 1h
  final PanelController _panelController = PanelController();
  
  // Coming soon feature flag
  final bool comingSoon = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Stack(
        children: [
          // Background when comingSoon is true but no original content is visible
          if (comingSoon)
            Container(
              color: isDark ? SafeJetColors.primaryBackground : SafeJetColors.lightBackground,
            ),
          
          // Original content - only shown when comingSoon is false
          if (!comingSoon)
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 60,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              backdropEnabled: true,
              backdropColor: Colors.black,
              backdropOpacity: 0.5,
              color: isDark 
                  ? SafeJetColors.primaryBackground
                  : SafeJetColors.lightBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              panel: _buildOrderBookPanel(isDark, theme),
              body: Column(
                children: [
                  // Trading Pair Header (Fixed at top)
                  _buildTradingPairHeader(theme, isDark),
                  
                  // Scrollable Content
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        // Timeframe Selection
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: _buildTimeframeSelector(isDark),
                        ),

                        // Chart
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            height: 250,
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                  : SafeJetColors.lightCardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                                    : SafeJetColors.lightCardBorder,
                              ),
                            ),
                            child: const CandlestickChart(),
                          ),
                        ),

                        // Trading Interface
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            height: 600,
                            margin: EdgeInsets.fromLTRB(
                              16, 
                              0, 
                              16, 
                              MediaQuery.of(context).size.height * 0.15, // 10% of screen height for bottom margin
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? SafeJetColors.primaryAccent.withOpacity(0.1)
                                  : SafeJetColors.lightCardBackground,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              border: Border.all(
                                color: isDark
                                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                                    : SafeJetColors.lightCardBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Buy/Sell Tabs
                                TabBar(
                                  controller: _tabController,
                                  tabs: [
                                    Tab(text: 'Buy BTC'),
                                    Tab(text: 'Sell BTC'),
                                  ],
                                  labelColor: SafeJetColors.secondaryHighlight,
                                  unselectedLabelColor: isDark 
                                      ? Colors.grey[400]
                                      : SafeJetColors.lightTextSecondary,
                                  indicatorColor: SafeJetColors.secondaryHighlight,
                                ),
                                
                                // Trading Form
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: const [
                                      TradeForm(isBuy: true),
                                      TradeForm(isBuy: false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Keep the bottom padding
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Coming soon overlay - displayed on top of everything when comingSoon is true
          if (comingSoon)
            _buildComingSoonOverlay(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTradingPairHeader(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () async {
        // Show trading pair selector
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TradingPairSelector(),
        );
        
        // Handle selected pair
        if (result != null) {
          // TODO: Update trading pair
          print(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark 
              ? SafeJetColors.primaryBackground
              : SafeJetColors.lightBackground,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SafeJetColors.secondaryHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.currency_bitcoin,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BTC/USDT',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$42,384.21',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: SafeJetColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SafeJetColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+2.34%',
                        style: TextStyle(
                          color: SafeJetColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeframes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedTimeframe;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeframe = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? SafeJetColors.secondaryHighlight
                    : (isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.1)
                        : SafeJetColors.lightCardBackground),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? SafeJetColors.secondaryHighlight
                      : (isDark
                          ? SafeJetColors.primaryAccent.withOpacity(0.2)
                          : SafeJetColors.lightCardBorder),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _timeframes[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.white : SafeJetColors.lightText),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderBookPanel(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? SafeJetColors.primaryAccent.withOpacity(0.2)
                    : SafeJetColors.lightCardBorder,
              ),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Book',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildPrecisionButton('0.1', true, isDark),
                      const SizedBox(width: 8),
                      _buildPrecisionButton('0.01', false, isDark),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Order Book Content
        Expanded(
          child: OrderBook(),
        ),
      ],
    );
  }

  Widget _buildPrecisionButton(String text, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? SafeJetColors.secondaryHighlight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected
              ? Colors.black
              : (isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Build the coming soon overlay
  Widget _buildComingSoonOverlay(BuildContext context, bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF121212),
                    const Color(0xFF0A0A0A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8F8F8),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background shapes for visual interest
              Positioned(
                top: -50,
                right: -20,
                child: _buildAnimatedShape(
                  isDark, 
                  size: 200, 
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.05),
                  duration: const Duration(seconds: 15),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _buildAnimatedShape(
                  isDark, 
                  size: 180, 
                  color: SafeJetColors.secondaryHighlight.withOpacity(0.07),
                  duration: const Duration(seconds: 20),
                  isReversed: true,
                ),
              ),
              
              // Floating animated coins
              ..._buildFloatingCoins(isDark),
              
              // Main content
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Logo animation
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer animated glow
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.5, end: 0.7),
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          SafeJetColors.secondaryHighlight.withOpacity(0.6),
                                          SafeJetColors.secondaryHighlight.withOpacity(0.1),
                                          SafeJetColors.secondaryHighlight.withOpacity(0.0),
                                        ],
                                        stops: const [0.2, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(),
                            ),
                            
                            // Second animated glow
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.8, end: 0.9),
                              duration: const Duration(seconds: 3),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          SafeJetColors.secondaryHighlight.withOpacity(0.4),
                                          SafeJetColors.secondaryHighlight.withOpacity(0.05),
                                          SafeJetColors.secondaryHighlight.withOpacity(0.0),
                                        ],
                                        stops: const [0.2, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(),
                            ),
                            
                            // Core circle with icon
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF242E15),
                                boxShadow: [
                                  BoxShadow(
                                    color: SafeJetColors.secondaryHighlight.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.8, end: 1.2),
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.easeInOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Icon(
                                        Icons.rocket_launch_rounded,
                                        color: SafeJetColors.secondaryHighlight,
                                        size: 60,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // Animated orbit
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 2 * 3.14159),
                              duration: const Duration(seconds: 8),
                              curve: Curves.linear,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    70 * cos(value),
                                    70 * sin(value),
                                  ),
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SafeJetColors.secondaryHighlight,
                                      boxShadow: [
                                        BoxShadow(
                                          color: SafeJetColors.secondaryHighlight.withOpacity(0.5),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Title with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 300),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              SafeJetColors.secondaryHighlight,
                              const Color(0xFFEDC04C),
                            ],
                            stops: const [0.3, 0.7],
                          ).createShader(bounds),
                          child: const Text(
                            "Spot & Futures Trading",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // This is filtered through the shader mask
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Coming soon badge with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                SafeJetColors.secondaryHighlight,
                                const Color(0xFFEDC04C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: SafeJetColors.secondaryHighlight.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing animation dot
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.5, end: 1.0),
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return AnimatedOpacity(
                                    opacity: value,
                                    duration: Duration.zero,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "COMING SOON",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description text with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          "We're putting the finishing touches on our advanced trading platform. "
                          "You'll be the first to know when it launches!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            height: 1.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Divider with text
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 600),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark ? Colors.transparent : Colors.grey[300]!.withOpacity(0.1),
                                      isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.grey[900] 
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.grey[800]! 
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                "MEANWHILE",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                      isDark ? Colors.transparent : Colors.grey[300]!.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // P2P suggestion text with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 700),
                        child: Text(
                          "Why not try our thriving P2P marketplace?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // P2P benefits text with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 800),
                        child: Text(
                          "Connect directly with hundreds of traders, enjoy flexible payment options, and trade your assets with zero platform fees!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // CTA button with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 900),
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to P2P screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const P2PScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  SafeJetColors.secondaryHighlight,
                                  const Color(0xFFEDC04C),
                                  SafeJetColors.secondaryHighlight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: SafeJetColors.secondaryHighlight.withOpacity(0.3),
                                  offset: const Offset(0, 5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Explore P2P Marketplace",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Get notified text with animation
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 1000),
                        child: Text(
                          "We'll notify you as soon as trading is live!",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to create animated background shapes
  Widget _buildAnimatedShape(bool isDark, {
    required double size, 
    required Color color, 
    required Duration duration,
    bool isReversed = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159),
      duration: duration,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: isReversed ? -value : value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size / 3),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build floating animated coins
  List<Widget> _buildFloatingCoins(bool isDark) {
    final random = Random();
    final coinIcons = [
      Icons.monetization_on_rounded,
      Icons.currency_bitcoin_rounded,
      Icons.currency_exchange_rounded,
      Icons.attach_money_rounded,
    ];
    
    return List.generate(8, (index) {
      // Random positions
      final top = random.nextDouble() * 700;
      final left = random.nextDouble() * 400;
      
      // Random sizes between 16 and 26
      final size = 16.0 + random.nextDouble() * 10.0;
      
      // Random animation durations between 15-40 seconds
      final durationSeconds = 15 + random.nextInt(25);
      
      // Random delay so they don't all animate at the same time
      final delaySeconds = random.nextInt(10);
      
      // Random Y movement distance
      final moveY = 50.0 + random.nextDouble() * 100;
      
      // Random coin icon
      final coinIcon = coinIcons[random.nextInt(coinIcons.length)];
      
      // Subtle gold colors for the coins
      final coinColor = [
        const Color(0xFFFFD700),  // Gold
        const Color(0xFFFFC125),  // Goldenrod
        const Color(0xFFEDC04C),  // Light gold
        SafeJetColors.secondaryHighlight,
      ][random.nextInt(4)];
      
      return Positioned(
        top: top,
        left: left,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(seconds: durationSeconds),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            // Float up and down in a sine wave pattern
            final yOffset = sin(value * 2 * pi) * moveY;
            
            // Slight rotation back and forth
            final rotation = sin(value * 2 * pi) * 0.2;
            
            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Transform.rotate(
                angle: rotation,
                child: Opacity(
                  opacity: 0.2 + (random.nextDouble() * 0.3),
                  child: Icon(
                    coinIcon,
                    size: size,
                    color: coinColor,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
} 