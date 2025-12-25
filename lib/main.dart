import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/recipe_provider.dart';
import 'providers/analysis_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/permission_service.dart';
import 'services/app_service.dart';
import 'services/firebase_service.dart';
import 'repository/app_repository.dart';
import 'screens/main_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with offline persistence
  try {
    await FirebaseService.initialize();
    // Sync from Firestore on app start
    await FirebaseService.syncFromFirestore();
  } catch (e) {
    print('[main] Firebase initialization failed: $e');
    // Continue without Firebase
  }
  
  // Initialize services
  final appService = AppService();
  await appService.initApiKeys();
  await appService.initML();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const YemekYardimciApp());
}

/// Main application widget with theme configuration
class YemekYardimciApp extends StatelessWidget {
  const YemekYardimciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemePreference()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..loadProfile()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const PermissionWrapper(child: MainScreen()),
            routes: {
              // AppRoutes.home removed - using 'home' property instead
              AppRoutes.recipeDetail: (context) => const RecipeDetailScreen(),
              AppRoutes.settings: (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              return null;
            },
          );
        },
      ),
    );
  }
}

/// App Theme configuration class
class AppTheme {
  // Primary color based on green[700]
  static const Color primaryGreen = Color(0xFF388E3C); // green[700]
  static const Color primaryGreenLight = Color(0xFF4CAF50); // green[500]
  static const Color primaryGreenDark = Color(0xFF1B5E20); // green[900]
  
  // Accent color - Orange
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentOrangeLight = Color(0xFFFFB74D);
  static const Color accentOrangeDark = Color(0xFFF57C00);
  
  // Star icon color - Yellow/Amber
  static const Color starColor = Color(0xFFFFC107); // Amber
  static const Color starColorLight = Color(0xFFFFD54F);
  static const Color starColorInactive = Color(0xFFBDBDBD);
  
  // Calorie icon color - Red/Orange
  static const Color calorieColor = Color(0xFFFF5722); // Deep Orange
  static const Color calorieColorLight = Color(0xFFFF8A65);
  static const Color highCalorieWarning = Color(0xFFD32F2F); // Red for warnings
  
  // High calorie threshold (for warnings)
  static const int highCalorieThreshold = 500;

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      
      // Color scheme with green[700] primary and orange accent
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        primaryContainer: primaryGreenLight,
        secondary: accentOrange,
        secondaryContainer: accentOrangeLight,
        surface: Colors.white,
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      
      // Text theme with bodyLarge 16 bold
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
        // bodyLarge: 16 bold as requested
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF212121)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF757575)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF757575)),
      ),
      
      // Icon theme - default icons
      iconTheme: const IconThemeData(
        color: primaryGreen,
        size: 24,
      ),
      
      // Primary icon theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: highCalorieWarning, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      
      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: primaryGreen.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF212121),
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // List tile theme
      listTileTheme: const ListTileThemeData(
        iconColor: primaryGreen,
        textColor: Color(0xFF212121),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      
      // Dark color scheme
      colorScheme: ColorScheme.dark(
        primary: Colors.green[800]!,
        primaryContainer: primaryGreen,
        secondary: accentOrangeLight,
        secondaryContainer: accentOrange,
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFEF5350),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Color(0xFFE0E0E0),
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: Colors.grey[900],
      
      // Text theme for dark mode with bodyLarge 16 bold - white text for visibility
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
        // bodyLarge: 16 bold as requested
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white70),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white60),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white60),
      ),
      
      // Icon theme for dark mode - light colors for visibility
      iconTheme: const IconThemeData(
        color: Colors.white70,
        size: 24,
      ),
      
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      
      // AppBar theme for dark mode
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
        iconTheme: IconThemeData(color: Color(0xFFE0E0E0)),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE0E0E0),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card theme for dark mode
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // FAB theme for dark mode
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreenLight,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      
      // Button themes for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: primaryGreenLight,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreenLight,
          side: const BorderSide(color: primaryGreenLight, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreenLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      
      // Input decoration for dark mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreenLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF757575)),
      ),
      
      // Bottom Navigation Bar for dark mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryGreenLight,
        unselectedItemColor: Color(0xFF757575),
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Tab bar theme for dark mode
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryGreenLight,
        unselectedLabelColor: Color(0xFF757575),
        indicatorColor: primaryGreenLight,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
      
      // Chip theme for dark mode
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedColor: primaryGreenLight.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog theme for dark mode
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE0E0E0),
        ),
      ),
      
      // Snackbar theme for dark mode
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // List tile theme for dark mode
      listTileTheme: const ListTileThemeData(
        iconColor: primaryGreenLight,
        textColor: Color(0xFFE0E0E0),
      ),
      
      // Divider theme for dark mode
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
      
      // Progress indicator for dark mode
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreenLight,
        linearTrackColor: Color(0xFF424242),
      ),
    );
  }
  
  /// Get star icon color based on favorite status
  static Color getStarColor(bool isFavorite) {
    return isFavorite ? starColor : starColorInactive;
  }
  
  /// Get calorie text color based on calorie count
  static Color getCalorieColor(int calories) {
    if (calories >= highCalorieThreshold) {
      return highCalorieWarning;
    }
    return calorieColor;
  }
  
  /// Get calorie text style with appropriate color
  static TextStyle getCalorieTextStyle(int calories, {double fontSize = 14}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: getCalorieColor(calories),
    );
  }
  
  /// Check if calories are high (for warnings)
  static bool isHighCalorie(int calories) {
    return calories >= highCalorieThreshold;
  }
}

/// Wrapper widget that handles permission requests and database initialization on app launch
class PermissionWrapper extends StatefulWidget {
  final Widget child;

  const PermissionWrapper({super.key, required this.child});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  final PermissionService _permissionService = PermissionService();
  final AppRepository _repository = AppRepository();
  final AppService _appService = AppService();
  
  bool _isInitialized = false;
  String _statusMessage = 'Hazırlanıyor...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Request permissions
      _updateStatus('İzinler isteniyor...');
      await _permissionService.requestAllPermissions();
      
      // Step 2: Initialize database
      _updateStatus('Veritabanı başlatılıyor...');
      await _repository.database;
      print('[Main] Database initialized successfully');
      
      // Step 3: Insert sample data on first launch
      _updateStatus('Örnek veriler yükleniyor...');
      await _insertSampleDataOnFirstLaunch();
      
      // Step 4: Initialize ML services
      _updateStatus('ML servisleri başlatılıyor...');
      await _appService.initML();
      print('[Main] ML services initialized');
      
      // Step 5: Load initial data into providers
      _updateStatus('Veriler yükleniyor...');
      await _loadInitialData();
      
      // Done
      if (mounted) {
        setState(() => _isInitialized = true);
      }
      print('[Main] App initialization complete');
    } catch (e) {
      print('[Main] Initialization error: $e');
      // Continue anyway to show the app
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }
  
  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  Future<void> _insertSampleDataOnFirstLaunch() async {
    try {
      final recipeCount = await _repository.getRecipeCount();
      
      if (recipeCount == 0) {
        print('[Main] First launch detected, inserting sample data...');
        
        // Insert sample recipes
        final sampleRecipes = _getSampleRecipes();
        for (final recipe in sampleRecipes) {
          final id = await _repository.insertRecipe(recipe);
          print('[Main] Inserted recipe: ${recipe.name} (ID: $id)');
        }
        
        // Insert sample analyses
        final sampleAnalyses = _getSampleAnalyses();
        for (final analysis in sampleAnalyses) {
          final id = await _repository.insertAnalysis(analysis);
          print('[Main] Inserted analysis ID: $id with ${analysis.foods.length} foods');
        }
        
        print('[Main] Sample data insertion complete');
        print('[Main] Total recipes: ${sampleRecipes.length}');
        print('[Main] Total analyses: ${sampleAnalyses.length}');
      } else {
        print('[Main] Database already has $recipeCount recipes, skipping sample data');
      }
    } catch (e) {
      print('[Main] Error inserting sample data: $e');
    }
  }

  List<RecipeModel> _getSampleRecipes() {
    return [
      // 1. Omlet
      RecipeModel(
        name: 'Omlet',
        ingredients: ['2 yumurta', '1 yemek kaşığı süt', 'Tuz', 'Karabiber', '1 yemek kaşığı tereyağı'],
        steps: [
          'Yumurtaları bir kaseye kırın ve çatalla çırpın',
          'Süt, tuz ve karabiberi ekleyip karıştırın',
          'Tavada tereyağını eritin',
          'Yumurta karışımını tavaya dökün',
          'Kısık ateşte 2-3 dakika pişirin',
          'Kenarları katlayarak servis edin'
        ],
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
      // 2. Menemen
      RecipeModel(
        name: 'Menemen',
        ingredients: ['3 yumurta', '2 domates', '2 yeşil biber', '1 soğan', '2 yemek kaşığı zeytinyağı', 'Tuz', 'Pul biber'],
        steps: [
          'Sebzeleri küçük küpler halinde doğrayın',
          'Tavada zeytinyağını kızdırın',
          'Soğanları pembeleşene kadar kavurun',
          'Biberleri ekleyip 2 dakika kavurun',
          'Domatesleri ekleyip sularını salana kadar pişirin',
          'Yumurtaları kırıp karıştırarak pişirin',
          'Tuz ve pul biber ekleyip servis edin'
        ],
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
      // 3. Mercimek Çorbası
      RecipeModel(
        name: 'Mercimek Çorbası',
        ingredients: ['1 su bardağı kırmızı mercimek', '1 soğan', '1 havuç', '1 patates', '6 su bardağı su', '2 yemek kaşığı tereyağı', 'Tuz', 'Karabiber', 'Kimyon'],
        steps: [
          'Mercimekleri yıkayıp süzün',
          'Soğan, havuç ve patatesi küp doğrayın',
          'Tencereye yağı koyup sebzeleri kavurun',
          'Mercimek ve suyu ekleyin',
          'Kaynayınca kısık ateşte 25-30 dakika pişirin',
          'Blenderdan geçirin',
          'Baharatları ekleyip sıcak servis edin'
        ],
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
      // 4. Tavuk Sote
      RecipeModel(
        name: 'Tavuk Sote',
        ingredients: ['500g tavuk göğsü', '2 yeşil biber', '2 kırmızı biber', '2 domates', '1 soğan', '3 yemek kaşığı zeytinyağı', 'Tuz', 'Karabiber', 'Kekik'],
        steps: [
          'Tavukları kuşbaşı doğrayın',
          'Biberleri ve soğanı iri doğrayın',
          'Domatesleri küp doğrayın',
          'Yağda tavukları soteleyin',
          'Soğan ve biberleri ekleyip kavurun',
          'Domatesleri ekleyin',
          'Baharatları ekleyip 20 dakika pişirin'
        ],
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
      // 5. Pilav
      RecipeModel(
        name: 'Tereyağlı Pilav',
        ingredients: ['2 su bardağı pirinç', '3.5 su bardağı tavuk suyu', '3 yemek kaşığı tereyağı', '1 çay kaşığı tuz', 'Şehriye (isteğe bağlı)'],
        steps: [
          'Pirinci yıkayıp 30 dakika ılık suda bekletin',
          'Tereyağının yarısını eritip şehriyeyi kavurun',
          'Süzülmüş pirinci ekleyip kavurun',
          'Kaynar suyu ekleyin',
          'Kaynayınca kısık ateşe alın',
          'Su çekilene kadar (15-20 dk) pişirin',
          'Kalan tereyağını ekleyip demlendirin'
        ],
        imageUrl: 'https://www.themealdb.com/images/media/meals/xxpqsy1511452222.jpg',
        isFavorite: false,
        calories: 250,
        protein: 5.0,
        carbs: 50.0,
        fat: 5.0,
        prepTime: 35,
        cookTime: 25,
        servings: 4,
        category: 'Yan Yemek',
      ),
      // 6. Karnıyarık
      RecipeModel(
        name: 'Karnıyarık',
        ingredients: ['4 adet patlıcan', '300g kıyma', '2 domates', '1 soğan', '3 diş sarımsak', 'Zeytinyağı', 'Tuz', 'Karabiber', 'Pul biber'],
        steps: [
          'Patlıcanları alacalı soyup kızartın',
          'Kıymayı soğanla kavurun',
          'Domates ve baharatları ekleyin',
          'Patlıcanların ortasını açın',
          'İç harcı doldurun',
          'Üzerine domates dilimi koyun',
          '180°C fırında 30 dakika pişirin'
        ],
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
      // 7. Sezar Salata
      RecipeModel(
        name: 'Sezar Salata',
        ingredients: ['1 adet marul', '100g parmesan', '1 su bardağı kruton', '200g tavuk göğsü', 'Sezar sos', 'Zeytinyağı'],
        steps: [
          'Tavuğu ızgara yapın ve dilimleyin',
          'Marulu yıkayıp parçalayın',
          'Krutonları hazırlayın',
          'Parmesan peynirini rendeleyin',
          'Tüm malzemeleri geniş tabağa dizin',
          'Sezar sosu gezdirin'
        ],
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
      // 8. Makarna
      RecipeModel(
        name: 'Domates Soslu Makarna',
        ingredients: ['250g spagetti', '400g konserve domates', '3 diş sarımsak', '3 yemek kaşığı zeytinyağı', 'Taze fesleğen', 'Parmesan', 'Tuz', 'Karabiber'],
        steps: [
          'Makarnayı tuzlu suda haşlayın',
          'Sarımsakları ince kıyın',
          'Zeytinyağında sarımsakları kavurun',
          'Domatesleri ekleyip 10 dakika pişirin',
          'Baharatları ekleyin',
          'Makarnayı sosla karıştırın',
          'Parmesan ve fesleğenle servis edin'
        ],
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
      // 9. Izgara Köfte
      RecipeModel(
        name: 'Izgara Köfte',
        ingredients: ['500g kıyma', '1 soğan (rendelenmiş)', '1 yumurta', '3 yemek kaşığı galeta unu', 'Tuz', 'Karabiber', 'Kimyon', 'Pul biber', 'Maydanoz'],
        steps: [
          'Kıymayı geniş bir kaba alın',
          'Rendelenmiş soğanı ekleyin',
          'Yumurta ve galeta ununu ilave edin',
          'Tüm baharatları ekleyin',
          '10 dakika yoğurun',
          'Köfte şekli verin',
          '30 dakika buzdolabında bekletin',
          'Izgarada her iki tarafı da pişirin'
        ],
        imageUrl: 'https://www.themealdb.com/images/media/meals/wvqpwt1468339226.jpg',
        isFavorite: true,
        calories: 450,
        protein: 35.0,
        carbs: 10.0,
        fat: 30.0,
        prepTime: 45,
        cookTime: 15,
        servings: 4,
        category: 'Ana Yemek',
      ),
      // 10. Sütlaç
      RecipeModel(
        name: 'Sütlaç',
        ingredients: ['1 litre süt', '1/2 su bardağı pirinç', '1 su bardağı şeker', '2 yemek kaşığı pirinç unu', '1 paket vanilin', 'Tarçın'],
        steps: [
          'Pirinci yıkayıp haşlayın',
          'Sütü ayrı bir tencerede ısıtın',
          'Haşlanmış pirinci süte ekleyin',
          'Şekeri ilave edip karıştırın',
          'Pirinç ununu az sütle açıp ekleyin',
          'Kıvam alana kadar karıştırarak pişirin',
          'Vanilini ekleyin',
          'Kaselere bölüp soğutun',
          'Üzerine tarçın serpin'
        ],
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

  List<AnalysisModel> _getSampleAnalyses() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    // final twoDaysAgo = today.subtract(const Duration(days: 2)); // Reserved for future use
    
    return [
      // Analysis 1: Today's Breakfast
      AnalysisModel(
        date: today.toIso8601String().split('T')[0],
        photoPath: '/mock/kahvalti_1.jpg',
        foods: [
          FoodItem(name: 'Omlet', grams: 150, calories: 200, protein: 14.0, carbs: 2.0, fat: 15.0),
          FoodItem(name: 'Ekmek', grams: 50, calories: 130, protein: 4.0, carbs: 25.0, fat: 1.0),
          FoodItem(name: 'Peynir', grams: 30, calories: 100, protein: 7.0, carbs: 0.5, fat: 8.0),
        ],
        totalCalories: 430,
        totalProtein: 25.0,
        totalCarbs: 27.5,
        totalFat: 24.0,
        notes: 'Sabah kahvaltısı',
      ),
      // Analysis 2: Today's Lunch
      AnalysisModel(
        date: today.toIso8601String().split('T')[0],
        photoPath: '/mock/ogle_yemegi_1.jpg',
        foods: [
          FoodItem(name: 'Tavuk Sote', grams: 200, calories: 280, protein: 32.0, carbs: 8.0, fat: 12.8),
          FoodItem(name: 'Pilav', grams: 150, calories: 190, protein: 3.8, carbs: 37.5, fat: 3.8),
          FoodItem(name: 'Salata', grams: 100, calories: 25, protein: 1.0, carbs: 5.0, fat: 0.2),
          FoodItem(name: 'Ayran', grams: 200, calories: 70, protein: 3.0, carbs: 4.0, fat: 3.5),
        ],
        totalCalories: 565,
        totalProtein: 39.8,
        totalCarbs: 54.5,
        totalFat: 20.3,
        notes: 'Öğle yemeği - iş yerinde',
      ),
      // Analysis 3: Yesterday's Dinner
      AnalysisModel(
        date: yesterday.toIso8601String().split('T')[0],
        photoPath: '/mock/aksam_yemegi_1.jpg',
        foods: [
          FoodItem(name: 'Köfte', grams: 180, calories: 360, protein: 25.2, carbs: 7.2, fat: 21.6),
          FoodItem(name: 'Makarna', grams: 200, calories: 300, protein: 10.0, carbs: 52.0, fat: 6.4),
          FoodItem(name: 'Cacık', grams: 150, calories: 65, protein: 4.5, carbs: 6.0, fat: 3.0),
        ],
        totalCalories: 725,
        totalProtein: 39.7,
        totalCarbs: 65.2,
        totalFat: 31.0,
        notes: 'Akşam yemeği - evde',
      ),
    ];
  }
  
  Future<void> _loadInitialData() async {
    try {
      // Get context for providers
      if (!mounted) return;
      
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      
      // Load recipes from database
      final recipes = await _repository.getAllRecipes();
      recipeProvider.setRecipesFromDb(recipes);
      print('[Main] Loaded ${recipes.length} recipes into provider');
      
      // Load analyses from database  
      final analyses = await _repository.getAllAnalyses();
      analysisProvider.setAnalysesFromDb(analyses);
      print('[Main] Loaded ${analyses.length} analyses into provider');
      
    } catch (e) {
      print('[Main] Error loading initial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Detect current brightness for splash screen
      final isDarkMode = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF9E9E9E) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
