import 'package:flutter/foundation.dart';
import '../models/food_analysis.dart';
import '../repository/food_analysis_repository.dart';
import '../repository/app_repository.dart';
import '../services/ml_service.dart';
import '../services/firebase_service.dart';

/// Provider for food analysis state management
class AnalysisProvider extends ChangeNotifier {
  final FoodAnalysisRepository _repository;
  final MlService _mlService;

  List<FoodAnalysis> _history = [];
  List<FoodAnalysis> _currentAnalysis = [];
  List<FoodAnalysis> _todayAnalyses = [];
  int _todayCalories = 0;
  Map<String, double> _todayMacros = {};
  bool _isAnalyzing = false;
  bool _isLoading = false;
  String? _error;
  
  // Database analyses storage
  List<AnalysisModel> _dbAnalyses = [];

  AnalysisProvider({
    FoodAnalysisRepository? repository,
    MlService? mlService,
  })  : _repository = repository ?? FoodAnalysisRepository(),
        _mlService = mlService ?? MlService();

  /// Set analyses from database (AppRepository AnalysisModel list)
  void setAnalysesFromDb(List<AnalysisModel> dbAnalyses) {
    _dbAnalyses = dbAnalyses;
    _history = dbAnalyses.map(_convertFromDbModel).toList();
    
    // Calculate today's data
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayItems = dbAnalyses.where((a) => a.date == today).toList();
    
    _todayAnalyses = todayItems.map(_convertFromDbModel).toList();
    _todayCalories = todayItems.fold(0, (sum, a) => sum + a.totalCalories);
    _todayMacros = {
      'protein': todayItems.fold(0.0, (sum, a) => sum + a.totalProtein),
      'carbs': todayItems.fold(0.0, (sum, a) => sum + a.totalCarbs),
      'fat': todayItems.fold(0.0, (sum, a) => sum + a.totalFat),
    };
    
    notifyListeners();
    print('[AnalysisProvider] Set ${_history.length} analyses, today: ${_todayAnalyses.length}');
  }

  /// Convert AnalysisModel from AppRepository to FoodAnalysis model
  FoodAnalysis _convertFromDbModel(AnalysisModel model) {
    return FoodAnalysis(
      id: model.id,
      foodName: model.foods.isNotEmpty ? model.foods.map((f) => f.name).join(', ') : 'Analiz',
      imagePath: model.photoPath,
      estimatedCalories: model.totalCalories,
      protein: model.totalProtein,
      carbs: model.totalCarbs,
      fat: model.totalFat,
      estimatedGrams: model.foods.isNotEmpty ? model.foods.fold(0.0, (sum, f) => sum + f.grams) : 0.0,
      analyzedAt: model.createdAt,
      confidence: 1.0,
    );
  }
  
  /// Get raw database analyses
  List<AnalysisModel> get dbAnalyses => _dbAnalyses;
  
  /// Get analyses grouped by date
  Map<String, List<AnalysisModel>> get analysesGroupedByDate {
    final grouped = <String, List<AnalysisModel>>{};
    for (final analysis in _dbAnalyses) {
      grouped.putIfAbsent(analysis.date, () => []).add(analysis);
    }
    return grouped;
  }
  
  /// Get total calories for a specific date
  int getCaloriesForDate(String date) {
    return _dbAnalyses
        .where((a) => a.date == date)
        .fold(0, (sum, a) => sum + a.totalCalories);
  }

  // Getters
  List<FoodAnalysis> get history => _history;
  List<FoodAnalysis> get currentAnalysis => _currentAnalysis;
  List<FoodAnalysis> get todayAnalyses => _todayAnalyses;
  int get todayCalories => _todayCalories;
  Map<String, double> get todayMacros => _todayMacros;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider - load history and today's data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _mlService.initialize();
      await loadHistory();
      await loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize: $e';
    }
    _setLoading(false);
  }

  /// Analyze food from image
  Future<List<FoodAnalysis>> analyzeImage(String imagePath) async {
    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      _currentAnalysis = await _mlService.analyzeImage(imagePath);
      _isAnalyzing = false;
      notifyListeners();
      return _currentAnalysis;
    } catch (e) {
      _error = 'Analysis failed: $e';
      _currentAnalysis = [];
      _isAnalyzing = false;
      notifyListeners();
      return [];
    }
  }

  /// Save analysis to history
  Future<void> saveAnalysis(FoodAnalysis analysis) async {
    try {
      await _repository.insertAnalysis(analysis);
      await loadHistory();
      await loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Failed to save analysis: $e';
      notifyListeners();
    }
  }

  /// Save all current analyses
  Future<void> saveAllCurrentAnalyses() async {
    for (final analysis in _currentAnalysis) {
      await saveAnalysis(analysis);
    }
    _currentAnalysis = [];
    notifyListeners();
  }

  /// Update portion size for an analysis
  FoodAnalysis updatePortionSize(FoodAnalysis analysis, double newGrams) {
    final updated = _mlService.updatePortionSize(analysis, newGrams);
    
    // Update in current analysis list if present
    final index = _currentAnalysis.indexWhere((a) => a.imagePath == analysis.imagePath);
    if (index != -1) {
      _currentAnalysis[index] = updated;
      notifyListeners();
    }
    
    return updated;
  }

  /// Load analysis history
  Future<void> loadHistory({int limit = 50}) async {
    _setLoading(true);
    try {
      _history = await _repository.getRecentAnalyses(limit: limit);
      _error = null;
    } catch (e) {
      _error = 'Failed to load history: $e';
    }
    _setLoading(false);
  }

  /// Load today's data
  Future<void> loadTodayData() async {
    try {
      final today = DateTime.now();
      _todayAnalyses = await _repository.getAnalysesByDate(today);
      _todayCalories = await _repository.getDailyCalories(today);
      _todayMacros = await _repository.getDailyMacros(today);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load today\'s data: $e';
    }
  }

  /// Get analyses for specific date
  Future<List<FoodAnalysis>> getAnalysesForDate(DateTime date) async {
    try {
      return await _repository.getAnalysesByDate(date);
    } catch (e) {
      _error = 'Failed to load analyses for date: $e';
      notifyListeners();
      return [];
    }
  }

  /// Search history by food name
  Future<List<FoodAnalysis>> searchHistory(String query) async {
    try {
      return await _repository.searchByFoodName(query);
    } catch (e) {
      _error = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  /// Delete analysis from history
  Future<void> deleteAnalysis(int analysisId) async {
    try {
      await _repository.deleteAnalysis(analysisId);
      await loadHistory();
      await loadTodayData();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete analysis: $e';
      notifyListeners();
    }
  }

  /// Link analysis to a recipe
  Future<void> linkToRecipe(int analysisId, String recipeId) async {
    try {
      await _repository.linkToRecipe(analysisId, recipeId);
      await loadHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to link to recipe: $e';
      notifyListeners();
    }
  }

  /// Clear analysis history
  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
      _history = [];
      await loadTodayData();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear history: $e';
      notifyListeners();
    }
  }

  /// Clear current analysis
  void clearCurrentAnalysis() {
    _currentAnalysis = [];
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
    _mlService.dispose();
    super.dispose();
  }
}

