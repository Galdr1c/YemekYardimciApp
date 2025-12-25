import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yemek_yardimci.db');

    return await openDatabase(
      path,
      version: 2, // Incremented for users table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Recipes table
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        ingredients TEXT,
        instructions TEXT,
        prep_time_minutes INTEGER DEFAULT 0,
        cook_time_minutes INTEGER DEFAULT 0,
        servings INTEGER DEFAULT 1,
        calories INTEGER DEFAULT 0,
        protein REAL DEFAULT 0.0,
        carbs REAL DEFAULT 0.0,
        fat REAL DEFAULT 0.0,
        category TEXT DEFAULT 'General',
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Food analysis history table
    await db.execute('''
      CREATE TABLE food_analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        food_name TEXT NOT NULL,
        confidence REAL NOT NULL,
        estimated_grams REAL DEFAULT 100.0,
        estimated_calories INTEGER DEFAULT 0,
        protein REAL DEFAULT 0.0,
        carbs REAL DEFAULT 0.0,
        fat REAL DEFAULT 0.0,
        fiber REAL DEFAULT 0.0,
        linked_recipe_id TEXT,
        analyzed_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Ingredients table
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        image_url TEXT,
        calories_per_100g INTEGER DEFAULT 0,
        protein_per_100g REAL DEFAULT 0.0,
        carbs_per_100g REAL DEFAULT 0.0,
        fat_per_100g REAL DEFAULT 0.0
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        search_type TEXT NOT NULL,
        searched_at TEXT NOT NULL
      )
    ''');

    // Users table (user profile)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        daily_calorie_goal INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_recipes_favorite ON recipes(is_favorite)');
    await db.execute('CREATE INDEX idx_recipes_category ON recipes(category)');
    await db.execute('CREATE INDEX idx_analyses_date ON food_analyses(analyzed_at)');
    await db.execute('CREATE INDEX idx_ingredients_name ON ingredients(name)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add users table for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          age INTEGER NOT NULL,
          gender TEXT NOT NULL,
          daily_calorie_goal INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('recipes');
    await db.delete('food_analyses');
    await db.delete('ingredients');
    await db.delete('search_history');
    await db.delete('users');
  }
}

