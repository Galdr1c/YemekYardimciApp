import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food_analysis.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Card displaying food analysis result
class AnalysisCard extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLinkRecipe;
  final bool showActions;

  const AnalysisCard({
    super.key,
    required this.analysis,
    this.onTap,
    this.onDelete,
    this.onLinkRecipe,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and confidence overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildImage(),
                ),
                // Confidence badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor().withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getConfidenceIcon(),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          analysis.confidencePercent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Time badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateTimeHelper.getRelativeTime(analysis.analyzedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Analysis info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analysis.foodName,
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${analysis.estimatedGrams.toStringAsFixed(0)}g serving',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      // Calorie display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.caloriesColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${analysis.estimatedCalories}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.caloriesColor,
                              ),
                            ),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Macros row
                  Row(
                    children: [
                      _MacroPill(
                        label: 'P',
                        value: '${analysis.protein.toStringAsFixed(0)}g',
                        color: AppColors.proteinColor,
                      ),
                      const SizedBox(width: 8),
                      _MacroPill(
                        label: 'C',
                        value: '${analysis.carbs.toStringAsFixed(0)}g',
                        color: AppColors.carbsColor,
                      ),
                      const SizedBox(width: 8),
                      _MacroPill(
                        label: 'F',
                        value: '${analysis.fat.toStringAsFixed(0)}g',
                        color: AppColors.fatColor,
                      ),
                    ],
                  ),
                  // Actions
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onLinkRecipe != null)
                          TextButton.icon(
                            onPressed: onLinkRecipe,
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Link Recipe'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.red,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (analysis.imagePath.startsWith('http')) {
      return Image.network(
        analysis.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    } else if (File(analysis.imagePath).existsSync()) {
      return Image.file(
        File(analysis.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.fastfood, size: 48, color: Colors.grey),
      ),
    );
  }

  Color _getConfidenceColor() {
    if (analysis.confidence >= 0.8) return Colors.green;
    if (analysis.confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getConfidenceIcon() {
    if (analysis.confidence >= 0.8) return Icons.check_circle;
    if (analysis.confidence >= 0.5) return Icons.warning;
    return Icons.error;
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact analysis card for lists
class AnalysisListTile extends StatelessWidget {
  final FoodAnalysis analysis;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AnalysisListTile({
    super.key,
    required this.analysis,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: _buildThumbnail(),
        ),
      ),
      title: Text(
        analysis.foodName,
        style: AppTextStyles.subtitle2,
      ),
      subtitle: Text(
        '${analysis.estimatedCalories} kcal • ${analysis.macrosSummary}',
        style: AppTextStyles.caption,
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red,
            )
          : Text(
              DateTimeHelper.getRelativeTime(analysis.analyzedAt),
              style: AppTextStyles.caption,
            ),
    );
  }

  Widget _buildThumbnail() {
    if (File(analysis.imagePath).existsSync()) {
      return Image.file(
        File(analysis.imagePath),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}

