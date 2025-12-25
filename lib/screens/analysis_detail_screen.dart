import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_analysis.dart';
import '../providers/analysis_provider.dart';
import '../providers/recipe_provider.dart';
import '../services/share_service.dart';
import '../services/app_service.dart';
import '../repository/app_repository.dart';
import '../widgets/share_consent_dialog.dart';
import 'recipe_search_screen.dart';

/// Screen displaying detailed food analysis results
/// 
/// Can receive data via:
/// - Constructor parameters
/// - Route arguments
class AnalysisDetailScreen extends StatelessWidget {
  final String? imagePath;
  final List<FoodAnalysis>? analyses;

  const AnalysisDetailScreen({
    super.key,
    this.imagePath,
    this.analyses,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, child) {
        // Get data from constructor, arguments, or provider
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final displayImagePath = imagePath ?? args?['imagePath'] as String?;
        final displayAnalyses = analyses ?? 
            (args?['analyses'] as List<FoodAnalysis>?) ?? 
            provider.currentAnalysis;

        if (displayAnalyses.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Analiz Sonuçları'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('Analiz sonucu bulunamadı'),
            ),
          );
        }

        // Calculate total calories
        final totalCalories = displayAnalyses.fold<int>(
          0,
          (sum, analysis) => sum + analysis.estimatedCalories,
        );

        // Calculate total macros
        final totalProtein = displayAnalyses.fold<double>(
          0,
          (sum, analysis) => sum + analysis.protein,
        );
        final totalCarbs = displayAnalyses.fold<double>(
          0,
          (sum, analysis) => sum + analysis.carbs,
        );
        final totalFat = displayAnalyses.fold<double>(
          0,
          (sum, analysis) => sum + analysis.fat,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Analiz Sonuçları',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Share button
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Paylaş',
                onPressed: () => _shareAnalysis(context, displayImagePath, displayAnalyses),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview with Image.file
                if (displayImagePath != null && File(displayImagePath).existsSync())
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Image.file(
                      File(displayImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.fastfood,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),

                // Total calories summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade700],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Toplam Kalori',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCalories kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MacroSummary(
                            label: 'Protein',
                            value: '${totalProtein.toStringAsFixed(0)}g',
                          ),
                          _MacroSummary(
                            label: 'Karb',
                            value: '${totalCarbs.toStringAsFixed(0)}g',
                          ),
                          _MacroSummary(
                            label: 'Yağ',
                            value: '${totalFat.toStringAsFixed(0)}g',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Foods section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Tespit Edilen Yiyecekler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${displayAnalyses.length}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Foods ListView
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayAnalyses.length,
                  itemBuilder: (context, index) {
                    final analysis = displayAnalyses[index];
                    return _FoodListItem(
                      analysis: analysis,
                      onFindRecipes: () => _navigateToRecipes(context, analysis.foodName),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Link button to search related recipes for all foods
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _searchRecipesForAllFoods(context, displayAnalyses),
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text(
                            'Tüm Yiyecekler İçin Tarif Ara',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToRecipes(
                            context,
                            displayAnalyses.first.foodName,
                          ),
                          icon: const Icon(Icons.search),
                          label: Text(
                            '${displayAnalyses.first.foodName} için ara',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding for FAB
                const SizedBox(height: 100),
              ],
            ),
          ),
          // FAB for save to history
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _saveToHistory(context, provider, displayAnalyses),
            backgroundColor: Colors.green,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Geçmişe Kaydet',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  /// Navigate to recipe search for a single food
  void _navigateToRecipes(BuildContext context, String foodName) {
    final recipeProvider = context.read<RecipeProvider>();
    recipeProvider.searchRecipes(foodName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeSearchScreen(),
      ),
    );
  }

  /// Search recipes for all analyzed foods using AppService
  Future<void> _searchRecipesForAllFoods(
    BuildContext context,
    List<FoodAnalysis> analyses,
  ) async {
    if (analyses.isEmpty) return;

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

    try {
      final appService = AppService();
      
      // Convert FoodAnalysis to FoodItem for AppService
      final foodItems = analyses.map((a) {
        return FoodItem(
          name: a.foodName,
          grams: a.estimatedGrams,
          calories: a.estimatedCalories,
          protein: a.protein,
          carbs: a.carbs,
          fat: a.fat,
        );
      }).toList();

      // Search recipes for all foods
      final result = await appService.searchRecipesForAnalysis(foodItems);

      if (context.mounted) {
        if (result.success && result.recipes.isNotEmpty) {
          // Navigate to recipe search
          final recipeProvider = context.read<RecipeProvider>();
          final foodNames = foodItems.map((f) => f.name).join(', ');
          recipeProvider.searchRecipes(foodNames);
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipeSearchScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Tarif arama hatası: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share analysis results
  Future<void> _shareAnalysis(
    BuildContext context,
    String? imagePath,
    List<FoodAnalysis> analyses,
  ) async {
    if (analyses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Paylaşılacak analiz bulunamadı'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show privacy consent dialog
    final confirmed = await ShareConsentDialog.show(
      context,
      title: 'Analizi Paylaş',
      message: 'Bu analiz sonuçlarını paylaşmak istediğinizden emin misiniz?',
    );

    if (!confirmed) {
      return;
    }

    try {
      final shareService = ShareService();

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
              Text('Hazırlanıyor...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Share with image if available
      if (imagePath != null && File(imagePath).existsSync()) {
        await shareService.shareAnalysisWithImage(imagePath, analyses);
      } else {
        await shareService.shareAnalysisResults(analyses);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Paylaşıldı'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Paylaşım hatası: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar',
              textColor: Colors.white,
              onPressed: () => _shareAnalysis(context, imagePath, analyses),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveToHistory(
    BuildContext context,
    AnalysisProvider provider,
    List<FoodAnalysis> analyses,
  ) async {
    if (analyses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Kaydedilecek analiz bulunamadı'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('${analyses.length} analiz kaydediliyor...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      int savedCount = 0;
      for (final analysis in analyses) {
        await provider.saveAnalysis(analysis);
        savedCount++;
      }
      
      // Refresh history and today's data
      await provider.loadHistory();
      await provider.loadTodayData();
      
      if (context.mounted) {
        // Calculate total calories
        final totalCalories = analyses.fold<int>(
          0,
          (sum, a) => sum + a.estimatedCalories,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$savedCount analiz geçmişe kaydedildi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Toplam: $totalCalories kcal',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Görüntüle',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to history screen
                Navigator.pop(context);
                // Note: This assumes MainScreen with BottomNavigationBar
                // In a real app, you'd navigate to history tab
              },
            ),
          ),
        );
        
        // Pop after a short delay to show the snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Kaydetme hatası: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _saveToHistory(context, provider, analyses),
            ),
          ),
        );
      }
    }
  }
}

/// Macro summary item
class _MacroSummary extends StatelessWidget {
  final String label;
  final String value;

  const _MacroSummary({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Food list item showing name, grams, and calories
class _FoodListItem extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback? onFindRecipes;

  const _FoodListItem({
    required this.analysis,
    this.onFindRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food name and confidence
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
                _ConfidenceBadge(confidence: analysis.confidence),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grams and calories row
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.scale,
                    value: '${analysis.estimatedGrams.toStringAsFixed(0)}g',
                    label: 'Porsiyon',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.local_fire_department,
                    value: '${analysis.estimatedCalories}',
                    label: 'Kalori',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.fitness_center,
                    value: '${analysis.protein.toStringAsFixed(0)}g',
                    label: 'Protein',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            // Find recipes button
            if (onFindRecipes != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onFindRecipes,
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('Bu yiyecekle tarif ara'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confidence badge
class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence >= 0.8 ? Icons.verified : Icons.info_outline,
            size: 14,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info tile for grams/calories
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

