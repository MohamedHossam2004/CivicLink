import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _loginMethodKey = 'login_method';

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

  // Save login credentials
  Future<void> _saveLoginCredentials(String email, String password, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userPasswordKey, password);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_loginMethodKey, method);
  }

  // Clear login credentials
  Future<void> _clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPasswordKey);
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_loginMethodKey);
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Auto login if credentials exist
  Future<UserCredential?> autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) return null;

      final loginMethod = prefs.getString(_loginMethodKey);
      final email = prefs.getString(_userEmailKey);
      final password = prefs.getString(_userPasswordKey);

      if (loginMethod == 'email' && email != null && password != null) {
        return await signInWithEmailAndPassword(email, password);
      } else if (loginMethod == 'google') {
        return await signInWithGoogle();
      } else if (loginMethod == 'facebook') {
        return await signInWithFacebook();
      }
      
      return null;
    } catch (e) {
      print('Error during auto login: $e');
      await _clearLoginCredentials();
      return null;
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

      // Save login credentials
      await _saveLoginCredentials(email, password, 'email');

      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print(
          'User signed in successfully. Token: ${token?.substring(0, 20)}...');

      final userDetails = await getUserDetails();
      print('User Details: $userDetails');

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

      // Save login credentials
      await _saveLoginCredentials(email, password, 'email');

      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print(
          'User registered successfully. Token: ${token?.substring(0, 20)}...');

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

      // Save login method
      await _saveLoginCredentials('', '', 'google');

      // Get and print token for debugging
      final token = await userCredential.user?.getIdToken();
      print(
          'User signed in with Google successfully. Token: ${token?.substring(0, 20)}...');

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

        // Save login method
        await _saveLoginCredentials('', '', 'facebook');

        // Get and print token for debugging
        final token = await userCredential.user?.getIdToken();
        print(
            'User signed in with Facebook successfully. Token: ${token?.substring(0, 20)}...');

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
      await _clearLoginCredentials();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user details
  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get user details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;

      return {
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'email': userData['email'] ?? '',
        'address': userData['address'] ?? '',
        'nationalId': userData['nationalId'] ?? '',
        'profilePictureUrl': userData['profilePictureUrl'] ?? '',
        'createdAt': userData['createdAt']?.toDate()?.toIso8601String(),
        'type': userData['type'] ?? 'User',
        'uid': userData['uid']
      };
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }
}
