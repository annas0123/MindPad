import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await DatabaseService().initDatabase();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MindpadApp(),
    ),
  );
}

class MindpadApp extends StatefulWidget {
  const MindpadApp({super.key});

  @override
  State<MindpadApp> createState() => _MindpadAppState();
}

class _MindpadAppState extends State<MindpadApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register observer to detect system theme changes
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    // Remove observer when the app is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    // When system brightness changes, notify the ThemeService
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.updateSystemDarkMode(brightness == Brightness.dark);
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: 'Mindpad',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeService.getThemeMode(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      // Override the app theme when a custom theme is selected (not light/dark)
      builder: (context, child) {
        if (themeService.currentTheme != ThemeOption.system && 
            themeService.currentTheme != ThemeOption.light && 
            themeService.currentTheme != ThemeOption.dark) {
          // Use the custom theme
          return Theme(
            data: themeService.getTheme(context),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}
