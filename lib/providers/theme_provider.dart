import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AppTheme { light, dark, lightFilter, pink }

class ThemeProvider with ChangeNotifier {
  static const String boxName = 'settings';
  static const String themeKey = 'app_theme';
  
  AppTheme _currentTheme = AppTheme.light;
  AppTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(boxName);
    final themeIndex = box.get(themeKey, defaultValue: AppTheme.light.index);
    _currentTheme = AppTheme.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final box = await Hive.openBox(boxName);
    await box.put(themeKey, theme.index);
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppTheme.dark:
        return ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0), // Indigo
            brightness: Brightness.dark,
          ),
        );
      case AppTheme.lightFilter:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0), // Indigo
            primary: const Color(0xFF5C6BC0),
            secondary: const Color(0xFFF06292), // Pink
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF9E6),
        );
      case AppTheme.pink:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF06292), // Pink
            primary: const Color(0xFFF06292),
            secondary: const Color(0xFF5C6BC0), // Indigo
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFCE4EC),
        );
      case AppTheme.light:
      default:
        return ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0), // Indigo as default primary
            primary: const Color(0xFF5C6BC0),
            secondary: const Color(0xFFF06292), // Pink
          ),
        );
    }
  }
}
