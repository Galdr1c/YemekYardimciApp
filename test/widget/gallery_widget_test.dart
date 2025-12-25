import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/screens/home_screen.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';

void main() {
  group('Gallery Import Widget Tests', () {
    testWidgets('HomeScreen shows gallery button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to calorie calculator tab
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 2) {
        await tester.tap(tabs.last);
        await tester.pumpAndSettle();

        // Find gallery button
        expect(find.text('Galeriden Seç'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      }
    });

    testWidgets('Gallery button is enabled when not analyzing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to calorie calculator tab
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 2) {
        await tester.tap(tabs.last);
        await tester.pumpAndSettle();

        // Find gallery button
        final galleryButton = find.text('Galeriden Seç');
        expect(galleryButton, findsOneWidget);

        // Button should be enabled (not disabled)
        final button = tester.widget<OutlinedButton>(galleryButton);
        // Note: onPressed should not be null when enabled
        expect(button.onPressed, isNotNull);
      }
    });

    testWidgets('Camera and gallery buttons both present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to calorie calculator tab
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 2) {
        await tester.tap(tabs.last);
        await tester.pumpAndSettle();

        // Both buttons should be present
        expect(find.text('Fotoğraf Çek'), findsOneWidget);
        expect(find.text('Galeriden Seç'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      }
    });
  });
}

