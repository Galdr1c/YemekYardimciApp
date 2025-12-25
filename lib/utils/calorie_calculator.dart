/// Utility class for calculating calories from ingredients
class CalorieCalculator {
  /// Ingredient nutrition database (per 100g)
  static final Map<String, Map<String, double>> _ingredientDb = {
    // Proteins
    'yumurta': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
    'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
    'tavuk': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
    'chicken': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
    'kıyma': {'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0},
    'meat': {'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0},
    'et': {'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0},
    'balık': {'calories': 206.0, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
    'fish': {'calories': 206.0, 'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
    'peynir': {'calories': 113.0, 'protein': 25.0, 'carbs': 1.0, 'fat': 27.0},
    'cheese': {'calories': 113.0, 'protein': 25.0, 'carbs': 1.0, 'fat': 27.0},
    
    // Carbs
    'pirinç': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
    'rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
    'pilav': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
    'makarna': {'calories': 131.0, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1},
    'pasta': {'calories': 131.0, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1},
    'ekmek': {'calories': 265.0, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.0},
    'bread': {'calories': 265.0, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.0},
    'patates': {'calories': 77.0, 'protein': 2.0, 'carbs': 17.0, 'fat': 0.1},
    'potato': {'calories': 77.0, 'protein': 2.0, 'carbs': 17.0, 'fat': 0.1},
    
    // Vegetables
    'domates': {'calories': 18.0, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
    'tomato': {'calories': 18.0, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
    'soğan': {'calories': 40.0, 'protein': 1.1, 'carbs': 9.3, 'fat': 0.1},
    'onion': {'calories': 40.0, 'protein': 1.1, 'carbs': 9.3, 'fat': 0.1},
    'biber': {'calories': 20.0, 'protein': 0.9, 'carbs': 4.6, 'fat': 0.2},
    'pepper': {'calories': 20.0, 'protein': 0.9, 'carbs': 4.6, 'fat': 0.2},
    'salatalık': {'calories': 16.0, 'protein': 0.7, 'carbs': 3.6, 'fat': 0.1},
    'cucumber': {'calories': 16.0, 'protein': 0.7, 'carbs': 3.6, 'fat': 0.1},
    'marul': {'calories': 15.0, 'protein': 1.4, 'carbs': 2.9, 'fat': 0.2},
    'lettuce': {'calories': 15.0, 'protein': 1.4, 'carbs': 2.9, 'fat': 0.2},
    'havuç': {'calories': 41.0, 'protein': 0.9, 'carbs': 9.6, 'fat': 0.2},
    'carrot': {'calories': 41.0, 'protein': 0.9, 'carbs': 9.6, 'fat': 0.2},
    'patlıcan': {'calories': 25.0, 'protein': 1.0, 'carbs': 5.9, 'fat': 0.2},
    'eggplant': {'calories': 25.0, 'protein': 1.0, 'carbs': 5.9, 'fat': 0.2},
    
    // Fats
    'zeytinyağı': {'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0},
    'olive oil': {'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0},
    'tereyağı': {'calories': 717.0, 'protein': 0.9, 'carbs': 0.1, 'fat': 81.0},
    'butter': {'calories': 717.0, 'protein': 0.9, 'carbs': 0.1, 'fat': 81.0},
    'yağ': {'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0},
    'oil': {'calories': 884.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 100.0},
    
    // Dairy
    'süt': {'calories': 42.0, 'protein': 3.4, 'carbs': 5.0, 'fat': 1.0},
    'milk': {'calories': 42.0, 'protein': 3.4, 'carbs': 5.0, 'fat': 1.0},
    'yoğurt': {'calories': 59.0, 'protein': 10.0, 'carbs': 3.6, 'fat': 0.4},
    'yogurt': {'calories': 59.0, 'protein': 10.0, 'carbs': 3.6, 'fat': 0.4},
    
    // Legumes
    'mercimek': {'calories': 116.0, 'protein': 9.0, 'carbs': 20.0, 'fat': 0.4},
    'lentil': {'calories': 116.0, 'protein': 9.0, 'carbs': 20.0, 'fat': 0.4},
    'fasulye': {'calories': 127.0, 'protein': 8.7, 'carbs': 22.8, 'fat': 0.5},
    'bean': {'calories': 127.0, 'protein': 8.7, 'carbs': 22.8, 'fat': 0.5},
    
    // Spices/Herbs (minimal calories)
    'tuz': {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0},
    'salt': {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0},
    'karabiber': {'calories': 251.0, 'protein': 10.4, 'carbs': 63.9, 'fat': 3.3},
    'black pepper': {'calories': 251.0, 'protein': 10.4, 'carbs': 63.9, 'fat': 3.3},
    'kimyon': {'calories': 375.0, 'protein': 17.8, 'carbs': 44.2, 'fat': 22.3},
    'cumin': {'calories': 375.0, 'protein': 17.8, 'carbs': 44.2, 'fat': 22.3},
  };

  /// Calculate calories from ingredient list
  static Map<String, double> calculateFromIngredients(List<String> ingredients) {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    
    for (final ingredient in ingredients) {
      final nutrition = _parseIngredient(ingredient);
      totalCalories += nutrition['calories']!;
      totalProtein += nutrition['protein']!;
      totalCarbs += nutrition['carbs']!;
      totalFat += nutrition['fat']!;
    }
    
    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  /// Parse ingredient string and extract nutrition
  static Map<String, double> _parseIngredient(String ingredient) {
    final lower = ingredient.toLowerCase().trim();
    
    // Try to extract quantity (e.g., "2 yumurta", "500g tavuk", "1 su bardağı süt")
    double quantity = 1.0;
    String ingredientName = lower;
    
    // Pattern: number + unit + ingredient
    final quantityPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:adet|ad|piece|pieces|g|gram|kg|ml|l|su\s+bardağı|cup|cups|yemek\s+kaşığı|tbsp|çay\s+kaşığı|tsp)?\s*(.+)');
    final match = quantityPattern.firstMatch(lower);
    
    if (match != null) {
      quantity = double.tryParse(match.group(1) ?? '1') ?? 1.0;
      ingredientName = match.group(2)?.trim() ?? lower;
      
      // Convert units to grams
      if (lower.contains('su bardağı') || lower.contains('cup')) {
        quantity *= 240.0; // 1 cup ≈ 240g/ml
      } else if (lower.contains('yemek kaşığı') || lower.contains('tbsp')) {
        quantity *= 15.0; // 1 tbsp ≈ 15g/ml
      } else if (lower.contains('çay kaşığı') || lower.contains('tsp')) {
        quantity *= 5.0; // 1 tsp ≈ 5g/ml
      } else if (lower.contains('kg')) {
        quantity *= 1000.0;
      } else if (lower.contains('adet') || lower.contains('ad') || lower.contains('piece')) {
        // Keep as is for countable items
        quantity = quantity;
      }
      // 'g' or 'gram' is already in grams
    }
    
    // Find matching ingredient in database
    Map<String, double>? nutrition;
    for (final entry in _ingredientDb.entries) {
      if (ingredientName.contains(entry.key)) {
        nutrition = Map<String, double>.from(entry.value);
        break;
      }
    }
    
    // Default nutrition if not found
    nutrition ??= {'calories': 50.0, 'protein': 2.0, 'carbs': 8.0, 'fat': 1.0};
    
    // Scale by quantity (assuming per 100g base)
    final factor = quantity / 100.0;
    
    return {
      'calories': nutrition['calories']! * factor,
      'protein': nutrition['protein']! * factor,
      'carbs': nutrition['carbs']! * factor,
      'fat': nutrition['fat']! * factor,
    };
  }

  /// Get nutrition for a single ingredient
  static Map<String, double> getIngredientNutrition(String ingredient) {
    return _parseIngredient(ingredient);
  }

  /// Estimate calories per serving
  static int estimateCaloriesPerServing(List<String> ingredients, int servings) {
    final total = calculateFromIngredients(ingredients);
    return (total['calories']! / servings).round();
  }

  /// Get detailed breakdown
  static Map<String, dynamic> getDetailedBreakdown(List<String> ingredients) {
    final breakdown = <String, Map<String, double>>{};
    
    for (final ingredient in ingredients) {
      breakdown[ingredient] = _parseIngredient(ingredient);
    }
    
    final total = calculateFromIngredients(ingredients);
    
    return {
      'total': total,
      'breakdown': breakdown,
    };
  }
}

