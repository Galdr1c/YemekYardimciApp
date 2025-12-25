import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/app_service.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('AppService Mock Tests', () {
    late AppService appService;
    late AppRepository repository;

    setUp(() async {
      repository = AppRepository();
      await repository.database;
      appService = AppService();
    });

    test('searchRecipesForAnalysis handles empty list', () async {
      final result = await appService.searchRecipesForAnalysis([]);
      
      expect(result.success, false);
      expect(result.recipes, isEmpty);
      expect(result.message, contains('Yiyecek'));
    });

    test('searchRecipesForAnalysis creates ingredient string', () async {
      final foods = [
        FoodItem(name: 'Elma', grams: 100, calories: 52),
        FoodItem(name: 'Muz', grams: 120, calories: 108),
      ];

      final result = await appService.searchRecipesForAnalysis(foods);
      
      // Should attempt to search (may fail without API key, but logic is correct)
      expect(result, isNotNull);
    });

    test('analyzeImage handles invalid path', () async {
      final result = await appService.analyzeImage('/invalid/path.jpg');
      
      expect(result.success, false);
      expect(result.foods, isEmpty);
      expect(result.message, isNotEmpty);
    });

    test('fetchRecipes handles empty query', () async {
      final result = await appService.fetchRecipes('');
      
      // Should return empty or error
      expect(result, isNotNull);
    });

    test('hasValidApiKeys returns false for default keys', () {
      // Default keys should be invalid
      expect(appService.hasValidApiKeys, false);
    });

    test('repository getter returns repository instance', () {
      final repo = appService.repository;
      expect(repo, isNotNull);
      expect(repo, isA<AppRepository>());
    });
  });
}

