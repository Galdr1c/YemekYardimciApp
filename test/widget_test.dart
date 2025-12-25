import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YemekYardimciApp());

    // Wait for permissions wrapper
    await tester.pump(const Duration(seconds: 2));

    // Verify app title is shown
    expect(find.text('YemekYardımcı'), findsOneWidget);
  });

  testWidgets('Home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const YemekYardimciApp());
    await tester.pumpAndSettle();

    // Check for navigation items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
  });
}

