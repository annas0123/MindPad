import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme settings section
          const ListTile(
            title: Text('Appearance'),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            tileColor: Colors.black12,
          ),
          _buildThemeSelector(context, themeService),
          
          // Other settings sections can be added here
          const Divider(),
          
          // App info section
          const ListTile(
            title: Text('About'),
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            tileColor: Colors.black12,
          ),
          ListTile(
            title: const Text('Version'),
            trailing: const Text('1.0.0'),
            onTap: () {
              // Show version info or check for updates
            },
          ),
        ],
      ),
    );
  }
  
  // Build the theme selector widget
  Widget _buildThemeSelector(BuildContext context, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        
        // Radio buttons for each theme option
        ...ThemeOption.values.map((option) => RadioListTile<ThemeOption>(
          title: Text(themeService.getThemeName(option)),
          value: option,
          groupValue: themeService.currentTheme,
          onChanged: (value) {
            if (value != null) {
              themeService.setTheme(value);
            }
          },
          // Show color preview for each theme
          secondary: _buildThemePreview(option),
        )),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  // Build a small preview of each theme
  Widget _buildThemePreview(ThemeOption option) {
    // Define colors for theme previews
    final Color primaryColor;
    final Color backgroundColor;
    
    switch (option) {
      case ThemeOption.system:
        // Show system theme icon
        return const Icon(Icons.devices);
        
      case ThemeOption.light:
        primaryColor = Colors.blue;
        backgroundColor = Colors.white;
        break;
        
      case ThemeOption.dark:
        primaryColor = Colors.blueGrey[700]!;
        backgroundColor = Colors.grey[850]!;
        break;
        
      case ThemeOption.sepia:
        primaryColor = const Color(0xFF8C7356);
        backgroundColor = const Color(0xFFF5ECD9);
        break;
        
      case ThemeOption.purple:
        primaryColor = Colors.deepPurple;
        backgroundColor = Colors.white;
        break;
        
      case ThemeOption.green:
        primaryColor = Colors.green;
        backgroundColor = Colors.white;
        break;
        
      case ThemeOption.pink:
        primaryColor = Colors.pink;
        backgroundColor = Colors.white;
        break;
    }
    
    // Create a small preview circle with theme colors
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
} 