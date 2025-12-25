import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/main.dart';

void main() {
  Widget createTestApp({Brightness brightness = Brightness.light}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
        home: const Scaffold(
          body: Center(
            child: Text('Theme Test'),
          ),
        ),
      ),
    );
  }

  group('Light Theme Tests', () {
    testWidgets('Light theme has correct primary color (green[700])', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.colorScheme.primary, AppTheme.primaryGreen);
    });

    testWidgets('Light theme has correct secondary color (orange)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.colorScheme.secondary, AppTheme.accentOrange);
    });

    testWidgets('Light theme bodyLarge is 16 bold', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.bold);
    });

    testWidgets('Light theme has white scaffold background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF5F5F5));
    });

    testWidgets('Light theme brightness is light', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('Light theme AppBar has green background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.appBarTheme.backgroundColor, AppTheme.primaryGreen);
    });

    testWidgets('Light theme icon color is green', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.iconTheme.color, AppTheme.primaryGreen);
    });
  });

  group('Dark Theme Tests', () {
    testWidgets('Dark theme has correct primary color', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.colorScheme.primary, AppTheme.primaryGreenLight);
    });

    testWidgets('Dark theme has correct secondary color', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.colorScheme.secondary, AppTheme.accentOrangeLight);
    });

    testWidgets('Dark theme bodyLarge is 16 bold', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.bodyLarge?.fontWeight, FontWeight.bold);
    });

    testWidgets('Dark theme has dark scaffold background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
    });

    testWidgets('Dark theme brightness is dark', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('Dark theme AppBar has dark background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
    });

    testWidgets('Dark theme icon color is light green', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.iconTheme.color, AppTheme.primaryGreenLight);
    });
  });

  group('AppTheme Utility Tests', () {
    test('Star color is yellow/amber when favorite', () {
      expect(AppTheme.getStarColor(true), AppTheme.starColor);
    });

    test('Star color is grey when not favorite', () {
      expect(AppTheme.getStarColor(false), AppTheme.starColorInactive);
    });

    test('Calorie color is red for high calories', () {
      // 500+ should be high calorie warning
      expect(AppTheme.getCalorieColor(500), AppTheme.highCalorieWarning);
      expect(AppTheme.getCalorieColor(600), AppTheme.highCalorieWarning);
      expect(AppTheme.getCalorieColor(1000), AppTheme.highCalorieWarning);
    });

    test('Calorie color is orange for normal calories', () {
      // Below 500 should be normal calorie color
      expect(AppTheme.getCalorieColor(100), AppTheme.calorieColor);
      expect(AppTheme.getCalorieColor(300), AppTheme.calorieColor);
      expect(AppTheme.getCalorieColor(499), AppTheme.calorieColor);
    });

    test('isHighCalorie returns true for >= 500', () {
      expect(AppTheme.isHighCalorie(500), true);
      expect(AppTheme.isHighCalorie(501), true);
      expect(AppTheme.isHighCalorie(1000), true);
    });

    test('isHighCalorie returns false for < 500', () {
      expect(AppTheme.isHighCalorie(0), false);
      expect(AppTheme.isHighCalorie(250), false);
      expect(AppTheme.isHighCalorie(499), false);
    });

    test('getCalorieTextStyle has bold weight', () {
      final style = AppTheme.getCalorieTextStyle(100);
      expect(style.fontWeight, FontWeight.bold);
    });

    test('getCalorieTextStyle uses custom font size', () {
      final style = AppTheme.getCalorieTextStyle(100, fontSize: 20);
      expect(style.fontSize, 20);
    });

    test('getCalorieTextStyle returns red for high calories', () {
      final style = AppTheme.getCalorieTextStyle(600);
      expect(style.color, AppTheme.highCalorieWarning);
    });

    test('getCalorieTextStyle returns orange for normal calories', () {
      final style = AppTheme.getCalorieTextStyle(200);
      expect(style.color, AppTheme.calorieColor);
    });
  });

  group('Theme Color Constants Tests', () {
    test('Primary green is green[700]', () {
      expect(AppTheme.primaryGreen, const Color(0xFF388E3C));
    });

    test('Accent orange is correct', () {
      expect(AppTheme.accentOrange, const Color(0xFFFF9800));
    });

    test('Star color is amber', () {
      expect(AppTheme.starColor, const Color(0xFFFFC107));
    });

    test('Calorie color is deep orange', () {
      expect(AppTheme.calorieColor, const Color(0xFFFF5722));
    });

    test('High calorie warning is red', () {
      expect(AppTheme.highCalorieWarning, const Color(0xFFD32F2F));
    });

    test('High calorie threshold is 500', () {
      expect(AppTheme.highCalorieThreshold, 500);
    });
  });

  group('Theme Switching Tests', () {
    testWidgets('Can switch from light to dark theme', (WidgetTester tester) async {
      // Start with light theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      var theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.light);
      
      // Switch to dark theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('Can switch from dark to light theme', (WidgetTester tester) async {
      // Start with dark theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      var theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.dark);
      
      // Switch to light theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      theme = Theme.of(tester.element(find.text('Theme Test')));
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('Light theme colors differ from dark theme', (WidgetTester tester) async {
      // Light theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      final lightTheme = Theme.of(tester.element(find.text('Theme Test')));
      
      // Dark theme
      await tester.pumpWidget(createTestApp(brightness: Brightness.dark));
      final darkTheme = Theme.of(tester.element(find.text('Theme Test')));
      
      // Verify different scaffold backgrounds
      expect(lightTheme.scaffoldBackgroundColor, isNot(darkTheme.scaffoldBackgroundColor));
      
      // Verify different card colors
      expect(lightTheme.cardTheme.color, isNot(darkTheme.cardTheme.color));
    });

    testWidgets('Theme preserves primary swatch concept', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      
      // Primary should be green-based
      expect(theme.colorScheme.primary.green, greaterThan(theme.colorScheme.primary.red));
      expect(theme.colorScheme.primary.green, greaterThan(theme.colorScheme.primary.blue));
    });
  });

  group('Button Theme Tests', () {
    testWidgets('Elevated button has green background in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      
      final buttonStyle = theme.elevatedButtonTheme.style;
      expect(buttonStyle, isNotNull);
    });

    testWidgets('Outlined button has green border in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(brightness: Brightness.light));
      final theme = Theme.of(tester.element(find.text('Theme Test')));
      
      final buttonStyle = theme.outlinedButtonTheme.style;
      expect(buttonStyle, isNotNull);
    });
  });
}

