import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/screens/analysis_detail_screen.dart';
import 'package:yemek_yardimci_app/models/food_analysis.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';

void main() {
  group('Share Widget Tests', () {
    testWidgets('AnalysisDetailScreen shows share button', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Test Food',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 200,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      // Find share button in AppBar
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byTooltip('Paylaş'), findsOneWidget);
    });

    testWidgets('AnalysisDetailScreen shows recipe search buttons', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Elma',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 52,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find recipe search buttons
      expect(find.text('Tüm Yiyecekler İçin Tarif Ara'), findsOneWidget);
      expect(find.textContaining('için ara'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('Share button triggers share action', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Test Food',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 200,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      // Find and tap share button
      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsOneWidget);

      await tester.tap(shareButton);
      await tester.pump();

      // Should show loading or snackbar
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Recipe search button navigates', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Elma',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 52,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap recipe search button
      final searchButton = find.text('Tüm Yiyecekler İçin Tarif Ara');
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pump();

        // Should show loading or navigate
        expect(find.byType(SnackBar), findsWidgets);
      }
    });
  });
}

