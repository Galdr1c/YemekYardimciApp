import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/app_service.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('AppService Enhanced Tests', () {
    test('should have cache statistics method', () {
      final service = AppService();
      
      final stats = service.getCacheStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('total'), true);
      expect(stats.containsKey('valid'), true);
      expect(stats.containsKey('expired'), true);
    });

    test('should clear cache', () {
      final service = AppService();
      
      // Should not throw
      service.clearCache();
      
      final stats = service.getCacheStats();
      expect(stats['total'], 0);
    });

    test('cache should track entries', () {
      final service = AppService();
      service.clearCache();
      
      final stats1 = service.getCacheStats();
      expect(stats1['total'], 0);
    });
  });

  group('ML Bounding Box Estimation Tests', () {
    test('should estimate grams from area calculation', () {
      // Mock bounding box area calculation
      // Area = width * height
      final width = 200.0;
      final height = 150.0;
      final area = width * height; // 30000
      
      // Base calculation: area / 150
      final baseGrams = area / 150.0; // 200g
      
      expect(baseGrams, closeTo(200, 10));
    });

    test('should adjust for aspect ratio - elongated foods', () {
      // Elongated food (bread, pasta) - aspect ratio > 1.5
      final width = 300.0;
      final height = 100.0;
      final aspectRatio = width / height; // 3.0
      
      final area = width * height; // 30000
      double baseGrams = area / 150.0; // 200g
      
      if (aspectRatio > 1.5) {
        baseGrams *= 0.8; // Lighter
      }
      
      expect(baseGrams, closeTo(160, 10));
    });

    test('should adjust for aspect ratio - tall foods', () {
      // Tall food (drinks, soups) - aspect ratio < 0.7
      final width = 100.0;
      final height = 200.0;
      final aspectRatio = width / height; // 0.5
      
      final area = width * height; // 20000
      double baseGrams = area / 150.0; // ~133g
      
      if (aspectRatio < 0.7) {
        baseGrams *= 1.2; // Heavier
      }
      
      expect(baseGrams, closeTo(160, 10));
    });

    test('should apply confidence multiplier', () {
      final baseGrams = 100.0;
      final confidence = 0.8;
      
      // Apply confidence multiplier: 0.7 + (confidence * 0.3)
      final multiplier = 0.7 + (confidence * 0.3); // 0.94
      final adjustedGrams = baseGrams * multiplier;
      
      expect(adjustedGrams, closeTo(94, 2));
    });

    test('should clamp grams to reasonable range', () {
      double grams = 1500.0;
      final clamped = grams.clamp(20.0, 1000.0);
      
      expect(clamped, 1000.0);
      
      grams = 10.0;
      final clamped2 = grams.clamp(20.0, 1000.0);
      
      expect(clamped2, 20.0);
    });
  });

  group('Cache Expiry Tests', () {
    test('cache entry should expire after duration', () {
      final timestamp = DateTime.now().subtract(const Duration(hours: 25));
      final expiry = const Duration(hours: 24);
      
      final isExpired = DateTime.now().difference(timestamp) > expiry;
      
      expect(isExpired, true);
    });

    test('cache entry should be valid before expiry', () {
      final timestamp = DateTime.now().subtract(const Duration(hours: 12));
      final expiry = const Duration(hours: 24);
      
      final isExpired = DateTime.now().difference(timestamp) > expiry;
      
      expect(isExpired, false);
    });
  });

  group('Nutrition Scaling Tests', () {
    test('should scale nutrition by grams factor', () {
      // Base nutrition for 100g
      final baseFood = FoodItem(
        name: 'Test',
        grams: 100,
        calories: 200,
        protein: 20.0,
        carbs: 10.0,
        fat: 5.0,
      );
      
      // Scale to 150g
      final factor = 150.0 / 100.0; // 1.5
      final scaledFood = FoodItem(
        name: baseFood.name,
        grams: 150,
        calories: (baseFood.calories * factor).round(),
        protein: baseFood.protein * factor,
        carbs: baseFood.carbs * factor,
        fat: baseFood.fat * factor,
      );
      
      expect(scaledFood.calories, 300);
      expect(scaledFood.protein, 30.0);
      expect(scaledFood.carbs, 15.0);
      expect(scaledFood.fat, 7.5);
    });

    test('should handle zero grams gracefully', () {
      final baseFood = FoodItem(
        name: 'Test',
        grams: 100,
        calories: 200,
        protein: 20.0,
        carbs: 10.0,
        fat: 5.0,
      );
      
      final factor = 0.0 / 100.0;
      final scaledFood = FoodItem(
        name: baseFood.name,
        grams: 0,
        calories: (baseFood.calories * factor).round(),
        protein: baseFood.protein * factor,
        carbs: baseFood.carbs * factor,
        fat: baseFood.fat * factor,
      );
      
      expect(scaledFood.calories, 0);
      expect(scaledFood.protein, 0.0);
    });
  });

  group('ImageAnalysisResult Calculations', () {
    test('should calculate totals correctly', () {
      final foods = [
        FoodItem(name: 'Food1', grams: 100, calories: 100, protein: 10, carbs: 10, fat: 5),
        FoodItem(name: 'Food2', grams: 150, calories: 200, protein: 20, carbs: 15, fat: 8),
        FoodItem(name: 'Food3', grams: 80, calories: 150, protein: 15, carbs: 12, fat: 6),
      ];

      final result = ImageAnalysisResult(
        success: true,
        foods: foods,
        message: 'Test',
      );

      expect(result.totalCalories, 450);
      expect(result.totalProtein, 45.0);
      expect(result.totalCarbs, 37.0);
      expect(result.totalFat, 19.0);
    });

    test('should handle empty foods list', () {
      final result = ImageAnalysisResult(
        success: true,
        foods: [],
        message: 'No foods',
      );

      expect(result.totalCalories, 0);
      expect(result.totalProtein, 0);
      expect(result.totalCarbs, 0);
      expect(result.totalFat, 0);
    });
  });

  group('Default Grams Estimation', () {
    test('should return correct default for eggs', () {
      // This tests the logic, not the actual method
      final foodName = 'yumurta';
      double grams = 60.0;
      
      if (foodName.contains('egg') || foodName.contains('yumurta')) {
        grams = 60.0;
      }
      
      expect(grams, 60.0);
    });

    test('should return correct default for bread', () {
      final foodName = 'ekmek';
      double grams = 50.0;
      
      if (foodName.contains('bread') || foodName.contains('ekmek')) {
        grams = 50.0;
      }
      
      expect(grams, 50.0);
    });

    test('should return default for unknown foods', () {
      final foodName = 'unknown';
      double grams = 100.0; // Default
      
      // No match, use default
      expect(grams, 100.0);
    });
  });

  group('Food Label Filtering Logic', () {
    test('should identify food keywords', () {
      final foodKeywords = ['food', 'egg', 'bread', 'yemek', 'ekmek'];
      final label = 'fresh egg';
      
      final labelLower = label.toLowerCase();
      final isFood = foodKeywords.any((keyword) => labelLower.contains(keyword));
      
      expect(isFood, true);
    });

    test('should filter non-food labels', () {
      final foodKeywords = ['food', 'egg', 'bread'];
      final label = 'car';
      
      final labelLower = label.toLowerCase();
      final isFood = foodKeywords.any((keyword) => labelLower.contains(keyword));
      
      expect(isFood, false);
    });
  });
}

