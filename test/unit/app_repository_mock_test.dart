import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('AppRepository Mock Tests', () {
    late AppRepository repository;

    setUp(() async {
      repository = AppRepository();
      await repository.database;
    });

    tearDown(() async {
      // Clean up test data
      final allRecipes = await repository.getAllRecipes();
      for (final recipe in allRecipes) {
        if (recipe.id != null && recipe.name.startsWith('Test_')) {
          await repository.deleteRecipe(recipe.id!);
        }
      }
    });

    test('insertRecipe returns valid ID', () async {
      final recipe = RecipeModel(
        name: 'Test_Recipe_1',
        ingredients: ['Test Ingredient'],
        steps: ['Test Step'],
        isFavorite: false,
      );

      final id = await repository.insertRecipe(recipe);
      expect(id, greaterThan(0));
    });

    test('getRecipeById returns correct recipe', () async {
      final recipe = RecipeModel(
        name: 'Test_Recipe_2',
        ingredients: ['Ing1', 'Ing2'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final id = await repository.insertRecipe(recipe);
      final retrieved = await repository.getRecipeById(id);

      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'Test_Recipe_2');
      expect(retrieved?.ingredients.length, 2);
    });

    test('toggleRecipeFavorite changes status', () async {
      final recipe = RecipeModel(
        name: 'Test_Recipe_3',
        ingredients: ['Ing1'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final id = await repository.insertRecipe(recipe);
      
      // Toggle to favorite
      final status1 = await repository.toggleRecipeFavorite(id);
      expect(status1, true);

      // Verify
      final recipe1 = await repository.getRecipeById(id);
      expect(recipe1?.isFavorite, true);

      // Toggle back
      final status2 = await repository.toggleRecipeFavorite(id);
      expect(status2, false);

      // Verify
      final recipe2 = await repository.getRecipeById(id);
      expect(recipe2?.isFavorite, false);
    });

    test('searchRecipes finds matching recipes', () async {
      // Insert test recipes
      final recipe1 = RecipeModel(
        name: 'Test_Recipe_4',
        ingredients: ['domates', 'soğan'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final recipe2 = RecipeModel(
        name: 'Test_Recipe_5',
        ingredients: ['patates', 'soğan'],
        steps: ['Step1'],
        isFavorite: false,
      );

      await repository.insertRecipe(recipe1);
      await repository.insertRecipe(recipe2);

      // Search for 'soğan'
      final results = await repository.searchRecipes('soğan');
      
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.any((r) => r.name == 'Test_Recipe_4'), true);
      expect(results.any((r) => r.name == 'Test_Recipe_5'), true);
    });

    test('insertAnalysis saves correctly', () async {
      final analysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path.jpg',
        foods: [
          FoodItem(name: 'Test Food', grams: 100, calories: 200),
        ],
      );

      final id = await repository.insertAnalysis(analysis);
      expect(id, greaterThan(0));

      final retrieved = await repository.getAnalysisById(id);
      expect(retrieved, isNotNull);
      expect(retrieved?.foods.length, 1);
      expect(retrieved?.foods.first.name, 'Test Food');
    });

    test('deleteAnalysis removes from database', () async {
      final analysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path.jpg',
        foods: [FoodItem(name: 'Test', grams: 100, calories: 200)],
      );

      final id = await repository.insertAnalysis(analysis);
      
      final deleted = await repository.deleteAnalysis(id);
      expect(deleted, 1);

      final retrieved = await repository.getAnalysisById(id);
      expect(retrieved, isNull);
    });

    test('getFavoriteRecipes returns only favorites', () async {
      final recipe1 = RecipeModel(
        name: 'Test_Recipe_6',
        ingredients: ['Ing1'],
        steps: ['Step1'],
        isFavorite: true,
      );

      final recipe2 = RecipeModel(
        name: 'Test_Recipe_7',
        ingredients: ['Ing2'],
        steps: ['Step2'],
        isFavorite: false,
      );

      await repository.insertRecipe(recipe1);
      await repository.insertRecipe(recipe2);

      final favorites = await repository.getFavoriteRecipes();
      
      expect(favorites.any((r) => r.name == 'Test_Recipe_6'), true);
      expect(favorites.any((r) => r.name == 'Test_Recipe_7'), false);
    });
  });
}

