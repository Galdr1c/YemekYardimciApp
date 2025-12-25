import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/food_analysis.dart';
import '../repository/app_repository.dart';

/// Service for sharing analysis results and recipes
class ShareService {
  /// Share analysis results as text
  Future<void> shareAnalysisResults(List<FoodAnalysis> analyses) async {
    if (analyses.isEmpty) return;

    final totalCalories = analyses.fold<int>(
      0,
      (sum, a) => sum + a.estimatedCalories,
    );

    final totalProtein = analyses.fold<double>(
      0,
      (sum, a) => sum + a.protein,
    );

    final totalCarbs = analyses.fold<double>(
      0,
      (sum, a) => sum + a.carbs,
    );

    final totalFat = analyses.fold<double>(
      0,
      (sum, a) => sum + a.fat,
    );

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final date = dateFormat.format(analyses.first.analyzedAt);

    final shareText = '''
🍽️ Yemek Analizi Sonuçları

📅 Tarih: $date
🔥 Toplam Kalori: $totalCalories kcal
🥩 Protein: ${totalProtein.toStringAsFixed(1)}g
🍞 Karbonhidrat: ${totalCarbs.toStringAsFixed(1)}g
🧈 Yağ: ${totalFat.toStringAsFixed(1)}g

📋 Tespit Edilen Yiyecekler:
${analyses.map((a) => '• ${a.foodName}: ${a.estimatedGrams.toStringAsFixed(0)}g, ${a.estimatedCalories} kcal').join('\n')}

YemekYardımcı App ile analiz edildi.
''';

    try {
      await Share.share(
        shareText,
        subject: 'Yemek Analizi Sonuçları',
      );
      print('[ShareService] Shared analysis results');
    } catch (e) {
      print('[ShareService] Share error: $e');
      rethrow;
    }
  }

  /// Share analysis with image
  Future<void> shareAnalysisWithImage(
    String imagePath,
    List<FoodAnalysis> analyses,
  ) async {
    if (analyses.isEmpty || !File(imagePath).existsSync()) {
      await shareAnalysisResults(analyses);
      return;
    }

    try {
      final imageFile = XFile(imagePath);
      final totalCalories = analyses.fold<int>(
        0,
        (sum, a) => sum + a.estimatedCalories,
      );

      final shareText = '''
🍽️ Yemek Analizi

🔥 Toplam Kalori: $totalCalories kcal
📋 ${analyses.length} yiyecek tespit edildi

YemekYardımcı App ile analiz edildi.
''';

      await Share.shareXFiles(
        [imageFile],
        text: shareText,
        subject: 'Yemek Analizi',
      );
      print('[ShareService] Shared analysis with image');
    } catch (e) {
      print('[ShareService] Share with image error: $e');
      // Fallback to text-only share
      await shareAnalysisResults(analyses);
    }
  }

  /// Share recipe with formatted text
  Future<void> shareRecipe({
    required String name,
    required List<String> ingredients,
    required int calories,
    required int prepTime,
    required int cookTime,
    String? imageUrl,
  }) async {
    // Format: "Tarif: [name] - Kalori: [calories]" as requested
    final shareText = '''
Tarif: $name - Kalori: $calories kcal

📋 Malzemeler:
${ingredients.map((ing) => '• $ing').join('\n')}

⏱️ Hazırlık: $prepTime dk
⏱️ Pişirme: $cookTime dk

YemekYardımcı App'ten paylaşıldı.
''';

    try {
      await Share.share(
        shareText,
        subject: 'Tarif: $name',
      );
      print('[ShareService] Shared recipe: $name');
    } catch (e) {
      print('[ShareService] Share recipe error: $e');
      rethrow;
    }
  }

  /// Share daily summary
  Future<void> shareDailySummary(DateTime date) async {
    final repository = AppRepository();
    final dateString = date.toIso8601String().split('T')[0];
    final analyses = await repository.getAnalysesByDate(dateString);

    if (analyses.isEmpty) {
      throw Exception('Bu tarih için analiz bulunamadı');
    }

    final totalCalories = analyses.fold<int>(
      0,
      (sum, a) => sum + a.totalCalories,
    );

    final dateFormat = DateFormat('dd.MM.yyyy');
    final formattedDate = dateFormat.format(date);

    final shareText = '''
📊 Günlük Özet - $formattedDate

🔥 Toplam Kalori: $totalCalories kcal
📋 ${analyses.length} analiz

YemekYardımcı App ile takip edildi.
''';

    try {
      await Share.share(
        shareText,
        subject: 'Günlük Özet - $formattedDate',
      );
      print('[ShareService] Shared daily summary for $dateString');
    } catch (e) {
      print('[ShareService] Share daily summary error: $e');
      rethrow;
    }
  }
}

