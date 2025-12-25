import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

/// Service for fetching recipes from API
class RecipeApiService {
  // Using TheMealDB free API (no key required)
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  final http.Client _client;

  RecipeApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Search recipes by name
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/search.php?s=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals == null) return [];
        
        return meals.map((meal) => _mealToRecipe(meal)).toList();
      }
      
      throw ApiException('Failed to search recipes: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get recipe by ID
  Future<Recipe?> getRecipeById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals == null || meals.isEmpty) return null;
        
        return _mealToRecipe(meals.first);
      }
      
      throw ApiException('Failed to get recipe: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get random recipe
  Future<Recipe?> getRandomRecipe() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/random.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals == null || meals.isEmpty) return null;
        
        return _mealToRecipe(meals.first);
      }
      
      throw ApiException('Failed to get random recipe: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/filter.php?c=$category'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals == null) return [];
        
        // Filter API returns limited data, fetch full details
        final recipes = <Recipe>[];
        for (final meal in meals.take(10)) {
          final fullRecipe = await getRecipeById(meal['idMeal']);
          if (fullRecipe != null) {
            recipes.add(fullRecipe);
          }
        }
        return recipes;
      }
      
      throw ApiException('Failed to get recipes by category: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get recipes by main ingredient
  Future<List<Recipe>> getRecipesByIngredient(String ingredient) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/filter.php?i=$ingredient'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List?;
        
        if (meals == null) return [];
        
        // Filter API returns limited data, fetch full details
        final recipes = <Recipe>[];
        for (final meal in meals.take(10)) {
          final fullRecipe = await getRecipeById(meal['idMeal']);
          if (fullRecipe != null) {
            recipes.add(fullRecipe);
          }
        }
        return recipes;
      }
      
      throw ApiException('Failed to get recipes by ingredient: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get all categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/categories.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = data['categories'] as List?;
        
        if (categories == null) return [];
        
        return categories
            .map((c) => c['strCategory'] as String)
            .toList();
      }
      
      throw ApiException('Failed to get categories: ${response.statusCode}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Convert TheMealDB meal format to Recipe model
  Recipe _mealToRecipe(Map<String, dynamic> meal) {
    // Extract ingredients (TheMealDB has strIngredient1-20 and strMeasure1-20)
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'] as String?;
      final measure = meal['strMeasure$i'] as String?;
      
      if (ingredient != null && ingredient.trim().isNotEmpty) {
        final measureStr = measure?.trim() ?? '';
        ingredients.add(measureStr.isNotEmpty 
            ? '$measureStr $ingredient'.trim()
            : ingredient.trim());
      }
    }

    // Parse instructions into steps
    final instructionsText = meal['strInstructions'] as String? ?? '';
    final instructions = instructionsText
        .split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Recipe(
      title: meal['strMeal'] as String? ?? '',
      description: 'Category: ${meal['strCategory'] ?? 'Unknown'} | Area: ${meal['strArea'] ?? 'Unknown'}',
      imageUrl: meal['strMealThumb'] as String? ?? '',
      ingredients: ingredients,
      instructions: instructions.isEmpty ? ['No instructions available'] : instructions,
      category: meal['strCategory'] as String? ?? 'General',
      // Estimate reasonable values for missing nutritional data
      calories: _estimateCalories(ingredients.length),
      prepTimeMinutes: 15,
      cookTimeMinutes: 30,
      servings: 4,
    );
  }

  /// Simple calorie estimation based on ingredient count
  int _estimateCalories(int ingredientCount) {
    // Rough estimate: 50-100 calories per ingredient average
    return ingredientCount * 75;
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

