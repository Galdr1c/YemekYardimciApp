import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/models/food_analysis.dart';
import 'package:yemek_yardimci_app/screens/analysis_detail_screen.dart';

void main() {
  // Create test analyses
  final testAnalyses = [
    FoodAnalysis(
      imagePath: '/test/image.jpg',
      foodName: 'Pizza',
      confidence: 0.85,
      estimatedGrams: 150,
      estimatedCalories: 400,
      protein: 15,
      carbs: 45,
      fat: 18,
    ),
    FoodAnalysis(
      imagePath: '/test/image.jpg',
      foodName: 'Salata',
      confidence: 0.92,
      estimatedGrams: 200,
      estimatedCalories: 150,
      protein: 5,
      carbs: 15,
      fat: 8,
    ),
  ];

  Widget createTestWidget({List<FoodAnalysis>? analyses}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = AnalysisProvider();
          // Provider will have empty currentAnalysis by default
          return provider;
        }),
      ],
      child: MaterialApp(
        home: AnalysisDetailScreen(
          analyses: analyses,
          imagePath: '/test/image.jpg',
        ),
      ),
    );
  }

  group('AnalysisDetailScreen Widget Tests', () {
    testWidgets('Renders with correct AppBar title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify AppBar title
      expect(find.text('Analiz Sonuçları'), findsOneWidget);
    });

    testWidgets('AppBar has green background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.green);
    });

    testWidgets('Shows total calories', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Total = 400 + 150 = 550
      expect(find.text('550 kcal'), findsOneWidget);
      expect(find.text('Toplam Kalori'), findsOneWidget);
    });

    testWidgets('Shows food items in list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify food names
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Salata'), findsOneWidget);
    });

    testWidgets('Shows food count badge', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify count badge (2 foods)
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Tespit Edilen Yiyecekler'), findsOneWidget);
    });

    testWidgets('Shows grams and calories for each food', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify portion sizes
      expect(find.text('150g'), findsOneWidget);
      expect(find.text('200g'), findsOneWidget);
      
      // Verify calories
      expect(find.text('400'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('Shows macro totals', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Total protein = 15 + 5 = 20g
      expect(find.text('20g'), findsOneWidget);
      
      // Verify macro labels
      expect(find.text('Protein'), findsWidgets);
      expect(find.text('Karb'), findsOneWidget);
      expect(find.text('Yağ'), findsOneWidget);
    });

    testWidgets('Shows search recipes button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify main search button
      expect(find.text('İlgili Tarifleri Ara'), findsOneWidget);
    });

    testWidgets('FAB for save is present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Geçmişe Kaydet'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('Shows confidence badges', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify confidence percentages
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
    });

    testWidgets('Shows empty state when no analyses', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: []));
      await tester.pump();

      // Verify empty state
      expect(find.text('Analiz sonucu bulunamadı'), findsOneWidget);
    });

    testWidgets('Share button is present in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify share icon
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('Each food item has find recipes button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify individual recipe search buttons
      expect(find.text('Bu yiyecekle tarif ara'), findsNWidgets(2));
    });

    testWidgets('Shows Porsiyon label for grams', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify portion label
      expect(find.text('Porsiyon'), findsWidgets);
    });

    testWidgets('Shows Kalori label', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Verify calorie label
      expect(find.text('Kalori'), findsWidgets);
    });
  });

  group('AnalysisDetailScreen Interaction Tests', () {
    testWidgets('Tapping share button shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Tap share button
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      // Verify snackbar
      expect(find.text('Paylaşım özelliği yakında!'), findsOneWidget);
    });

    testWidgets('Search button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Find and tap the search button
      final searchButton = find.text('İlgili Tarifleri Ara');
      expect(searchButton, findsOneWidget);
      
      // Button should be enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'İlgili Tarifleri Ara'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('FAB is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(analyses: testAnalyses));
      await tester.pump();

      // Find FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      
      // FAB should have onPressed
      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.onPressed, isNotNull);
    });
  });
}

