import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// Extended AppThemeType with system option
enum ThemeOption {
  system,
  light,
  dark,
  sepia,
  purple,
  green,
  pink
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  ThemeOption _currentTheme = ThemeOption.system;
  bool _useDarkMode = false; // Used when theme is system

  ThemeOption get currentTheme => _currentTheme;
  bool get useDarkMode => _useDarkMode;

  // Constructor - Try to load saved theme
  ThemeService() {
    _loadTheme();
  }

  // Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _currentTheme = _themeFromString(savedTheme);
      }
      
      // Initialize dark mode flag based on system if using system theme
      if (_currentTheme == ThemeOption.system) {
        _useDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      }
      
      notifyListeners();
    } catch (e) {
      // Fallback to default theme if loading fails
      _currentTheme = ThemeOption.system;
      print('Error loading theme: $e');
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme(ThemeOption theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.toString());
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Set theme and persist the change
  Future<void> setTheme(ThemeOption theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      await _saveTheme(theme);
      notifyListeners();
    }
  }

  // Update dark mode flag when using system theme
  void updateSystemDarkMode(bool isDark) {
    if (_currentTheme == ThemeOption.system && _useDarkMode != isDark) {
      _useDarkMode = isDark;
      notifyListeners();
    }
  }

  // Get ThemeData based on current settings
  ThemeData getTheme(BuildContext context) {
    if (_currentTheme == ThemeOption.system) {
      // Use system theme preference
      return _useDarkMode ? darkTheme : lightTheme;
    }
    
    // Convert ThemeOption to AppThemeType for other themes
    return getThemeByType(_getAppThemeType(_currentTheme));
  }

  // Get ThemeMode for MaterialApp
  ThemeMode getThemeMode() {
    switch (_currentTheme) {
      case ThemeOption.system:
        return ThemeMode.system;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.light:
      case ThemeOption.sepia:
      case ThemeOption.purple:
      case ThemeOption.green:
      case ThemeOption.pink:
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  // Convert string back to ThemeOption enum
  ThemeOption _themeFromString(String value) {
    try {
      return ThemeOption.values.firstWhere(
        (e) => 'ThemeOption.${e.toString().split('.').last}' == value,
        orElse: () => ThemeOption.system,
      );
    } catch (_) {
      return ThemeOption.system;
    }
  }
  
  // Convert ThemeOption to AppThemeType
  AppThemeType _getAppThemeType(ThemeOption option) {
    switch (option) {
      case ThemeOption.light:
        return AppThemeType.light;
      case ThemeOption.dark:
        return AppThemeType.dark;
      case ThemeOption.sepia:
        return AppThemeType.sepia;
      case ThemeOption.purple:
        return AppThemeType.purple;
      case ThemeOption.green:
        return AppThemeType.green;
      case ThemeOption.pink:
        return AppThemeType.pink;
      case ThemeOption.system:
        return _useDarkMode ? AppThemeType.dark : AppThemeType.light;
    }
  }
  
  // Get theme name for display
  String getThemeName(ThemeOption option) {
    switch (option) {
      case ThemeOption.system:
        return 'System Default';
      case ThemeOption.light:
        return 'Light';
      case ThemeOption.dark:
        return 'Dark';
      case ThemeOption.sepia:
        return 'Sepia';
      case ThemeOption.purple:
        return 'Purple';
      case ThemeOption.green:
        return 'Green';
      case ThemeOption.pink:
        return 'Pink';
      default:
        return 'Unknown';
    }
  }
} 