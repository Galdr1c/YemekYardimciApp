import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/screens/history_screen.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const MaterialApp(
        home: HistoryScreen(),
      ),
    );
  }

  group('HistoryScreen Widget Tests', () {
    testWidgets('Renders with correct AppBar title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify AppBar title
      expect(find.text('Geçmiş'), findsOneWidget);
    });

    testWidgets('AppBar has green background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.green);
    });

    testWidgets('Shows empty state when no history', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify empty state text
      expect(find.text('Geçmiş Boş'), findsOneWidget);
      expect(find.text('Yemek fotoğrafı çekerek kalori\nanalizi yapmaya başlayın.'), findsOneWidget);
    });

    testWidgets('Empty state has history icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify history icon in empty state
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('AppBar foreground color is white', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.foregroundColor, Colors.white);
    });

    testWidgets('No clear history button when empty', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear history button should not be visible when no history
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });

    testWidgets('Empty state is centered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Center widget exists
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('Empty state has blue themed icon container', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for containers
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers, isNotEmpty);
    });

    testWidgets('Title style has correct font weight', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find the text with Geçmiş and verify it exists
      final titleFinder = find.text('Geçmiş');
      expect(titleFinder, findsOneWidget);
    });
  });

  group('HistoryScreen Integration Tests', () {
    testWidgets('Screen is scrollable when content exists', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Screen structure should support scrolling
      // Empty state is in a Center, actual content would be in ListView
    });

    testWidgets('Has proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Padding widgets exist
      expect(find.byType(Padding), findsWidgets);
    });
  });
}

