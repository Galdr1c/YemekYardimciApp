import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/services/nutrition_report_service.dart';

void main() {
  group('NutritionReportService Tests', () {
    late NutritionReportService service;

    setUp(() {
      service = NutritionReportService();
    });

    test('compareToGoal returns correct message when under goal', () {
      final message = service.compareToGoal(1500, 2000);
      expect(message, contains('Hedefin altında'));
      expect(message, contains('500'));
    });

    test('compareToGoal returns correct message when over goal', () {
      final message = service.compareToGoal(2500, 2000);
      expect(message, contains('Hedefi'));
      expect(message, contains('500'));
    });

    test('compareToGoal returns correct message when at goal', () {
      final message = service.compareToGoal(2000, 2000);
      expect(message, contains('Hedefine ulaştın'));
    });

    test('compareToGoal handles null goal', () {
      final message = service.compareToGoal(1500, null);
      expect(message, contains('Hedef belirlenmemiş'));
    });

    test('exportToCSV method exists', () {
      // Note: Actual CSV export requires database setup
      // This test verifies the method signature
      expect(service.exportToCSV, isA<Function>());
    });
  });
}

