import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _refreshUser(data.session?.user);
    });
  }

  void _refreshUser(User? user) {
    if (user != null) {
      _currentUser = UserModel(
        username: user.userMetadata?['username'] ?? user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        password: '',
        profileImagePath: user.userMetadata?['avatar_url'], // Ensure this is captured
      );
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      _refreshUser(response.user);
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: identifier,
        password: password,
      );
      _refreshUser(response.user);
      return true;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'http://localhost:55177' : 'io.supabase.emojitrack://login-callback',
      );
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    }
  }

  Future<void> updateUser(String newUsername, String newEmail, {String? profilePath}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          email: newEmail,
          data: {
            'username': newUsername,
            if (profilePath != null) 'avatar_url': profilePath,
          },
        ),
      );
      _refreshUser(response.user); // Immediately update local state with new info
    } catch (e) {
      debugPrint('Update User Error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }
}
