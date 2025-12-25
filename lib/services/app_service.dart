import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../repository/app_repository.dart';
import 'firebase_service.dart';
// import 'ml_service_hms.dart'; // HMS support - enable when packages are available

/// Unified service for ML and API integrations
class AppService {
  static final AppService _instance = AppService._internal();
  
  // API Keys - Loaded from secure storage or environment
  String? _spoonacularApiKey;
  String? _nutritionixAppId;
  String? _nutritionixApiKey;
  
  /// Initialize API keys from secure storage
  Future<void> initApiKeys() async {
    // In production, load from SecureStorage
    // For now, use environment variables or defaults
    _spoonacularApiKey = const String.fromEnvironment('SPOONACULAR_API_KEY', defaultValue: 'YOUR_SPOONACULAR_API_KEY');
    _nutritionixAppId = const String.fromEnvironment('NUTRITIONIX_APP_ID', defaultValue: 'YOUR_NUTRITIONIX_APP_ID');
    _nutritionixApiKey = const String.fromEnvironment('NUTRITIONIX_API_KEY', defaultValue: 'YOUR_NUTRITIONIX_API_KEY');
  }
  
  // API Endpoints
  static const String _spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String _nutritionixBaseUrl = 'https://trackapi.nutritionix.com/v2';
  
  // ML Kit instances
  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;
  
  // HTTP client
  final http.Client _httpClient = http.Client();
  
  // Repository
  final AppRepository _repository = AppRepository();

  // Response cache for API calls
  final Map<String, _CachedResponse> _responseCache = {};

  factory AppService() => _instance;

  AppService._internal();

  /// Initialize ML services
  Future<void> initML() async {
    print('[AppService] Initializing ML services...');
    
    // Note: HMS support is prepared but packages need to be configured
    // For now, using Google ML Kit which works on all Android devices
    // including Huawei devices (if Google Play Services is available)
    
    try {
      final labelerOptions = ImageLabelerOptions(
        confidenceThreshold: 0.5,
      );
      _imageLabeler = ImageLabeler(options: labelerOptions);
      
      final detectorOptions = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: detectorOptions);
      
      print('[AppService] Google ML Kit initialized successfully');
    } catch (e) {
      print('[AppService] ⚠️ Google ML Kit initialization failed: $e');
      print('[AppService] ℹ️ This is normal on Huawei devices without Google Play Services');
      print('[AppService] ℹ️ App will use API-based analysis instead');
      // Set to null so we know ML Kit is not available
      _imageLabeler = null;
      _objectDetector = null;
    }
  }

  /// Dispose ML resources
  Future<void> dispose() async {
    await _imageLabeler?.close();
    await _objectDetector?.close();
    _httpClient.close();
    print('[AppService] Services disposed');
  }

  // ==================== ML ANALYSIS ====================

  /// Analyze image for food recognition
  Future<ImageAnalysisResult> analyzeImage(String photoPath) async {
    print('[AppService] Analyzing image: $photoPath');
    
    try {
      // Try to use Google ML Kit if available
      if (_imageLabeler != null && _objectDetector != null) {
        try {
          final inputImage = InputImage.fromFilePath(photoPath);
          
          // Get labels from image
          final labels = await _processImageLabels(inputImage);
          
          // Get detected objects with bounding boxes
          final detectedObjects = await _processObjectDetection(inputImage);
          
          // Filter for food-related items
          final foodLabels = _filterFoodLabels(labels);
          
          // Estimate grams based on bounding boxes
          final foodItems = await _estimateNutrition(foodLabels, detectedObjects);
          
          // Save analysis to database
          if (foodItems.isNotEmpty) {
            final analysis = AnalysisModel(
              date: DateTime.now().toIso8601String().split('T')[0],
              photoPath: photoPath,
              foods: foodItems,
            );
            
            final id = await _repository.insertAnalysis(analysis);
            print('[AppService] Analysis saved with ID: $id');
            
            // Upload to Firebase if available (offline cache will handle it)
            try {
              if (FirebaseService.isAvailable) {
                await FirebaseService.uploadAnalysisToFirestore(analysis);
              }
            } catch (e) {
              print('[AppService] Firebase upload error: $e');
              // Continue without Firebase
            }
            
            return ImageAnalysisResult(
              success: true,
              foods: foodItems,
              analysisId: id,
              message: '${foodItems.length} yiyecek tespit edildi',
            );
          }
        } catch (e) {
          print('[AppService] ML Kit analysis failed, falling back to API: $e');
          // Fall through to API-based analysis
        }
      }
      
      // Fallback: Use API-based analysis (works on all devices including Huawei)
      print('[AppService] Using API-based analysis (ML Kit not available)');
      return await _analyzeImageViaAPI(photoPath);
      
    } catch (e) {
      print('[AppService] Image analysis error: $e');
      return ImageAnalysisResult(
        success: false,
        foods: [],
        message: 'Analiz hatası: $e',
      );
    }
  }
  
  /// Fallback: Analyze image using API only (for devices without ML Kit)
  Future<ImageAnalysisResult> _analyzeImageViaAPI(String photoPath) async {
    print('[AppService] Using API-based analysis for: $photoPath');
    
    // For now, return a message that manual input is needed
    // In the future, you could use a cloud vision API here
    return ImageAnalysisResult(
      success: true,
      foods: [],
      message: 'ML servisi mevcut değil. Lütfen yiyecekleri manuel olarak ekleyin.',
    );
  }

  /// Process image labels using ML Kit
  Future<List<ImageLabel>> _processImageLabels(InputImage inputImage) async {
    if (_imageLabeler == null) {
      await initML();
      if (_imageLabeler == null) {
        print('[AppService] ML Kit not available, skipping label processing');
        return [];
      }
    }
    
    try {
      final labels = await _imageLabeler!.processImage(inputImage);
      print('[AppService] Found ${labels.length} labels');
      return labels;
    } catch (e) {
      print('[AppService] Label processing error: $e');
      return [];
    }
  }

  /// Process object detection using ML Kit
  Future<List<DetectedObject>> _processObjectDetection(InputImage inputImage) async {
    if (_objectDetector == null) {
      await initML();
      if (_objectDetector == null) {
        print('[AppService] ML Kit not available, skipping object detection');
        return [];
      }
    }
    
    try {
      final objects = await _objectDetector!.processImage(inputImage);
      print('[AppService] Found ${objects.length} objects');
      return objects;
    } catch (e) {
      print('[AppService] Object detection error: $e');
      return [];
    }
  }

  /// Filter labels for food-related items
  List<ImageLabel> _filterFoodLabels(List<ImageLabel> labels) {
    final foodKeywords = [
      'food', 'fruit', 'vegetable', 'meat', 'bread', 'rice', 'pasta',
      'egg', 'cheese', 'milk', 'coffee', 'tea', 'juice', 'soup',
      'salad', 'cake', 'pizza', 'burger', 'sandwich', 'chicken',
      'fish', 'beef', 'pork', 'tomato', 'potato', 'carrot', 'apple',
      'banana', 'orange', 'grape', 'strawberry', 'breakfast', 'lunch',
      'dinner', 'meal', 'dish', 'cuisine', 'snack', 'dessert',
      // Turkish food keywords
      'yemek', 'meyve', 'sebze', 'et', 'ekmek', 'pilav', 'makarna',
      'yumurta', 'peynir', 'süt', 'kahve', 'çay', 'çorba', 'salata',
      'kebap', 'döner', 'lahmacun', 'pide', 'börek',
    ];
    
    return labels.where((label) {
      final labelLower = label.label.toLowerCase();
      return foodKeywords.any((keyword) => labelLower.contains(keyword)) ||
             label.confidence > 0.7;
    }).toList();
  }

  /// Estimate nutrition based on labels and bounding boxes
  Future<List<FoodItem>> _estimateNutrition(
    List<ImageLabel> labels,
    List<DetectedObject> objects,
  ) async {
    final foods = <FoodItem>[];
    
    // Use mock data if no API keys or for demo
    if (_spoonacularApiKey == null || _spoonacularApiKey == 'YOUR_SPOONACULAR_API_KEY') {
      // Generate mock food items from labels
      for (final label in labels.take(5)) {
        final grams = _estimateGramsFromBoundingBox(objects, label.label);
        final mockNutrition = _getMockNutrition(label.label);
        
        foods.add(FoodItem(
          name: _translateFoodName(label.label),
          grams: grams,
          calories: mockNutrition['calories']!.toInt(),
          protein: mockNutrition['protein']!,
          carbs: mockNutrition['carbs']!,
          fat: mockNutrition['fat']!,
        ));
      }
    } else {
      // Use Nutritionix API for real data
      for (final label in labels.take(5)) {
        final grams = _estimateGramsFromBoundingBox(objects, label.label);
        final nutrition = await _getNutritionFromApi(label.label, grams);
        
        if (nutrition != null) {
          foods.add(nutrition);
        }
      }
    }
    
    return foods;
  }

  /// Estimate grams from ML bounding box size (enhanced)
  /// Uses area, aspect ratio, and position for better accuracy
  double _estimateGramsFromBoundingBox(List<DetectedObject> objects, String label) {
    // Find matching object by label
    DetectedObject? matchedObject;
    double bestConfidence = 0.0;
    
    for (final obj in objects) {
      for (final objLabel in obj.labels) {
        final labelLower = label.toLowerCase();
        final objLabelLower = objLabel.text.toLowerCase();
        
        if (objLabelLower.contains(labelLower) || labelLower.contains(objLabelLower)) {
          if (objLabel.confidence > bestConfidence) {
            matchedObject = obj;
            bestConfidence = objLabel.confidence;
          }
        }
      }
    }
    
    if (matchedObject != null) {
      final box = matchedObject.boundingBox;
      
      // Calculate area in pixels
      final area = box.width * box.height;
      
      // Calculate aspect ratio (helps identify food type)
      final aspectRatio = box.width / box.height;
      
      // Estimate grams based on:
      // 1. Area (larger = more food)
      // 2. Aspect ratio (round foods vs elongated)
      // 3. Confidence (higher confidence = more accurate)
      
      double baseGrams = area / 150.0; // Base calculation: pixels to grams
      
      // Adjust for aspect ratio
      if (aspectRatio > 1.5) {
        // Elongated food (bread, pasta) - typically lighter
        baseGrams *= 0.8;
      } else if (aspectRatio < 0.7) {
        // Tall food (drinks, soups) - typically heavier
        baseGrams *= 1.2;
      }
      
      // Apply confidence multiplier
      baseGrams *= (0.7 + (bestConfidence * 0.3));
      
      // Clamp to reasonable range
      final estimatedGrams = baseGrams.clamp(20.0, 1000.0);
      
      print('[AppService] Estimated ${estimatedGrams.toStringAsFixed(0)}g for $label '
          '(area: ${area.toStringAsFixed(0)}, aspect: ${aspectRatio.toStringAsFixed(2)}, '
          'confidence: ${(bestConfidence * 100).toStringAsFixed(0)}%)');
      
      return estimatedGrams;
    }
    
    // Default estimation based on food type if no bounding box found
    final defaultGrams = _getDefaultGrams(label);
    print('[AppService] Using default ${defaultGrams}g for $label (no bounding box)');
    return defaultGrams;
  }

  /// Get default grams estimation for food type
  double _getDefaultGrams(String foodName) {
    final foodLower = foodName.toLowerCase();
    
    if (foodLower.contains('egg') || foodLower.contains('yumurta')) return 60.0;
    if (foodLower.contains('bread') || foodLower.contains('ekmek')) return 50.0;
    if (foodLower.contains('rice') || foodLower.contains('pilav')) return 150.0;
    if (foodLower.contains('pasta') || foodLower.contains('makarna')) return 200.0;
    if (foodLower.contains('chicken') || foodLower.contains('tavuk')) return 150.0;
    if (foodLower.contains('meat') || foodLower.contains('et')) return 150.0;
    if (foodLower.contains('salad') || foodLower.contains('salata')) return 100.0;
    if (foodLower.contains('soup') || foodLower.contains('çorba')) return 250.0;
    if (foodLower.contains('fruit') || foodLower.contains('meyve')) return 120.0;
    
    return 100.0; // Default
  }

  /// Get mock nutrition data
  Map<String, double> _getMockNutrition(String foodName) {
    final foodLower = foodName.toLowerCase();
    
    // Database of common foods (per 100g)
    final nutritionDb = {
      'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
      'yumurta': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
      'bread': {'calories': 265.0, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.0},
      'ekmek': {'calories': 265.0, 'protein': 9.0, 'carbs': 49.0, 'fat': 3.0},
      'rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'pilav': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'chicken': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      'tavuk': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      'salad': {'calories': 25.0, 'protein': 2.0, 'carbs': 4.0, 'fat': 0.5},
      'salata': {'calories': 25.0, 'protein': 2.0, 'carbs': 4.0, 'fat': 0.5},
      'pasta': {'calories': 131.0, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1},
      'makarna': {'calories': 131.0, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1},
      'meat': {'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0},
      'et': {'calories': 250.0, 'protein': 26.0, 'carbs': 0.0, 'fat': 15.0},
    };
    
    for (final entry in nutritionDb.entries) {
      if (foodLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default nutrition
    return {'calories': 100.0, 'protein': 5.0, 'carbs': 15.0, 'fat': 3.0};
  }

  /// Translate food name to Turkish
  String _translateFoodName(String englishName) {
    final translations = {
      'egg': 'Yumurta',
      'bread': 'Ekmek',
      'rice': 'Pilav',
      'chicken': 'Tavuk',
      'meat': 'Et',
      'salad': 'Salata',
      'pasta': 'Makarna',
      'soup': 'Çorba',
      'cheese': 'Peynir',
      'milk': 'Süt',
      'coffee': 'Kahve',
      'tea': 'Çay',
      'fruit': 'Meyve',
      'vegetable': 'Sebze',
      'fish': 'Balık',
      'pizza': 'Pizza',
      'burger': 'Hamburger',
      'sandwich': 'Sandviç',
      'cake': 'Pasta',
      'dessert': 'Tatlı',
    };
    
    final nameLower = englishName.toLowerCase();
    for (final entry in translations.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return englishName;
  }

  /// Get nutrition from Nutritionix API with caching
  Future<FoodItem?> _getNutritionFromApi(String foodName, double grams) async {
    // Create cache key
    final cacheKey = 'nutrition_${foodName.toLowerCase()}_${grams.toStringAsFixed(0)}';
    
    // Check cache first
    final cached = _responseCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      print('[AppService] Using cached nutrition for $foodName');
      // Scale to requested grams
      final cachedFood = cached.data as FoodItem;
      if (cachedFood.grams != grams) {
        final factor = grams / cachedFood.grams;
        return FoodItem(
          name: cachedFood.name,
          grams: grams,
          calories: (cachedFood.calories * factor).round(),
          protein: cachedFood.protein * factor,
          carbs: cachedFood.carbs * factor,
          fat: cachedFood.fat * factor,
        );
      }
      return cachedFood;
    }
    
    try {
      print('[AppService] Fetching nutrition from API for $foodName ($grams g)');
      
      final response = await _httpClient.post(
        Uri.parse('$_nutritionixBaseUrl/natural/nutrients'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _nutritionixAppId ?? '',
          'x-app-key': _nutritionixApiKey ?? '',
        },
        body: jsonEncode({
          'query': '$grams grams $foodName',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List?;
        
        if (foods != null && foods.isNotEmpty) {
          final food = foods.first;
          final foodItem = FoodItem(
            name: food['food_name'] ?? foodName,
            grams: grams,
            calories: (food['nf_calories'] as num?)?.toInt() ?? 0,
            protein: (food['nf_protein'] as num?)?.toDouble() ?? 0.0,
            carbs: (food['nf_total_carbohydrate'] as num?)?.toDouble() ?? 0.0,
            fat: (food['nf_total_fat'] as num?)?.toDouble() ?? 0.0,
          );
          
          // Cache the response (use 100g as base for caching)
          if (grams == 100.0 || grams == 0) {
            _responseCache[cacheKey] = _CachedResponse(
              data: foodItem,
              timestamp: DateTime.now(),
            );
            print('[AppService] Cached nutrition for $foodName');
          }
          
          return foodItem;
        }
      } else {
        print('[AppService] Nutritionix API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('[AppService] Nutritionix API error: $e');
    }
    
    return null;
  }
  
  /// Clear expired cache entries
  void clearExpiredCache() {
    _responseCache.removeWhere((key, value) => value.isExpired);
    print('[AppService] Cleared expired cache entries');
  }
  
  /// Clear all cache
  void clearCache() {
    _responseCache.clear();
    print('[AppService] Cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int expired = 0;
    int valid = 0;
    
    for (final entry in _responseCache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        valid++;
      }
    }
    
    return {
      'total': _responseCache.length,
      'valid': valid,
      'expired': expired,
    };
  }

  // ==================== RECIPE API ====================

  /// Fetch recipes from Spoonacular API
  Future<RecipeSearchResult> fetchRecipes(String ingredients, {int number = 10}) async {
    print('[AppService] Fetching recipes for: $ingredients');
    
    try {
      // Use mock data if no API key
      if (_spoonacularApiKey == null || _spoonacularApiKey == 'YOUR_SPOONACULAR_API_KEY') {
        // Fallback to local DB if offline
        final localRecipes = await _repository.searchRecipes(ingredients);
        if (localRecipes.isNotEmpty) {
          return RecipeSearchResult(
            success: true,
            recipes: localRecipes,
            message: 'Yerel veritabanından ${localRecipes.length} tarif bulundu',
          );
        }
        return _getMockRecipeResults(ingredients);
      }
      
      final response = await _httpClient.get(
        Uri.parse(
          '$_spoonacularBaseUrl/recipes/complexSearch'
          '?apiKey=$_spoonacularApiKey'
          '&includeIngredients=${Uri.encodeComponent(ingredients)}'
          '&number=$number'
          '&addRecipeNutrition=true'
          '&fillIngredients=true',
        ),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        
        final recipes = <RecipeModel>[];
        for (final result in results) {
          final recipeModel = _parseSpoonacularRecipe(result);
          
          // Save to database
          final id = await _repository.insertRecipe(recipeModel);
          recipes.add(recipeModel.copyWith(id: id));
        }
        
        return RecipeSearchResult(
          success: true,
          recipes: recipes,
          message: '${recipes.length} tarif bulundu',
        );
      } else {
        return RecipeSearchResult(
          success: false,
          recipes: [],
          message: 'API hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[AppService] Recipe fetch error: $e');
      return RecipeSearchResult(
        success: false,
        recipes: [],
        message: 'Bağlantı hatası: $e',
      );
    }
  }

  /// Parse Spoonacular recipe response
  RecipeModel _parseSpoonacularRecipe(Map<String, dynamic> data) {
    final ingredients = <String>[];
    final steps = <String>[];
    
    // Parse ingredients
    final extendedIngredients = data['extendedIngredients'] as List? ?? [];
    for (final ing in extendedIngredients) {
      ingredients.add(ing['original'] as String? ?? '');
    }
    
    // Parse steps
    final analyzedInstructions = data['analyzedInstructions'] as List? ?? [];
    if (analyzedInstructions.isNotEmpty) {
      final instructionSteps = analyzedInstructions.first['steps'] as List? ?? [];
      for (final step in instructionSteps) {
        steps.add(step['step'] as String? ?? '');
      }
    }
    
    // Get nutrition info
    final nutrition = data['nutrition'] as Map<String, dynamic>? ?? {};
    final nutrients = nutrition['nutrients'] as List? ?? [];
    
    int calories = 0;
    double protein = 0, carbs = 0, fat = 0;
    
    for (final nutrient in nutrients) {
      final name = nutrient['name'] as String? ?? '';
      final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0;
      
      if (name == 'Calories') calories = amount.toInt();
      if (name == 'Protein') protein = amount;
      if (name == 'Carbohydrates') carbs = amount;
      if (name == 'Fat') fat = amount;
    }
    
    return RecipeModel(
      name: data['title'] as String? ?? '',
      ingredients: ingredients.isEmpty ? ['Malzeme bilgisi yok'] : ingredients,
      steps: steps.isEmpty ? ['Tarif adımları yok'] : steps,
      imageUrl: data['image'] as String? ?? '',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      prepTime: data['preparationMinutes'] as int? ?? 10,
      cookTime: data['cookingMinutes'] as int? ?? 20,
      servings: data['servings'] as int? ?? 1,
    );
  }

  /// Get mock recipe results for demo
  RecipeSearchResult _getMockRecipeResults(String ingredients) {
    final ingredientLower = ingredients.toLowerCase();
    final mockRecipes = <RecipeModel>[];
    
    // Generate contextual mock recipes based on ingredients
    if (ingredientLower.contains('yumurta') || ingredientLower.contains('egg')) {
      mockRecipes.add(RecipeModel(
        name: 'Sebzeli Omlet',
        ingredients: ['2 yumurta', 'Biber', 'Domates', 'Tuz'],
        steps: ['Yumurtaları çırpın', 'Sebzeleri ekleyin', 'Pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/ryspuw1511786711.jpg',
        calories: 220,
        protein: 16.0,
        carbs: 4.0,
        fat: 15.0,
        prepTime: 5,
        cookTime: 5,
        servings: 1,
        category: 'Kahvaltı',
      ));
    }
    
    if (ingredientLower.contains('tavuk') || ingredientLower.contains('chicken')) {
      mockRecipes.add(RecipeModel(
        name: 'Tavuk Şiş',
        ingredients: ['500g tavuk', 'Biber', 'Soğan', 'Baharatlar'],
        steps: ['Marine edin', 'Şişe dizin', 'Izgara yapın'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/wyxwsp1486979827.jpg',
        calories: 280,
        protein: 35.0,
        carbs: 8.0,
        fat: 12.0,
        prepTime: 30,
        cookTime: 20,
        servings: 4,
        category: 'Ana Yemek',
      ));
    }
    
    if (ingredientLower.contains('domates') || ingredientLower.contains('tomato')) {
      mockRecipes.add(RecipeModel(
        name: 'Domates Çorbası',
        ingredients: ['4 domates', 'Soğan', 'Tereyağı', 'Et suyu'],
        steps: ['Sebzeleri kavurun', 'Haşlayın', 'Blenderdan geçirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/tnwy8m1628770384.jpg',
        calories: 150,
        protein: 4.0,
        carbs: 18.0,
        fat: 8.0,
        prepTime: 10,
        cookTime: 25,
        servings: 4,
        category: 'Çorba',
      ));
    }
    
    // Add some generic recipes
    mockRecipes.addAll([
      RecipeModel(
        name: 'Kolay Salata',
        ingredients: ['Marul', 'Domates', 'Salatalık', 'Zeytinyağı'],
        steps: ['Sebzeleri doğrayın', 'Karıştırın', 'Sosunu ekleyin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg',
        calories: 120,
        protein: 3.0,
        carbs: 10.0,
        fat: 8.0,
        prepTime: 10,
        cookTime: 0,
        servings: 2,
        category: 'Salata',
      ),
      RecipeModel(
        name: 'Karışık Kızartma',
        ingredients: ['Patates', 'Patlıcan', 'Biber', 'Kabak'],
        steps: ['Sebzeleri doğrayın', 'Yağda kızartın', 'Sıcak servis edin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/uyqrrv1511553350.jpg',
        calories: 320,
        protein: 5.0,
        carbs: 35.0,
        fat: 18.0,
        prepTime: 15,
        cookTime: 20,
        servings: 3,
        category: 'Yan Yemek',
      ),
    ]);
    
    return RecipeSearchResult(
      success: true,
      recipes: mockRecipes,
      message: '${mockRecipes.length} tarif bulundu (demo)',
    );
  }

  /// Search recipes linked to analyzed foods
  Future<RecipeSearchResult> searchRecipesForAnalysis(List<FoodItem> foods) async {
    if (foods.isEmpty) {
      return RecipeSearchResult(
        success: false,
        recipes: [],
        message: 'Yiyecek bulunamadı',
      );
    }
    
    // Extract food names as ingredients
    final ingredients = foods.map((f) => f.name).join(', ');
    return fetchRecipes(ingredients);
  }

  /// Get recipe suggestions based on available ingredients
  Future<RecipeSearchResult> getSuggestions() async {
    // Get frequently used ingredients from history
    final analyses = await _repository.getAllAnalyses();
    
    if (analyses.isEmpty) {
      return fetchRecipes('tavuk, pilav, salata');
    }
    
    // Get unique food names from recent analyses
    final recentFoods = <String>{};
    for (final analysis in analyses.take(5)) {
      for (final food in analysis.foods) {
        recentFoods.add(food.name);
      }
    }
    
    final ingredients = recentFoods.take(3).join(', ');
    return fetchRecipes(ingredients);
  }

  // ==================== UTILITY METHODS ====================

  /// Validate API keys
  bool get hasValidApiKeys {
    return _spoonacularApiKey != null &&
           _spoonacularApiKey != 'YOUR_SPOONACULAR_API_KEY' &&
           _nutritionixAppId != null &&
           _nutritionixAppId != 'YOUR_NUTRITIONIX_APP_ID' &&
           _nutritionixApiKey != null &&
           _nutritionixApiKey != 'YOUR_NUTRITIONIX_API_KEY';
  }

  /// Get repository instance
  AppRepository get repository => _repository;

  /// Check if running in demo mode
  bool get isDemoMode => !hasValidApiKeys;
}

// ==================== RESULT MODELS ====================

/// Result of image analysis
class ImageAnalysisResult {
  final bool success;
  final List<FoodItem> foods;
  final int? analysisId;
  final String message;

  ImageAnalysisResult({
    required this.success,
    required this.foods,
    this.analysisId,
    required this.message,
  });

  int get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);
  double get totalProtein => foods.fold(0.0, (sum, f) => sum + f.protein);
  double get totalCarbs => foods.fold(0.0, (sum, f) => sum + f.carbs);
  double get totalFat => foods.fold(0.0, (sum, f) => sum + f.fat);
}

/// Result of recipe search
class RecipeSearchResult {
  final bool success;
  final List<RecipeModel> recipes;
  final String message;

  RecipeSearchResult({
    required this.success,
    required this.recipes,
    required this.message,
  });
}

// ==================== CACHE CLASS ====================

/// Cached API response with expiry
class _CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  static const Duration _expiry = Duration(hours: 24);

  _CachedResponse({
    required this.data,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > _expiry;
  }
}

