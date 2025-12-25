import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Card displaying nutritional information
class NutritionCard extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final bool showDailyPercent;
  final int dailyCalorieGoal;

  const NutritionCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.showDailyPercent = false,
    this.dailyCalorieGoal = AppConstants.defaultDailyCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calories header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.caloriesColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: AppColors.caloriesColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calories',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          '$calories kcal',
                          style: AppTextStyles.headline3.copyWith(
                            color: AppColors.caloriesColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showDailyPercent)
                  _DailyPercentIndicator(
                    percent: calories / dailyCalorieGoal,
                    color: AppColors.caloriesColor,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Macros
            Row(
              children: [
                Expanded(
                  child: _MacroItem(
                    label: 'Protein',
                    value: protein,
                    color: AppColors.proteinColor,
                    dailyValue: showDailyPercent ? AppConstants.defaultDailyProtein : null,
                  ),
                ),
                Expanded(
                  child: _MacroItem(
                    label: 'Carbs',
                    value: carbs,
                    color: AppColors.carbsColor,
                    dailyValue: showDailyPercent ? AppConstants.defaultDailyCarbs : null,
                  ),
                ),
                Expanded(
                  child: _MacroItem(
                    label: 'Fat',
                    value: fat,
                    color: AppColors.fatColor,
                    dailyValue: showDailyPercent ? AppConstants.defaultDailyFat : null,
                  ),
                ),
                if (fiber != null)
                  Expanded(
                    child: _MacroItem(
                      label: 'Fiber',
                      value: fiber!,
                      color: AppColors.fiberColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double? dailyValue;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.color,
    this.dailyValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${value.toStringAsFixed(0)}g',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
        if (dailyValue != null) ...[
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (value / dailyValue!).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ],
      ],
    );
  }
}

class _DailyPercentIndicator extends StatelessWidget {
  final double percent;
  final Color color;

  const _DailyPercentIndicator({
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: clampedPercent,
            strokeWidth: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        Text(
          '${(percent * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Compact nutrition row for list items
class NutritionRow extends StatelessWidget {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NutritionChip(
          icon: Icons.local_fire_department,
          value: '$calories',
          unit: 'kcal',
          color: AppColors.caloriesColor,
        ),
        _NutritionChip(
          icon: Icons.fitness_center,
          value: '${protein.toStringAsFixed(0)}',
          unit: 'g protein',
          color: AppColors.proteinColor,
        ),
        _NutritionChip(
          icon: Icons.grain,
          value: '${carbs.toStringAsFixed(0)}',
          unit: 'g carbs',
          color: AppColors.carbsColor,
        ),
        _NutritionChip(
          icon: Icons.water_drop,
          value: '${fat.toStringAsFixed(0)}',
          unit: 'g fat',
          color: AppColors.fatColor,
        ),
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _NutritionChip({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
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
          unit,
          style: AppTextStyles.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

