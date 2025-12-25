import '../models/food_analysis.dart';
import 'database_helper.dart';

/// Repository for FoodAnalysis database operations
class FoodAnalysisRepository {
  final DatabaseHelper _dbHelper;

  FoodAnalysisRepository({DatabaseHelper? dbHelper}) 
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Insert a new food analysis
  Future<int> insertAnalysis(FoodAnalysis analysis) async {
    final db = await _dbHelper.database;
    return await db.insert('food_analyses', analysis.toDb());
  }

  /// Get all food analyses (history)
  Future<List<FoodAnalysis>> getAllAnalyses() async {
    final db = await _dbHelper.database;
    final maps = await db.query('food_analyses', orderBy: 'analyzed_at DESC');
    return maps.map((map) => FoodAnalysis.fromDb(map)).toList();
  }

  /// Get analysis by ID
  Future<FoodAnalysis?> getAnalysisById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_analyses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FoodAnalysis.fromDb(maps.first);
  }

  /// Get analyses for a specific date
  Future<List<FoodAnalysis>> getAnalysesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await db.query(
      'food_analyses',
      where: 'analyzed_at >= ? AND analyzed_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'analyzed_at DESC',
    );
    return maps.map((map) => FoodAnalysis.fromDb(map)).toList();
  }

  /// Get analyses for date range
  Future<List<FoodAnalysis>> getAnalysesInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_analyses',
      where: 'analyzed_at >= ? AND analyzed_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'analyzed_at DESC',
    );
    return maps.map((map) => FoodAnalysis.fromDb(map)).toList();
  }

  /// Get recent analyses (last N items)
  Future<List<FoodAnalysis>> getRecentAnalyses({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_analyses',
      orderBy: 'analyzed_at DESC',
      limit: limit,
    );
    return maps.map((map) => FoodAnalysis.fromDb(map)).toList();
  }

  /// Search analyses by food name
  Future<List<FoodAnalysis>> searchByFoodName(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_analyses',
      where: 'food_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'analyzed_at DESC',
    );
    return maps.map((map) => FoodAnalysis.fromDb(map)).toList();
  }

  /// Update an analysis
  Future<int> updateAnalysis(FoodAnalysis analysis) async {
    if (analysis.id == null) throw ArgumentError('Analysis ID cannot be null');
    
    final db = await _dbHelper.database;
    return await db.update(
      'food_analyses',
      analysis.toDb(),
      where: 'id = ?',
      whereArgs: [analysis.id],
    );
  }

  /// Link analysis to a recipe
  Future<int> linkToRecipe(int analysisId, String recipeId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'food_analyses',
      {'linked_recipe_id': recipeId},
      where: 'id = ?',
      whereArgs: [analysisId],
    );
  }

  /// Delete an analysis
  Future<int> deleteAnalysis(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'food_analyses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get daily calorie total
  Future<int> getDailyCalories(DateTime date) async {
    final analyses = await getAnalysesByDate(date);
    return analyses.fold<int>(0, (sum, a) => sum + a.estimatedCalories);
  }

  /// Get daily macros totals
  Future<Map<String, double>> getDailyMacros(DateTime date) async {
    final analyses = await getAnalysesByDate(date);
    return {
      'protein': analyses.fold(0.0, (sum, a) => sum + a.protein),
      'carbs': analyses.fold(0.0, (sum, a) => sum + a.carbs),
      'fat': analyses.fold(0.0, (sum, a) => sum + a.fat),
      'fiber': analyses.fold(0.0, (sum, a) => sum + a.fiber),
    };
  }

  /// Get analyses count
  Future<int> getAnalysesCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM food_analyses');
    return result.first['count'] as int;
  }

  /// Clear all analysis history
  Future<void> clearHistory() async {
    final db = await _dbHelper.database;
    await db.delete('food_analyses');
  }
}

