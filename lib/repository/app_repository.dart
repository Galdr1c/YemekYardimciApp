import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Unified repository for all database operations
class AppRepository {
  static final AppRepository _instance = AppRepository._internal();
  static Database? _database;
  
  // Flag to track if sample data has been inserted
  static bool _sampleDataInserted = false;

  factory AppRepository() => _instance;

  AppRepository._internal();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  /// Initialize the database with schemas
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yemek_yardimci.db');

    print('[AppRepository] Initializing database at: $path');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables with proper schemas
  Future<void> _onCreate(Database db, int version) async {
    print('[AppRepository] Creating database tables...');

    // Recipes table schema
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        steps TEXT NOT NULL,
        image_url TEXT,
        is_favorite INTEGER DEFAULT 0,
        calories INTEGER DEFAULT 0,
        protein REAL DEFAULT 0.0,
        carbs REAL DEFAULT 0.0,
        fat REAL DEFAULT 0.0,
        prep_time INTEGER DEFAULT 0,
        cook_time INTEGER DEFAULT 0,
        servings INTEGER DEFAULT 1,
        category TEXT DEFAULT 'Genel',
        created_at TEXT NOT NULL
      )
    ''');

    // Analyses table schema
    await db.execute('''
      CREATE TABLE analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        photo_path TEXT NOT NULL,
        foods TEXT NOT NULL,
        total_calories INTEGER DEFAULT 0,
        total_protein REAL DEFAULT 0.0,
        total_carbs REAL DEFAULT 0.0,
        total_fat REAL DEFAULT 0.0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_recipes_name ON recipes(name)');
    await db.execute('CREATE INDEX idx_recipes_favorite ON recipes(is_favorite)');
    await db.execute('CREATE INDEX idx_recipes_category ON recipes(category)');
    await db.execute('CREATE INDEX idx_analyses_date ON analyses(date)');

    print('[AppRepository] Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('[AppRepository] Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 2) {
      // Add new columns if upgrading from v1
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN protein REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE recipes ADD COLUMN carbs REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE recipes ADD COLUMN fat REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE recipes ADD COLUMN prep_time INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE recipes ADD COLUMN cook_time INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE recipes ADD COLUMN servings INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT "Genel"');
      } catch (e) {
        print('[AppRepository] Column already exists or error: $e');
      }
    }
  }

  // ==================== RECIPE METHODS ====================

  /// Insert a new recipe
  Future<int> insertRecipe(RecipeModel recipe) async {
    final db = await database;
    final id = await db.insert('recipes', recipe.toMap());
    print('[AppRepository] Inserted recipe: ${recipe.name} (ID: $id)');
    return id;
  }

  /// Update an existing recipe
  Future<int> updateRecipe(RecipeModel recipe) async {
    if (recipe.id == null) throw ArgumentError('Recipe ID cannot be null');
    
    final db = await database;
    final count = await db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
    print('[AppRepository] Updated recipe ID: ${recipe.id}');
    return count;
  }

  /// Get all recipes
  Future<List<RecipeModel>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes', orderBy: 'created_at DESC');
    print('[AppRepository] Retrieved ${maps.length} recipes');
    return maps.map((map) => RecipeModel.fromMap(map)).toList();
  }

  /// Get recipe by ID
  Future<RecipeModel?> getRecipeById(int id) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RecipeModel.fromMap(maps.first);
  }

  /// Search recipes by name or ingredients
  Future<List<RecipeModel>> searchRecipes(String query) async {
    final db = await database;
    final searchQuery = '%$query%';
    final maps = await db.query(
      'recipes',
      where: 'name LIKE ? OR ingredients LIKE ?',
      whereArgs: [searchQuery, searchQuery],
      orderBy: 'created_at DESC',
    );
    print('[AppRepository] Search "$query" found ${maps.length} recipes');
    return maps.map((map) => RecipeModel.fromMap(map)).toList();
  }

  /// Get favorite recipes
  Future<List<RecipeModel>> getFavoriteRecipes() async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    print('[AppRepository] Retrieved ${maps.length} favorite recipes');
    return maps.map((map) => RecipeModel.fromMap(map)).toList();
  }

  /// Toggle favorite status
  Future<bool> toggleRecipeFavorite(int id) async {
    final db = await database;
    final recipe = await getRecipeById(id);
    if (recipe == null) return false;

    final newStatus = !recipe.isFavorite;
    await db.update(
      'recipes',
      {'is_favorite': newStatus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('[AppRepository] Toggled favorite for recipe ID: $id -> $newStatus');
    return newStatus;
  }

  /// Delete a recipe
  Future<int> deleteRecipe(int id) async {
    final db = await database;
    final count = await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    print('[AppRepository] Deleted recipe ID: $id');
    return count;
  }

  /// Get recipes by category
  Future<List<RecipeModel>> getRecipesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => RecipeModel.fromMap(map)).toList();
  }

  /// Get recipe count
  Future<int> getRecipeCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recipes');
    return result.first['count'] as int;
  }

  // ==================== ANALYSIS METHODS ====================

  /// Insert a new analysis
  Future<int> insertAnalysis(AnalysisModel analysis) async {
    final db = await database;
    final id = await db.insert('analyses', analysis.toMap());
    print('[AppRepository] Inserted analysis (ID: $id) with ${analysis.foods.length} foods');
    return id;
  }

  /// Get all analyses
  Future<List<AnalysisModel>> getAllAnalyses() async {
    final db = await database;
    final maps = await db.query('analyses', orderBy: 'date DESC, created_at DESC');
    print('[AppRepository] Retrieved ${maps.length} analyses');
    return maps.map((map) => AnalysisModel.fromMap(map)).toList();
  }

  /// Get analysis by ID
  Future<AnalysisModel?> getAnalysisById(int id) async {
    final db = await database;
    final maps = await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AnalysisModel.fromMap(maps.first);
  }

  /// Get analyses by date
  Future<List<AnalysisModel>> getAnalysesByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'analyses',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    print('[AppRepository] Retrieved ${maps.length} analyses for date: $date');
    return maps.map((map) => AnalysisModel.fromMap(map)).toList();
  }

  /// Delete an analysis
  Future<int> deleteAnalysis(int id) async {
    final db = await database;
    final count = await db.delete('analyses', where: 'id = ?', whereArgs: [id]);
    print('[AppRepository] Deleted analysis ID: $id');
    return count;
  }

  /// Clear all analyses
  Future<void> clearAllAnalyses() async {
    final db = await database;
    await db.delete('analyses');
    print('[AppRepository] Cleared all analyses');
  }

  /// Get today's total calories
  Future<int> getTodayCalories() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final analyses = await getAnalysesByDate(today);
    return analyses.fold<int>(0, (sum, a) => sum + a.totalCalories);
  }

  /// Get analysis count
  Future<int> getAnalysisCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM analyses');
    return result.first['count'] as int;
  }

  // ==================== SAMPLE DATA ====================

  /// Insert sample data on first launch
  Future<void> insertSampleDataIfNeeded() async {
    if (_sampleDataInserted) return;

    final recipeCount = await getRecipeCount();
    if (recipeCount > 0) {
      _sampleDataInserted = true;
      print('[AppRepository] Sample data already exists, skipping...');
      return;
    }

    print('[AppRepository] Inserting sample data...');

    // Insert 10 sample recipes
    final sampleRecipes = _getSampleRecipes();
    for (final recipe in sampleRecipes) {
      await insertRecipe(recipe);
    }

    // Insert 3 sample analyses
    final sampleAnalyses = _getSampleAnalyses();
    for (final analysis in sampleAnalyses) {
      await insertAnalysis(analysis);
    }

    _sampleDataInserted = true;
    print('[AppRepository] Sample data inserted successfully');
  }

  /// Get sample recipes
  List<RecipeModel> _getSampleRecipes() {
    return [
      RecipeModel(
        name: 'Omlet',
        ingredients: ['2 yumurta', '1 yemek kaşığı süt', 'Tuz', 'Karabiber', '1 yemek kaşığı tereyağı'],
        steps: ['Yumurtaları çırpın', 'Süt ve baharatları ekleyin', 'Tavada tereyağını eritin', 'Karışımı dökün', '2-3 dakika pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/ryspuw1511786711.jpg',
        isFavorite: true,
        calories: 200,
        protein: 14.0,
        carbs: 2.0,
        fat: 15.0,
        prepTime: 5,
        cookTime: 5,
        servings: 1,
        category: 'Kahvaltı',
      ),
      RecipeModel(
        name: 'Menemen',
        ingredients: ['3 yumurta', '2 domates', '2 biber', '1 soğan', 'Zeytinyağı', 'Tuz'],
        steps: ['Sebzeleri doğrayın', 'Zeytinyağında kavurun', 'Yumurtaları kırın', 'Karıştırarak pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
        isFavorite: true,
        calories: 280,
        protein: 16.0,
        carbs: 12.0,
        fat: 18.0,
        prepTime: 10,
        cookTime: 15,
        servings: 2,
        category: 'Kahvaltı',
      ),
      RecipeModel(
        name: 'Mercimek Çorbası',
        ingredients: ['1 su bardağı kırmızı mercimek', '1 soğan', '1 havuç', '1 patates', '6 su bardağı su', 'Tuz', 'Karabiber'],
        steps: ['Mercimekleri yıkayın', 'Sebzeleri doğrayın', 'Tümünü haşlayın', 'Blenderdan geçirin', 'Baharatları ekleyin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/tnwy8m1628770384.jpg',
        isFavorite: false,
        calories: 180,
        protein: 12.0,
        carbs: 30.0,
        fat: 2.0,
        prepTime: 10,
        cookTime: 30,
        servings: 4,
        category: 'Çorba',
      ),
      RecipeModel(
        name: 'Tavuk Sote',
        ingredients: ['500g tavuk göğsü', '2 biber', '2 domates', '1 soğan', 'Zeytinyağı', 'Tuz', 'Karabiber'],
        steps: ['Tavukları küp doğrayın', 'Yağda kavurun', 'Sebzeleri ekleyin', '20 dakika pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/wyxwsp1486979827.jpg',
        isFavorite: true,
        calories: 350,
        protein: 40.0,
        carbs: 10.0,
        fat: 16.0,
        prepTime: 15,
        cookTime: 25,
        servings: 3,
        category: 'Ana Yemek',
      ),
      RecipeModel(
        name: 'Pilav',
        ingredients: ['2 su bardağı pirinç', '3 su bardağı su', '2 yemek kaşığı tereyağı', 'Tuz'],
        steps: ['Pirinci yıkayın', 'Tereyağında kavurun', 'Suyu ekleyin', 'Kısık ateşte pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/xxpqsy1511452222.jpg',
        isFavorite: false,
        calories: 250,
        protein: 5.0,
        carbs: 50.0,
        fat: 5.0,
        prepTime: 5,
        cookTime: 20,
        servings: 4,
        category: 'Yan Yemek',
      ),
      RecipeModel(
        name: 'Karnıyarık',
        ingredients: ['4 patlıcan', '300g kıyma', '2 domates', '1 soğan', 'Sarımsak', 'Tuz', 'Karabiber'],
        steps: ['Patlıcanları kızartın', 'İç harcı hazırlayın', 'Patlıcanları doldurun', 'Fırında pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/uyqrrv1511553350.jpg',
        isFavorite: true,
        calories: 420,
        protein: 22.0,
        carbs: 18.0,
        fat: 28.0,
        prepTime: 20,
        cookTime: 40,
        servings: 4,
        category: 'Ana Yemek',
      ),
      RecipeModel(
        name: 'Sezar Salata',
        ingredients: ['1 marul', '100g parmesan', 'Kruton', 'Sezar sos', 'Tavuk göğsü'],
        steps: ['Marulu yıkayın ve doğrayın', 'Tavuğu pişirin', 'Tüm malzemeleri karıştırın', 'Sos ile servis edin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg',
        isFavorite: false,
        calories: 320,
        protein: 25.0,
        carbs: 15.0,
        fat: 18.0,
        prepTime: 15,
        cookTime: 10,
        servings: 2,
        category: 'Salata',
      ),
      RecipeModel(
        name: 'Makarna',
        ingredients: ['250g makarna', 'Domates sosu', 'Sarımsak', 'Zeytinyağı', 'Fesleğen', 'Parmesan'],
        steps: ['Makarnayı haşlayın', 'Sosu hazırlayın', 'Makarnayı sosla karıştırın', 'Peynir ile servis edin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg',
        isFavorite: false,
        calories: 380,
        protein: 12.0,
        carbs: 65.0,
        fat: 8.0,
        prepTime: 5,
        cookTime: 15,
        servings: 2,
        category: 'Ana Yemek',
      ),
      RecipeModel(
        name: 'Izgara Köfte',
        ingredients: ['500g kıyma', '1 soğan', '1 yumurta', 'Galeta unu', 'Tuz', 'Karabiber', 'Kimyon'],
        steps: ['Kıymayı yoğurun', 'Soğanı rendeleyin', 'Tüm malzemeleri karıştırın', 'Köfte şekli verin', 'Izgarada pişirin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/wvqpwt1468339226.jpg',
        isFavorite: true,
        calories: 450,
        protein: 35.0,
        carbs: 10.0,
        fat: 30.0,
        prepTime: 15,
        cookTime: 15,
        servings: 4,
        category: 'Ana Yemek',
      ),
      RecipeModel(
        name: 'Sütlaç',
        ingredients: ['1 litre süt', '1/2 su bardağı pirinç', '1 su bardağı şeker', 'Vanilin', 'Tarçın'],
        steps: ['Pirinci haşlayın', 'Sütü ekleyin', 'Şekeri ekleyip karıştırın', 'Kıvam alınca indirin', 'Soğuk servis edin'],
        imageUrl: 'https://www.themealdb.com/images/media/meals/xqwwpy1483908697.jpg',
        isFavorite: false,
        calories: 280,
        protein: 8.0,
        carbs: 50.0,
        fat: 6.0,
        prepTime: 10,
        cookTime: 30,
        servings: 6,
        category: 'Tatlı',
      ),
    ];
  }

  /// Get sample analyses
  List<AnalysisModel> _getSampleAnalyses() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    return [
      AnalysisModel(
        date: today.toIso8601String().split('T')[0],
        photoPath: '/mock/breakfast.jpg',
        foods: [
          FoodItem(name: 'Omlet', grams: 150, calories: 200),
          FoodItem(name: 'Ekmek', grams: 50, calories: 130),
        ],
        totalCalories: 330,
        totalProtein: 16.0,
        totalCarbs: 25.0,
        totalFat: 17.0,
        notes: 'Kahvaltı',
      ),
      AnalysisModel(
        date: today.toIso8601String().split('T')[0],
        photoPath: '/mock/lunch.jpg',
        foods: [
          FoodItem(name: 'Tavuk Sote', grams: 200, calories: 280),
          FoodItem(name: 'Pilav', grams: 150, calories: 200),
          FoodItem(name: 'Salata', grams: 100, calories: 50),
        ],
        totalCalories: 530,
        totalProtein: 35.0,
        totalCarbs: 55.0,
        totalFat: 18.0,
        notes: 'Öğle yemeği',
      ),
      AnalysisModel(
        date: yesterday.toIso8601String().split('T')[0],
        photoPath: '/mock/dinner.jpg',
        foods: [
          FoodItem(name: 'Köfte', grams: 180, calories: 350),
          FoodItem(name: 'Makarna', grams: 200, calories: 300),
        ],
        totalCalories: 650,
        totalProtein: 30.0,
        totalCarbs: 60.0,
        totalFat: 28.0,
        notes: 'Akşam yemeği',
      ),
    ];
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('[AppRepository] Database closed');
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('recipes');
    await db.delete('analyses');
    _sampleDataInserted = false;
    print('[AppRepository] All data cleared');
  }
}

// ==================== MODELS ====================

/// Recipe model for database operations
class RecipeModel {
  final int? id;
  final String name;
  final List<String> ingredients;
  final List<String> steps;
  final String imageUrl;
  final bool isFavorite;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String category;
  final DateTime createdAt;

  RecipeModel({
    this.id,
    required this.name,
    required this.ingredients,
    required this.steps,
    this.imageUrl = '',
    this.isFavorite = false,
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.category = 'Genel',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'ingredients': jsonEncode(ingredients),
      'steps': jsonEncode(steps),
      'image_url': imageUrl,
      'is_favorite': isFavorite ? 1 : 0,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      ingredients: _parseJsonList(map['ingredients']),
      steps: _parseJsonList(map['steps']),
      imageUrl: map['image_url'] as String? ?? '',
      isFavorite: (map['is_favorite'] as int?) == 1,
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      prepTime: map['prep_time'] as int? ?? 0,
      cookTime: map['cook_time'] as int? ?? 0,
      servings: map['servings'] as int? ?? 1,
      category: map['category'] as String? ?? 'Genel',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static List<String> _parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If not JSON, split by delimiter
        return data.split('|||');
      }
    }
    return [];
  }

  RecipeModel copyWith({
    int? id,
    String? name,
    List<String>? ingredients,
    List<String>? steps,
    String? imageUrl,
    bool? isFavorite,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? category,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }

  int get totalTime => prepTime + cookTime;

  @override
  String toString() => 'RecipeModel(id: $id, name: $name, calories: $calories)';
}

/// Analysis model for database operations
class AnalysisModel {
  final int? id;
  final String date;
  final String photoPath;
  final List<FoodItem> foods;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? notes;
  final DateTime createdAt;

  AnalysisModel({
    this.id,
    required this.date,
    required this.photoPath,
    required this.foods,
    int? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    this.notes,
    DateTime? createdAt,
  })  : totalCalories = totalCalories ?? foods.fold(0, (sum, f) => sum + f.calories),
        totalProtein = totalProtein ?? 0.0,
        totalCarbs = totalCarbs ?? 0.0,
        totalFat = totalFat ?? 0.0,
        createdAt = createdAt ?? DateTime.now();

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'photo_path': photoPath,
      'foods': jsonEncode(foods.map((f) => f.toMap()).toList()),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from database map
  factory AnalysisModel.fromMap(Map<String, dynamic> map) {
    return AnalysisModel(
      id: map['id'] as int?,
      date: map['date'] as String,
      photoPath: map['photo_path'] as String,
      foods: _parseFoodsList(map['foods']),
      totalCalories: map['total_calories'] as int? ?? 0,
      totalProtein: (map['total_protein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (map['total_carbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (map['total_fat'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static List<FoodItem> _parseFoodsList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((e) => FoodItem.fromMap(e as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  @override
  String toString() => 'AnalysisModel(id: $id, date: $date, totalCalories: $totalCalories)';
}

/// Food item model for analysis
class FoodItem {
  final String name;
  final double grams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.name,
    required this.grams,
    required this.calories,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] as String? ?? '',
      grams: (map['grams'] as num?)?.toDouble() ?? 0.0,
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => 'FoodItem(name: $name, grams: $grams, calories: $calories)';
}

