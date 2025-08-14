import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import './services/service_locator.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/kyc_provider.dart';
import './services/services.dart';
import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'providers/payment_methods_provider.dart';
import 'services/payment_methods_service.dart';
import './widgets/auth_wrapper.dart';
import './services/dio_interceptors.dart';
import 'providers/auto_response_provider.dart';
import '../services/p2p_settings_service.dart';
import 'providers/notification_settings_provider.dart';
import '../services/notification_settings_service.dart';
import 'providers/language_settings_provider.dart';
import '../services/language_settings_service.dart';
import 'providers/biometric_settings_provider.dart';
import '../services/biometric_settings_service.dart';
import './services/p2p_service.dart';
import 'screens/main/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'providers/notification_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/env/env_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load dotenv FIRST
  await dotenv.load(fileName: ".env");

  // Now it's safe to initialize Firebase and use EnvConfig
  await Firebase.initializeApp();

  // Initialize firebase_messaging
  await _setupFirebaseMessaging();

  final dio = Dio();

  // Add interceptors
  dio.interceptors.addAll([
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ),
    // If you need AuthProvider in interceptors, get it from Provider where needed
  ]);

  await setupServices();
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider()..init(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<P2PService>(
          create: (context) => P2PService(),
        ),
        ChangeNotifierProvider(
          create: (context) => KYCProvider(
            KYCService(dio),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PaymentMethodsProvider(
            PaymentMethodsService(dio),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AutoResponseProvider(
            P2PSettingsService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationSettingsProvider(
            NotificationSettingsService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LanguageSettingsProvider(
            LanguageSettingsService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BiometricSettingsProvider(
            BiometricSettingsService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(NotificationService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Handling a background message: ${message.messageId}');
}

Future<void> registerDeviceWithBackend() async {
  final storage = const FlutterSecureStorage();
  final jwt = await storage.read(key: 'accessToken');
  print('JWT for device registration: $jwt');
  if (jwt == null) return;
  String? fcmToken;
  try {
    fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token for registration: $fcmToken');
  } on FirebaseException catch (e) {
    if (e.code == 'apns-token-not-set') {
      print('Firebase Messaging: APNS token not available on this device (likely a simulator). This is normal.');
    } else {
      print('Firebase Messaging: Failed to get token: ${e.message}');
    }
  } catch (e) {
    print('Firebase Messaging: An unknown error occurred while fetching the token: $e');
  }

  if (fcmToken == null) {
    print('FCM token is null, skipping device registration.');
    return;
  }

  final apiBase = EnvConfig.apiUrl;
  final url = Uri.parse('$apiBase/user-devices/register');
  final platform = Platform.isAndroid
      ? 'android'
      : Platform.isIOS
          ? 'ios'
          : 'web';
  print('Registering device at URL: $url with platform: $platform');

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fcmToken': fcmToken,
        'platform': platform,
      }),
    );
    print(
        'Device registration response:  [32m${response.statusCode} ${response.body} [0m');
    if (response.statusCode == 200) {
      print('Device registered for notifications');
    } else {
      print('Failed to register device: ${response.body}');
    }
  } catch (e) {
    print('Error registering device: $e');
  }
}

Future<void> _setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions (Android will always return granted)
  await messaging.requestPermission();

  // Get the token (for debugging/logging)
  String? token = await messaging.getToken();
  print('FCM Token: ${token ?? "(null)"}');

  // Register device with backend
  await registerDeviceWithBackend();

  // Set up background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.messageId}');
    // You can show a dialog/snackbar/notification here
  });

  // Set up when app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');
    // Handle navigation or other logic here
  });
}

Future<bool> isFirstLaunch() async {
  print('Checking first launch...');
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  print('First launch: ${!hasSeenOnboarding}');
  return !hasSeenOnboarding;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'NadiaPoint Exchange',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      navigatorKey: navigatorKey,
      home: FutureBuilder<bool>(
        future: isFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.data == true) {
            return const OnboardingScreen();
          }
          // Only show AuthWrapper after onboarding is done
          return AuthWrapper(
            child: const HomeScreen(),
          );
        },
      ),
    );
  }
}
