import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yemek_yardimci_app/providers/theme_provider.dart';
import 'package:yemek_yardimci_app/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
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
    
    testWidgets('SettingsScreen displays dark mode switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: const SettingsScreen(),
          ),
        ),
      );
      
      expect(find.text('Karanlık Mod'), findsOneWidget);
      expect(find.text('Görünüm'), findsOneWidget);
    });
    
    testWidgets('Toggling dark mode switch updates theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: const SettingsScreen(),
          ),
        ),
      );
      
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      
      // Initially should be false (system mode)
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, false);
      
      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      
      // Theme should be dark now
      expect(themeProvider.themeMode, ThemeMode.dark);
    });
    
    testWidgets('Theme mode dropdown updates theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ThemeProvider>.value(
            value: themeProvider,
            child: const SettingsScreen(),
          ),
        ),
      );
      
      final dropdownFinder = find.byType(DropdownButton<ThemeMode>);
      expect(dropdownFinder, findsOneWidget);
      
      // Tap dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Select dark mode
      final darkModeOption = find.text('Koyu').last;
      await tester.tap(darkModeOption);
      await tester.pumpAndSettle();
      
      expect(themeProvider.themeMode, ThemeMode.dark);
    });
  });
}

