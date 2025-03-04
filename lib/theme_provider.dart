import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider() : _themeData = _createLightTheme();

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  static ThemeData _createLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Light gray background
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        background: const Color(0xFFF5F5F7),
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey[200],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData _createDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        background: Colors.black,
        surface: Colors.grey[900]!,
        onSurface: Colors.white,
      ),
      cardColor: Colors.grey[900],
      dividerColor: Colors.white10,
    );
  }

  void toggleTheme() {
    _themeData = isDarkMode ? _createLightTheme() : _createDarkTheme();
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _themeData = prefs.getBool('isDarkMode') == true
        ? _createDarkTheme()
        : _createLightTheme();
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}
