import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/theme_provider.dart';
import '../../widgets/p2p_app_bar.dart';
import 'identity_verification_screen.dart';
import '../../providers/kyc_provider.dart';
import '../../models/kyc_level.dart';
import 'phone_verification_screen.dart';
import 'advanced_verification_screen.dart';
import 'package:shimmer/shimmer.dart';

class KYCLevelsScreen extends StatefulWidget {
  const KYCLevelsScreen({super.key});

  @override
  State<KYCLevelsScreen> createState() => _KYCLevelsScreenState();
}

class _KYCLevelsScreenState extends State<KYCLevelsScreen> {
  bool _loading = false;
  late KYCProvider _kycProvider;

  @override
  void initState() {
    super.initState();
    _kycProvider = Provider.of<KYCProvider>(context, listen: false);
    // Schedule loading KYC levels after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kycProvider.loadKYCLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: P2PAppBar(
        title: 'Verification Levels',
        hasNotification: false,
        onThemeToggle: () {
          themeProvider.toggleTheme();
        },
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: Consumer<KYCProvider>(
              builder: (context, kycProvider, child) {
                if (kycProvider.loading) {
                  return _buildShimmerLoading(isDark);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCurrentLevel(isDark),
                      const SizedBox(height: 24),
                      _buildLevelsList(context, isDark),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
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
              Icons.verified_user,
              color: SafeJetColors.secondaryHighlight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Levels',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Unlock higher limits and features',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLevel(bool isDark) {
    return Consumer<KYCProvider>(
      builder: (context, kycProvider, child) {
        final kycDetails = kycProvider.kycDetails;
        final currentLevel = kycDetails?.currentLevel ?? 0;
        final nextLevel = currentLevel < 3 ? currentLevel + 1 : 3;
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getCurrentLevelGradient(currentLevel),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCurrentLevelIcon(currentLevel),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Level',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getCurrentLevelText(currentLevel),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: currentLevel / 3,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentLevel < 3 
                      ? 'Complete identity verification to reach Level $nextLevel'
                      : 'Maximum level reached',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getCurrentLevelGradient(int level) {
    switch (level) {
      case 3:
        return [
          SafeJetColors.primary,
          SafeJetColors.primary.withOpacity(0.8),
        ];
      case 2:
        return [
          SafeJetColors.success,
          SafeJetColors.success.withOpacity(0.8),
        ];
      case 1:
        return [
          SafeJetColors.warning,
          SafeJetColors.warning.withOpacity(0.8),
        ];
      default:
        return [
          SafeJetColors.error,
          SafeJetColors.error.withOpacity(0.8),
        ];
    }
  }

  IconData _getCurrentLevelIcon(int level) {
    switch (level) {
      case 3:
        return Icons.verified;
      case 2:
        return Icons.check_circle;
      case 1:
        return Icons.pending;
      default:
        return Icons.cancel;
    }
  }

  String _getCurrentLevelText(int level) {
    switch (level) {
      case 3:
        return 'Level 3';
      case 2:
        return 'Level 2';
      case 1:
        return 'Level 1';
      default:
        return 'Level 0';
    }
  }

  Widget _buildLevelsList(BuildContext context, bool isDark) {
    return Consumer<KYCProvider>(
      builder: (context, kycProvider, child) {
        if (kycProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final levels = kycProvider.kycLevels;
        if (levels == null) {
          return const Center(child: Text('Unable to load KYC levels'));
        }

        return Column(
          children: levels.map((level) => FadeInUp(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: level.level * 100),
            child: _buildLevelCard(context, level, isDark),
          )).toList(),
        );
      },
    );
  }

  Widget _buildLevelCard(BuildContext context, KYCLevel level, bool isDark) {
    Color levelColor = _getLevelColor(level.level);
    String status = _getLevelStatus(level.level);
    final currentLevel = context.read<KYCProvider>().kycDetails?.currentLevel ?? 0;
    final isNextLevel = level.level == currentLevel + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SafeJetColors.primaryAccent.withOpacity(0.1)
            : SafeJetColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${level.level}',
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  level.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requirements',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ...level.requirements.map((req) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        _isRequirementCompleted(req, level.level)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: _isRequirementCompleted(req, level.level)
                            ? SafeJetColors.success
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(req),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'Benefits',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : SafeJetColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ...level.benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 8),
                      Text(benefit),
                    ],
                  ),
                )),
                if (isNextLevel) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final nextStep = _getNextVerificationStep(level.level);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => nextStep,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: levelColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Complete Verification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey;
      case 1:
        return SafeJetColors.warning;
      case 2:
        return SafeJetColors.secondaryHighlight;
      case 3:
        return SafeJetColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getLevelStatus(int level) {
    // Get current level from KYC provider
    final currentLevel = context.read<KYCProvider>().kycDetails?.currentLevel ?? 0;
    
    switch (level) {
      case 0:
        return 'Completed';
      case _ when level <= currentLevel:
        return 'Completed';
      case _ when level == currentLevel + 1:
        return 'In Progress';
      default:
        return 'Locked';
    }
  }

  bool _isLevelCompleted(int level) {
    // Get current level from KYC provider
    final currentLevel = context.read<KYCProvider>().kycDetails?.currentLevel ?? 0;
    return level <= currentLevel;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return SafeJetColors.secondaryHighlight;
      case 'Locked':
        return Colors.grey;
      default:
        return SafeJetColors.success;
    }
  }

  bool _isRequirementCompleted(String requirement, int level) {
    final kycDetails = context.read<KYCProvider>().kycDetails;
    if (kycDetails == null) return false;

    // If the level is completed, all requirements are considered completed
    if (_isLevelCompleted(level)) return true;

    // Convert requirement to lowercase for case-insensitive comparison
    final req = requirement.toLowerCase().trim();

    switch (req) {
      case 'email verification':
        return kycDetails.userDetails.emailVerified;
      case 'phone verification':
        return kycDetails.userDetails.phoneVerified;
      case 'identity verification':
      case 'address proof':
        return kycDetails.verificationStatus?.identity?.status == 'completed' && 
               kycDetails.verificationStatus?.identity?.reviewAnswer == 'GREEN';
      case 'advanced verification':
      case 'bank statement':
      case 'proof of income':
      case 'tax documents':
        final isAdvancedCompleted = kycDetails.verificationStatus?.advanced?.status?.toLowerCase() == 'completed' && 
                                   kycDetails.verificationStatus?.advanced?.reviewAnswer == 'GREEN';
        return isAdvancedCompleted;
      default:
        return false;
    }
  }

  Widget _getNextVerificationStep(int level) {
    switch (level) {
      case 1:
        return const PhoneVerificationScreen();
      case 2:
        return const IdentityVerificationScreen();
      case 3:
        return const AdvancedVerificationScreen();
      default:
        return const IdentityVerificationScreen();
    }
  }

  Widget _buildVerificationButton(BuildContext context, int currentLevel) {
    if (currentLevel >= 2) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: _kycProvider.loading 
        ? null 
        : () async {
            try {
              await _kycProvider.startVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification completed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Verification failed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
      child: Text(
        _kycProvider.loading ? 'Verifying...' : 'Start Verification',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _startVerification() async {
    try {
      setState(() => _loading = true);
      await _kycProvider.startVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification started')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting verification')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildShimmerLoading(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Level Card Shimmer
          Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Level Cards Shimmer
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(3, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 200,
                                    height: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
} 