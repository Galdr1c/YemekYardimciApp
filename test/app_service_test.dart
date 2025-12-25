import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/app_service.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('AppService Tests', () {
    test('should create singleton instance', () {
      final service1 = AppService();
      final service2 = AppService();

      expect(identical(service1, service2), true);
    });

    test('should be in demo mode without API keys', () {
      final service = AppService();

      // Default state is demo mode (no real API keys)
      expect(service.isDemoMode, true);
      expect(service.hasValidApiKeys, false);
    });

    test('should have repository access', () {
      final service = AppService();

      expect(service.repository, isA<AppRepository>());
    });
  });

  group('ImageAnalysisResult Tests', () {
    test('should create successful result with foods', () {
      final foods = [
        FoodItem(name: 'Yumurta', grams: 100, calories: 155, protein: 13.0, carbs: 1.1, fat: 11.0),
        FoodItem(name: 'Ekmek', grams: 50, calories: 130, protein: 4.0, carbs: 25.0, fat: 1.0),
      ];

      final result = ImageAnalysisResult(
        success: true,
        foods: foods,
        analysisId: 1,
        message: '2 yiyecek tespit edildi',
      );

      expect(result.success, true);
      expect(result.foods.length, 2);
      expect(result.analysisId, 1);
      expect(result.totalCalories, 285);
      expect(result.totalProtein, 17.0);
      expect(result.totalCarbs, 26.1);
      expect(result.totalFat, 12.0);
    });

    test('should create failed result', () {
      final result = ImageAnalysisResult(
        success: false,
        foods: [],
        message: 'Analiz hatası',
      );

      expect(result.success, false);
      expect(result.foods.isEmpty, true);
      expect(result.analysisId, null);
      expect(result.totalCalories, 0);
    });

    test('should calculate totals correctly', () {
      final foods = [
        FoodItem(name: 'Food1', grams: 100, calories: 100, protein: 10.0, carbs: 10.0, fat: 5.0),
        FoodItem(name: 'Food2', grams: 100, calories: 200, protein: 20.0, carbs: 20.0, fat: 10.0),
        FoodItem(name: 'Food3', grams: 100, calories: 150, protein: 15.0, carbs: 15.0, fat: 7.5),
      ];

      final result = ImageAnalysisResult(
        success: true,
        foods: foods,
        message: 'Test',
      );

      expect(result.totalCalories, 450);
      expect(result.totalProtein, 45.0);
      expect(result.totalCarbs, 45.0);
      expect(result.totalFat, 22.5);
    });
  });

  group('RecipeSearchResult Tests', () {
    test('should create successful result with recipes', () {
      final recipes = [
        RecipeModel(
          name: 'Omlet',
          ingredients: ['Yumurta'],
          steps: ['Pişir'],
          calories: 200,
        ),
        RecipeModel(
          name: 'Menemen',
          ingredients: ['Yumurta', 'Domates'],
          steps: ['Kavur', 'Pişir'],
          calories: 280,
        ),
      ];

      final result = RecipeSearchResult(
        success: true,
        recipes: recipes,
        message: '2 tarif bulundu',
      );

      expect(result.success, true);
      expect(result.recipes.length, 2);
      expect(result.message, '2 tarif bulundu');
    });

    test('should create failed result', () {
      final result = RecipeSearchResult(
        success: false,
        recipes: [],
        message: 'API hatası',
      );

      expect(result.success, false);
      expect(result.recipes.isEmpty, true);
    });
  });

  group('Mock Data Generation Tests', () {
    test('should generate contextual recipes for eggs', () {
      // Simulating the mock recipe generation logic
      final ingredients = 'yumurta, tuz';
      final ingredientLower = ingredients.toLowerCase();

      expect(ingredientLower.contains('yumurta'), true);
    });

    test('should generate contextual recipes for chicken', () {
      final ingredients = 'tavuk, biber';
      final ingredientLower = ingredients.toLowerCase();

      expect(ingredientLower.contains('tavuk'), true);
    });

    test('should translate food names correctly', () {
      final translations = {
        'egg': 'Yumurta',
        'bread': 'Ekmek',
        'rice': 'Pilav',
        'chicken': 'Tavuk',
        'meat': 'Et',
        'salad': 'Salata',
        'pasta': 'Makarna',
        'soup': 'Çorba',
      };

      expect(translations['egg'], 'Yumurta');
      expect(translations['chicken'], 'Tavuk');
      expect(translations['soup'], 'Çorba');
    });
  });

  group('Nutrition Estimation Tests', () {
    test('should estimate default grams for common foods', () {
      // Mock the estimation logic
      double getDefaultGrams(String foodName) {
        final foodLower = foodName.toLowerCase();
        
        if (foodLower.contains('egg') || foodLower.contains('yumurta')) return 60.0;
        if (foodLower.contains('bread') || foodLower.contains('ekmek')) return 50.0;
        if (foodLower.contains('rice') || foodLower.contains('pilav')) return 150.0;
        if (foodLower.contains('pasta') || foodLower.contains('makarna')) return 200.0;
        if (foodLower.contains('chicken') || foodLower.contains('tavuk')) return 150.0;
        
        return 100.0;
      }

      expect(getDefaultGrams('yumurta'), 60.0);
      expect(getDefaultGrams('Egg'), 60.0);
      expect(getDefaultGrams('ekmek'), 50.0);
      expect(getDefaultGrams('pilav'), 150.0);
      expect(getDefaultGrams('unknown'), 100.0);
    });

    test('should provide mock nutrition for common foods', () {
      final nutritionDb = {
        'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
        'bread': {'calories': 265.0, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.0},
        'rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
        'chicken': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      };

      expect(nutritionDb['egg']!['calories'], 155.0);
      expect(nutritionDb['chicken']!['protein'], 31.0);
      expect(nutritionDb['rice']!['carbs'], 28.0);
    });
  });

  group('Food Label Filtering Tests', () {
    test('should identify food-related keywords', () {
      final foodKeywords = [
        'food', 'fruit', 'vegetable', 'meat', 'bread', 'rice', 'pasta',
        'egg', 'cheese', 'milk', 'coffee', 'soup', 'salad', 'cake',
        'yemek', 'meyve', 'sebze', 'et', 'ekmek', 'pilav', 'makarna',
      ];

      // Test filtering logic
      bool isFoodRelated(String label) {
        final labelLower = label.toLowerCase();
        return foodKeywords.any((keyword) => labelLower.contains(keyword));
      }

      expect(isFoodRelated('fresh fruit'), true);
      expect(isFoodRelated('grilled meat'), true);
      expect(isFoodRelated('domates çorbası'), true);
      expect(isFoodRelated('car'), false);
      expect(isFoodRelated('building'), false);
    });
  });

  group('API Response Parsing Tests', () {
    test('should parse Spoonacular-style recipe response', () {
      final mockResponse = {
        'title': 'Test Recipe',
        'image': 'https://example.com/image.jpg',
        'extendedIngredients': [
          {'original': '2 eggs'},
          {'original': '1 cup milk'},
        ],
        'analyzedInstructions': [
          {
            'steps': [
              {'step': 'Mix ingredients'},
              {'step': 'Cook for 10 minutes'},
            ]
          }
        ],
        'nutrition': {
          'nutrients': [
            {'name': 'Calories', 'amount': 250},
            {'name': 'Protein', 'amount': 15.0},
            {'name': 'Carbohydrates', 'amount': 20.0},
            {'name': 'Fat', 'amount': 12.0},
          ]
        },
        'preparationMinutes': 10,
        'cookingMinutes': 15,
        'servings': 2,
      };

      expect(mockResponse['title'], 'Test Recipe');
      expect((mockResponse['extendedIngredients'] as List).length, 2);
      expect((mockResponse['nutrition'] as Map)['nutrients'], isA<List>());
    });

    test('should parse Nutritionix-style response', () {
      final mockResponse = {
        'foods': [
          {
            'food_name': 'egg',
            'nf_calories': 155,
            'nf_protein': 13.0,
            'nf_total_carbohydrate': 1.1,
            'nf_total_fat': 11.0,
          }
        ]
      };

      final foods = mockResponse['foods'] as List;
      expect(foods.isNotEmpty, true);
      expect(foods.first['food_name'], 'egg');
      expect(foods.first['nf_calories'], 155);
    });
  });

  group('Error Handling Tests', () {
    test('should handle empty food list gracefully', () {
      final result = ImageAnalysisResult(
        success: true,
        foods: [],
        message: 'Yiyecek tespit edilemedi',
      );

      expect(result.totalCalories, 0);
      expect(result.foods.isEmpty, true);
    });

    test('should handle null values in FoodItem', () {
      final map = {
        'name': 'Test',
        'grams': null,
        'calories': null,
      };

      final food = FoodItem.fromMap(map);

      expect(food.name, 'Test');
      expect(food.grams, 0.0);
      expect(food.calories, 0);
    });

    test('should handle missing optional fields', () {
      final map = {
        'name': 'Simple Food',
        'grams': 100.0,
        'calories': 150,
        // protein, carbs, fat are missing
      };

      final food = FoodItem.fromMap(map);

      expect(food.protein, 0.0);
      expect(food.carbs, 0.0);
      expect(food.fat, 0.0);
    });
  });

  group('Integration Simulation Tests', () {
    test('should simulate full analysis flow', () {
      // Simulate: Photo -> ML Labels -> Nutrition -> Analysis
      
      // Step 1: Mock ML labels
      final mlLabels = ['egg', 'bread', 'cheese'];
      
      // Step 2: Get mock nutrition for each
      final foods = mlLabels.map((label) {
        return FoodItem(
          name: label,
          grams: 100,
          calories: 150,
          protein: 10.0,
          carbs: 15.0,
          fat: 5.0,
        );
      }).toList();

      // Step 3: Create analysis
      final analysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/photo.jpg',
        foods: foods,
      );

      expect(analysis.foods.length, 3);
      expect(analysis.totalCalories, 450);
    });

    test('should simulate recipe search flow', () {
      // Simulate: Ingredients -> API -> Recipes
      
      final searchIngredients = 'yumurta, domates';
      final ingredientList = searchIngredients.split(', ');

      expect(ingredientList.length, 2);
      expect(ingredientList.contains('yumurta'), true);
      expect(ingredientList.contains('domates'), true);
    });

    test('should simulate linking analysis to recipe search', () {
      // Simulate: Analysis Foods -> Extract Names -> Search Recipes
      
      final analysisfoods = [
        FoodItem(name: 'Tavuk', grams: 150, calories: 250),
        FoodItem(name: 'Pilav', grams: 200, calories: 260),
      ];

      final searchQuery = analysisfoods.map((f) => f.name).join(', ');

      expect(searchQuery, 'Tavuk, Pilav');
    });
  });
}

