# YemekYardımcı App 🍳

A Flutter mobile app that combines recipe search with photo-based calorie analysis. Users can search recipes by ingredients, take meal photos for AI-powered food recognition and calorie estimation, and save their history.

## Features

- 🔍 **Recipe Search** - Search recipes by name or ingredients
- 📸 **Food Scanner** - Take photos of meals for AI-powered nutritional analysis
- 📊 **Calorie Tracking** - Track daily calorie and macro intake
- ❤️ **Favorites** - Save favorite recipes for quick access
- 📜 **History** - View past food analyses and nutrition history
- 🔗 **Recipe Linking** - Link analyzed foods to recipes for cooking ideas
- 🌙 **Dark Mode** - Full dark theme support with user preference and system auto-switch
- 👤 **User Profile** - **Kullanıcı profili eklendi, kalori hedeflerine göre öneriler** - Set age, gender, and daily calorie goals with personalized recommendations
- 📤 **Social Sharing** - **Sosyal paylaşım eklendi, arkadaş entegrasyonu ile ortak tarifler** - Share recipes and analysis results with privacy consent
- 📡 **Offline Mode** - **Offline mod eklendi, Firebase ile veri senkronu** - Work offline with local database, sync with Firebase when online
- 🎤 **Voice Search** - **Sesli arama eklendi, Türkçe destekli komutlar** - Search recipes by voice, support Turkish commands like "kalori hesapla"
- 📊 **Nutrition Reports** - **Beslenme raporları eklendi, grafikli öneriler** - View weekly calorie charts, get personalized recipe suggestions, export CSV reports

## Screenshots

Coming soon...

## App Theme

The app uses a custom `AppTheme` class for consistent styling with dark mode support.

### Theme Colors
| Color | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| **Primary** | `green[700]` (#388E3C) | `green[500]` (#4CAF50) | Buttons, AppBar, icons |
| **Secondary** | `orange` (#FF9800) | `orange[300]` (#FFB74D) | Accent elements |
| **Star** | `amber` (#FFC107) | `amber` (#FFC107) | Favorite icons |
| **Calorie** | `deepOrange` (#FF5722) | `deepOrange` (#FF5722) | Calorie displays |
| **Warning** | `red` (#D32F2F) | `red[300]` (#EF5350) | High-calorie warnings |

### Text Theme
- **bodyLarge**: 16px, bold (as specified)
- All text styles are optimized for readability

### Icon Colors
- ⭐ **Star icons**: Yellow/Amber for favorites, grey when inactive
- 🔥 **Calorie icons**: Red for high calories (≥500), orange for normal

### Dark Mode
- **Dark tema desteği eklendi, cihaz ayarına göre otomatik geçiş**
- Automatically detected via `MediaQuery.platformBrightnessOf(context)`
- System-level theme switching supported
- `ThemeMode.system` for automatic switching
- User preference saved via SharedPreferences (key: 'theme_mode')
- Settings screen with theme toggle switch
- Dark theme optimized with:
  - Background: `Colors.grey[900]`
  - Primary: `Colors.green[800]`
  - Text: White colors for visibility
  - Icons: Light colors for visibility

### User Profile
- **Kullanıcı profili eklendi, kalori hedeflerine göre öneriler**
- User profile management with age, gender, and daily calorie goal
- Profile stored in SQLite database (`users` table)
- Validation:
  - Age: 18-100
  - Daily calorie goal: 1000-5000 kcal
  - Gender: Erkek/Kadın/Diğer
- Personalization features:
  - Calorie goal warnings when total calories exceed daily goal
  - Low-calorie recipe suggestions when goal < 2000 kcal
  - Remaining calories display
  - Recipe sorting by calories for low-calorie users
- Accessible via BottomNavigationBar "Profil" tab

### Social Sharing
- **Sosyal paylaşım eklendi, arkadaş entegrasyonu ile ortak tarifler**
- Share recipes and analysis results via `share_plus` package
- Privacy consent dialog before sharing (no personal data without permission)
- Share format: "Tarif: [name] - Kalori: [calories] kcal"
- Available in:
  - RecipeDetailScreen: Share button in AppBar
  - AnalysisDetailScreen: Share button in AppBar
- Features:
  - Text sharing with formatted recipe/analysis data
  - Image sharing for analysis results (when available)
  - Privacy-first approach with user consent
- Future enhancements (planned):
  - Firebase Auth integration for user login
  - Firestore integration for shared recipes collection
  - Deep linking via Firebase Dynamic Links
  - Friend sharing and collaborative features

### Offline Mode
- **Offline mod eklendi, Firebase ile veri senkronu**
- Firebase Firestore with offline persistence (`enablePersistence`)
- Automatic sync on app start (Firestore → Local DB)
- Offline banner shows when connectivity is lost
- Local database fallback for all operations:
  - Recipe search falls back to local DB when API fails
  - All data operations work offline
- Automatic sync on reconnect:
  - Local changes uploaded to Firestore
  - Firestore changes downloaded to local DB
- Features:
  - `connectivity_plus` for network status monitoring
  - `ConnectivityProvider` for state management
  - `OfflineBanner` widget for user feedback
  - Firebase offline cache enabled
- Collections synced:
  - `recipes` collection
  - `analyses` collection

### Voice Search
- **Sesli arama eklendi, Türkçe destekli komutlar**
- Voice search with Turkish language support (`localeId: 'tr_TR'`)
- Mic button in SearchBar (next to search field)
- Features:
  - Speech-to-text recognition using `speech_to_text` package
  - Automatic permission request for microphone
  - Real-time listening indicator (red mic icon when active)
  - Command recognition:
    - "kalori hesapla" / "kalori hesaplama" → Opens camera for calorie calculation
    - "fotoğraf çek" / "kamera aç" → Opens camera
    - Other phrases → Treated as search query
  - Error handling for permission denied or recognition errors
- Usage:
  - Tap mic button to start listening
  - Speak your query (e.g., "yumurta peynir")
  - Results automatically populate search field and trigger search
  - Speak command (e.g., "kalori hesapla") to open camera
- Permissions:
  - Microphone permission requested on first use
  - Error message shown if permission denied

### Nutrition Reports
- **Beslenme raporları eklendi, grafikli öneriler**
- Weekly calorie tracking with interactive bar charts
- Personalized recipe suggestions based on calorie status
- CSV export functionality for data analysis
- Features:
  - **BarChart** using `fl_chart` package
  - Daily/weekly calorie aggregation
  - Color coding: green (under goal), red (over goal)
  - Goal comparison with user profile
  - Recipe suggestions:
    - Under goal: Suggests low-calorie recipes
    - Over goal: Suggests very low-calorie options
  - Summary card showing daily goal vs. actual intake
- Available in HistoryScreen "Raporlar" tab
- Export:
  - CSV format with date and calories
  - Share via `share_plus` package
- Chart details:
  - X-axis: Dates (formatted as day names for weekly view)
  - Y-axis: Calories
  - Interactive tooltips on bar tap
  - Grid lines for easy reading

### High-Calorie Warnings
Foods with ≥500 calories are highlighted in **red** to warn users:
```dart
// Usage example
Text(
  '${calories} kcal',
  style: AppTheme.getCalorieTextStyle(calories),
);

// Check if high calorie
if (AppTheme.isHighCalorie(calories)) {
  // Show warning indicator
}
```

### Using Theme Colors
```dart
// Get star color based on favorite status
Icon(
  isFavorite ? Icons.star : Icons.star_border,
  color: AppTheme.getStarColor(isFavorite),
)

// Get calorie color based on value
Text(
  '$calories kcal',
  style: AppTheme.getCalorieTextStyle(calories),
)
```

## HomeScreen (Main Screen)

The HomeScreen is the main entry point with a tabbed interface:

### UI Structure
- **AppBar**: Title "Yemek Yardımcısı" with green background
- **TabBar**: Two tabs with icons
  - **Tarif Ara** (Recipe Search) - Search icon
  - **Kalori Hesapla** (Calorie Calculator) - Calculator icon

### Tab 1: Recipe Search (Tarif Ara)

#### Real-Time Search
- **SearchBar**: Search recipes by ingredients with:
  - Debounced input (300ms delay)
  - Real-time LIKE query against SQLite database
  - Results count badge showing matches
  - Clear button when text is entered

```dart
// Debounced search implementation
void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    _performLocalSearch(query);
  });
}

// LIKE query in AppRepository
final results = await _repository.searchRecipes(query);
// Searches: WHERE name LIKE '%query%' OR ingredients LIKE '%query%'
```

#### Recipe List
- **ListView**: Display recipe results with:
  - `RecipeCard`: CachedNetworkImage (50x50), title, ingredients subtitle, star favorite button
  - Pull-to-refresh support
  - Animated transitions
- **Empty State**: Random recipe suggestion button
- **No Results State**: "Tüm Tarifleri Göster" button to reset

#### UI Feedback
- `LinearProgressIndicator` during search
- Results count badge: "X için Y sonuç bulundu"
- Loading state with "Tarifler aranıyor..." message

### Tab 2: Calorie Calculator (Kalori Hesapla)

#### Photo Capture
- **Row Layout**: Two buttons side by side
  - **ElevatedButton**: "Fotoğraf Çek" (Take Photo) - Camera capture
  - **OutlinedButton**: "Galeriden Seç" (Choose from Gallery)
- Buttons disabled during analysis
- Permission dialog for camera access

#### Image Analysis with AppService
```dart
// Full ML + API analysis flow
final result = await _appService.analyzeImage(photoPath);

// Result contains:
// - success: bool
// - foods: List<FoodItem>
// - analysisId: int
// - totalCalories, totalProtein, totalCarbs, totalFat
```

#### Analysis Status Updates
- "Görüntü hazırlanıyor..." → "Yiyecekler tanınıyor..."
- Animated progress indicator with restaurant icon
- Demo mode badge when no API keys configured

#### Image Preview
- **Container**: 220px height with rounded corners
- Overlay badge: "X yiyecek" showing food count
- Retake button in bottom-right corner
- Placeholder with icon and instructions

#### Results Display
- **Total Nutrition Card**: Gradient green background
  - Large calorie display (36px font)
  - Macro chips: Protein, Karb, Yağ
- **Food Items List**: Individual `_FoodItemCard` widgets
  - Food name and icon
  - Grams and macros breakdown
  - Calorie display with orange color
  - Arrow to find related recipes
- **Action Buttons Row**:
  - "İlgili Tarifler" - Search recipes for analyzed foods
  - "Yeni Analiz" - Take new photo

#### Snackbar Feedback
```dart
// Success feedback
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(children: [
      Icon(Icons.check_circle, color: Colors.white),
      Text(result.message),
    ]),
    backgroundColor: Colors.green,
  ),
);

// Error feedback with retry action
SnackBar(
  action: SnackBarAction(
    label: 'Tekrar',
    onPressed: () => _analyzeImageWithService(imagePath),
  ),
);
```

### Navigation
- Tap recipe → `RecipeDetailScreen`
- After food analysis → Link to related recipes via `RecipeSearchScreen`
- Toggle favorite → Updates database and refreshes list

### State Management
Uses Provider pattern with:
- `RecipeProvider`: Manages recipe list, search results, favorites
- `AnalysisProvider`: Manages food analysis results, history

Also uses direct repository/service access for:
- `AppRepository`: Local SQLite queries (LIKE search)
- `AppService`: ML analysis and API calls

## RecipeDetailScreen

Displays detailed recipe information with ingredients and cooking steps.

### UI Structure
- **AppBar**: Recipe name as title, green background, white text
- **CachedNetworkImage**: Recipe photo (200px height)
- **Info Row**: Calories, cooking time, servings with icons
- **Malzemeler (Ingredients)**: Numbered list with shopping basket icon
- **Adımlar (Steps)**: Numbered cards with step-by-step instructions
- **Besin Değerleri (Nutrition)**: Protein, carbs, fat display
- **FAB**: Star icon for adding to favorites

### Data Passing
```dart
// Via constructor
RecipeDetailScreen(recipe: myRecipe)

// Via Provider
provider.selectRecipe(recipe);
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const RecipeDetailScreen(),
));

// Via route arguments
Navigator.pushNamed(context, '/recipe-detail', arguments: recipe);
```

### Features
- Calorie estimate from API or calculated from ingredients
- **Enhanced Favorite Toggle**: FAB with loading indicator and undo action
  - Shows "Ekleniyor..." / "Kaldırılıyor..." during operation
  - Success snackbar with recipe name and undo button
  - Automatically refreshes favorites list
  - Updates database and provider state
- Snackbar feedback with icons and undo functionality

## AnalysisDetailScreen

Displays food analysis results with nutritional breakdown.

### UI Structure
- **AppBar**: "Analiz Sonuçları" title, share button
- **Image.file**: Photo preview (200px height)
- **Total Summary**: Green gradient card with:
  - Total calories (large text)
  - Macro totals (Protein, Karb, Yağ)
- **Food ListView**: Each item shows:
  - Food name with confidence badge (%)
  - Portion size (grams)
  - Calories
  - Protein
  - "Bu yiyecekle tarif ara" button
- **Link Button**: "İlgili Tarifleri Ara" → RecipeSearchScreen
- **FAB**: "Geçmişe Kaydet" (Save to History)

### Data Passing
```dart
// Via constructor
AnalysisDetailScreen(
  imagePath: '/path/to/image.jpg',
  analyses: listOfAnalyses,
)

// Via route arguments
Navigator.pushNamed(context, '/analysis-detail', arguments: {
  'imagePath': imagePath,
  'analyses': analyses,
});
```

### Features
- Total calorie calculation from all detected foods
- Confidence percentage with color coding (green/orange/red)
- Direct link to search related recipes
- **Enhanced Save to History**: FAB with comprehensive feedback
  - Shows loading: "X analiz kaydediliyor..."
  - Success snackbar with count and total calories
  - "Görüntüle" action to navigate to history
  - Automatically refreshes history and today's data
  - Error handling with retry option

## MainScreen (App Navigation)

The MainScreen provides bottom navigation between main sections.

### UI Structure
- **IndexedStack**: Keeps screen state when switching tabs
- **BottomNavigationBar**: 3 navigation items
  - 🏠 **Ana Sayfa** (Home) - Home icon
  - ⭐ **Favoriler** (Favorites) - Star icon
  - 📜 **Geçmiş** (History) - History icon

### Features
- Smooth tab switching with IndexedStack
- Green selected item color
- Active/inactive icon states

## FavoritesScreen

Displays saved favorite recipes with enhanced toggle and remove functionality.

### UI Structure
- **AppBar**: "Favoriler" title, green background
  - Clear all button (when items exist) with confirmation dialog
- **ListView**: Favorite recipe cards with:
  - CachedNetworkImage (70x70)
  - Recipe title
  - Calories and time info
  - Category badge
  - **Delete button** with confirmation
  - Calories, cooking time
  - Category badge
  - Remove button (red delete icon)
- **Empty State**: Star icon with hint text

### Enhanced Toggle/Save Features

#### Favorite Toggle
- **RecipeCard Star Button**: Quick toggle with instant snackbar feedback
- **RecipeDetailScreen FAB**: Extended FAB with loading and undo
  ```dart
  // Toggle with refresh
  await provider.toggleFavorite(recipe);
  await provider.loadFavorites(); // Refresh list
  ```

#### Remove Favorite
- **Delete Button**: Per-recipe delete with confirmation dialog
- **Loading Feedback**: Shows "X kaldırılıyor..." during operation
- **Success Snackbar**: 
  - Icon + recipe name
  - "Geri Al" (Undo) action
  - Auto-refreshes favorites list
- **Clear All**: 
  - Confirmation with count: "X favori tarif silinsin mi?"
  - Loading indicator during bulk delete
  - Success feedback with count

### Integration
```dart
// Load favorites
await provider.loadFavorites();

// Toggle favorite (with refresh)
await provider.toggleFavorite(recipe);
await provider.loadFavorites();

// Remove favorite (with refresh)
await provider.removeFromFavorites(recipe.id);
await provider.loadFavorites();

// Clear all (with refresh)
for (final recipe in provider.favorites) {
  await provider.removeFromFavorites(recipe.id!);
}
await provider.loadFavorites();
```

## HistoryScreen

Displays food analysis history grouped by date with enhanced save/delete functionality.

### UI Structure
- **AppBar**: "Geçmiş" title, green background
  - Clear history button (when items exist) with confirmation dialog
- **ListView**: History items grouped by date
  - **Date Header**: Date (Bugün/Dün/Date), item count, total calories
  - **History Cards**:
    - Image thumbnail (60x60)
    - Food name with confidence badge
    - Grams, calories, protein info
    - Time of analysis
    - Delete button
- **Empty State**: History icon with hint text

### Enhanced Save/Delete Features

#### Save to History (AnalysisDetailScreen FAB)
- **FAB**: "Geçmişe Kaydet" with save icon
- **Loading Feedback**: Shows "X analiz kaydediliyor..." with progress indicator
- **Success Snackbar**:
  - Check circle icon
  - Count: "X analiz geçmişe kaydedildi"
  - Total calories: "Toplam: X kcal"
  - "Görüntüle" action button
- **Auto-refresh**: Updates history and today's data after save
- **Error Handling**: Retry option on failure

#### Delete Analysis
- **Delete Button**: Per-analysis delete with confirmation dialog
- **Loading Feedback**: Shows "X siliniyor..." during operation
- **Success Snackbar**:
  - Delete icon + food name
  - "Geri Al" action (placeholder for future undo)
  - Auto-refreshes history and today's data
- **Clear All History**:
  - Confirmation with count: "X analiz kaydı silinsin mi?"
  - Loading indicator during bulk delete
  - Success feedback with count

### Features
- Grouped by date (Bugün, Dün, or actual date)
- Total calories per day in header
- Pull-to-refresh to reload history
- Confirmation dialogs with item counts
- Enhanced UI feedback with icons
- Tap card to view full analysis details

### Integration
```dart
// Provider fetches from repository
context.read<AnalysisProvider>().loadHistory();

// Delete analysis
provider.deleteAnalysis(analysis.id);

// Clear all history
provider.clearHistory();
```

## Getting Started

### Prerequisites

- Flutter SDK 3.13.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code with Flutter extensions
- Physical device or emulator for testing camera features

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd YemekYardimciApp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Quick Start
```bash
flutter pub get && flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point with theme and routing
├── models/                # Data models
│   ├── recipe.dart        # Recipe model
│   ├── food_analysis.dart # Food analysis model
│   └── ingredient.dart    # Ingredient model
├── screens/               # UI screens
│   ├── main_screen.dart           # Bottom navigation wrapper
│   ├── home_screen.dart           # Main home with tabs
│   ├── recipe_search_screen.dart  # Recipe search
│   ├── recipe_detail_screen.dart  # Recipe details
│   ├── analysis_detail_screen.dart # Analysis details
│   ├── camera_screen.dart         # Food photo capture
│   ├── analysis_result_screen.dart# Analysis results (legacy)
│   ├── history_screen.dart        # Analysis history
│   └── favorites_screen.dart      # Favorite recipes
├── widgets/               # Reusable widgets
│   ├── recipe_card.dart   # Recipe card component
│   ├── nutrition_card.dart# Nutrition display card
│   └── analysis_card.dart # Analysis result card
├── providers/             # State management
│   ├── recipe_provider.dart   # Recipe state
│   └── analysis_provider.dart # Analysis state
├── repository/            # Database operations
│   ├── database_helper.dart      # SQLite helper
│   ├── recipe_repository.dart    # Recipe CRUD
│   └── food_analysis_repository.dart # Analysis CRUD
├── services/              # External services
│   ├── permission_service.dart  # Permissions handling
│   ├── recipe_api_service.dart  # Recipe API calls
│   └── ml_service.dart          # ML image analysis
└── utils/                 # Utilities
    ├── constants.dart     # App constants
    └── helpers.dart       # Helper functions
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database |
| `path` | File path utilities |
| `http` | HTTP networking |
| `cached_network_image` | Image caching |
| `provider` | State management |
| `camera` | Camera access |
| `google_mlkit_image_labeling` | ML food recognition |
| `google_mlkit_object_detection` | Object detection |
| `image_picker` | Image selection |
| `permission_handler` | Permission management |

## Configuration

### Android

Permissions are configured in `android/app/src/main/AndroidManifest.xml`:
- Camera access
- Internet access
- Storage access

### iOS

Permissions are configured in `ios/Runner/Info.plist`:
- Camera usage description
- Photo library usage description

## API

The app uses [TheMealDB](https://www.themealdb.com/) free API for recipe data.

## Share & Gallery Features

### Share Functionality

The app includes comprehensive sharing capabilities for analysis results and recipes.

#### ShareService (`lib/services/share_service.dart`)

**Methods:**
- `shareAnalysisResults(List<FoodAnalysis>)` - Share analysis as formatted text
- `shareAnalysisWithImage(String imagePath, List<FoodAnalysis>)` - Share analysis with photo
- `shareRecipe(...)` - Share recipe details
- `shareDailySummary(DateTime)` - Share daily calorie summary

**Features:**
- Formatted text with emojis and structure
- Image sharing via `share_plus`
- Total calories and macros included
- Date formatting with `intl`
- Error handling with fallback

#### Integration in AnalysisDetailScreen

- **Share Button**: AppBar icon button with tooltip
- **Loading Feedback**: Shows "Hazırlanıyor..." during share
- **Success Snackbar**: Confirms share completion
- **Error Handling**: Retry option on failure
- **Image Support**: Shares with image if available, text-only fallback

### Gallery Import

Gallery import is available in the Calorie Calculator tab:

- **"Galeriden Seç" Button**: OutlinedButton with photo_library icon
- **Image Picker**: Uses `image_picker` package
- **Source Selection**: `ImageSource.gallery`
- **Analysis**: Same ML analysis flow as camera photos
- **UI Feedback**: Progress indicators and result display

### Recipe Search from Analysis

Enhanced recipe search integration:

- **"Tüm Yiyecekler İçin Tarif Ara"**: Searches recipes for all analyzed foods
- **Individual Food Search**: Quick search button for first food
- **AppService Integration**: Uses `searchRecipesForAnalysis()` method
- **Loading Feedback**: Shows progress during search
- **Navigation**: Automatically navigates to RecipeSearchScreen with results

## Testing

### Run Widget Tests
```bash
flutter test
```

### HomeScreen Tests
```bash
flutter test test/home_screen_test.dart
```

Tests verify:
- Tab rendering (Tarif Ara, Kalori Hesapla)
- SearchBar presence and functionality
- Photo button visibility
- Tab switching behavior
- AppBar styling (green background)
- Empty states

### RecipeDetailScreen Tests
```bash
flutter test test/recipe_detail_screen_test.dart
```

Tests verify:
- Recipe name in AppBar
- Malzemeler (ingredients) section
- Adımlar (steps) section
- Calorie/time/servings display
- FAB favorite button
- Nutrition info card
- Empty state handling

### AnalysisDetailScreen Tests
```bash
flutter test test/analysis_detail_screen_test.dart
```

Tests verify:
- AppBar title "Analiz Sonuçları"
- Total calories calculation
- Food items ListView
- Grams/calories for each food
- Macro totals (protein, carbs, fat)
- Save to history FAB
- Search recipes button
- Confidence badges

### MainScreen Tests
```bash
flutter test test/main_screen_test.dart
```

Tests verify:
- BottomNavigationBar presence
- 3 navigation items (Ana Sayfa, Favoriler, Geçmiş)
- Tab switching functionality
- Correct icon states (active/inactive)
- Navigation item colors

### FavoritesScreen Tests
```bash
flutter test test/favorites_screen_test.dart
```

Tests verify:
- AppBar title "Favoriler"
- Empty state display
- Star icon in empty state
- Green AppBar background
- Clear all button visibility

### HistoryScreen Tests
```bash
flutter test test/history_screen_test.dart
```

Tests verify:
- AppBar title "Geçmiş"
- Empty state display
- History icon in empty state
- Green AppBar background
- Clear history button visibility

### Theme Tests
```bash
flutter test test/theme_test.dart
```

Tests verify:
- Light theme primary color (green[700])
- Dark theme primary color (green[500])
- Secondary/accent color (orange)
- bodyLarge text style (16px bold)
- Star icon colors (yellow/grey)
- Calorie icon colors (red for high, orange for normal)
- High-calorie warning threshold (500)
- Theme switching (light ↔ dark)
- Scaffold background colors
- AppBar theme colors

## Database (SQLite)

The app uses SQLite via `sqflite` package for local data persistence.

### Database Schema

#### Recipes Table
| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key, auto-increment |
| `name` | TEXT | Recipe name |
| `ingredients` | TEXT | JSON array of ingredients |
| `steps` | TEXT | JSON array of cooking steps |
| `image_url` | TEXT | URL to recipe image |
| `is_favorite` | INTEGER | Boolean (0/1) for favorite status |
| `calories` | INTEGER | Total calories |
| `protein` | REAL | Protein in grams |
| `carbs` | REAL | Carbohydrates in grams |
| `fat` | REAL | Fat in grams |
| `prep_time` | INTEGER | Preparation time in minutes |
| `cook_time` | INTEGER | Cooking time in minutes |
| `servings` | INTEGER | Number of servings |
| `category` | TEXT | Recipe category |
| `created_at` | TEXT | ISO 8601 datetime |

#### Analyses Table
| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Primary key, auto-increment |
| `date` | TEXT | Date (YYYY-MM-DD) |
| `photo_path` | TEXT | Path to analyzed photo |
| `foods` | TEXT | JSON array of FoodItem objects |
| `total_calories` | INTEGER | Sum of all food calories |
| `total_protein` | REAL | Sum of all protein |
| `total_carbs` | REAL | Sum of all carbs |
| `total_fat` | REAL | Sum of all fat |
| `notes` | TEXT | Optional notes |
| `created_at` | TEXT | ISO 8601 datetime |

### AppRepository Methods

```dart
// Initialize database
await AppRepository().database;

// Recipe methods
await repository.insertRecipe(recipe);
await repository.updateRecipe(recipe);
await repository.getAllRecipes();
await repository.getRecipeById(id);
await repository.searchRecipes(query);
await repository.getFavoriteRecipes();
await repository.toggleRecipeFavorite(id);
await repository.deleteRecipe(id);

// Analysis methods
await repository.insertAnalysis(analysis);
await repository.getAllAnalyses();
await repository.getAnalysisById(id);
await repository.getAnalysesByDate(date);
await repository.deleteAnalysis(id);
await repository.getTodayCalories();
```

### Data Models

#### RecipeModel
```dart
RecipeModel(
  name: 'Omlet',
  ingredients: ['2 yumurta', 'Tuz', 'Karabiber'],
  steps: ['Çırp', 'Pişir'],
  imageUrl: 'https://example.com/omlet.jpg',
  isFavorite: true,
  calories: 200,
  protein: 14.0,
  carbs: 2.0,
  fat: 15.0,
  prepTime: 5,
  cookTime: 5,
  servings: 1,
  category: 'Kahvaltı',
);
```

#### AnalysisModel
```dart
AnalysisModel(
  date: '2024-12-24',
  photoPath: '/path/to/photo.jpg',
  foods: [
    FoodItem(name: 'Yumurta', grams: 100, calories: 155),
    FoodItem(name: 'Ekmek', grams: 50, calories: 130),
  ],
  totalCalories: 285,
  notes: 'Kahvaltı',
);
```

#### FoodItem
```dart
FoodItem(
  name: 'Tavuk',
  grams: 150.0,
  calories: 250,
  protein: 31.0,
  carbs: 0.0,
  fat: 5.4,
);
```

## Sample Data

On first launch, the app automatically inserts sample data for demonstration:

### 10 Sample Recipes
| Recipe | Category | Calories | Description |
|--------|----------|----------|-------------|
| Omlet | Kahvaltı | 200 | Classic egg omelet |
| Menemen | Kahvaltı | 280 | Turkish scrambled eggs with vegetables |
| Mercimek Çorbası | Çorba | 180 | Red lentil soup |
| Tavuk Sote | Ana Yemek | 350 | Chicken sauté with peppers |
| Tereyağlı Pilav | Yan Yemek | 250 | Butter rice |
| Karnıyarık | Ana Yemek | 420 | Stuffed eggplant |
| Sezar Salata | Salata | 320 | Caesar salad |
| Domates Soslu Makarna | Ana Yemek | 380 | Pasta with tomato sauce |
| Izgara Köfte | Ana Yemek | 450 | Grilled meatballs |
| Sütlaç | Tatlı | 280 | Turkish rice pudding |

### 3 Sample Analyses
| Date | Meal | Foods | Total Calories |
|------|------|-------|----------------|
| Today | Kahvaltı | Omlet, Ekmek, Peynir | 430 |
| Today | Öğle | Tavuk Sote, Pilav, Salata, Ayran | 565 |
| Yesterday | Akşam | Köfte, Makarna, Cacık | 725 |

### Initialization Flow
```dart
// In main.dart PermissionWrapper
Future<void> _initializeApp() async {
  // 1. Request permissions
  await _permissionService.requestAllPermissions();
  
  // 2. Initialize database
  await _repository.database;
  
  // 3. Insert sample data on first launch
  await _insertSampleDataOnFirstLaunch();
  
  // 4. Initialize ML services
  await _appService.initML();
  
  // 5. Load initial data into providers
  await _loadInitialData();
}
```

## ML & API Integration

### AppService

The `AppService` class provides unified access to ML analysis and recipe APIs.

#### ML Integration (Google ML Kit)

```dart
// Initialize ML services
await AppService().initML();

// Analyze an image
final result = await AppService().analyzeImage('/path/to/photo.jpg');

// Result contains:
// - success: bool
// - foods: List<FoodItem>
// - analysisId: int?
// - message: String
// - totalCalories, totalProtein, totalCarbs, totalFat (computed)
```

**Food Recognition Flow:**
1. Image is processed with `ImageLabeler` for food labels
2. `ObjectDetector` finds bounding boxes for gram estimation
3. Labels are filtered for food-related items
4. Nutrition data is fetched (API or mock)
5. Analysis is saved to database

#### Recipe API Integration

**Spoonacular API** (Recipe Search):
```dart
final result = await AppService().fetchRecipes('yumurta, domates');

// Returns RecipeSearchResult with:
// - success: bool
// - recipes: List<RecipeModel>
// - message: String
```

**Nutritionix API** (Nutrition Data):
- Provides accurate calorie/macro data for detected foods
- Endpoint: `natural/nutrients`

#### API Configuration

Replace placeholder keys in `lib/services/app_service.dart`:
```dart
static const String _spoonacularApiKey = 'YOUR_SPOONACULAR_API_KEY';
static const String _nutritionixAppId = 'YOUR_NUTRITIONIX_APP_ID';
static const String _nutritionixApiKey = 'YOUR_NUTRITIONIX_API_KEY';
```

**Get API Keys:**
- Spoonacular: https://spoonacular.com/food-api
- Nutritionix: https://developer.nutritionix.com/

#### Demo Mode

Without API keys, the app runs in demo mode with mock data:
```dart
if (AppService().isDemoMode) {
  // Using mock nutrition data
  // Using mock recipe results
}
```

### Linking Analysis to Recipes

After analyzing a meal, users can search for related recipes:
```dart
final analysisResult = await appService.analyzeImage(photoPath);
final recipeResult = await appService.searchRecipesForAnalysis(analysisResult.foods);
```

### Error Handling

All API/ML operations include error handling with user-friendly messages:
```dart
final result = await appService.analyzeImage(photoPath);
if (!result.success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.message)),
  );
}
```

### Enhanced ML Bounding Box Estimation

The service uses advanced ML bounding box analysis for gram estimation:

```dart
// Enhanced estimation considers:
// 1. Bounding box area (width * height)
// 2. Aspect ratio (elongated vs tall foods)
// 3. Confidence score (higher = more accurate)
// 4. Food type defaults (fallback)

double _estimateGramsFromBoundingBox(objects, label) {
  // Calculate area in pixels
  final area = box.width * box.height;
  
  // Adjust for aspect ratio
  if (aspectRatio > 1.5) baseGrams *= 0.8; // Elongated (bread, pasta)
  if (aspectRatio < 0.7) baseGrams *= 1.2; // Tall (drinks, soups)
  
  // Apply confidence multiplier
  baseGrams *= (0.7 + (confidence * 0.3));
  
  // Clamp to reasonable range (20-1000g)
  return baseGrams.clamp(20.0, 1000.0);
}
```

### Response Caching

API responses are cached to reduce network calls and improve performance:

```dart
// Cache key format: 'nutrition_{foodName}_{grams}'
final cacheKey = 'nutrition_egg_100';

// Check cache first
if (cache.containsKey(cacheKey) && !cache[cacheKey].isExpired) {
  return cache[cacheKey].data;
}

// Fetch from API and cache
final response = await fetchFromAPI();
cache[cacheKey] = CachedResponse(data: response, timestamp: now);
```

**Cache Management:**
- **Expiry**: 24 hours
- **Auto-cleanup**: Expired entries removed automatically
- **Statistics**: Track cache hits/misses

```dart
// Get cache stats
final stats = appService.getCacheStats();
// Returns: {total: 10, valid: 8, expired: 2}

// Clear expired entries
appService.clearExpiredCache();

// Clear all cache
appService.clearCache();
```

## Calorie Calculation from Ingredients

The app includes a `CalorieCalculator` utility for calculating nutrition from ingredient lists.

### Usage

```dart
import 'package:yemek_yardimci_app/utils/calorie_calculator.dart';

// Calculate total nutrition
final ingredients = ['2 yumurta', '1 ekmek', '30g peynir'];
final nutrition = CalorieCalculator.calculateFromIngredients(ingredients);

// Returns: {calories: 450, protein: 35, carbs: 50, fat: 20}
```

### Supported Units

- **Countable**: `2 adet yumurta`, `3 piece chicken`
- **Grams**: `500g tavuk`, `100 gram rice`
- **Cups**: `1 su bardağı süt` (≈240g)
- **Tablespoons**: `1 yemek kaşığı zeytinyağı` (≈15g)
- **Teaspoons**: `1 çay kaşığı tuz` (≈5g)
- **Kilograms**: `1 kg tavuk` (1000g)

### Ingredient Database

Includes 50+ common ingredients with nutrition data:
- Proteins: eggs, chicken, meat, fish, cheese
- Carbs: rice, pasta, bread, potatoes
- Vegetables: tomatoes, onions, peppers, etc.
- Fats: olive oil, butter
- Dairy: milk, yogurt
- Legumes: lentils, beans
- Spices: salt, pepper, cumin

### Features

```dart
// Get nutrition for single ingredient
final nutrition = CalorieCalculator.getIngredientNutrition('2 yumurta');

// Estimate per serving
final caloriesPerServing = CalorieCalculator.estimateCaloriesPerServing(
  ingredients,
  servings: 4,
);

// Detailed breakdown
final breakdown = CalorieCalculator.getDetailedBreakdown(ingredients);
// Returns: {total: {...}, breakdown: {ingredient1: {...}, ...}}
```

### RecipeDetailScreen Integration

The `RecipeDetailScreen` automatically calculates calories from ingredients:

```dart
// If API calories not available, calculate from ingredients
final calculatedNutrition = CalorieCalculator.calculateFromIngredients(
  recipe.ingredients,
);

// Display shows:
// - API calories (if available)
// - Calculated calories (fallback or verification)
// - "Hesaplanan" badge for calculated values
```

**Display Logic:**
- Shows API calories if available
- Falls back to calculated if API = 0
- Shows comparison: "API: 200 kcal | Hesaplanan: 195 kcal"
- Displays "* Malzemelerden hesaplanan değerler" note

## Image Handling

### Recipe Images (CachedNetworkImage)

All recipe images use `CachedNetworkImage` for optimal performance:

```dart
CachedNetworkImage(
  imageUrl: recipe.imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.restaurant),
)
```

**Benefits:**
- Automatic caching
- Placeholder while loading
- Error handling
- Memory efficient

### Analysis Photos (Image.file)

Food analysis photos use `Image.file` for local files:

```dart
Image.file(
  File(photoPath),
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported),
)
```

**Usage:**
- Direct file access
- No network overhead
- Fast loading
- Error handling for missing files

## Repository & Service Tests

### AppRepository Tests
```bash
flutter test test/app_repository_test.dart
```

Tests verify:
- RecipeModel creation and conversion
- AnalysisModel creation and conversion
- FoodItem creation and conversion
- Map serialization/deserialization
- JSON parsing
- Data validation
- Date handling

### AppService Tests
```bash
flutter test test/app_service_test.dart
```

Tests verify:
- Singleton pattern
- Demo mode detection
- ImageAnalysisResult calculations
- RecipeSearchResult structure
- Mock data generation
- Nutrition estimation
- Food label filtering
- API response parsing
- Error handling
- Integration flow simulation

### AppService Enhanced Tests
```bash
flutter test test/app_service_enhanced_test.dart
```

Tests verify:
- Cache statistics and management
- ML bounding box gram estimation
- Aspect ratio adjustments (elongated vs tall foods)
- Confidence multiplier application
- Grams clamping (20-1000g range)
- Cache expiry logic
- Nutrition scaling by quantity
- Default grams for food types

### Calorie Calculator Tests
```bash
flutter test test/calorie_calculator_test.dart
```

Tests verify:
- Ingredient parsing (quantities, units)
- Grams, cups, tablespoons, teaspoons conversion
- Turkish and English ingredient names
- Total nutrition calculation
- Calories per serving estimation
- Detailed breakdown generation
- Unknown ingredient handling
- Zero-calorie ingredients (salt)
- Spices and herbs
- Vegetables and fats
- Edge cases (large/small quantities, special characters)

### Favorites Toggle Tests
```bash
flutter test test/favorites_toggle_test.dart
```

Tests verify:
- RecipeDetailScreen FAB toggles favorite
- FAB shows undo action in snackbar
- RecipeCard star button triggers toggle
- FavoritesScreen empty state display
- Remove button shows confirmation dialog
- Clear all shows confirmation with count
- Toggle logic changes isFavorite state correctly
- Database toggle returns correct status
- Provider refresh after toggle operations

### History Save Tests
```bash
flutter test test/history_save_test.dart
```

Tests verify:
- AnalysisDetailScreen FAB saves to history
- Save shows loading and success feedback
- HistoryScreen empty state display
- Delete button shows confirmation dialog
- Clear all shows confirmation with count
- insertAnalysis saves to database correctly
- deleteAnalysis removes from database
- getAllAnalyses returns all saved analyses
- getAnalysesByDate filters correctly
- UI feedback with correct icons (star, save, delete, check)
- Loading indicators during operations

### Share Service Tests
```bash
flutter test test/unit/share_service_test.dart
```

Tests verify:
- shareAnalysisResults formats text correctly
- shareAnalysisResults handles empty list
- shareRecipe includes all recipe details
- shareDailySummary requires valid date
- Text formatting with emojis and structure

### Gallery Import Tests
```bash
flutter test test/widget/gallery_widget_test.dart
```

Tests verify:
- HomeScreen shows gallery button
- Gallery button is enabled when not analyzing
- Camera and gallery buttons both present
- Button interactions and state

### Share Widget Tests
```bash
flutter test test/widget/share_widget_test.dart
```

Tests verify:
- AnalysisDetailScreen shows share button
- Share button triggers share action
- Recipe search buttons are present
- Navigation to recipe search

### Unit Tests (Mocks)
```bash
flutter test test/unit/
```

**app_service_mock_test.dart:**
- searchRecipesForAnalysis handles empty list
- analyzeImage handles invalid path
- fetchRecipes handles empty query
- hasValidApiKeys validation
- Repository getter

**app_repository_mock_test.dart:**
- insertRecipe returns valid ID
- getRecipeById returns correct recipe
- toggleRecipeFavorite changes status
- searchRecipes finds matching recipes
- insertAnalysis saves correctly
- deleteAnalysis removes from database
- getFavoriteRecipes returns only favorites

### Integration Tests (E2E)
```bash
flutter test test/integration/e2e_test.dart
```

Tests verify:
- Complete flow: Search -> View -> Favorite -> Check Favorites
- Complete flow: Analyze -> Save -> View History
- Navigation flow: Home -> Search -> Favorites -> History
- Repository and Service integration

### Running All Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/share_service_test.dart

# Run tests in directory
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

### Test Structure
```
test/
├── unit/                    # Unit tests with mocks
│   ├── share_service_test.dart
│   ├── app_service_mock_test.dart
│   └── app_repository_mock_test.dart
├── widget/                  # Widget tests
│   ├── share_widget_test.dart
│   └── gallery_widget_test.dart
├── integration/             # End-to-end tests
│   └── e2e_test.dart
└── [other test files]
```

### Test Coverage Goals
- **Unit Tests**: Services, repositories, utilities
- **Widget Tests**: All screens, interactions, state changes
- **Integration Tests**: Complete user flows
- **Mock Tests**: API/ML service mocks

## Performance & Optimization

### Image Optimization

- **Automatic Resizing**: Images resized to max 640x640 for ML processing
- **Compression**: JPEG quality set to 85% for optimal size/quality balance
- **Isolate Processing**: Image optimization runs in separate isolates
- **Cache Management**: Optimized images cached temporarily

### ML Performance

- **Confidence Threshold**: 0.5 (configurable)
- **Batch Processing**: Processes up to 5 labels per image
- **Response Caching**: API responses cached for 24 hours

### Performance Tests

All operations tested to complete in <5s:
- Repository initialization: <1s
- Recipe search: <2s
- Image optimization: <2s
- Complete workflow: <5s

Run performance tests:
```bash
flutter test test/performance/performance_test.dart
```

## Security

### API Keys

API keys are loaded from environment variables or secure storage:

```bash
# Set environment variables
export SPOONACULAR_API_KEY="your_key"
export NUTRITIONIX_APP_ID="your_app_id"
export NUTRITIONIX_API_KEY="your_api_key"
```

### Network Security

- HTTPS only (cleartext traffic disabled)
- Network security config enforced
- ProGuard code obfuscation enabled

## Building & Deployment

### Quick Build Scripts

**Release APK (Windows):**
```powershell
.\scripts\build_release.ps1
```

**Release APK (Linux/Mac):**
```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh
```

**App Bundle for Google Play:**
```bash
# Windows
.\scripts\build_bundle.ps1

# Linux/Mac
./scripts/build_bundle.sh
```

### Manual Build

**Debug Build:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter clean
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

**App Bundle (Google Play):**
```bash
flutter build appbundle --release
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

**Split APKs (Smaller Size):**
```bash
flutter build apk --release --split-per-abi
```

### Build Configuration

- ✅ **Minify**: Enabled in release
- ✅ **Shrink Resources**: Enabled
- ✅ **ProGuard**: Configured
- ✅ **MultiDex**: Enabled
- ✅ **Network Security**: HTTPS only

See `BUILD.md` for detailed deployment instructions.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [TheMealDB](https://www.themealdb.com/) for recipe API
- [Google ML Kit](https://developers.google.com/ml-kit) for food recognition
- Flutter and the Flutter community

#   Y e m e k Y a r d i m c i A p p  
 #   Y e m e k Y a r d i m c i A p p  
 