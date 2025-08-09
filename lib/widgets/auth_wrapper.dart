import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../config/theme/colors.dart';
import '../providers/notification_provider.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    print('AuthWrapper: loading user data...');
    if (mounted) {
      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .checkAuthStatus();
        print('AuthWrapper: checkAuthStatus done');
        
        // Initialize notifications after authentication is confirmed
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAuthenticated && authProvider.user?.emailVerified != false) {
            _initializeNotifications(context);
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _initializeNotifications(BuildContext context) {
    if (!_notificationsInitialized) {
      print('🔔 Initializing notifications...');
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.initialize();
      notificationProvider.fetchNotifications(); // Fetch existing notifications
      _notificationsInitialized = true;
      print('🔔 Notifications initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      SafeJetColors.primaryBackground,
                      SafeJetColors.secondaryBackground,
                    ]
                  : [
                      SafeJetColors.lightBackground,
                      SafeJetColors.lightSecondaryBackground,
                    ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('AuthWrapper: isAuthenticated=' +
            authProvider.isAuthenticated.toString() +
            ', emailVerified=' +
            (authProvider.user?.emailVerified.toString() ?? 'null'));
        if (authProvider.isAuthenticated) {
          if (authProvider.user != null &&
              authProvider.user!.emailVerified == false) {
            print('AuthWrapper: Showing EmailVerificationScreen');
            return EmailVerificationScreen(email: authProvider.user!.email);
          }
          print('AuthWrapper: Showing Home/Dashboard');
          return widget.child;
        }
        print('AuthWrapper: Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
