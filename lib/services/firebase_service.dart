import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/recipe.dart';
import '../repository/app_repository.dart';

// Import AnalysisModel and FoodItem from app_repository
// These are defined in app_repository.dart

/// Service for Firebase Firestore operations with offline support
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static bool _initialized = false;

  /// Initialize Firebase with offline persistence
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      
      // Enable offline persistence
      await _firestore!.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );

      _initialized = true;
      print('[FirebaseService] Initialized with offline persistence');
    } catch (e) {
      print('[FirebaseService] Initialization error: $e');
      // Continue without Firebase if initialization fails
      _initialized = false;
    }
  }

  /// Check if Firebase is available
  static bool get isAvailable => _initialized && _firestore != null;

  /// Get Firestore instance
  static FirebaseFirestore? get firestore => _firestore;

  /// Sync recipes from Firestore to local DB
  static Future<void> syncRecipesFromFirestore() async {
    if (!isAvailable) return;

    try {
      final recipesSnapshot = await _firestore!
          .collection('recipes')
          .get();

      final repository = AppRepository();
      
      for (var doc in recipesSnapshot.docs) {
        final data = doc.data();
        // Convert Firestore data to RecipeModel and save to local DB
        final recipeModel = RecipeModel(
          name: data['name'] ?? '',
          ingredients: List<String>.from(data['ingredients'] ?? []),
          steps: List<String>.from(data['steps'] ?? []),
          imageUrl: data['image_url'] ?? '',
          calories: data['calories'] ?? 0,
          protein: (data['protein'] ?? 0).toDouble(),
          carbs: (data['carbs'] ?? 0).toDouble(),
          fat: (data['fat'] ?? 0).toDouble(),
          prepTime: data['prep_time'] ?? 0,
          cookTime: data['cook_time'] ?? 0,
          servings: data['servings'] ?? 1,
          category: data['category'] ?? 'Genel',
          isFavorite: (data['is_favorite'] == true || data['is_favorite'] == 1),
        );
        await repository.insertRecipe(recipeModel);
      }

      print('[FirebaseService] Synced ${recipesSnapshot.docs.length} recipes from Firestore');
    } catch (e) {
      print('[FirebaseService] Error syncing recipes: $e');
    }
  }

  /// Sync analyses from Firestore to local DB
  static Future<void> syncAnalysesFromFirestore() async {
    if (!isAvailable) return;

    try {
      final analysesSnapshot = await _firestore!
          .collection('analyses')
          .get();

      final repository = AppRepository();
      
      for (var doc in analysesSnapshot.docs) {
        final data = doc.data();
        // Convert Firestore data to AnalysisModel and save to local DB
        final foodsData = List<Map<String, dynamic>>.from(data['foods'] ?? []);
        final foods = foodsData.map((f) => FoodItem(
          name: f['name'] ?? '',
          grams: (f['grams'] ?? 100).toDouble(),
          calories: f['calories'] ?? 0,
          protein: (f['protein'] ?? 0).toDouble(),
          carbs: (f['carbs'] ?? 0).toDouble(),
          fat: (f['fat'] ?? 0).toDouble(),
        )).toList();

        final analysis = AnalysisModel(
          date: data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
          photoPath: data['photo_path'] ?? '',
          foods: foods,
          totalCalories: data['total_calories'] ?? 0,
          totalProtein: (data['total_protein'] ?? 0).toDouble(),
          totalCarbs: (data['total_carbs'] ?? 0).toDouble(),
          totalFat: (data['total_fat'] ?? 0).toDouble(),
        );

        await repository.insertAnalysis(analysis);
      }

      print('[FirebaseService] Synced ${analysesSnapshot.docs.length} analyses from Firestore');
    } catch (e) {
      print('[FirebaseService] Error syncing analyses: $e');
    }
  }

  /// Upload recipe to Firestore
  static Future<void> uploadRecipeToFirestore(Recipe recipe) async {
    if (!isAvailable) return;

    try {
      await _firestore!.collection('recipes').add({
        'name': recipe.title,
        'ingredients': recipe.ingredients,
        'steps': recipe.instructions,
        'image_url': recipe.imageUrl,
        'calories': recipe.calories,
        'protein': recipe.protein,
        'carbs': recipe.carbs,
        'fat': recipe.fat,
        'prep_time': recipe.prepTimeMinutes,
        'cook_time': recipe.cookTimeMinutes,
        'servings': recipe.servings,
        'is_favorite': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('[FirebaseService] Uploaded recipe: ${recipe.title}');
    } catch (e) {
      print('[FirebaseService] Error uploading recipe: $e');
      rethrow;
    }
  }

  /// Upload analysis to Firestore
  static Future<void> uploadAnalysisToFirestore(AnalysisModel analysis) async {
    if (!isAvailable) return;

    try {
      await _firestore!.collection('analyses').add({
        'date': analysis.date,
        'photo_path': analysis.photoPath,
        'foods': analysis.foods.map((f) => {
          'name': f.name,
          'grams': f.grams,
          'calories': f.calories,
          'protein': f.protein,
          'carbs': f.carbs,
          'fat': f.fat,
        }).toList(),
        'total_calories': analysis.totalCalories,
        'total_protein': analysis.foods.fold(0.0, (sum, f) => sum + f.protein),
        'total_carbs': analysis.foods.fold(0.0, (sum, f) => sum + f.carbs),
        'total_fat': analysis.foods.fold(0.0, (sum, f) => sum + f.fat),
        'created_at': FieldValue.serverTimestamp(),
      });

      print('[FirebaseService] Uploaded analysis: ${analysis.date}');
    } catch (e) {
      print('[FirebaseService] Error uploading analysis: $e');
      rethrow;
    }
  }

  /// Sync local changes to Firestore (on reconnect)
  static Future<void> syncLocalChangesToFirestore() async {
    if (!isAvailable) return;

    try {
      // Sync favorite changes
      final repository = AppRepository();
      final favorites = await repository.getFavoriteRecipes();
      
      for (var recipe in favorites) {
        // Update favorite status in Firestore
        // This is simplified - you may need to track recipe IDs
        await _firestore!.collection('recipes')
            .where('name', isEqualTo: recipe.name)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'is_favorite': true});
          }
        });
      }

      print('[FirebaseService] Synced local changes to Firestore');
    } catch (e) {
      print('[FirebaseService] Error syncing local changes: $e');
    }
  }

  /// Full sync: Firestore -> Local DB
  static Future<void> syncFromFirestore() async {
    if (!isAvailable) return;

    await syncRecipesFromFirestore();
    await syncAnalysesFromFirestore();
  }

  /// Full sync: Local DB -> Firestore
  static Future<void> syncToFirestore() async {
    if (!isAvailable) return;

    await syncLocalChangesToFirestore();
  }
}

