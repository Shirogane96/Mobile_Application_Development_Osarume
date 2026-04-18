import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // Listen to auth changes (sign in, sign out, etc.)
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _currentUser = UserModel(
          username: user.userMetadata?['username'] ?? user.email?.split('@')[0] ?? 'User',
          email: user.email ?? '',
          password: '', // Password isn't stored locally for Supabase users
          profileImagePath: user.userMetadata?['avatar_url'],
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> register(String username, String email, String password) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      // Supabase normally uses email for login
      await _supabase.auth.signInWithPassword(
        email: identifier,
        password: password,
      );
      return true;
    } catch (e) {
      debugPrint('Login Error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      // For Web, Supabase handles the redirect automatically
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:55177', // Match your locked port
      );
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    }
  }

  Future<void> updateUser(String newUsername, String newEmail, {String? profilePath}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          email: newEmail,
          data: {
            'username': newUsername,
            if (profilePath != null) 'avatar_url': profilePath,
          },
        ),
      );
    } catch (e) {
      debugPrint('Update User Error: $e');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
