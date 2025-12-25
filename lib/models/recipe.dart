/// Recipe model representing a food recipe with nutritional information
class Recipe {
  final int? id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  final bool isFavorite;
  final DateTime? createdAt;

  Recipe({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.servings = 1,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.category = 'General',
    this.isFavorite = false,
    this.createdAt,
  });

  /// Create Recipe from JSON map (API response)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String? ?? '',
      ingredients: _parseStringList(json['ingredients'] ?? json['extendedIngredients']),
      instructions: _parseInstructions(json['instructions'] ?? json['analyzedInstructions']),
      prepTimeMinutes: json['preparationMinutes'] as int? ?? json['prepTimeMinutes'] as int? ?? 0,
      cookTimeMinutes: json['cookingMinutes'] as int? ?? json['cookTimeMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      calories: _parseCalories(json['nutrition']),
      protein: _parseNutrient(json['nutrition'], 'Protein'),
      carbs: _parseNutrient(json['nutrition'], 'Carbohydrates'),
      fat: _parseNutrient(json['nutrition'], 'Fat'),
      category: json['dishTypes']?.first as String? ?? json['category'] as String? ?? 'General',
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
    );
  }

  /// Create Recipe from database map
  factory Recipe.fromDb(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String,
      ingredients: (map['ingredients'] as String).split('|||'),
      instructions: (map['instructions'] as String).split('|||'),
      prepTimeMinutes: map['prep_time_minutes'] as int,
      cookTimeMinutes: map['cook_time_minutes'] as int,
      servings: map['servings'] as int,
      calories: map['calories'] as int,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      category: map['category'] as String,
      isFavorite: (map['is_favorite'] as int) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'ingredients': ingredients.join('|||'),
      'instructions': instructions.join('|||'),
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copy with modified fields
  Recipe copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? instructions,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Total cooking time
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is String) return item;
        if (item is Map) return item['original'] as String? ?? item['name'] as String? ?? '';
        return item.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  static List<String> _parseInstructions(dynamic data) {
    if (data == null) return [];
    if (data is String) return data.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (data is List) {
      final List<String> instructions = [];
      for (final item in data) {
        if (item is String) {
          instructions.add(item);
        } else if (item is Map && item['steps'] is List) {
          for (final step in item['steps']) {
            if (step is Map && step['step'] != null) {
              instructions.add(step['step'] as String);
            }
          }
        }
      }
      return instructions;
    }
    return [];
  }

  static int _parseCalories(dynamic nutrition) {
    if (nutrition == null) return 0;
    if (nutrition is Map && nutrition['nutrients'] is List) {
      for (final nutrient in nutrition['nutrients']) {
        if (nutrient['name'] == 'Calories') {
          return (nutrient['amount'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return 0;
  }

  static double _parseNutrient(dynamic nutrition, String name) {
    if (nutrition == null) return 0.0;
    if (nutrition is Map && nutrition['nutrients'] is List) {
      for (final nutrient in nutrition['nutrients']) {
        if (nutrient['name'] == name) {
          return (nutrient['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return 0.0;
  }

  @override
  String toString() => 'Recipe(id: $id, title: $title, calories: $calories)';
}

