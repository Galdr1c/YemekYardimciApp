import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/widgets/nutrition_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionChart Widget Tests', () {
    testWidgets('NutritionChart displays empty state when no data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NutritionChart(
              dailyCalories: {},
              goal: 2000,
            ),
          ),
        ),
      );

      expect(find.text('Henüz veri yok'), findsOneWidget);
    });

    testWidgets('NutritionChart renders with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NutritionChart(
              dailyCalories: {
                '2024-01-01': 1500,
                '2024-01-02': 2000,
                '2024-01-03': 2500,
              },
              goal: 2000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Chart should render
      expect(find.byType(NutritionChart), findsOneWidget);
    });

    testWidgets('NutritionChart handles null goal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NutritionChart(
              dailyCalories: {
                '2024-01-01': 1500,
              },
              goal: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NutritionChart), findsOneWidget);
    });
  });
}

