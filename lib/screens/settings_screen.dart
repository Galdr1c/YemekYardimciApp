import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Settings screen with theme toggle and other preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dark Mode Switch
                  SwitchListTile(
                    title: const Text('Karanlık Mod'),
                    subtitle: Text(
                      _getThemeModeDescription(themeProvider.themeMode),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) async {
                      if (value) {
                        await themeProvider.setDarkMode();
                      } else {
                        // If switching off dark mode, check if we should go to system or light
                        if (themeProvider.themeMode == ThemeMode.system) {
                          await themeProvider.setLightMode();
                        } else {
                          await themeProvider.setLightMode();
                        }
                      }
                    },
                    secondary: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Theme Mode Selection
                  ListTile(
                    title: const Text('Tema Modu'),
                    subtitle: Text(
                      _getThemeModeDescription(themeProvider.themeMode),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Sistem'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Açık'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Koyu'),
                        ),
                      ],
                      onChanged: (ThemeMode? mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                    ),
                    leading: Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uygulama Bilgisi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Sürüm'),
                    subtitle: const Text('1.0.0'),
                    leading: Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık tema kullanılıyor';
      case ThemeMode.dark:
        return 'Koyu tema kullanılıyor';
      case ThemeMode.system:
        return 'Cihaz ayarına göre otomatik';
    }
  }
}

