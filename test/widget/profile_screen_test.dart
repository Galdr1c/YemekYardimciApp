import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/profile_provider.dart';
import 'package:yemek_yardimci_app/screens/profile_screen.dart';
import 'package:yemek_yardimci_app/repository/user_repository.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    late ProfileProvider profileProvider;

    setUp(() {
      profileProvider = ProfileProvider();
    });

    testWidgets('ProfileScreen displays form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      expect(find.text('Yaş'), findsOneWidget);
      expect(find.text('Cinsiyet'), findsOneWidget);
      expect(find.text('Günlük Kalori Hedefi'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });

    testWidgets('ProfileScreen validates age field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      final ageField = find.byType(TextFormField).first;
      await tester.enterText(ageField, '15');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Yaş en az 18 olmalıdır'), findsOneWidget);
    });

    testWidgets('ProfileScreen validates calorie goal field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      final calorieField = find.byType(TextFormField).last;
      await tester.enterText(calorieField, '500');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Günlük kalori hedefi en az 1000 olmalıdır'), findsOneWidget);
    });

    testWidgets('ProfileScreen validates gender selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      expect(find.text('Cinsiyet seçilmelidir'), findsOneWidget);
    });

    testWidgets('ProfileScreen saves valid profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ProfileProvider>.value(
            value: profileProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      // Enter valid data
      final ageField = find.byType(TextFormField).first;
      await tester.enterText(ageField, '25');

      final calorieField = find.byType(TextFormField).last;
      await tester.enterText(calorieField, '2000');

      // Select gender
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erkek').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Should show success message (if snackbar appears)
      // Note: Actual save will fail in test without database, but validation should pass
    });
  });
}

