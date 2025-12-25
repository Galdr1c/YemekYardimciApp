import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/models/recipe.dart';
import 'package:yemek_yardimci_app/screens/recipe_detail_screen.dart';

void main() {
  // Create a test recipe
  final testRecipe = Recipe(
    id: 1,
    title: 'Test Tarif',
    description: 'Test açıklaması',
    imageUrl: 'https://example.com/image.jpg',
    ingredients: ['Malzeme 1', 'Malzeme 2', 'Malzeme 3'],
    instructions: ['Adım 1', 'Adım 2', 'Adım 3'],
    calories: 350,
    protein: 25.0,
    carbs: 30.0,
    fat: 15.0,
    prepTimeMinutes: 15,
    cookTimeMinutes: 30,
    servings: 4,
    category: 'Ana Yemek',
  );

  Widget createTestWidget({Recipe? recipe}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = RecipeProvider();
          if (recipe != null) {
            provider.selectRecipe(recipe);
          }
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: MaterialApp(
        home: RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  group('RecipeDetailScreen Widget Tests', () {
    testWidgets('Renders with recipe name in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify AppBar shows recipe name
      expect(find.text('Test Tarif'), findsOneWidget);
    });

    testWidgets('AppBar has green background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.green);
    });

    testWidgets('Shows Malzemeler section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify ingredients section
      expect(find.text('Malzemeler'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
    });

    testWidgets('Shows Adımlar section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify steps section
      expect(find.text('Adımlar'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });

    testWidgets('Shows calorie information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify calorie display
      expect(find.text('350'), findsOneWidget);
      expect(find.text('Kalori'), findsOneWidget);
    });

    testWidgets('Shows servings and time info', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify time (15 + 30 = 45 total minutes)
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Dakika'), findsOneWidget);

      // Verify servings
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Porsiyon'), findsOneWidget);
    });

    testWidgets('FAB for favorite is present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('Tapping FAB shows snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('Favorilere eklendi'), findsOneWidget);
    });

    testWidgets('Shows all ingredients', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify all ingredients are shown
      expect(find.text('Malzeme 1'), findsOneWidget);
      expect(find.text('Malzeme 2'), findsOneWidget);
      expect(find.text('Malzeme 3'), findsOneWidget);
    });

    testWidgets('Shows nutrition section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify nutrition section
      expect(find.text('Besin Değerleri'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Karbonhidrat'), findsOneWidget);
      expect(find.text('Yağ'), findsOneWidget);
    });

    testWidgets('Shows empty state when no recipe', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: null));
      await tester.pump();

      // Verify empty state
      expect(find.text('Tarif bulunamadı'), findsOneWidget);
    });

    testWidgets('Ingredient count badge is shown', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(recipe: testRecipe));
      await tester.pump();

      // Verify ingredient count (3 ingredients)
      expect(find.text('3'), findsWidgets);
    });
  });
}

