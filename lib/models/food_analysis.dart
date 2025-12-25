/// Model representing analyzed food from a photo
class FoodAnalysis {
  final int? id;
  final String imagePath;
  final String foodName;
  final double confidence;
  final double estimatedGrams;
  final int estimatedCalories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? linkedRecipeId;
  final DateTime analyzedAt;
  final String? notes;

  FoodAnalysis({
    this.id,
    required this.imagePath,
    required this.foodName,
    required this.confidence,
    this.estimatedGrams = 0.0,
    this.estimatedCalories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.linkedRecipeId,
    DateTime? analyzedAt,
    this.notes,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// Create from database map
  factory FoodAnalysis.fromDb(Map<String, dynamic> map) {
    return FoodAnalysis(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String,
      foodName: map['food_name'] as String,
      confidence: map['confidence'] as double,
      estimatedGrams: map['estimated_grams'] as double,
      estimatedCalories: map['estimated_calories'] as int,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      fiber: map['fiber'] as double,
      linkedRecipeId: map['linked_recipe_id'] as String?,
      analyzedAt: DateTime.parse(map['analyzed_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  /// Create from ML detection result
  factory FoodAnalysis.fromDetection({
    required String imagePath,
    required String label,
    required double confidence,
    NutritionEstimate? nutrition,
  }) {
    return FoodAnalysis(
      imagePath: imagePath,
      foodName: _formatFoodName(label),
      confidence: confidence,
      estimatedGrams: nutrition?.grams ?? 100.0,
      estimatedCalories: nutrition?.calories ?? 0,
      protein: nutrition?.protein ?? 0.0,
      carbs: nutrition?.carbs ?? 0.0,
      fat: nutrition?.fat ?? 0.0,
      fiber: nutrition?.fiber ?? 0.0,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'image_path': imagePath,
      'food_name': foodName,
      'confidence': confidence,
      'estimated_grams': estimatedGrams,
      'estimated_calories': estimatedCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'linked_recipe_id': linkedRecipeId,
      'analyzed_at': analyzedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copy with modified fields
  FoodAnalysis copyWith({
    int? id,
    String? imagePath,
    String? foodName,
    double? confidence,
    double? estimatedGrams,
    int? estimatedCalories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    String? linkedRecipeId,
    DateTime? analyzedAt,
    String? notes,
  }) {
    return FoodAnalysis(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      foodName: foodName ?? this.foodName,
      confidence: confidence ?? this.confidence,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      linkedRecipeId: linkedRecipeId ?? this.linkedRecipeId,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Confidence level as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Macros summary string
  String get macrosSummary => 
      'P: ${protein.toStringAsFixed(1)}g | C: ${carbs.toStringAsFixed(1)}g | F: ${fat.toStringAsFixed(1)}g';

  static String _formatFoodName(String label) {
    // Clean up ML labels (e.g., "food_pizza" -> "Pizza")
    String formatted = label
        .replaceAll('food_', '')
        .replaceAll('_', ' ')
        .trim();
    
    if (formatted.isEmpty) return 'Unknown Food';
    
    // Capitalize first letter of each word
    return formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  String toString() => 'FoodAnalysis(foodName: $foodName, calories: $estimatedCalories, confidence: $confidencePercent)';
}

/// Helper class for nutrition estimates
class NutritionEstimate {
  final double grams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const NutritionEstimate({
    this.grams = 100.0,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
  });

  /// Scale nutrition by portion size
  NutritionEstimate scaleTo(double newGrams) {
    final factor = newGrams / grams;
    return NutritionEstimate(
      grams: newGrams,
      calories: (calories * factor).round(),
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
    );
  }
}

