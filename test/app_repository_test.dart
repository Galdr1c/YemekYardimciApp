import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('RecipeModel Tests', () {
    test('should create RecipeModel with required fields', () {
      final recipe = RecipeModel(
        name: 'Test Omlet',
        ingredients: ['2 yumurta', 'Tuz', 'Karabiber'],
        steps: ['Yumurtaları çırp', 'Pişir'],
      );

      expect(recipe.name, 'Test Omlet');
      expect(recipe.ingredients.length, 3);
      expect(recipe.steps.length, 2);
      expect(recipe.isFavorite, false);
      expect(recipe.calories, 0);
    });

    test('should create RecipeModel with all fields', () {
      final recipe = RecipeModel(
        name: 'Menemen',
        ingredients: ['Yumurta', 'Domates', 'Biber'],
        steps: ['Kavur', 'Yumurta ekle', 'Pişir'],
        imageUrl: 'https://example.com/menemen.jpg',
        isFavorite: true,
        calories: 280,
        protein: 16.0,
        carbs: 12.0,
        fat: 18.0,
        prepTime: 10,
        cookTime: 15,
        servings: 2,
        category: 'Kahvaltı',
      );

      expect(recipe.name, 'Menemen');
      expect(recipe.isFavorite, true);
      expect(recipe.calories, 280);
      expect(recipe.protein, 16.0);
      expect(recipe.category, 'Kahvaltı');
      expect(recipe.totalTime, 25);
    });

    test('should convert RecipeModel to Map', () {
      final recipe = RecipeModel(
        name: 'Test Recipe',
        ingredients: ['Ing1', 'Ing2'],
        steps: ['Step1', 'Step2'],
        calories: 200,
        isFavorite: true,
      );

      final map = recipe.toMap();

      expect(map['name'], 'Test Recipe');
      expect(map['calories'], 200);
      expect(map['is_favorite'], 1);
      expect(map.containsKey('ingredients'), true);
      expect(map.containsKey('steps'), true);
    });

    test('should create RecipeModel from Map', () {
      final map = {
        'id': 1,
        'name': 'DB Recipe',
        'ingredients': '["Yumurta","Tuz"]',
        'steps': '["Pişir","Servis et"]',
        'image_url': 'https://example.com/test.jpg',
        'is_favorite': 1,
        'calories': 150,
        'protein': 10.0,
        'carbs': 5.0,
        'fat': 8.0,
        'prep_time': 5,
        'cook_time': 10,
        'servings': 1,
        'category': 'Test',
        'created_at': DateTime.now().toIso8601String(),
      };

      final recipe = RecipeModel.fromMap(map);

      expect(recipe.id, 1);
      expect(recipe.name, 'DB Recipe');
      expect(recipe.ingredients.length, 2);
      expect(recipe.isFavorite, true);
      expect(recipe.calories, 150);
    });

    test('should copy RecipeModel with modified fields', () {
      final original = RecipeModel(
        name: 'Original',
        ingredients: ['Ing1'],
        steps: ['Step1'],
        isFavorite: false,
      );

      final copied = original.copyWith(
        name: 'Modified',
        isFavorite: true,
        calories: 300,
      );

      expect(copied.name, 'Modified');
      expect(copied.isFavorite, true);
      expect(copied.calories, 300);
      expect(copied.ingredients, original.ingredients);
    });
  });

  group('AnalysisModel Tests', () {
    test('should create AnalysisModel with required fields', () {
      final analysis = AnalysisModel(
        date: '2024-12-24',
        photoPath: '/path/to/photo.jpg',
        foods: [
          FoodItem(name: 'Yumurta', grams: 100, calories: 155),
        ],
      );

      expect(analysis.date, '2024-12-24');
      expect(analysis.photoPath, '/path/to/photo.jpg');
      expect(analysis.foods.length, 1);
      expect(analysis.totalCalories, 155);
    });

    test('should calculate total calories automatically', () {
      final analysis = AnalysisModel(
        date: '2024-12-24',
        photoPath: '/path/to/photo.jpg',
        foods: [
          FoodItem(name: 'Yumurta', grams: 100, calories: 155),
          FoodItem(name: 'Ekmek', grams: 50, calories: 130),
          FoodItem(name: 'Peynir', grams: 30, calories: 100),
        ],
      );

      expect(analysis.totalCalories, 385);
    });

    test('should convert AnalysisModel to Map', () {
      final analysis = AnalysisModel(
        date: '2024-12-24',
        photoPath: '/path/to/photo.jpg',
        foods: [
          FoodItem(name: 'Test', grams: 100, calories: 100),
        ],
        notes: 'Test note',
      );

      final map = analysis.toMap();

      expect(map['date'], '2024-12-24');
      expect(map['photo_path'], '/path/to/photo.jpg');
      expect(map['notes'], 'Test note');
      expect(map.containsKey('foods'), true);
    });

    test('should create AnalysisModel from Map', () {
      final map = {
        'id': 1,
        'date': '2024-12-24',
        'photo_path': '/test/photo.jpg',
        'foods': '[{"name":"Yumurta","grams":100,"calories":155,"protein":13.0,"carbs":1.1,"fat":11.0}]',
        'total_calories': 155,
        'total_protein': 13.0,
        'total_carbs': 1.1,
        'total_fat': 11.0,
        'notes': 'Kahvaltı',
        'created_at': DateTime.now().toIso8601String(),
      };

      final analysis = AnalysisModel.fromMap(map);

      expect(analysis.id, 1);
      expect(analysis.date, '2024-12-24');
      expect(analysis.foods.length, 1);
      expect(analysis.foods.first.name, 'Yumurta');
      expect(analysis.totalCalories, 155);
      expect(analysis.notes, 'Kahvaltı');
    });
  });

  group('FoodItem Tests', () {
    test('should create FoodItem with required fields', () {
      final food = FoodItem(
        name: 'Tavuk',
        grams: 150,
        calories: 250,
      );

      expect(food.name, 'Tavuk');
      expect(food.grams, 150);
      expect(food.calories, 250);
      expect(food.protein, 0.0);
    });

    test('should create FoodItem with all fields', () {
      final food = FoodItem(
        name: 'Tavuk',
        grams: 150,
        calories: 250,
        protein: 31.0,
        carbs: 0.0,
        fat: 5.4,
      );

      expect(food.name, 'Tavuk');
      expect(food.protein, 31.0);
      expect(food.carbs, 0.0);
      expect(food.fat, 5.4);
    });

    test('should convert FoodItem to Map', () {
      final food = FoodItem(
        name: 'Test Food',
        grams: 100,
        calories: 200,
        protein: 10.0,
      );

      final map = food.toMap();

      expect(map['name'], 'Test Food');
      expect(map['grams'], 100);
      expect(map['calories'], 200);
      expect(map['protein'], 10.0);
    });

    test('should create FoodItem from Map', () {
      final map = {
        'name': 'Pilav',
        'grams': 150.0,
        'calories': 190,
        'protein': 3.8,
        'carbs': 37.5,
        'fat': 3.8,
      };

      final food = FoodItem.fromMap(map);

      expect(food.name, 'Pilav');
      expect(food.grams, 150.0);
      expect(food.calories, 190);
      expect(food.protein, 3.8);
    });
  });

  group('AppRepository Mock Tests', () {
    test('should create singleton instance', () {
      final repo1 = AppRepository();
      final repo2 = AppRepository();

      expect(identical(repo1, repo2), true);
    });

    test('sample recipes should have valid structure', () {
      // Test the sample data structure
      final sampleRecipes = [
        RecipeModel(
          name: 'Omlet',
          ingredients: ['2 yumurta', 'Tuz'],
          steps: ['Çırp', 'Pişir'],
          imageUrl: 'https://example.com/omlet.jpg',
          calories: 200,
        ),
      ];

      expect(sampleRecipes.first.name.isNotEmpty, true);
      expect(sampleRecipes.first.ingredients.isNotEmpty, true);
      expect(sampleRecipes.first.steps.isNotEmpty, true);
      expect(sampleRecipes.first.calories > 0, true);
    });

    test('sample analyses should have valid structure', () {
      final sampleAnalysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/mock/test.jpg',
        foods: [
          FoodItem(name: 'Test Food', grams: 100, calories: 150),
        ],
        totalCalories: 150,
      );

      expect(sampleAnalysis.date.isNotEmpty, true);
      expect(sampleAnalysis.photoPath.isNotEmpty, true);
      expect(sampleAnalysis.foods.isNotEmpty, true);
      expect(sampleAnalysis.totalCalories, 150);
    });
  });

  group('Data Validation Tests', () {
    test('RecipeModel should handle empty ingredients', () {
      final recipe = RecipeModel(
        name: 'Empty Recipe',
        ingredients: [],
        steps: [],
      );

      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
    });

    test('AnalysisModel should handle empty foods list', () {
      final analysis = AnalysisModel(
        date: '2024-12-24',
        photoPath: '/path/test.jpg',
        foods: [],
      );

      expect(analysis.foods, isEmpty);
      expect(analysis.totalCalories, 0);
    });

    test('FoodItem should handle zero values', () {
      final food = FoodItem(
        name: 'Zero Food',
        grams: 0,
        calories: 0,
      );

      expect(food.grams, 0);
      expect(food.calories, 0);
    });

    test('RecipeModel JSON parsing should handle malformed data', () {
      final map = {
        'id': 1,
        'name': 'Test',
        'ingredients': 'not|json|format',
        'steps': 'also|not|json',
        'image_url': '',
        'is_favorite': 0,
        'calories': 0,
        'prep_time': 0,
        'cook_time': 0,
        'servings': 1,
        'category': 'Test',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Should not throw
      final recipe = RecipeModel.fromMap(map);
      expect(recipe.name, 'Test');
    });
  });

  group('Date Handling Tests', () {
    test('should format date correctly for analysis', () {
      final now = DateTime.now();
      final dateString = now.toIso8601String().split('T')[0];
      
      expect(dateString.contains('-'), true);
      expect(dateString.length, 10); // YYYY-MM-DD format
    });

    test('should handle yesterday date calculation', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      expect(yesterday.day != today.day || yesterday.month != today.month, true);
    });
  });
}

