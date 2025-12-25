import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/recipe_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/profile_provider.dart';
import '../models/recipe.dart';
import '../models/food_analysis.dart';
import '../services/permission_service.dart';
import '../services/app_service.dart';
import '../services/voice_search_service.dart';
import '../repository/app_repository.dart';
import 'recipe_detail_screen.dart';
import 'recipe_search_screen.dart';
import 'camera_screen.dart';
import '../utils/constants.dart';

/// Main home screen with tabbed navigation for recipe search and calorie analysis
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().initialize();
      context.read<AnalysisProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yemek Yardımcısı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
            tooltip: 'Ayarlar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              text: 'Tarif Ara',
              icon: Icon(Icons.search),
            ),
            Tab(
              text: 'Kalori Hesapla',
              icon: Icon(Icons.calculate),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RecipeSearchTab(),
          _CalorieCalculatorTab(),
        ],
      ),
    );
  }
}

/// First tab: Recipe search by ingredients
class _RecipeSearchTab extends StatefulWidget {
  const _RecipeSearchTab();

  @override
  State<_RecipeSearchTab> createState() => _RecipeSearchTabState();
}

class _RecipeSearchTabState extends State<_RecipeSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final AppRepository _repository = AppRepository();
  final VoiceSearchService _voiceService = VoiceSearchService();
  
  Timer? _debounceTimer;
  List<RecipeModel> _localResults = [];
  bool _isSearching = false;
  bool _isListening = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllRecipes();
    _initializeVoiceService();
  }

  /// Initialize voice search service
  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    _voiceService.stopListening();
    super.dispose();
  }

  /// Load all recipes from database on init
  Future<void> _loadAllRecipes() async {
    try {
      final recipes = await _repository.getAllRecipes();
      if (mounted) {
        setState(() {
          _localResults = recipes;
        });
      }
    } catch (e) {
      print('[HomeScreen] Error loading recipes: $e');
    }
  }

  /// Debounced search - triggers after user stops typing
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _loadAllRecipes();
      setState(() {
        _lastQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _lastQuery = query;
    });

    // Debounce 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performLocalSearch(query);
    });
  }

  /// Perform LIKE search in local database
  Future<void> _performLocalSearch(String query) async {
    if (!mounted) return;

    try {
      print('[HomeScreen] Searching for: $query');
      final results = await _repository.searchRecipes(query);
      
      if (mounted && _lastQuery == query) {
        setState(() {
          _localResults = results;
          _isSearching = false;
        });
        print('[HomeScreen] Found ${results.length} recipes for "$query"');
      }
    } catch (e) {
      print('[HomeScreen] Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Perform search and also update provider (for detail navigation)
  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadAllRecipes();
      return;
    }

    _performLocalSearch(query);
    
    // Also update provider for potential API search
    final provider = context.read<RecipeProvider>();
    provider.searchByIngredient(query);
    _searchFocus.unfocus();
  }

  /// Clear search and show all recipes
  void _clearSearch() {
    _searchController.clear();
    _loadAllRecipes();
    setState(() {
      _lastQuery = '';
      _isSearching = false;
    });
  }

  /// Start voice search
  Future<void> _startVoiceSearch() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _voiceService.startListening(
      onResult: (result) {
        setState(() {
          _isListening = false;
        });

        // Process command
        final command = _voiceService.processCommand(result);
        
        if (command == VoiceCommand.calculateCalories) {
          // Navigate to camera/calorie calculator tab
          // Find parent HomeScreen to access TabController
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          if (homeState != null && mounted) {
            homeState._tabController.animateTo(1); // Switch to calorie tab
            // Small delay then open camera
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              }
            });
          }
        } else {
          // Set search text and perform search
          _searchController.text = result;
          _performSearch();
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar with real-time search
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SearchBar(
                controller: _searchController,
                focusNode: _searchFocus,
                hintText: 'Malzeme ile tarif ara...',
                leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                      tooltip: 'Temizle',
                    ),
                  // Voice search button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.green,
                    ),
                    onPressed: _startVoiceSearch,
                    tooltip: _isListening ? 'Dinlemeyi durdur' : 'Sesli arama',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.green),
                    onPressed: _performSearch,
                    tooltip: 'Ara',
                  ),
                ],
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _performSearch(),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
                elevation: WidgetStateProperty.all(2),
                backgroundColor: WidgetStateProperty.all(Colors.white),
              ),
              // Search indicator
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),

        // Results count badge
        if (_lastQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '"$_lastQuery" için ${_localResults.length} sonuç bulundu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_localResults.isNotEmpty)
                  TextButton(
                    onPressed: _clearSearch,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Temizle',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

        // Recipe list
        Expanded(
          child: _buildRecipeList(),
        ),
      ],
    );
  }

  Widget _buildRecipeList() {
    // Show loading state
    if (_isSearching && _localResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tarifler aranıyor...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_localResults.isEmpty) {
      if (_lastQuery.isNotEmpty) {
        return _NoResultsState(
          query: _lastQuery,
          onClear: _clearSearch,
        );
      }
      return _EmptySearchState(
        onRandomRecipe: () async {
          final provider = context.read<RecipeProvider>();
          final recipe = await provider.getRandomRecipe();
          if (recipe != null && context.mounted) {
            provider.selectRecipe(recipe);
          }
        },
      );
    }

    // Show results
    return RefreshIndicator(
      onRefresh: () async {
        if (_lastQuery.isNotEmpty) {
          await _performLocalSearch(_lastQuery);
        } else {
          await _loadAllRecipes();
        }
      },
      color: Colors.green,
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          // Sort recipes: if low-calorie suggestion, show low-calorie first
          final sortedResults = List<RecipeModel>.from(_localResults);
          if (profileProvider.shouldSuggestLowCalorieRecipes()) {
            sortedResults.sort((a, b) {
              final aCal = a.calories ?? 0;
              final bCal = b.calories ?? 0;
              return aCal.compareTo(bCal);
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedResults.length + (profileProvider.shouldSuggestLowCalorieRecipes() && sortedResults.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              // Show suggestion banner at top if low-calorie mode
              if (index == 0 && profileProvider.shouldSuggestLowCalorieRecipes() && sortedResults.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Düşük kalorili tarifler öneriliyor (Hedef: ${profileProvider.dailyCalorieGoal} kcal)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final recipeIndex = profileProvider.shouldSuggestLowCalorieRecipes() ? index - 1 : index;
              final recipeModel = sortedResults[recipeIndex];
              final recipe = _convertToRecipe(recipeModel);
              final provider = context.read<RecipeProvider>();
              
              return RecipeCard(
            recipe: recipe,
            isFavorite: recipeModel.isFavorite,
            onTap: () {
              provider.selectRecipe(recipe);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeDetailScreen(),
                ),
              );
            },
            onFavoriteToggle: () async {
              final provider = context.read<RecipeProvider>();
              
              // Toggle in database
              await _repository.toggleRecipeFavorite(recipeModel.id!);
              
              // Refresh provider favorites
              await provider.loadFavorites();
              
              // Refresh the local list
              if (_lastQuery.isNotEmpty) {
                await _performLocalSearch(_lastQuery);
              } else {
                await _loadAllRecipes();
              }
            },
          );
        },
      );
        },
      ),
    );
  }

  /// Convert RecipeModel to Recipe for display
  Recipe _convertToRecipe(RecipeModel model) {
    return Recipe(
      id: model.id,
      title: model.name,
      description: model.steps.isNotEmpty ? model.steps.first : '',
      category: model.category,
      instructions: model.steps,
      ingredients: model.ingredients,
      imageUrl: model.imageUrl,
      isFavorite: model.isFavorite,
      calories: model.calories,
      protein: model.protein,
      carbs: model.carbs,
      fat: model.fat,
      prepTimeMinutes: model.prepTime,
      cookTimeMinutes: model.cookTime,
      servings: model.servings,
    );
  }
}

/// No results state widget
class _NoResultsState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoResultsState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '"$query" için sonuç bulunamadı',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı malzemeler deneyin veya\ndaha genel bir arama yapın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Tüm Tarifleri Göster'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recipe card widget with image, title, subtitle, and favorite button
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: recipe.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        title: Text(
          recipe.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          recipe.ingredients.take(3).join(', '),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : Colors.grey,
          ),
          onPressed: () {
            onFavoriteToggle();
            // Show quick feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFavorite ? Icons.star_border : Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFavorite 
                          ? 'Favorilerden kaldırıldı' 
                          : 'Favorilere eklendi',
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          tooltip: isFavorite ? 'Favorilerden kaldır' : 'Favorilere ekle',
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Second tab: Calorie calculator with photo capture
class _CalorieCalculatorTab extends StatefulWidget {
  const _CalorieCalculatorTab();

  @override
  State<_CalorieCalculatorTab> createState() => _CalorieCalculatorTabState();
}

class _CalorieCalculatorTabState extends State<_CalorieCalculatorTab> {
  final ImagePicker _picker = ImagePicker();
  final PermissionService _permissionService = PermissionService();
  final AppService _appService = AppService();
  
  String? _imagePath;
  bool _isAnalyzing = false;
  String _analysisStatus = '';
  ImageAnalysisResult? _currentResult;
  List<FoodItem> _analyzedFoods = [];

  Future<void> _takePhoto() async {
    final result = await _permissionService.ensureCameraPermission();

    if (result == PermissionResult.permanentlyDenied) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    if (result != PermissionResult.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera izni gerekli'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() => _imagePath = photo.path);
        await _analyzeImageWithService(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _imagePath = image.path);
        await _analyzeImageWithService(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Analyze image using AppService (ML + API)
  Future<void> _analyzeImageWithService(String imagePath) async {
    setState(() {
      _isAnalyzing = true;
      _analysisStatus = 'Görüntü hazırlanıyor...';
      _analyzedFoods = [];
      _currentResult = null;
    });

    try {
      // Update status for ML analysis
      if (mounted) {
        setState(() => _analysisStatus = 'Yiyecekler tanınıyor...');
      }
      
      print('[CalorieTab] Starting analysis for: $imagePath');
      
      // Use AppService for full analysis
      final result = await _appService.analyzeImage(imagePath);
      
      if (mounted) {
        setState(() {
          _currentResult = result;
          _analyzedFoods = result.foods;
          _isAnalyzing = false;
          _analysisStatus = '';
        });

        // Show result feedback
        if (result.success && result.foods.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (!result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Also update the provider
        final analysisProvider = context.read<AnalysisProvider>();
        await analysisProvider.analyzeImage(imagePath);
      }
      
      print('[CalorieTab] Analysis complete: ${result.foods.length} foods');
    } catch (e) {
      print('[CalorieTab] Analysis error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Analiz hatası: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Tekrar',
              textColor: Colors.white,
              onPressed: () => _analyzeImageWithService(imagePath),
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.green),
            SizedBox(width: 8),
            Text('Kamera İzni Gerekli'),
          ],
        ),
        content: const Text(
          'Fotoğraf çekmek için kamera izni gerekiyor. '
          'Lütfen ayarlardan izin verin.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _permissionService.openSettings();
            },
            icon: const Icon(Icons.settings, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            label: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// Navigate to recipe search with analyzed food
  void _navigateToRelatedRecipes(String foodName) {
    final recipeProvider = context.read<RecipeProvider>();
    recipeProvider.searchRecipes(foodName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeSearchScreen(),
      ),
    );
  }

  /// Search recipes for all analyzed foods
  Future<void> _searchRecipesForAnalysis() async {
    if (_analyzedFoods.isEmpty) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('İlgili tarifler aranıyor...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    final result = await _appService.searchRecipesForAnalysis(_analyzedFoods);
    
    if (mounted && result.success && result.recipes.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RecipeSearchScreen(),
        ),
      );
    }
  }

  /// Save current analysis to history
  Future<void> _saveToHistory() async {
    if (_currentResult == null || _analyzedFoods.isEmpty) return;

    try {
      // Already saved by AppService, just show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Geçmişe kaydedildi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Update provider
        final analysisProvider = context.read<AnalysisProvider>();
        await analysisProvider.loadHistory();
        await analysisProvider.loadTodayData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo capture buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text(
                    'Fotoğraf Çek',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.green.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text(
                    'Galeriden Seç',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image preview container with analysis overlay
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: _buildPreviewContent(),
          ),
          const SizedBox(height: 16),

          // Analysis results
          _buildAnalysisResults(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 3,
                    backgroundColor: Colors.green.withOpacity(0.2),
                  ),
                ),
                const Icon(
                  Icons.restaurant,
                  size: 24,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _analysisStatus,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (_appService.isDemoMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Demo modu',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_imagePath != null && File(_imagePath!).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(_imagePath!),
              fit: BoxFit.cover,
            ),
          ),
          // Overlay with food count
          if (_analyzedFoods.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_analyzedFoods.length} yiyecek',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Retake button
          Positioned(
            bottom: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                onTap: _isAnalyzing ? null : _takePhoto,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate,
              size: 40,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fotoğraf önizlemesi',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Yemek fotoğrafı çekin veya seçin',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_analyzedFoods.isEmpty && _currentResult == null) {
      return _buildEmptyResultsHint();
    }

    int totalCalories;
    double totalProtein;
    double totalCarbs;
    double totalFat;
    
    if (_currentResult != null) {
      totalCalories = _currentResult!.totalCalories;
      totalProtein = _currentResult!.totalProtein;
      totalCarbs = _currentResult!.totalCarbs;
      totalFat = _currentResult!.totalFat;
    } else if (_analyzedFoods.isEmpty) {
      totalCalories = 0;
      totalProtein = 0.0;
      totalCarbs = 0.0;
      totalFat = 0.0;
    } else {
      totalCalories = _analyzedFoods.fold<int>(0, (sum, f) => sum + f.calories);
      totalProtein = _analyzedFoods.fold<double>(0.0, (sum, f) => sum + f.protein);
      totalCarbs = _analyzedFoods.fold<double>(0.0, (sum, f) => sum + f.carbs);
      totalFat = _analyzedFoods.fold<double>(0.0, (sum, f) => sum + f.fat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and actions
        Row(
          children: [
            const Icon(Icons.analytics, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Analiz Sonuçları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _saveToHistory,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Kaydet'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Total nutrition summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$totalCalories',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MacroChip(label: 'Protein', value: '${totalProtein.toStringAsFixed(1)}g'),
                  _MacroChip(label: 'Karb', value: '${totalCarbs.toStringAsFixed(1)}g'),
                  _MacroChip(label: 'Yağ', value: '${totalFat.toStringAsFixed(1)}g'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calorie goal warning (personalization)
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, _) {
            if (profileProvider.hasProfile && profileProvider.exceedsCalorieGoal(totalCalories)) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalori Hedefi Aşıldı!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                          Text(
                            'Günlük hedef: ${profileProvider.dailyCalorieGoal} kcal\n'
                            'Toplam: $totalCalories kcal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (profileProvider.hasProfile) {
              final remaining = profileProvider.getRemainingCalories(totalCalories);
              if (remaining != null && remaining < 200) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kalan kalori: $remaining kcal (Hedef: ${profileProvider.dailyCalorieGoal} kcal)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
              }
            }
            return const SizedBox.shrink();
          },
        ),

        // Food items list
        const Text(
          'Tespit Edilen Yiyecekler',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _analyzedFoods.length,
          itemBuilder: (context, index) {
            final food = _analyzedFoods[index];
            return _FoodItemCard(
              food: food,
              onFindRecipes: () => _navigateToRelatedRecipes(food.name),
            );
          },
        ),
        const SizedBox(height: 12),

        // Actions row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _searchRecipesForAnalysis,
                icon: const Icon(Icons.restaurant_menu, size: 18),
                label: const Text('İlgili Tarifler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Yeni Analiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyResultsHint() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 28,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nasıl Çalışır?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Yemek fotoğrafı çekin veya seçin\n'
            '2. Yapay zeka yiyecekleri tanır\n'
            '3. Kalori ve besin değerleri hesaplanır\n'
            '4. İlgili tariflere göz atın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_appService.isDemoMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Demo modunda çalışıyor',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Macro nutrient chip for summary
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual food item card
class _FoodItemCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onFindRecipes;

  const _FoodItemCard({required this.food, this.onFindRecipes});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Food icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.grams.toStringAsFixed(0)}g • P: ${food.protein.toStringAsFixed(0)}g • K: ${food.carbs.toStringAsFixed(0)}g • Y: ${food.fat.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Calories
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food.calories}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            // Recipe button
            if (onFindRecipes != null)
              IconButton(
                onPressed: onFindRecipes,
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                color: Colors.grey,
                tooltip: 'İlgili tarifleri bul',
              ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying food analysis result with grams and calories
class FoodAnalysisCard extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback? onFindRecipes;

  const FoodAnalysisCard({
    super.key,
    required this.analysis,
    this.onFindRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with food name and confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    analysis.foodName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis.confidencePercent,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getConfidenceColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Nutrition info row
            Row(
              children: [
                _NutritionBadge(
                  icon: Icons.scale,
                  value: '${analysis.estimatedGrams.toStringAsFixed(0)}g',
                  label: 'Porsiyon',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _NutritionBadge(
                  icon: Icons.local_fire_department,
                  value: '${analysis.estimatedCalories}',
                  label: 'Kalori',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _NutritionBadge(
                  icon: Icons.fitness_center,
                  value: '${analysis.protein.toStringAsFixed(0)}g',
                  label: 'Protein',
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Link to recipes button
            if (onFindRecipes != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onFindRecipes,
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('İlgili Tarifleri Bul'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor() {
    if (analysis.confidence >= 0.8) return Colors.green;
    if (analysis.confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class _NutritionBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _NutritionBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for recipe search
class _EmptySearchState extends StatelessWidget {
  final VoidCallback onRandomRecipe;

  const _EmptySearchState({required this.onRandomRecipe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tarif Ara',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Malzeme adı girerek\ntarif arayabilirsiniz',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: onRandomRecipe,
              icon: const Icon(Icons.casino),
              label: const Text('Rastgele Tarif'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

