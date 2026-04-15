import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  static const String boxName = 'users';
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> register(String username, String email, String password) async {
    final box = await Hive.openBox<UserModel>(boxName);
    final user = UserModel(username: username, email: email, password: password);
    await box.put(email, user);
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    final box = await Hive.openBox<UserModel>(boxName);
    
    UserModel? user;
    try {
      user = box.values.firstWhere(
        (u) => (u.email == identifier || u.username == identifier) && u.password == password
      );
    } catch (e) {
      user = null;
    }

    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> updateUser(String newUsername, String newEmail, {String? profilePath}) async {
    if (_currentUser == null) return;
    
    final box = await Hive.openBox<UserModel>(boxName);
    
    final updatedUser = UserModel(
      username: newUsername,
      email: newEmail,
      password: _currentUser!.password,
      profileImagePath: profilePath ?? _currentUser!.profileImagePath,
    );

    if (_currentUser!.email != newEmail) {
      await box.delete(_currentUser!.email);
    }
    
    await box.put(newEmail, updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
