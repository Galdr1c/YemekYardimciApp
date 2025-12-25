import 'package:intl/intl.dart';
import '../repository/app_repository.dart';

/// Service for generating nutrition reports and statistics
class NutritionReportService {
  final AppRepository _repository = AppRepository();

  /// Get daily calorie totals for a date range
  Future<Map<String, int>> getDailyCalories({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dailyTotals = <String, int>{};
    
    for (var date = startDate; 
         date.isBefore(endDate) || date.isAtSameMomentAs(endDate); 
         date = date.add(const Duration(days: 1))) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final analyses = await _repository.getAnalysesByDate(dateString);
      
      final totalCalories = analyses.fold<int>(
        0,
        (sum, analysis) => sum + analysis.totalCalories,
      );
      
      if (totalCalories > 0) {
        dailyTotals[dateString] = totalCalories;
      }
    }
    
    return dailyTotals;
  }

  /// Get weekly calorie totals
  Future<Map<String, int>> getWeeklyCalories() async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: now.weekday - 1));
    final endDate = startDate.add(const Duration(days: 6));
    
    return getDailyCalories(startDate: startDate, endDate: endDate);
  }

  /// Compare daily calories to goal
  String compareToGoal(int dailyCalories, int? goal) {
    if (goal == null) {
      return 'Hedef belirlenmemiş';
    }
    
    if (dailyCalories < goal) {
      final remaining = goal - dailyCalories;
      return 'Hedefin altında kaldın, $remaining kcal kaldı';
    } else if (dailyCalories > goal) {
      final over = dailyCalories - goal;
      return 'Hedefi $over kcal aştın';
    } else {
      return 'Hedefine ulaştın!';
    }
  }

  /// Get suggestion based on calorie status
  Future<String> getSuggestion(int dailyCalories, int? goal) async {
    if (goal == null) {
      return 'Profil oluşturarak günlük kalori hedefi belirleyebilirsin.';
    }
    
    if (dailyCalories < goal) {
      // Under goal - suggest low-calorie recipes
      final lowCalRecipes = await _repository.searchRecipes('salata');
      if (lowCalRecipes.isNotEmpty) {
        return 'Hedefin altında kaldın, şu tarifi dene: ${lowCalRecipes.first.name}';
      }
      return 'Hedefin altında kaldın, sağlıklı atıştırmalıklar ekleyebilirsin.';
    } else if (dailyCalories > goal) {
      // Over goal - suggest very low-calorie recipes
      final veryLowCalRecipes = await _repository.searchRecipes('salata sebze');
      if (veryLowCalRecipes.isNotEmpty) {
        return 'Hedefi aştın, düşük kalorili seçenekler: ${veryLowCalRecipes.first.name}';
      }
      return 'Hedefi aştın, yarın daha dikkatli olabilirsin.';
    }
    
    return 'Hedefine ulaştın, harika iş!';
  }

  /// Export data to CSV format
  Future<String> exportToCSV({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dailyCalories = await getDailyCalories(
      startDate: startDate,
      endDate: endDate,
    );
    
    final buffer = StringBuffer();
    buffer.writeln('Tarih,Kalori');
    
    for (var entry in dailyCalories.entries) {
      final date = DateFormat('dd.MM.yyyy').format(DateTime.parse(entry.key));
      buffer.writeln('$date,${entry.value}');
    }
    
    return buffer.toString();
  }

  /// Get average calories for date range
  Future<double> getAverageCalories({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dailyCalories = await getDailyCalories(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (dailyCalories.isEmpty) return 0.0;
    
    final total = dailyCalories.values.fold<int>(0, (sum, cal) => sum + cal);
    return total / dailyCalories.length;
  }
}

