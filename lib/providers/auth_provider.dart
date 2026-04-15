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
    await box.put(email, user); // Using email as key
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    final box = await Hive.openBox<UserModel>(boxName);
    
    // Check if identifier is email or username
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

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
