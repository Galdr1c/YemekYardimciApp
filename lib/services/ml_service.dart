import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../models/food_analysis.dart';

/// Service for ML-based food recognition and analysis
class MlService {
  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;

  /// Initialize ML models
  Future<void> initialize() async {
    // Initialize image labeler with default model
    final labelerOptions = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: labelerOptions);

    // Initialize object detector
    final detectorOptions = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: detectorOptions);
  }

  /// Analyze food from image file
  Future<List<FoodAnalysis>> analyzeImage(String imagePath) async {
    if (_imageLabeler == null) {
      await initialize();
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final results = <FoodAnalysis>[];

    // Get image labels
    final labels = await _imageLabeler!.processImage(inputImage);
    
    // Filter for food-related labels
    final foodLabels = labels.where((label) => _isFoodRelated(label.label)).toList();

    if (foodLabels.isEmpty) {
      // If no specific food found, try object detection
      final detectedObjects = await _detectObjects(inputImage);
      if (detectedObjects.isNotEmpty) {
        for (final obj in detectedObjects) {
          results.add(FoodAnalysis.fromDetection(
            imagePath: imagePath,
            label: obj.label,
            confidence: obj.confidence,
            nutrition: _estimateNutrition(obj.label),
          ));
        }
      } else {
        // Return a generic food analysis if nothing detected
        results.add(FoodAnalysis(
          imagePath: imagePath,
          foodName: 'Unknown Food',
          confidence: 0.3,
          estimatedGrams: 100,
          estimatedCalories: 200,
        ));
      }
    } else {
      // Process detected food labels
      for (final label in foodLabels.take(3)) {
        final nutrition = _estimateNutrition(label.label);
        results.add(FoodAnalysis.fromDetection(
          imagePath: imagePath,
          label: label.label,
          confidence: label.confidence,
          nutrition: nutrition,
        ));
      }
    }

    return results;
  }

  /// Detect objects in image
  Future<List<_DetectedFood>> _detectObjects(InputImage inputImage) async {
    if (_objectDetector == null) return [];

    try {
      final objects = await _objectDetector!.processImage(inputImage);
      final foods = <_DetectedFood>[];

      for (final obj in objects) {
        for (final label in obj.labels) {
          if (_isFoodRelated(label.text)) {
            foods.add(_DetectedFood(
              label: label.text,
              confidence: label.confidence,
            ));
          }
        }
      }

      return foods;
    } catch (e) {
      return [];
    }
  }

  /// Check if a label is food-related
  bool _isFoodRelated(String label) {
    final foodKeywords = [
      'food', 'meal', 'dish', 'fruit', 'vegetable', 'meat', 'bread',
      'rice', 'pasta', 'pizza', 'burger', 'sandwich', 'salad', 'soup',
      'cake', 'dessert', 'drink', 'beverage', 'snack', 'breakfast',
      'lunch', 'dinner', 'appetizer', 'chicken', 'beef', 'pork', 'fish',
      'seafood', 'egg', 'cheese', 'milk', 'yogurt', 'apple', 'banana',
      'orange', 'tomato', 'potato', 'carrot', 'onion', 'garlic',
      'noodle', 'sushi', 'taco', 'burrito', 'curry', 'steak', 'fries',
    ];

    final lowerLabel = label.toLowerCase();
    return foodKeywords.any((keyword) => lowerLabel.contains(keyword));
  }

  /// Estimate nutrition based on food type
  NutritionEstimate _estimateNutrition(String foodLabel) {
    final lowerLabel = foodLabel.toLowerCase();
    
    // Nutrition database (per 100g estimates)
    final nutritionData = {
      'pizza': const NutritionEstimate(grams: 150, calories: 400, protein: 15, carbs: 45, fat: 18, fiber: 2),
      'burger': const NutritionEstimate(grams: 200, calories: 500, protein: 25, carbs: 35, fat: 28, fiber: 2),
      'sandwich': const NutritionEstimate(grams: 150, calories: 350, protein: 15, carbs: 40, fat: 14, fiber: 3),
      'salad': const NutritionEstimate(grams: 200, calories: 150, protein: 5, carbs: 15, fat: 8, fiber: 5),
      'soup': const NutritionEstimate(grams: 250, calories: 150, protein: 8, carbs: 18, fat: 5, fiber: 3),
      'pasta': const NutritionEstimate(grams: 200, calories: 400, protein: 12, carbs: 65, fat: 10, fiber: 4),
      'rice': const NutritionEstimate(grams: 150, calories: 200, protein: 4, carbs: 45, fat: 1, fiber: 1),
      'chicken': const NutritionEstimate(grams: 150, calories: 250, protein: 35, carbs: 0, fat: 12, fiber: 0),
      'beef': const NutritionEstimate(grams: 150, calories: 350, protein: 30, carbs: 0, fat: 25, fiber: 0),
      'fish': const NutritionEstimate(grams: 150, calories: 200, protein: 30, carbs: 0, fat: 8, fiber: 0),
      'egg': const NutritionEstimate(grams: 50, calories: 80, protein: 6, carbs: 1, fat: 5, fiber: 0),
      'bread': const NutritionEstimate(grams: 50, calories: 130, protein: 4, carbs: 25, fat: 2, fiber: 2),
      'fruit': const NutritionEstimate(grams: 150, calories: 80, protein: 1, carbs: 20, fat: 0, fiber: 3),
      'apple': const NutritionEstimate(grams: 150, calories: 80, protein: 0, carbs: 21, fat: 0, fiber: 4),
      'banana': const NutritionEstimate(grams: 120, calories: 105, protein: 1, carbs: 27, fat: 0, fiber: 3),
      'vegetable': const NutritionEstimate(grams: 100, calories: 40, protein: 2, carbs: 8, fat: 0, fiber: 3),
      'cake': const NutritionEstimate(grams: 100, calories: 350, protein: 4, carbs: 50, fat: 15, fiber: 1),
      'dessert': const NutritionEstimate(grams: 100, calories: 300, protein: 3, carbs: 45, fat: 12, fiber: 1),
      'sushi': const NutritionEstimate(grams: 150, calories: 250, protein: 12, carbs: 35, fat: 7, fiber: 1),
      'curry': const NutritionEstimate(grams: 200, calories: 350, protein: 15, carbs: 30, fat: 18, fiber: 4),
      'fries': const NutritionEstimate(grams: 100, calories: 320, protein: 4, carbs: 40, fat: 16, fiber: 3),
      'steak': const NutritionEstimate(grams: 200, calories: 500, protein: 45, carbs: 0, fat: 35, fiber: 0),
    };

    // Find matching nutrition data
    for (final entry in nutritionData.entries) {
      if (lowerLabel.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default estimation for unknown foods
    return const NutritionEstimate(
      grams: 100,
      calories: 200,
      protein: 8,
      carbs: 25,
      fat: 8,
      fiber: 2,
    );
  }

  /// Update portion size and recalculate nutrition
  FoodAnalysis updatePortionSize(FoodAnalysis analysis, double newGrams) {
    final factor = newGrams / analysis.estimatedGrams;
    return analysis.copyWith(
      estimatedGrams: newGrams,
      estimatedCalories: (analysis.estimatedCalories * factor).round(),
      protein: analysis.protein * factor,
      carbs: analysis.carbs * factor,
      fat: analysis.fat * factor,
      fiber: analysis.fiber * factor,
    );
  }

  /// Dispose ML resources
  Future<void> dispose() async {
    await _imageLabeler?.close();
    await _objectDetector?.close();
    _imageLabeler = null;
    _objectDetector = null;
  }
}

/// Internal class for detected food objects
class _DetectedFood {
  final String label;
  final double confidence;

  _DetectedFood({required this.label, required this.confidence});
}

