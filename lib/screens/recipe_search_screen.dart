import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/constants.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

/// Screen for searching and browsing recipes
class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchByIngredient = false;
  List<String> _selectedIngredients = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedIngredients.isEmpty) return;

    final provider = context.read<RecipeProvider>();
    
    if (_isSearchByIngredient && _selectedIngredients.isNotEmpty) {
      provider.searchByIngredient(_selectedIngredients.first);
    } else {
      provider.searchRecipes(query);
    }
    
    _searchFocus.unfocus();
  }

  void _addIngredient(String ingredient) {
    if (ingredient.isNotEmpty && !_selectedIngredients.contains(ingredient)) {
      setState(() {
        _selectedIngredients.add(ingredient);
        _searchController.clear();
      });
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        selected: {_isSearchByIngredient},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _isSearchByIngredient = selected.first;
                            _selectedIngredients.clear();
                          });
                        },
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('By Name'),
                            icon: Icon(Icons.search),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('By Ingredient'),
                            icon: Icon(Icons.food_bank),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: _isSearchByIngredient
                        ? 'Enter an ingredient...'
                        : 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearchByIngredient)
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addIngredient(_searchController.text.trim()),
                          ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _performSearch,
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (_isSearchByIngredient) {
                      _addIngredient(_searchController.text.trim());
                    } else {
                      _performSearch();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Selected ingredients chips
          if (_selectedIngredients.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.primary.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Ingredients:',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedIngredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        onDeleted: () => _removeIngredient(ingredient),
                        deleteIconColor: Colors.red,
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Search Recipes'),
                    ),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: AppTextStyles.subtitle1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            _performSearch();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.searchResults.isEmpty) {
                  return _EmptyState(
                    onRandomRecipe: () async {
                      final recipe = await provider.getRandomRecipe();
                      if (recipe != null && context.mounted) {
                        provider.selectRecipe(recipe);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecipeDetailScreen(),
                          ),
                        );
                      }
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final recipe = provider.searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecipeCard(
                        recipe: recipe,
                        isFavorite: provider.isFavorite(recipe),
                        onTap: () {
                          provider.selectRecipe(recipe);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecipeDetailScreen(),
                            ),
                          );
                        },
                        onFavoriteToggle: () => provider.toggleFavorite(recipe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRandomRecipe;

  const _EmptyState({required this.onRandomRecipe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Find Your Next Meal',
              style: AppTextStyles.headline2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search by recipe name or ingredients to discover delicious meals',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: onRandomRecipe,
              icon: const Icon(Icons.casino),
              label: const Text('Try a Random Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}

