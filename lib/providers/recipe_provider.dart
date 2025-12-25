import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../repository/recipe_repository.dart';
import '../repository/app_repository.dart';
import '../services/recipe_api_service.dart';
import '../services/firebase_service.dart';

/// Provider for recipe state management
class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;
  final RecipeApiService _apiService;

  List<Recipe> _recipes = [];
  List<Recipe> _searchResults = [];
  List<Recipe> _favorites = [];
  List<String> _categories = [];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _error;

  RecipeProvider({
    RecipeRepository? repository,
    RecipeApiService? apiService,
  })  : _repository = repository ?? RecipeRepository(),
        _apiService = apiService ?? RecipeApiService();
  
  /// Set recipes from database (AppRepository RecipeModel list)
  void setRecipesFromDb(List<RecipeModel> dbRecipes) {
    _recipes = dbRecipes.map(_convertFromDbModel).toList();
    _favorites = _recipes.where((r) => r.isFavorite).toList();
    _categories = _recipes
        .map((r) => r.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    notifyListeners();
    print('[RecipeProvider] Set ${_recipes.length} recipes, ${_favorites.length} favorites');
  }

  /// Convert RecipeModel from AppRepository to Recipe model
  Recipe _convertFromDbModel(RecipeModel model) {
    return Recipe(
      id: model.id,
      title: model.name,
      description: model.steps.isNotEmpty ? model.steps.first : '',
      category: model.category,
      instructions: model.steps,
      ingredients: model.ingredients,
      imageUrl: model.imageUrl,
      isFavorite: model.isFavorite,
      calories: model.calories,
      protein: model.protein,
      carbs: model.carbs,
      fat: model.fat,
      prepTimeMinutes: model.prepTime,
      cookTimeMinutes: model.cookTime,
      servings: model.servings,
    );
  }
  
  /// Get all recipes loaded from database
  List<Recipe> get allRecipes => _recipes;

  // Getters
  List<Recipe> get recipes => _recipes;
  List<Recipe> get searchResults => _searchResults;
  List<Recipe> get favorites => _favorites;
  List<String> get categories => _categories;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider - load favorites and categories
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _favorites = await _repository.getFavoriteRecipes();
      _categories = await _apiService.getCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    }
    _setLoading(false);
  }

  /// Search recipes online by query
  Future<void> searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResults = await _apiService.searchRecipes(query);
      _error = null;
    } catch (e) {
      _error = 'Search failed: $e';
      _searchResults = [];
    }
    _setLoading(false);
  }

  /// Search recipes by ingredient
  Future<void> searchByIngredient(String ingredient) async {
    if (ingredient.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResults = await _apiService.getRecipesByIngredient(ingredient);
      _error = null;
    } catch (e) {
      _error = 'Search failed: $e';
      _searchResults = [];
    }
    _setLoading(false);
  }

  /// Search recipes by category
  Future<void> searchByCategory(String category) async {
    _setLoading(true);
    try {
      _searchResults = await _apiService.getRecipesByCategory(category);
      _error = null;
    } catch (e) {
      _error = 'Search failed: $e';
      _searchResults = [];
    }
    _setLoading(false);
  }

  /// Get a random recipe
  Future<Recipe?> getRandomRecipe() async {
    _setLoading(true);
    try {
      final recipe = await _apiService.getRandomRecipe();
      _error = null;
      _setLoading(false);
      return recipe;
    } catch (e) {
      _error = 'Failed to get random recipe: $e';
      _setLoading(false);
      return null;
    }
  }

  /// Load local favorites
  Future<void> loadFavorites() async {
    _setLoading(true);
    try {
      _favorites = await _repository.getFavoriteRecipes();
      _error = null;
    } catch (e) {
      _error = 'Failed to load favorites: $e';
    }
    _setLoading(false);
  }

  /// Save recipe to favorites
  Future<void> saveToFavorites(Recipe recipe) async {
    try {
      final savedRecipe = recipe.copyWith(isFavorite: true);
      await _repository.insertRecipe(savedRecipe);
      await loadFavorites();
      _error = null;
    } catch (e) {
      _error = 'Failed to save favorite: $e';
      notifyListeners();
    }
  }

  /// Remove recipe from favorites
  Future<void> removeFromFavorites(int recipeId) async {
    try {
      await _repository.deleteRecipe(recipeId);
      await loadFavorites();
      _error = null;
    } catch (e) {
      _error = 'Failed to remove favorite: $e';
      notifyListeners();
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Recipe recipe) async {
    if (recipe.id != null) {
      await _repository.toggleFavorite(recipe.id!);
      await loadFavorites();
      
      // Sync to Firebase if available (offline cache will handle it)
      try {
        if (FirebaseService.isAvailable) {
          await FirebaseService.syncLocalChangesToFirestore();
        }
      } catch (e) {
        print('[RecipeProvider] Firebase sync error: $e');
        // Continue without Firebase
      }
    } else {
      await saveToFavorites(recipe);
    }
  }

  /// Check if recipe is in favorites
  bool isFavorite(Recipe recipe) {
    return _favorites.any((fav) => 
        fav.title.toLowerCase() == recipe.title.toLowerCase());
  }

  /// Select a recipe for detail view
  void selectRecipe(Recipe recipe) {
    _selectedRecipe = recipe;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedRecipe = null;
    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

