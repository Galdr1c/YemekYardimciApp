import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/screens/home_screen.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/providers/theme_provider.dart';
import 'package:yemek_yardimci_app/providers/profile_provider.dart';
import 'package:yemek_yardimci_app/providers/connectivity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Search UI Tests', () {
    testWidgets('Mic button is displayed in SearchBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ],
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find mic button (mic_none icon when not listening)
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('SearchBar has voice search button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
            ChangeNotifierProvider(create: (_) => RecipeProvider()),
            ChangeNotifierProvider(create: (_) => AnalysisProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
          ],
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SearchBar exists
      expect(find.byType(SearchBar), findsOneWidget);
      
      // Verify mic button exists in trailing
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });
  });
}

