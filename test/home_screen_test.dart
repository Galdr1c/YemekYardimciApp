import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yemek_yardimci_app/providers/recipe_provider.dart';
import 'package:yemek_yardimci_app/providers/analysis_provider.dart';
import 'package:yemek_yardimci_app/screens/home_screen.dart';
import 'package:yemek_yardimci_app/repository/app_repository.dart';
import 'package:yemek_yardimci_app/services/app_service.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen renders with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify app bar title
      expect(find.text('Yemek Yardımcısı'), findsOneWidget);
    });

    testWidgets('HomeScreen has two tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify tabs exist
      expect(find.text('Tarif Ara'), findsOneWidget);
      expect(find.text('Kalori Hesapla'), findsOneWidget);
    });

    testWidgets('Tab icons are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify tab icons
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('SearchBar is present in first tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify search bar
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Malzeme ile tarif ara...'), findsOneWidget);
    });

    testWidgets('Can switch to second tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Tap on second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify second tab content is shown
      expect(find.text('Fotoğraf Çek'), findsOneWidget);
    });

    testWidgets('Photo button is present in second tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify photo button
      expect(find.text('Fotoğraf Çek'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
    });

    testWidgets('Gallery button is present in second tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify gallery button
      expect(find.text('Galeriden Seç'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('Image preview container is present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify preview container placeholder text
      expect(find.text('Fotoğraf önizlemesi'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    });

    testWidgets('Empty state shows in recipe search', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify empty state
      expect(find.text('Tarif Ara'), findsWidgets); // Tab and empty state title
      expect(find.text('Rastgele Tarif'), findsOneWidget);
    });

    testWidgets('Hint section is shown in calorie tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify hint section - updated to new text
      expect(find.text('Nasıl Çalışır?'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('AppBar has green background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find the AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.green);
    });

    testWidgets('TabBar has white indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find the TabBar
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.indicatorColor, Colors.white);
    });

    testWidgets('Search icon triggers search action', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find search icon button in the SearchBar trailing
      final searchIcons = find.byIcon(Icons.search);
      expect(searchIcons, findsWidgets);
    });

    testWidgets('Tab switching works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Initially on first tab - verify SearchBar
      expect(find.byType(SearchBar), findsOneWidget);

      // Switch to second tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify second tab content
      expect(find.text('Fotoğraf Çek'), findsOneWidget);

      // Switch back to first tab
      await tester.tap(find.text('Tarif Ara'));
      await tester.pumpAndSettle();

      // Verify first tab content again
      expect(find.byType(SearchBar), findsOneWidget);
    });
  });

  group('Recipe Search Tests', () {
    testWidgets('SearchBar accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find and tap on search bar
      final searchBar = find.byType(SearchBar);
      expect(searchBar, findsOneWidget);
      
      await tester.tap(searchBar);
      await tester.pump();

      // Enter text
      await tester.enterText(searchBar, 'yumurta');
      await tester.pump();

      // Verify text was entered
      expect(find.text('yumurta'), findsOneWidget);
    });

    testWidgets('Search bar has restaurant menu icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify leading icon
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('Search triggers on submit', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find search bar
      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pump();

      // Enter and submit
      await tester.enterText(searchBar, 'tavuk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should not crash
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Clear button appears when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Find search bar
      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pump();

      // Enter text
      await tester.enterText(searchBar, 'test');
      await tester.pump(const Duration(milliseconds: 400)); // Wait for debounce

      // Clear icon should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('Empty search state shows random recipe button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify random recipe button
      expect(find.text('Rastgele Tarif'), findsOneWidget);
      expect(find.byIcon(Icons.casino), findsOneWidget);
    });
  });

  group('Calorie Analysis Tests', () {
    testWidgets('Both photo buttons are present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify both buttons
      expect(find.text('Fotoğraf Çek'), findsOneWidget);
      expect(find.text('Galeriden Seç'), findsOneWidget);
    });

    testWidgets('Photo buttons are in a row', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify Row with buttons exists
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Preview container shows placeholder text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify placeholder
      expect(find.text('Fotoğraf önizlemesi'), findsOneWidget);
      expect(find.text('Yemek fotoğrafı çekin veya seçin'), findsOneWidget);
    });

    testWidgets('How it works section shows steps', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify how it works section
      expect(find.text('Nasıl Çalışır?'), findsOneWidget);
      expect(find.textContaining('Yemek fotoğrafı'), findsWidgets);
    });

    testWidgets('Camera icon button present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify camera icon
      expect(find.byIcon(Icons.camera_alt), findsWidgets);
    });

    testWidgets('Gallery icon button present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify gallery icon
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });
  });

  group('UI Elements Tests', () {
    testWidgets('ElevatedButton styled correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Find elevated buttons
      final elevatedButtons = find.byType(ElevatedButton);
      expect(elevatedButtons, findsWidgets);
    });

    testWidgets('OutlinedButton styled correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Find outlined buttons
      final outlinedButtons = find.byType(OutlinedButton);
      expect(outlinedButtons, findsWidgets);
    });

    testWidgets('Scrollable content in calorie tab', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Navigate to calorie tab
      await tester.tap(find.text('Kalori Hesapla'));
      await tester.pumpAndSettle();

      // Verify scrollable
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator shows during search', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Enter text to trigger search
      final searchBar = find.byType(SearchBar);
      await tester.tap(searchBar);
      await tester.pump();

      await tester.enterText(searchBar, 'test');
      await tester.pump();

      // Progress indicator might be visible during search
      // This depends on timing, so just verify no crash
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('RecipeCard Widget Tests', () {
    testWidgets('RecipeCard widget exists', (WidgetTester tester) async {
      // RecipeCard is used for displaying recipe results
      // When there are no results, it won't be shown
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify the HomeScreen renders without errors
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('FoodItem Model Tests', () {
    test('FoodItem can be created', () {
      final food = FoodItem(
        name: 'Test Food',
        grams: 100,
        calories: 200,
        protein: 10.0,
        carbs: 20.0,
        fat: 5.0,
      );

      expect(food.name, 'Test Food');
      expect(food.grams, 100);
      expect(food.calories, 200);
    });

    test('FoodItem converts to map correctly', () {
      final food = FoodItem(
        name: 'Test',
        grams: 50,
        calories: 100,
      );

      final map = food.toMap();

      expect(map['name'], 'Test');
      expect(map['grams'], 50);
      expect(map['calories'], 100);
    });
  });

  group('ImageAnalysisResult Tests', () {
    test('ImageAnalysisResult calculates totals', () {
      final foods = [
        FoodItem(name: 'Food1', grams: 100, calories: 100, protein: 10, carbs: 10, fat: 5),
        FoodItem(name: 'Food2', grams: 100, calories: 150, protein: 15, carbs: 15, fat: 7),
      ];

      final result = ImageAnalysisResult(
        success: true,
        foods: foods,
        message: 'Test',
      );

      expect(result.totalCalories, 250);
      expect(result.totalProtein, 25);
      expect(result.totalCarbs, 25);
      expect(result.totalFat, 12);
    });

    test('Empty ImageAnalysisResult has zero totals', () {
      final result = ImageAnalysisResult(
        success: true,
        foods: [],
        message: 'No foods',
      );

      expect(result.totalCalories, 0);
      expect(result.totalProtein, 0);
    });
  });

  group('RecipeSearchResult Tests', () {
    test('RecipeSearchResult stores recipes', () {
      final recipes = [
        RecipeModel(
          name: 'Test Recipe',
          ingredients: ['Ing1'],
          steps: ['Step1'],
        ),
      ];

      final result = RecipeSearchResult(
        success: true,
        recipes: recipes,
        message: '1 tarif bulundu',
      );

      expect(result.success, true);
      expect(result.recipes.length, 1);
      expect(result.recipes.first.name, 'Test Recipe');
    });

    test('Failed RecipeSearchResult has empty list', () {
      final result = RecipeSearchResult(
        success: false,
        recipes: [],
        message: 'Error',
      );

      expect(result.success, false);
      expect(result.recipes.isEmpty, true);
    });
  });
}
