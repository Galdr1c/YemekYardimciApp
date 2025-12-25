/// Model representing a food ingredient
class Ingredient {
  final int? id;
  final String name;
  final String? category;
  final String? imageUrl;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const Ingredient({
    this.id,
    required this.name,
    this.category,
    this.imageUrl,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0.0,
    this.carbsPer100g = 0.0,
    this.fatPer100g = 0.0,
  });

  /// Create from JSON
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      category: json['aisle'] as String? ?? json['category'] as String?,
      imageUrl: json['image'] as String?,
      caloriesPer100g: json['caloriesPer100g'] as int? ?? 0,
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Create from database map
  factory Ingredient.fromDb(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
      caloriesPer100g: map['calories_per_100g'] as int,
      proteinPer100g: map['protein_per_100g'] as double,
      carbsPer100g: map['carbs_per_100g'] as double,
      fatPer100g: map['fat_per_100g'] as double,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'image_url': imageUrl,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
    };
  }

  @override
  String toString() => 'Ingredient(name: $name, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;
}

