// HMS ML Service - Currently disabled due to package availability
// Uncomment when HMS packages are available for your Flutter version
/*
import 'dart:io';
import 'package:huawei_ml/huawei_ml.dart';
import 'package:huawei_ml_image/huawei_ml_image.dart';
import '../models/food_analysis.dart';
*/

/// HMS ML Kit service for Huawei devices
class HMSMLService {
  static final HMSMLService _instance = HMSMLService._internal();
  factory HMSMLService() => _instance;
  HMSMLService._internal();

  bool _initialized = false;

  /// Initialize HMS ML Kit
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await MLApplication().setApiKey("your_hms_api_key_here");
      _initialized = true;
      print('[HMSMLService] Initialized successfully');
    } catch (e) {
      print('[HMSMLService] Initialization error: $e');
      _initialized = false;
    }
  }

  /// Check if HMS is available (Huawei device)
  Future<bool> isHMSAvailable() async {
    try {
      // Check if HMS Core is installed
      final result = await MLApplication().getApiKey();
      return result != null && result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Analyze image using HMS ML Kit
  Future<List<FoodAnalysis>> analyzeImage(String imagePath) async {
    if (!_initialized) {
      await initialize();
    }

    final results = <FoodAnalysis>[];

    try {
      // Use HMS Image Classification
      final analyzer = MLImageClassificationAnalyzer();
      final setting = MLImageClassificationAnalyzerSetting.local();
      
      final mlImage = MLImage.fromFilePath(imagePath);
      final classificationList = await analyzer.asyncAnalyseFrame(mlImage);

      for (final classification in classificationList) {
        // Filter for food-related labels
        if (_isFoodRelated(classification.identity)) {
          results.add(FoodAnalysis(
            imagePath: imagePath,
            foodName: _translateFoodName(classification.identity),
            confidence: classification.possibility.toDouble(),
            estimatedGrams: _estimateGrams(classification.identity),
            estimatedCalories: _estimateCalories(classification.identity),
          ));
        }
      }

      await analyzer.stop();
    } catch (e) {
      print('[HMSMLService] Analysis error: $e');
    }

    return results;
  }

  /// Check if label is food-related
  bool _isFoodRelated(String label) {
    final foodKeywords = [
      'food', 'meal', 'dish', 'cuisine', 'recipe',
      'yemek', 'yemek', 'yemek', 'tarif', 'yemek'
    ];
    
    final labelLower = label.toLowerCase();
    return foodKeywords.any((keyword) => labelLower.contains(keyword));
  }

  /// Translate food name to Turkish
  String _translateFoodName(String englishName) {
    final translations = {
      'apple': 'Elma',
      'banana': 'Muz',
      'bread': 'Ekmek',
      'chicken': 'Tavuk',
      'egg': 'Yumurta',
      'rice': 'Pilav',
      'salad': 'Salata',
      'pasta': 'Makarna',
      'pizza': 'Pizza',
      'soup': 'Çorba',
    };

    return translations[englishName.toLowerCase()] ?? englishName;
  }

  /// Estimate grams from food type
  double _estimateGrams(String foodName) {
    // Default estimates based on food type
    final estimates = {
      'apple': 150.0,
      'banana': 120.0,
      'bread': 50.0,
      'chicken': 100.0,
      'egg': 50.0,
      'rice': 150.0,
      'salad': 100.0,
      'pasta': 200.0,
      'pizza': 150.0,
      'soup': 250.0,
    };

    return estimates[foodName.toLowerCase()] ?? 100.0;
  }

  /// Estimate calories from food type
  int _estimateCalories(String foodName) {
    final calories = {
      'apple': 80,
      'banana': 105,
      'bread': 130,
      'chicken': 165,
      'egg': 70,
      'rice': 200,
      'salad': 50,
      'pasta': 300,
      'pizza': 250,
      'soup': 150,
    };

    return calories[foodName.toLowerCase()] ?? 100;
  }
}

