import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FirebaseGoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Always sign out first to force account picker
      await _googleSignIn.signOut();
      // Optionally, disconnect to remove the account from the device's list
      // await _googleSignIn.disconnect();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      return await _auth.signInWithCredential(credential);
    } catch (e, stack) {
      print('Firebase Google Sign-In Error: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Start the Facebook Sign In process
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook sign in failed: ${result.status}');
      }

      // Create a Facebook credential with the access token
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );

      // Sign in to Firebase with the Facebook credential
      return await _auth.signInWithCredential(credential);
    } catch (e, stack) {
      print('Firebase Facebook Sign-In Error: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}
