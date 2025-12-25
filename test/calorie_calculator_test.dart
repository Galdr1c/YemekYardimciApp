import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/utils/calorie_calculator.dart';

void main() {
  group('CalorieCalculator Tests', () {
    test('should calculate calories from simple ingredients', () {
      final ingredients = ['2 yumurta', '1 ekmek'];
      
      final result = CalorieCalculator.calculateFromIngredients(ingredients);
      
      expect(result['calories'], greaterThan(0));
      expect(result['protein'], greaterThan(0));
      expect(result['carbs'], greaterThan(0));
      expect(result['fat'], greaterThan(0));
    });

    test('should handle quantity parsing', () {
      final result1 = CalorieCalculator.getIngredientNutrition('2 yumurta');
      final result2 = CalorieCalculator.getIngredientNutrition('1 yumurta');
      
      // 2 eggs should have approximately 2x calories of 1 egg
      expect(result1['calories'], closeTo(result2['calories']! * 2, 10));
    });

    test('should parse grams correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('500g tavuk');
      
      // 500g chicken should have approximately 5x calories of 100g
      expect(result['calories'], greaterThan(700)); // ~165 * 5 = 825
      expect(result['protein'], greaterThan(150)); // ~31 * 5 = 155
    });

    test('should parse cups correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('1 su bardağı süt');
      
      // 1 cup milk ≈ 240g, so ~42 * 2.4 = ~100 calories
      expect(result['calories'], greaterThan(80));
      expect(result['calories'], lessThan(120));
    });

    test('should parse tablespoons correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('1 yemek kaşığı zeytinyağı');
      
      // 1 tbsp olive oil ≈ 15g, so ~884 * 0.15 = ~133 calories
      expect(result['calories'], greaterThan(100));
      expect(result['calories'], lessThan(150));
    });

    test('should handle Turkish ingredient names', () {
      final result = CalorieCalculator.getIngredientNutrition('tavuk');
      
      expect(result['calories'], greaterThan(0));
      expect(result['protein'], greaterThan(0));
    });

    test('should handle English ingredient names', () {
      final result = CalorieCalculator.getIngredientNutrition('chicken');
      
      expect(result['calories'], greaterThan(0));
      expect(result['protein'], greaterThan(0));
    });

    test('should calculate total for recipe', () {
      final ingredients = [
        '2 yumurta',
        '1 ekmek',
        '30g peynir',
        '1 yemek kaşığı zeytinyağı',
      ];
      
      final result = CalorieCalculator.calculateFromIngredients(ingredients);
      
      expect(result['calories'], greaterThan(500));
      expect(result['protein'], greaterThan(30));
      expect(result['carbs'], greaterThan(50));
      expect(result['fat'], greaterThan(20));
    });

    test('should estimate calories per serving', () {
      final ingredients = ['500g tavuk', '200g pilav'];
      final servings = 4;
      
      final caloriesPerServing = CalorieCalculator.estimateCaloriesPerServing(
        ingredients,
        servings,
      );
      
      // Total should be around 825 + 260 = 1085, per serving ~271
      expect(caloriesPerServing, greaterThan(200));
      expect(caloriesPerServing, lessThan(400));
    });

    test('should provide detailed breakdown', () {
      final ingredients = ['2 yumurta', '1 ekmek'];
      
      final breakdown = CalorieCalculator.getDetailedBreakdown(ingredients);
      
      expect(breakdown['total'], isA<Map<String, double>>());
      expect(breakdown['breakdown'], isA<Map<String, Map<String, double>>>());
      expect(breakdown['breakdown'].length, 2);
    });

    test('should handle unknown ingredients with default values', () {
      final result = CalorieCalculator.getIngredientNutrition('unknown ingredient xyz');
      
      // Should return default nutrition
      expect(result['calories'], greaterThan(0));
      expect(result['protein'], greaterThan(0));
      expect(result['carbs'], greaterThan(0));
      expect(result['fat'], greaterThan(0));
    });

    test('should handle zero-calorie ingredients', () {
      final result = CalorieCalculator.getIngredientNutrition('tuz');
      
      expect(result['calories'], 0);
    });

    test('should handle spices correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('karabiber');
      
      // Spices have calories but in small amounts
      expect(result['calories'], greaterThan(0));
    });

    test('should scale nutrition by quantity', () {
      final single = CalorieCalculator.getIngredientNutrition('1 yumurta');
      final double_ = CalorieCalculator.getIngredientNutrition('2 yumurta');
      final triple = CalorieCalculator.getIngredientNutrition('3 yumurta');
      
      expect(double_['calories'], closeTo(single['calories']! * 2, 5));
      expect(triple['calories'], closeTo(single['calories']! * 3, 5));
    });

    test('should handle decimal quantities', () {
      final result = CalorieCalculator.getIngredientNutrition('1.5 yumurta');
      
      expect(result['calories'], greaterThan(0));
      expect(result['calories'], lessThan(300));
    });

    test('should handle complex ingredient strings', () {
      final ingredients = [
        '2 adet yumurta',
        '500 gram tavuk',
        '1 su bardağı süt',
        '2 yemek kaşığı zeytinyağı',
      ];
      
      final result = CalorieCalculator.calculateFromIngredients(ingredients);
      
      expect(result['calories'], greaterThan(1000));
      expect(result['protein'], greaterThan(100));
    });

    test('should calculate macros correctly', () {
      final ingredients = ['100g tavuk'];
      
      final result = CalorieCalculator.calculateFromIngredients(ingredients);
      
      // 100g chicken: ~165 cal, ~31g protein, ~0g carbs, ~3.6g fat
      expect(result['calories'], closeTo(165, 10));
      expect(result['protein'], closeTo(31, 5));
      expect(result['carbs'], closeTo(0, 2));
      expect(result['fat'], closeTo(3.6, 2));
    });

    test('should handle empty ingredient list', () {
      final result = CalorieCalculator.calculateFromIngredients([]);
      
      expect(result['calories'], 0);
      expect(result['protein'], 0);
      expect(result['carbs'], 0);
      expect(result['fat'], 0);
    });

    test('should handle vegetables correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('domates');
      
      // Tomatoes are low calorie
      expect(result['calories'], lessThan(50));
      expect(result['carbs'], greaterThan(0));
    });

    test('should handle fats correctly', () {
      final result = CalorieCalculator.getIngredientNutrition('zeytinyağı');
      
      // Olive oil is high calorie (per 100g)
      expect(result['calories'], greaterThan(800));
      expect(result['fat'], closeTo(100, 5));
    });
  });

  group('CalorieCalculator Edge Cases', () {
    test('should handle ingredients with special characters', () {
      final result = CalorieCalculator.getIngredientNutrition('çay kaşığı tuz');
      
      expect(result['calories'], greaterThanOrEqualTo(0));
    });

    test('should handle very large quantities', () {
      final result = CalorieCalculator.getIngredientNutrition('10 kg tavuk');
      
      expect(result['calories'], greaterThan(10000));
    });

    test('should handle very small quantities', () {
      final result = CalorieCalculator.getIngredientNutrition('0.1 yumurta');
      
      expect(result['calories'], greaterThan(0));
      expect(result['calories'], lessThan(20));
    });

    test('should handle mixed units', () {
      final ingredients = [
        '2 adet yumurta',
        '100g ekmek',
        '1 su bardağı süt',
      ];
      
      final result = CalorieCalculator.calculateFromIngredients(ingredients);
      
      expect(result['calories'], greaterThan(0));
    });
  });
}

