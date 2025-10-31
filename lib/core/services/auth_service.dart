import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Firebase Authentication state and token persistence.
///
/// This service is a [ChangeNotifier] and is intended to be provided
/// at the root of the application using `Provider`.
///
/// It handles:
/// - Listening to auth state changes from Firebase.
/// - Providing the current [User] object.
/// - Handling user login with email and password.
/// - Handling user logout.
/// - Retrieving and caching the Firebase ID token for API requests.
///
/// Note: Registration is handled by [ApiService] as it involves
/// creating a user in both Firebase Auth and Firestore via your backend.
class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  String? _cachedToken;

  /// The currently authenticated Firebase [User].
  /// Returns `null` if no user is signed in.
  User? get firebaseUser => _firebaseUser;

  /// Returns `true` if a user is currently authenticated.
  bool get isAuthenticated => _firebaseUser != null;

  AuthService() {
    // Listen to authentication state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Called whenever the Firebase auth state changes.
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      // User signed out, clear cached token
      _cachedToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
    } else {
      // User signed in, proactively cache the token
      await getUserToken(forceRefresh: true);
    }
    
    // Notify all listeners (like AuthWrapper) of the change
    notifyListeners();
  }

  /// Signs in a user with email and password.
  ///
  /// Throws a [FirebaseAuthException] if login fails.
  Future<void> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _firebaseUser = cred.user;

      // Force refresh the token on login and cache it
      await getUserToken(forceRefresh: true);

      notifyListeners();
    } on FirebaseAuthException {
      // Re-throw the specific Firebase exception for the UI to handle
      rethrow;
    } catch (e) {
      // Catch any other potential errors
      debugPrint("AuthService login error: $e");
      throw Exception('An unknown error occurred during login.');
    }
  }

  /// Signs out the current user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      // The _onAuthStateChanged listener will handle clearing state
    } catch (e) {
      debugPrint("AuthService logout error: $e");
      // Handle logout error if necessary
    }
  }

  /// Retrieves the Firebase ID token for the current user.
  ///
  /// Caches the token in [SharedPreferences] for persistence.
  /// Set [forceRefresh] to `true` to get a new token from Firebase,
  /// bypassing the cache (e.g., after login).
  Future<String?> getUserToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      // Try to use the in-memory cached token first
      _cachedToken ??= prefs.getString('authToken');
      if (_cachedToken != null) {
        return _cachedToken;
      }
    }

    // If no token or if refreshing, get it from Firebase
    if (_auth.currentUser != null) {
      try {
        final newToken = await _auth.currentUser!.getIdToken(forceRefresh);
        _cachedToken = newToken;
        await prefs.setString('authToken', newToken ?? "");
        return newToken;
      } catch (e) {
        debugPrint("Error getting user token: $e");
        // If token refresh fails (e.g., user disabled), log out
        await logout();
        return null;
      }
    }

    return null;
  }
}
