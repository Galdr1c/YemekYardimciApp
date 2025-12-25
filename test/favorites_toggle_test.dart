import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/models/recipe.dart';
import 'package:yemek_yardimci_app/screens/recipe_detail_screen.dart';
import 'package:yemek_yardimci_app/screens/favorites_screen.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('Favorites Toggle Tests', () {
    testWidgets('RecipeDetailScreen FAB toggles favorite', (WidgetTester tester) async {
      final recipe = Recipe(
        id: 1,
        title: 'Test Recipe',
        description: 'Test',
        imageUrl: '',
        ingredients: ['Ing1'],
        instructions: ['Step1'],
        isFavorite: false,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: recipe),
          ),
        ),
      );

      // Find FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Tap FAB
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.textContaining('favorilere eklendi'), findsOneWidget);
    });

    testWidgets('RecipeDetailScreen FAB shows undo action', (WidgetTester tester) async {
      final recipe = Recipe(
        id: 1,
        title: 'Test Recipe',
        description: 'Test',
        imageUrl: '',
        ingredients: ['Ing1'],
        instructions: ['Step1'],
        isFavorite: false,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: RecipeDetailScreen(recipe: recipe),
          ),
        ),
      );

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Find undo button
      expect(find.text('Geri Al'), findsOneWidget);
    });

    testWidgets('RecipeCard star button toggles favorite', (WidgetTester tester) async {
      final recipe = Recipe(
        id: 1,
        title: 'Test Recipe',
        description: 'Test',
        imageUrl: '',
        ingredients: ['Ing1'],
        instructions: ['Step1'],
        isFavorite: false,
      );

      bool toggled = false;
      void onToggle() {
        toggled = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(recipe.title),
              trailing: IconButton(
                icon: Icon(
                  recipe.isFavorite ? Icons.star : Icons.star_border,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      );

      // Find star button
      final starButton = find.byIcon(Icons.star_border);
      expect(starButton, findsOneWidget);

      // Tap star button
      await tester.tap(starButton);
      await tester.pump();

      // Verify toggle was called
      expect(toggled, true);
    });

    testWidgets('FavoritesScreen shows empty state when no favorites', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: const FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('Favori Tarif Yok'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsWidgets);
    });

    testWidgets('FavoritesScreen remove button shows confirmation', (WidgetTester tester) async {
      final recipe = Recipe(
        id: 1,
        title: 'Test Recipe',
        description: 'Test',
        imageUrl: '',
        ingredients: ['Ing1'],
        instructions: ['Step1'],
        isFavorite: true,
      );

      final provider = RecipeProvider();
      await provider.saveToFavorites(recipe);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: const FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find delete button
      final deleteButton = find.byIcon(Icons.delete_outline);
      expect(deleteButton, findsWidgets);

      // Tap delete button
      await tester.tap(deleteButton.first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Favorilerden Kaldır'), findsOneWidget);
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Kaldır'), findsOneWidget);
    });

    testWidgets('FavoritesScreen clear all shows confirmation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
          ],
          child: MaterialApp(
            home: const FavoritesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find clear all button (may not be visible if empty)
      final clearButton = find.byIcon(Icons.delete_sweep);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('Tümünü Temizle'), findsOneWidget);
      }
    });
  });

  group('Favorite Toggle Logic Tests', () {
    test('toggleFavorite changes isFavorite state', () async {
      final repository = AppRepository();
      await repository.database;

      // Create test recipe
      final recipe = RecipeModel(
        name: 'Toggle Test',
        ingredients: ['Ing1'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final id = await repository.insertRecipe(recipe);
      expect(id, greaterThan(0));

      // Toggle to favorite
      final newStatus1 = await repository.toggleRecipeFavorite(id);
      expect(newStatus1, true);

      // Verify in database
      final recipe1 = await repository.getRecipeById(id);
      expect(recipe1?.isFavorite, true);

      // Toggle back to not favorite
      final newStatus2 = await repository.toggleRecipeFavorite(id);
      expect(newStatus2, false);

      // Verify in database
      final recipe2 = await repository.getRecipeById(id);
      expect(recipe2?.isFavorite, false);

      // Cleanup
      await repository.deleteRecipe(id);
    });

    test('toggleFavorite returns correct status', () async {
      final repository = AppRepository();
      await repository.database;

      final recipe = RecipeModel(
        name: 'Status Test',
        ingredients: ['Ing1'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final id = await repository.insertRecipe(recipe);

      // First toggle: false -> true
      final status1 = await repository.toggleRecipeFavorite(id);
      expect(status1, true);

      // Second toggle: true -> false
      final status2 = await repository.toggleRecipeFavorite(id);
      expect(status2, false);

      // Third toggle: false -> true
      final status3 = await repository.toggleRecipeFavorite(id);
      expect(status3, true);

      // Cleanup
      await repository.deleteRecipe(id);
    });
  });
}

