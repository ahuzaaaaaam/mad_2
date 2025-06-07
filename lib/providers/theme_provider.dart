import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  static const String _themePreferenceKey = 'themeMode';
  
  // Theme modes: system, light, dark
  String _themeMode = 'system';
  String get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == 'system') {
      return SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
    }
    return _themeMode == 'dark';
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _prefs.getString(_themePreferenceKey) ?? 'system';
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) return;
    _themeMode = mode;
    await _prefs.setString(_themePreferenceKey, mode);
    notifyListeners();
  }

  ThemeData get theme => isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      primary: Colors.red,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static final _darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      primary: Colors.red,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    primaryColor: Colors.red,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    shadowColor: Colors.white.withOpacity(0.1),
    canvasColor: const Color(0xFF121212),
  );
}
