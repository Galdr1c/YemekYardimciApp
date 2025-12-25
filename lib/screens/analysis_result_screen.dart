import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_analysis.dart';
import '../providers/analysis_provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/constants.dart';
import '../widgets/nutrition_card.dart';
import 'recipe_search_screen.dart';

/// Screen displaying food analysis results
class AnalysisResultScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  int _selectedIndex = 0;
  final Map<int, double> _customPortions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          final analyses = provider.currentAnalysis;

          if (analyses.isEmpty) {
            return _buildNoResultsView();
          }

          final selectedAnalysis = analyses[_selectedIndex];
          final portion = _customPortions[_selectedIndex] ?? 
                          selectedAnalysis.estimatedGrams;

          return Column(
            children: [
              // Image preview
              _ImagePreview(imagePath: widget.imagePath),

              // Results tabs (if multiple foods detected)
              if (analyses.length > 1)
                _FoodTabs(
                  analyses: analyses,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                ),

              // Food details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name and confidence
                      _FoodHeader(analysis: selectedAnalysis),
                      const SizedBox(height: 16),

                      // Portion size adjuster
                      _PortionAdjuster(
                        currentGrams: portion,
                        onChanged: (grams) {
                          setState(() {
                            _customPortions[_selectedIndex] = grams;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nutrition card with scaled values
                      _buildNutritionCard(selectedAnalysis, portion),
                      const SizedBox(height: 24),

                      // Find recipes button
                      _FindRecipesButton(
                        foodName: selectedAnalysis.foodName,
                        onPressed: () => _findRecipes(selectedAnalysis.foodName),
                      ),
                    ],
                  ),
                ),
              ),

              // Save button
              _SaveButton(
                onSave: () => _saveAnalysis(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNutritionCard(FoodAnalysis analysis, double portion) {
    final factor = portion / analysis.estimatedGrams;
    return NutritionCard(
      calories: (analysis.estimatedCalories * factor).round(),
      protein: analysis.protein * factor,
      carbs: analysis.carbs * factor,
      fat: analysis.fat * factor,
      fiber: analysis.fiber * factor,
      showDailyPercent: true,
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No food detected',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 8),
          Text(
            'Try taking another photo with better lighting',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _findRecipes(String foodName) {
    final recipeProvider = context.read<RecipeProvider>();
    recipeProvider.searchRecipes(foodName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecipeSearchScreen(),
      ),
    );
  }

  Future<void> _saveAnalysis(AnalysisProvider provider) async {
    final analyses = provider.currentAnalysis;
    
    for (int i = 0; i < analyses.length; i++) {
      final customPortion = _customPortions[i];
      var analysis = analyses[i];
      
      if (customPortion != null) {
        analysis = provider.updatePortionSize(analysis, customPortion);
      }
      
      await provider.saveAnalysis(analysis);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis saved to history'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How it works'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• AI identifies foods in your photo'),
            SizedBox(height: 8),
            Text('• Nutritional values are estimated'),
            SizedBox(height: 8),
            Text('• Adjust portion size for accuracy'),
            SizedBox(height: 8),
            Text('• Link to recipes for cooking ideas'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;

  const _ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FoodTabs extends StatelessWidget {
  final List<FoodAnalysis> analyses;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FoodTabs({
    required this.analyses,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: analyses.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(analyses[index].foodName),
              selected: isSelected,
              onSelected: (_) => onSelected(index),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoodHeader extends StatelessWidget {
  final FoodAnalysis analysis;

  const _FoodHeader({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analysis.foodName,
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _ConfidenceBadge(confidence: analysis.confidence),
                  const SizedBox(width: 12),
                  Text(
                    'Detected food item',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Calorie highlight
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.caloriesColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${analysis.estimatedCalories}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.caloriesColor,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence >= 0.8) return AppColors.success;
    if (confidence >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  IconData get _icon {
    if (confidence >= 0.8) return Icons.verified;
    if (confidence >= 0.5) return Icons.help_outline;
    return Icons.warning_amber;
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
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}% match',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionAdjuster extends StatelessWidget {
  final double currentGrams;
  final ValueChanged<double> onChanged;

  const _PortionAdjuster({
    required this.currentGrams,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portion Size',
                  style: AppTextStyles.subtitle2,
                ),
                Text(
                  '${currentGrams.toInt()}g',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.1),
              ),
              child: Slider(
                value: currentGrams,
                min: 10,
                max: 500,
                divisions: 49,
                onChanged: onChanged,
              ),
            ),
            // Quick select buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [50, 100, 150, 200, 300].map((grams) {
                final isSelected = currentGrams.round() == grams;
                return InkWell(
                  onTap: () => onChanged(grams.toDouble()),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: Text(
                      '${grams}g',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindRecipesButton extends StatelessWidget {
  final String foodName;
  final VoidCallback onPressed;

  const _FindRecipesButton({
    required this.foodName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Recipes',
                      style: AppTextStyles.subtitle1,
                    ),
                    Text(
                      'Search recipes with "$foodName"',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text(
              'Save to History',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

