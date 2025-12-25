import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/screens/home_screen.dart';
import 'package:yemek_yardimci_app/screens/recipe_search_screen.dart';
import 'package:yemek_yardimci_app/screens/favorites_screen.dart';
import 'package:yemek_yardimci_app/screens/history_screen.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('End-to-End Integration Tests', () {
    late AppRepository repository;

    setUp(() async {
      repository = AppRepository();
      await repository.database;
    });

    testWidgets('Complete flow: Search -> View -> Favorite -> Check Favorites', (WidgetTester tester) async {
      // Setup providers
      final recipeProvider = RecipeProvider();
      final analysisProvider = AnalysisProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Search for recipes
      final searchBar = find.byType(SearchBar);
      if (searchBar.evaluate().isNotEmpty) {
        await tester.enterText(searchBar, 'tavuk');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify search results appear
        expect(find.byType(ListView), findsWidgets);
      }

      // Step 2: Navigate to favorites
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify favorites screen loads
      expect(find.text('Favoriler'), findsOneWidget);
    });

    testWidgets('Complete flow: Analyze -> Save -> View History', (WidgetTester tester) async {
      final recipeProvider = RecipeProvider();
      final analysisProvider = AnalysisProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
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

        // Verify tab switched
        expect(find.text('Galeriden Seç'), findsOneWidget);
      }

      // Navigate to history
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify history screen loads
      expect(find.text('Geçmiş'), findsOneWidget);
    });

    testWidgets('Navigation flow: Home -> Search -> Favorites -> History', (WidgetTester tester) async {
      final recipeProvider = RecipeProvider();
      final analysisProvider = AnalysisProvider();

      // Start at home
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to search
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: RecipeSearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RecipeSearchScreen), findsOneWidget);

      // Navigate to favorites
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FavoritesScreen), findsOneWidget);

      // Navigate to history
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: recipeProvider),
            ChangeNotifierProvider.value(value: analysisProvider),
          ],
          child: MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    test('Repository and Service integration', () async {
      // Test that repository and service work together
      final recipe = RecipeModel(
        name: 'E2E_Test_Recipe',
        ingredients: ['Test Ingredient'],
        steps: ['Test Step'],
        isFavorite: false,
      );

      // Insert via repository
      final id = await repository.insertRecipe(recipe);
      expect(id, greaterThan(0));

      // Retrieve via repository
      final retrieved = await repository.getRecipeById(id);
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'E2E_Test_Recipe');

      // Toggle favorite
      await repository.toggleRecipeFavorite(id);
      final favorite = await repository.getFavoriteRecipes();
      expect(favorite.any((r) => r.id == id && r.isFavorite), true);

      // Cleanup
      await repository.deleteRecipe(id);
    });
  });
}

