import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:dio/dio.dart';
import '../config/env/env_config.dart';

class SocialAuthService {
  final Dio _dio = Dio();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '730446950124-67b079n5tn1iso1f9vnrkcj6raojjrgn.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  SocialAuthService() {
    _dio.options.baseUrl = EnvConfig.authBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Start the Google Sign In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get user info
      final userInfo = {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };

      // Send to backend for verification and user creation/login
      final response = await _dio.post(
        '/auth/social/google',
        data: {
          'accessToken': googleAuth.accessToken,
          'idToken': googleAuth.idToken,
          'userInfo': userInfo,
        },
      );

      return response.data;
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  /// Facebook Sign In
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      // Start the Facebook Sign In process
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook sign in failed: ${result.status}');
      }

      // Get user data
      final userData = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture.width(200)",
      );

      // Send to backend for verification and user creation/login
      final response = await _dio.post(
        '/auth/facebook-login',
        data: {
          'accessToken': result.accessToken?.token,
          'userData': userData,
        },
      );

      return response.data;
    } catch (e) {
      print('Facebook Sign In Error: $e');
      rethrow;
    }
  }

  /// Sign Out from social accounts
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Facebook
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('Social Sign Out Error: $e');
    }
  }

  /// Check if user is signed in to any social account
  Future<bool> isSignedIn() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      final facebookUser = await FacebookAuth.instance.getUserData();

      return googleUser != null || facebookUser.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
