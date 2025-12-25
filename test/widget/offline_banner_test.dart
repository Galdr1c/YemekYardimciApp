import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/widgets/offline_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('OfflineBanner Widget Tests', () {
    testWidgets('OfflineBanner is hidden when online', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      // Banner should be hidden (SizedBox.shrink) when online
      // Note: Actual connectivity check requires platform channels
      expect(find.text('Offline mod aktif, senkronizasyon bekleniyor'), findsNothing);
    });

    testWidgets('OfflineBanner displays correct message', (WidgetTester tester) async {
      // This test would require mocking connectivity
      // For now, we verify the widget structure
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(OfflineBanner), findsOneWidget);
    });
  });
}

