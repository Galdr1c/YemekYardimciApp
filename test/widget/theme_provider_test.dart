import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemek_yardimci_app/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      await themeProvider.loadThemePreference();
    });
    
    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });
    
    test('initial theme mode should be system', () {
      expect(themeProvider.themeMode, ThemeMode.system);
    });
    
    test('setThemeMode should update theme mode', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
    });
    
    test('setThemeMode should persist to SharedPreferences', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      
      await themeProvider.setThemeMode(ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });
    
    test('loadThemePreference should load saved preference', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', 'dark');
      
      final newProvider = ThemeProvider();
      await newProvider.loadThemePreference();
      
      expect(newProvider.themeMode, ThemeMode.dark);
    });
    
    test('toggleTheme should switch between light and dark', () async {
      await themeProvider.setThemeMode(ThemeMode.light);
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.light);
    });
    
    test('setSystemMode should set theme to system', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      await themeProvider.setSystemMode();
      expect(themeProvider.themeMode, ThemeMode.system);
    });
  });
}

