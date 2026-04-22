import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SecurityProvider with ChangeNotifier {
  static const String boxName = 'settings';
  static const String lockKey = 'biometric_lock';
  
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLockEnabled = false;
  bool _isAuthenticated = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isAuthenticated => _isAuthenticated;

  SecurityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox(boxName);
    _isLockEnabled = box.get(lockKey, defaultValue: false);
    // On startup, we are not authenticated yet if lock is on
    _isAuthenticated = !_isLockEnabled;
    notifyListeners();
  }

  Future<void> toggleLock(bool value) async {
    final box = await Hive.openBox(boxName);
    await box.put(lockKey, value);
    _isLockEnabled = value;
    notifyListeners();
  }

  Future<bool> authenticate() async {
    if (!_isLockEnabled || kIsWeb) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your reflections',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern fallback
        ),
      );
      
      _isAuthenticated = didAuthenticate;
      notifyListeners();
      return didAuthenticate;
    } catch (e) {
      debugPrint('Auth Error: $e');
      return false;
    }
  }

  void lock() {
    if (_isLockEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
