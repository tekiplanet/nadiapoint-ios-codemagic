import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme/colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Trade Crypto\nSecurely',
      'subtitle': 'Buy and sell cryptocurrencies with confidence using advanced security features',
      'icon': Icons.security_rounded,
      'secondaryIcons': [
        Icons.lock_outline,
        Icons.verified_user_outlined,
        Icons.shield_outlined,
      ],
      'iconColor': SafeJetColors.secondaryHighlight,
    },
    {
      'title': 'P2P Trading\nMade Easy',
      'subtitle': 'Trade directly with other users using your preferred payment methods',
      'icon': Icons.swap_horiz_rounded,
      'secondaryIcons': [
        Icons.people_outline,
        Icons.currency_exchange,
        Icons.handshake_outlined,
      ],
      'iconColor': SafeJetColors.success,
    },
    {
      'title': 'Instant\nDeposits',
      'subtitle': 'Fund your account instantly using multiple payment options',
      'icon': Icons.account_balance_wallet_rounded,
      'secondaryIcons': [
        Icons.credit_card_outlined,
        Icons.bolt_outlined,
        Icons.payments_outlined,
      ],
      'iconColor': SafeJetColors.warning,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SafeJetColors.primaryBackground,
              SafeJetColors.secondaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main icon with pulsing animation
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: _pages[index]['iconColor'].withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _pages[index]['iconColor'].withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _pages[index]['icon'],
                      size: 80,
                      color: _pages[index]['iconColor'],
                    ),
                  ),
                ),
                // Floating secondary icons
                ..._buildFloatingIcons(index),
              ],
            ),
          ),
          const SizedBox(height: 40),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Text(
              _pages[index]['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Text(
              _pages[index]['subtitle']!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingIcons(int index) {
    final secondaryIcons = _pages[index]['secondaryIcons'] as List<IconData>;
    final positions = [
      const Alignment(-0.8, -0.3),
      const Alignment(0.8, -0.3),
      const Alignment(0, 0.8),
    ];

    return List.generate(
      secondaryIcons.length,
      (i) => Positioned.fill(
        child: Align(
          alignment: positions[i],
          child: FadeInDown(
            delay: Duration(milliseconds: 200 * (i + 1)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pages[index]['iconColor'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pages[index]['iconColor'].withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                secondaryIcons[i],
                size: 24,
                color: _pages[index]['iconColor'],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            SafeJetColors.primaryBackground.withOpacity(0.8),
            SafeJetColors.primaryBackground,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: _currentPage == index ? 32 : 12,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _pages[_currentPage]['iconColor']
                      : _pages[_currentPage]['iconColor'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              if (_currentPage < _pages.length - 1) ...[
                TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),
                _buildNextButton(),
              ] else
                Expanded(child: _buildGetStartedButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _pages[_currentPage]['iconColor'],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Next',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: _completeOnboarding,
      style: ElevatedButton.styleFrom(
        backgroundColor: _pages[_currentPage]['iconColor'],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Get Started',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 