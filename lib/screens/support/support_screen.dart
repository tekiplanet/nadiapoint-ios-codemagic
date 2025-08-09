import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/colors.dart';
import '../../services/home_service.dart';
import 'package:shimmer/shimmer.dart';
import 'webview_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _homeService = HomeService();
  Map<String, dynamic>? _contactInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final info = await _homeService.getContactInfo();
      if (mounted) {
        setState(() {
          _contactInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: SafeJetColors.secondaryHighlight,
        backgroundColor: isDark ? SafeJetColors.primaryBackground : Colors.white,
        onRefresh: _loadContactInfo,
        child: _isLoading
            ? _buildLoadingState(isDark)
            : _error != null
                ? _buildErrorState()
                : _buildContent(isDark),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (index) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: SafeJetColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load support information',
            style: TextStyle(
              color: SafeJetColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadContactInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeJetColors.secondaryHighlight,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_contactInfo == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Support Actions
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: _buildQuickSupportActions(isDark),
        ),
        const SizedBox(height: 24),

        // Contact Information
        FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: _buildContactInformation(isDark),
        ),
        const SizedBox(height: 24),

        // Support Resources
        FadeInDown(
          duration: const Duration(milliseconds: 1000),
          child: _buildSupportResources(isDark),
        ),
        const SizedBox(height: 24),

        // Social Media
        FadeInDown(
          duration: const Duration(milliseconds: 1200),
          child: _buildSocialMedia(isDark),
        ),
        const SizedBox(height: 24),

        // Company Address
        FadeInDown(
          duration: const Duration(milliseconds: 1400),
          child: _buildCompanyAddress(isDark),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQuickSupportActions(bool isDark) {
    final emergencyContact = _contactInfo!['emergencyContact'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Support',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Emergency',
                Icons.emergency_rounded,
                SafeJetColors.error,
                isDark,
                onTap: () => launchUrl(Uri.parse('tel:${emergencyContact['phone']}')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Live Chat',
                Icons.chat_rounded,
                SafeJetColors.secondaryHighlight,
                isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(
                      url: _contactInfo!['supportLinks']['liveChat'],
                      title: 'Live Chat',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'FAQ',
                Icons.help_rounded,
                SafeJetColors.success,
                isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(
                      url: _contactInfo!['supportLinks']['faq'],
                      title: 'FAQ',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInformation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  SafeJetColors.secondaryHighlight.withOpacity(0.15),
                  SafeJetColors.primaryAccent.withOpacity(0.05),
                ]
              : [
                  SafeJetColors.lightCardBackground,
                  SafeJetColors.lightCardBackground,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SafeJetColors.secondaryHighlight.withOpacity(0.2)
              : SafeJetColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.email_rounded,
            'Email',
            _contactInfo!['contactEmail'],
            isDark,
            onTap: () => launchUrl(Uri.parse('mailto:${_contactInfo!['contactEmail']}')),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.phone_rounded,
            'Support Phone',
            _contactInfo!['supportPhone'],
            isDark,
            onTap: () => launchUrl(Uri.parse('tel:${_contactInfo!['supportPhone']}')),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.support_agent_rounded,
            '24/7 Support',
            _contactInfo!['emergencyContact']['supportLine'],
            isDark,
            onTap: () => launchUrl(Uri.parse('tel:${_contactInfo!['emergencyContact']['supportLine']}')),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportResources(bool isDark) {
    final supportLinks = _contactInfo!['supportLinks'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildResourceCard(
          'Help Center',
          'Get detailed guides and tutorials',
          Icons.school_rounded,
          isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: supportLinks['helpCenter'],
                title: 'Help Center',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Support Tickets',
          'Create a ticket for specific issues',
          Icons.confirmation_number_rounded,
          isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: supportLinks['supportTickets'],
                title: 'Submit Ticket',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Knowledge Base',
          'Browse through our documentation',
          Icons.library_books_rounded,
          isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: supportLinks['knowledgeBase'],
                title: 'Knowledge Base',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMedia(bool isDark) {
    final socialMedia = _contactInfo!['socialMedia'] as Map<String, dynamic>;
    final activeSocialMedia = socialMedia.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    if (activeSocialMedia.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect With Us',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: activeSocialMedia.map((entry) {
            final platform = entry.key;
            final url = entry.value;
            
            IconData icon;
            switch (platform) {
              case 'facebook':
                icon = Icons.facebook_rounded;
                break;
              case 'twitter':
                icon = Icons.flutter_dash_rounded;
                break;
              case 'instagram':
                icon = Icons.camera_alt_rounded;
                break;
              case 'telegram':
                icon = Icons.send_rounded;
                break;
              case 'discord':
                icon = Icons.discord;
                break;
              case 'youtube':
                icon = Icons.youtube_searched_for_rounded;
                break;
              default:
                icon = Icons.link_rounded;
            }

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebViewScreen(
                    url: url,
                    title: platform,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? SafeJetColors.primaryAccent.withOpacity(0.1)
                      : SafeJetColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? SafeJetColors.primaryAccent.withOpacity(0.2)
                        : SafeJetColors.lightCardBorder,
                  ),
                ),
                child: Icon(
                  icon,
                  color: SafeJetColors.secondaryHighlight,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompanyAddress(bool isDark) {
    final address = _contactInfo!['companyAddress'] as Map<String, dynamic>;
    final hasAddress = address.values.any((value) => value.isNotEmpty);

    if (!hasAddress) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
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
            children: [
              Icon(
                Icons.location_on_rounded,
                color: SafeJetColors.secondaryHighlight,
              ),
              const SizedBox(width: 8),
              Text(
                'Company Address',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${address['street']}\n'
            '${address['city']}, ${address['state']} ${address['postalCode']}\n'
            '${address['country']}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color accentColor,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(isDark ? 0.15 : 0.1),
              accentColor.withOpacity(isDark ? 0.05 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.2 : 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: SafeJetColors.secondaryHighlight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    String title,
    String description,
    IconData icon,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SafeJetColors.secondaryHighlight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: SafeJetColors.secondaryHighlight,
                size: 24,
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
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 