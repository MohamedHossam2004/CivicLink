import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService() {
    // Configure Firebase Auth settings when service is initialized
    _configureFirebaseAuth();
  }

  // Configure Firebase Auth settings
  Future<void> _configureFirebaseAuth() async {
    try {
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );
      print('Auth Service: Firebase Auth settings configured successfully');
    } catch (e) {
      print('Auth Service: Error configuring Firebase Auth settings: $e');
    }
  }

  // Get current user's ID token
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  // Get current user's ID token with force refresh
  Future<String?> getIdTokenForceRefresh() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // Force refresh
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  // Check if token is valid
  Future<bool> isTokenValid() async {
    try {
      final token = await getIdToken();
      return token != null;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print('User signed in successfully. Token: ${token?.substring(0, 20)}...');
      
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print('User registered successfully. Token: ${token?.substring(0, 20)}...');
      
      return userCredential;
    } catch (e) {
      print('Error registering: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google sign in aborted';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print('User signed in with Google successfully. Token: ${token?.substring(0, 20)}...');
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Facebook
  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);
            
        final userCredential = await _auth.signInWithCredential(credential);
        
        // Get and print token for debugging
        final token = await userCredential.user?.getIdToken();
        print('User signed in with Facebook successfully. Token: ${token?.substring(0, 20)}...');
        
        return userCredential;
      } else {
        throw 'Facebook sign in failed';
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
