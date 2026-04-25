import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  bool _isOnboardingCompleted = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  AuthProvider() {
    _init();
  }

  // We no longer load onboarding status from Hive because the user wants it
  // to show every time the app opens (if not logged in).
  Future<void> completeOnboarding() async {
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  void _init() {
    _supabase.auth.onAuthStateChange.listen((data) {
      _refreshUser(data.session?.user);
      // If the user logs out, reset onboarding so it shows again on next launch
      if (data.session == null) {
        _isOnboardingCompleted = false;
      }
    });
  }

  void _refreshUser(User? user) {
    if (user != null) {
      _currentUser = UserModel(
        username: user.userMetadata?['username'] ?? user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        password: '',
        profileImagePath: user.userMetadata?['avatar_url'],
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
    } on AuthApiException catch (e) {
      if (e.message.contains('User already registered') || e.code == 'user_already_exists') {
        throw 'This email is already registered. Please log in instead.';
      }
      rethrow;
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
      String? finalAvatarUrl = _currentUser?.profileImagePath;

      if (profilePath != null) {
        final userId = _supabase.auth.currentUser!.id;
        final fileExtension = profilePath.split('.').last;
        final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        
        if (!kIsWeb) {
          final file = File(profilePath);
          await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          finalAvatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
        }
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(
          email: newEmail,
          data: {
            'username': newUsername,
            if (finalAvatarUrl != null) 'avatar_url': finalAvatarUrl,
          },
        ),
      );
      _refreshUser(response.user);
    } catch (e) {
      debugPrint('Update User Error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _isOnboardingCompleted = false; // Reset for next launch
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }
}
