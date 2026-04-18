import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserModel? _currentUser;
  bool _isOnboardingCompleted = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _supabase.auth.currentSession != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  AuthProvider() {
    _loadOnboardingStatus();
    _init();
  }

  Future<void> _loadOnboardingStatus() async {
    final box = await Hive.openBox('settings');
    _isOnboardingCompleted = box.get('onboarding_completed', defaultValue: false);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final box = await Hive.openBox('settings');
    await box.put('onboarding_completed', true);
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  void _init() {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }
}
