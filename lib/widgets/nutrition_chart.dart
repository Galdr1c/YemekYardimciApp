import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Bar chart widget for displaying daily/weekly calories
class NutritionChart extends StatelessWidget {
  final Map<String, int> dailyCalories;
  final int? goal;
  final bool isWeekly;

  const NutritionChart({
    super.key,
    required this.dailyCalories,
    this.goal,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyCalories.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Henüz veri yok',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final entries = dailyCalories.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.grey[800]!,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= entries.length) return const Text('');
                  final date = entries[value.toInt()].key;
                  final dateObj = DateTime.parse(date);
                  final formatted = isWeekly
                      ? DateFormat('E', 'tr_TR').format(dateObj)
                      : DateFormat('dd.MM').format(dateObj);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formatted,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxY() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[400]!, width: 1),
              left: BorderSide(color: Colors.grey[400]!, width: 1),
            ),
          ),
          barGroups: entries.asMap().entries.map((entry) {
            final index = entry.key;
            final calories = entry.value.value;
            final isOverGoal = goal != null && calories > goal!;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: calories.toDouble(),
                  color: isOverGoal ? Colors.red : Colors.green,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (dailyCalories.isEmpty) return 2000;
    
    final maxCalories = dailyCalories.values.reduce((a, b) => a > b ? a : b);
    final goalValue = goal ?? 2000;
    final maxValue = maxCalories > goalValue ? maxCalories : goalValue;
    
    // Round up to nearest 500
    return (maxValue / 500).ceil() * 500.0;
  }
}

