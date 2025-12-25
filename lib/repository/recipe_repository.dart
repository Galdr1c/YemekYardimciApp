import '../models/recipe.dart';
import 'database_helper.dart';

/// Repository for Recipe database operations
class RecipeRepository {
  final DatabaseHelper _dbHelper;

  RecipeRepository({DatabaseHelper? dbHelper}) 
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Insert a new recipe
  Future<int> insertRecipe(Recipe recipe) async {
    final db = await _dbHelper.database;
    return await db.insert('recipes', recipe.toDb());
  }

  /// Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('recipes', orderBy: 'created_at DESC');
    return maps.map((map) => Recipe.fromDb(map)).toList();
  }

  /// Get recipe by ID
  Future<Recipe?> getRecipeById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Recipe.fromDb(maps.first);
  }

  /// Get favorite recipes
  Future<List<Recipe>> getFavoriteRecipes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromDb(map)).toList();
  }

  /// Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'recipes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromDb(map)).toList();
  }

  /// Search recipes by title or ingredients
  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await _dbHelper.database;
    final searchQuery = '%$query%';
    final maps = await db.query(
      'recipes',
      where: 'title LIKE ? OR ingredients LIKE ? OR description LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromDb(map)).toList();
  }

  /// Search recipes by multiple ingredients
  Future<List<Recipe>> searchByIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return [];
    
    final db = await _dbHelper.database;
    
    // Build WHERE clause for multiple ingredients
    final whereClauses = ingredients.map((_) => 'ingredients LIKE ?').join(' AND ');
    final whereArgs = ingredients.map((i) => '%$i%').toList();
    
    final maps = await db.query(
      'recipes',
      where: whereClauses,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Recipe.fromDb(map)).toList();
  }

  /// Update a recipe
  Future<int> updateRecipe(Recipe recipe) async {
    if (recipe.id == null) throw ArgumentError('Recipe ID cannot be null');
    
    final db = await _dbHelper.database;
    return await db.update(
      'recipes',
      recipe.toDb(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int recipeId) async {
    final db = await _dbHelper.database;
    final recipe = await getRecipeById(recipeId);
    if (recipe == null) return false;

    final newFavoriteStatus = !recipe.isFavorite;
    await db.update(
      'recipes',
      {'is_favorite': newFavoriteStatus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
    return newFavoriteStatus;
  }

  /// Delete a recipe
  Future<int> deleteRecipe(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get distinct categories
  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM recipes');
    return result.map((row) => row['category'] as String).toList();
  }

  /// Get recipes count
  Future<int> getRecipesCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    return result.first['count'] as int;
  }
}

