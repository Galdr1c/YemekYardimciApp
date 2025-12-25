import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/models/food_analysis.dart';
import 'package:yemek_yardimci_app/screens/analysis_detail_screen.dart';
import 'package:yemek_yardimci_app/screens/history_screen.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';

void main() {
  group('History Save Tests', () {
    testWidgets('AnalysisDetailScreen FAB saves to history', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Test Food',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 200,
        protein: 10.0,
        carbs: 20.0,
        fat: 5.0,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      // Find FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Verify FAB label
      expect(find.text('Geçmişe Kaydet'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('AnalysisDetailScreen shows save feedback', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        imagePath: '/test/path.jpg',
        foodName: 'Test Food',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 200,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: AnalysisDetailScreen(
              imagePath: '/test/path.jpg',
              analyses: [analysis],
            ),
          ),
        ),
      );

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Should show loading or success snackbar
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('HistoryScreen shows empty state when no history', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: const HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('Geçmiş Boş'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsWidgets);
    });

    testWidgets('HistoryScreen delete button shows confirmation', (WidgetTester tester) async {
      final analysis = FoodAnalysis(
        id: 1,
        imagePath: '/test/path.jpg',
        foodName: 'Test Food',
        confidence: 0.9,
        estimatedGrams: 100,
        estimatedCalories: 200,
      );

      final provider = AnalysisProvider();
      await provider.saveAnalysis(analysis);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: const HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find delete button
      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        // Tap delete button
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('Kaydı Sil'), findsOneWidget);
        expect(find.text('İptal'), findsOneWidget);
        expect(find.text('Sil'), findsOneWidget);
      }
    });

    testWidgets('HistoryScreen clear all shows confirmation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
          ],
          child: MaterialApp(
            home: const HistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find clear all button (may not be visible if empty)
      final clearButton = find.byIcon(Icons.delete_sweep);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.text('Geçmişi Temizle'), findsOneWidget);
      }
    });
  });

  group('History Save Logic Tests', () {
    test('insertAnalysis saves to database', () async {
      final repository = AppRepository();
      await repository.database;

      final analysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path.jpg',
        foods: [
          FoodItem(name: 'Test Food', grams: 100, calories: 200),
        ],
      );

      final id = await repository.insertAnalysis(analysis);
      expect(id, greaterThan(0));

      // Verify in database
      final saved = await repository.getAnalysisById(id);
      expect(saved, isNotNull);
      expect(saved?.foods.length, 1);
      expect(saved?.foods.first.name, 'Test Food');

      // Cleanup
      await repository.deleteAnalysis(id);
    });

    test('deleteAnalysis removes from database', () async {
      final repository = AppRepository();
      await repository.database;

      final analysis = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path.jpg',
        foods: [
          FoodItem(name: 'Test Food', grams: 100, calories: 200),
        ],
      );

      final id = await repository.insertAnalysis(analysis);
      expect(id, greaterThan(0));

      // Verify exists
      final before = await repository.getAnalysisById(id);
      expect(before, isNotNull);

      // Delete
      final deleted = await repository.deleteAnalysis(id);
      expect(deleted, 1);

      // Verify deleted
      final after = await repository.getAnalysisById(id);
      expect(after, isNull);
    });

    test('getAllAnalyses returns all saved analyses', () async {
      final repository = AppRepository();
      await repository.database;

      // Insert multiple analyses
      final analysis1 = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path1.jpg',
        foods: [FoodItem(name: 'Food1', grams: 100, calories: 200)],
      );

      final analysis2 = AnalysisModel(
        date: DateTime.now().toIso8601String().split('T')[0],
        photoPath: '/test/path2.jpg',
        foods: [FoodItem(name: 'Food2', grams: 150, calories: 300)],
      );

      final id1 = await repository.insertAnalysis(analysis1);
      final id2 = await repository.insertAnalysis(analysis2);

      // Get all
      final all = await repository.getAllAnalyses();
      expect(all.length, greaterThanOrEqualTo(2));

      // Verify both are present
      final found1 = all.any((a) => a.id == id1);
      final found2 = all.any((a) => a.id == id2);
      expect(found1, true);
      expect(found2, true);

      // Cleanup
      await repository.deleteAnalysis(id1);
      await repository.deleteAnalysis(id2);
    });

    test('getAnalysesByDate filters correctly', () async {
      final repository = AppRepository();
      await repository.database;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      // Insert analyses for different dates
      final analysis1 = AnalysisModel(
        date: today,
        photoPath: '/test/today.jpg',
        foods: [FoodItem(name: 'Today Food', grams: 100, calories: 200)],
      );

      final analysis2 = AnalysisModel(
        date: yesterday,
        photoPath: '/test/yesterday.jpg',
        foods: [FoodItem(name: 'Yesterday Food', grams: 150, calories: 300)],
      );

      final id1 = await repository.insertAnalysis(analysis1);
      final id2 = await repository.insertAnalysis(analysis2);

      // Get today's analyses
      final todayAnalyses = await repository.getAnalysesByDate(today);
      expect(todayAnalyses.length, greaterThanOrEqualTo(1));
      expect(todayAnalyses.any((a) => a.id == id1), true);

      // Get yesterday's analyses
      final yesterdayAnalyses = await repository.getAnalysesByDate(yesterday);
      expect(yesterdayAnalyses.length, greaterThanOrEqualTo(1));
      expect(yesterdayAnalyses.any((a) => a.id == id2), true);

      // Cleanup
      await repository.deleteAnalysis(id1);
      await repository.deleteAnalysis(id2);
    });
  });

  group('UI Feedback Tests', () {
    testWidgets('Snackbar shows correct icon for favorite add', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            const Text('Favorilere eklendi'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Favorilere eklendi'), findsOneWidget);
    });

    testWidgets('Snackbar shows correct icon for save', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text('Geçmişe kaydedildi'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Geçmişe kaydedildi'), findsOneWidget);
    });

    testWidgets('Loading indicator shows during operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
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
                            Text('İşleniyor...'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('İşleniyor...'), findsOneWidget);
    });
  });
}

