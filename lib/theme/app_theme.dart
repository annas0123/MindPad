import 'package:flutter/material.dart';

// Text styles that can be used throughout the app
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
}

// Define theme identifiers
enum AppThemeType {
  light,
  dark,
  sepia,
  purple,
  green,
  pink
}

// Get theme name for display
String getThemeName(AppThemeType type) {
  switch (type) {
    case AppThemeType.light:
      return 'Light';
    case AppThemeType.dark:
      return 'Dark';
    case AppThemeType.sepia:
      return 'Sepia';
    case AppThemeType.purple:
      return 'Purple';
    case AppThemeType.green:
      return 'Green';
    case AppThemeType.pink:
      return 'Pink';
    default:
      return 'Unknown';
  }
}

// Light theme configuration
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  colorScheme: const ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.lightBlue,
    surface: Colors.white,
    background: Color(0xFFF5F5F5),
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Colors.white,
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1,
    titleLarge: AppTextStyles.heading2,
    bodyLarge: AppTextStyles.bodyText,
    bodySmall: AppTextStyles.caption,
  ),
);

// Dark theme configuration
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueGrey[700],
  colorScheme: ColorScheme.dark(
    primary: Colors.blueGrey[700]!,
    secondary: Colors.blueGrey[500]!,
    surface: Colors.grey[850]!,
    background: Colors.grey[900]!,
    error: Colors.redAccent,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blueGrey[800],
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blueGrey[700],
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    color: Colors.grey[850],
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1.copyWith(color: Colors.white),
    titleLarge: AppTextStyles.heading2.copyWith(color: Colors.white),
    bodyLarge: AppTextStyles.bodyText.copyWith(color: Colors.white70),
    bodySmall: AppTextStyles.caption.copyWith(color: Colors.white54),
  ),
);

// Sepia theme - warm, reading-friendly theme
final ThemeData sepiaTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF8C7356),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF8C7356),
    secondary: Color(0xFFB59E80),
    surface: Color(0xFFF8F1E3),
    background: Color(0xFFF5ECD9),
    error: Color(0xFFCF6679),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF8C7356),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF8C7356),
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Color(0xFFF8F1E3),
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1.copyWith(color: const Color(0xFF442C1E)),
    titleLarge: AppTextStyles.heading2.copyWith(color: const Color(0xFF442C1E)),
    bodyLarge: AppTextStyles.bodyText.copyWith(color: const Color(0xFF442C1E)),
    bodySmall: AppTextStyles.caption.copyWith(color: const Color(0xFF7D5F49)),
  ),
);

// Purple theme
final ThemeData purpleTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.deepPurple,
  colorScheme: const ColorScheme.light(
    primary: Colors.deepPurple,
    secondary: Colors.purpleAccent,
    surface: Colors.white,
    background: Color(0xFFF5F0FF),
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Colors.white,
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1,
    titleLarge: AppTextStyles.heading2,
    bodyLarge: AppTextStyles.bodyText,
    bodySmall: AppTextStyles.caption,
  ),
);

// Green theme
final ThemeData greenTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.green,
  colorScheme: const ColorScheme.light(
    primary: Colors.green,
    secondary: Colors.lightGreen,
    surface: Colors.white,
    background: Color(0xFFF0F8F0),
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Colors.white,
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1,
    titleLarge: AppTextStyles.heading2,
    bodyLarge: AppTextStyles.bodyText,
    bodySmall: AppTextStyles.caption,
  ),
);

// Pink theme
final ThemeData pinkTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.pink,
  colorScheme: const ColorScheme.light(
    primary: Colors.pink,
    secondary: Colors.pinkAccent,
    surface: Colors.white,
    background: Color(0xFFFFF0F5),
    error: Colors.redAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.pink,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.pink,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardTheme(
    color: Colors.white,
  ),
  textTheme: TextTheme(
    displayLarge: AppTextStyles.heading1,
    titleLarge: AppTextStyles.heading2,
    bodyLarge: AppTextStyles.bodyText,
    bodySmall: AppTextStyles.caption,
  ),
);

// Get theme data by type
ThemeData getThemeByType(AppThemeType type) {
  switch (type) {
    case AppThemeType.light:
      return lightTheme;
    case AppThemeType.dark:
      return darkTheme;
    case AppThemeType.sepia:
      return sepiaTheme;
    case AppThemeType.purple:
      return purpleTheme;
    case AppThemeType.green:
      return greenTheme;
    case AppThemeType.pink:
      return pinkTheme;
    default:
      return lightTheme;
  }
} 