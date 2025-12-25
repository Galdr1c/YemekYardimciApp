import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/screens/main_screen.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const MaterialApp(
        home: MainScreen(),
      ),
    );
  }

  group('MainScreen Widget Tests', () {
    testWidgets('Has BottomNavigationBar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('BottomNavigationBar has 3 items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify all navigation labels
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Favoriler'), findsOneWidget);
      expect(find.text('Geçmiş'), findsOneWidget);
    });

    testWidgets('Home tab is selected by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('Navigation items have correct icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check for navigation icons (both outlined and filled versions)
      expect(find.byIcon(Icons.home), findsOneWidget); // Active home icon
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.byIcon(Icons.history_outlined), findsOneWidget);
    });

    testWidgets('Can navigate to Favorites tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on Favoriler
      await tester.tap(find.text('Favoriler'));
      await tester.pumpAndSettle();

      // Verify navigation occurred (star icon should be active)
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Can navigate to History tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on Geçmiş
      await tester.tap(find.text('Geçmiş'));
      await tester.pumpAndSettle();

      // Verify navigation occurred (history icon should be active)
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('BottomNavigationBar has white background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.backgroundColor, Colors.white);
    });

    testWidgets('Selected item color is green', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.selectedItemColor, Colors.green);
    });

    testWidgets('Unselected item color is grey', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.unselectedItemColor, Colors.grey);
    });

    testWidgets('Uses IndexedStack for screen management', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('Can navigate back to Home from Favorites', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Navigate to Favorites
      await tester.tap(find.text('Favoriler'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.text('Ana Sayfa'));
      await tester.pumpAndSettle();

      // Verify home icon is active
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('All tabs are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Test each tab
      await tester.tap(find.text('Favoriler'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Geçmiş'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Ana Sayfa'));
      await tester.pumpAndSettle();

      // Verify we're back at home
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });
  });
}

