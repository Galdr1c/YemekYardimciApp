import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemek_yardimci_app/widgets/share_consent_dialog.dart';

void main() {
  group('ShareConsentDialog Tests', () {
    testWidgets('ShareConsentDialog displays title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await ShareConsentDialog.show(
                  context,
                  title: 'Test Title',
                  message: 'Test Message',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('Kişisel bilgileriniz paylaşılmayacaktır.'), findsOneWidget);
    });

    testWidgets('ShareConsentDialog has cancel and confirm buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await ShareConsentDialog.show(
                  context,
                  title: 'Test',
                  message: 'Test',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
    });

    testWidgets('ShareConsentDialog returns false when cancelled', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ShareConsentDialog.show(
                  context,
                  title: 'Test',
                  message: 'Test',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('ShareConsentDialog returns true when confirmed', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await ShareConsentDialog.show(
                  context,
                  title: 'Test',
                  message: 'Test',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paylaş'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}

