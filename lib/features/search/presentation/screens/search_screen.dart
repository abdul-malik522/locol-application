import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/search/providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search',
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, searchState),
          if (hasActiveFilters) _buildActiveFilters(context, searchState),
          Expanded(
            child: _buildBody(context, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products, sellers...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).search('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          ref.read(searchProvider.notifier).search(value);
        },
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context, SearchState state) {
    final filters = state.filters;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (filters.containsKey('categories') && filters['categories'] != null)
            ...(filters['categories'] as List<String>).map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(category),
                  onDeleted: () {
                    final categories = List<String>.from(
                      filters['categories'] as List<String>,
                    );
                    categories.remove(category);
                    ref.read(searchProvider.notifier).updateFilters({
                      'categories': categories.isEmpty ? null : categories,
                    });
                  },
                ),
              );
            }),
          if (filters.containsKey('postType') && filters['postType'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filters['postType'] as String),
                onDeleted: () {
                  ref.read(searchProvider.notifier).updateFilters({
                    'postType': null,
                  });
                },
              ),
            ),
          if (filters.containsKey('priceRange') && filters['priceRange'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Price Range'),
                onDeleted: () {
                  ref.read(searchProvider.notifier).updateFilters({
                    'priceRange': null,
                  });
                },
              ),
            ),
          if (filters.containsKey('distance') && filters['distance'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('Within ${filters['distance']} km'),
                onDeleted: () {
                  ref.read(searchProvider.notifier).updateFilters({
                    'distance': null,
                  });
                },
              ),
            ),
          TextButton(
            onPressed: () {
              ref.read(searchProvider.notifier).clearFilters();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchState state) {
    if (state.query.isEmpty) {
      return _buildEmptyState(context, state);
    }

    if (state.isLoading) {
      return const LoadingIndicator();
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(searchProvider.notifier).search(state.query);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No Results Found',
        message: 'No posts match your search "${state.query}"',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${state.results.length} results found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final post = state.results[index];
                    return PostCard(post: post);
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final post = state.results[index];
                    return PostCard(post: post);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, SearchState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryGrid(context),
          const SizedBox(height: 24),
          _buildRecentSearches(context, state),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: AppConstants.categories.length,
            itemBuilder: (context, index) {
              final category = AppConstants.categories[index];
              return InkWell(
                onTap: () {
                  _searchController.text = category;
                  ref.read(searchProvider.notifier).updateFilters({
                    'categories': [category],
                  });
                  ref.read(searchProvider.notifier).search(category);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, SearchState state) {
    if (state.recentSearches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchProvider.notifier).clearRecentSearches();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.recentSearches.map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  ref.read(searchProvider.notifier).selectRecentSearch(query);
                },
                avatar: const Icon(Icons.history, size: 18),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'meat':
        return Icons.set_meal;
      case 'dairy':
        return Icons.local_drink;
      case 'spices':
        return Icons.spa;
      case 'grains':
        return Icons.grain;
      case 'herbs':
        return Icons.forest;
      case 'seafood':
        return Icons.water;
      case 'beverages':
        return Icons.local_bar;
      case 'bakery':
        return Icons.bakery_dining;
      case 'condiments':
        return Icons.restaurant;
      case 'prepared meals':
        return Icons.lunch_dining;
      default:
        return Icons.category;
    }
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late List<String> _selectedCategories;
  String? _selectedPostType;
  double _minPrice = 0;
  double _maxPrice = 100;
  double _distance = 50;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedCategories = [];
  }

  void _initializeFromFilters(Map<String, dynamic> filters) {
    if (_initialized) return;
    _initialized = true;

    if (filters.containsKey('categories') && filters['categories'] != null) {
      _selectedCategories = List<String>.from(filters['categories'] as List<String>);
    }
    if (filters.containsKey('postType') && filters['postType'] != null) {
      _selectedPostType = filters['postType'] as String;
    }
    if (filters.containsKey('priceRange') && filters['priceRange'] != null) {
      final priceRange = filters['priceRange'] as Map<String, double>;
      _minPrice = priceRange['min'] ?? 0;
      _maxPrice = priceRange['max'] ?? 100;
    }
    if (filters.containsKey('distance') && filters['distance'] != null) {
      _distance = filters['distance'] as double;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final filters = searchState.filters;

    _initializeFromFilters(filters);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _buildCategoryFilter(context),
          const SizedBox(height: 24),
          _buildPostTypeFilter(context),
          const SizedBox(height: 24),
          _buildPriceRangeFilter(context),
          const SizedBox(height: 24),
          _buildDistanceFilter(context),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final newFilters = <String, dynamic>{};
                  if (_selectedCategories.isNotEmpty) {
                    newFilters['categories'] = _selectedCategories;
                  }
                  if (_selectedPostType != null) {
                    newFilters['postType'] = _selectedPostType;
                  }
                  if (_minPrice > 0 || _maxPrice < 100) {
                    newFilters['priceRange'] = {
                      'min': _minPrice,
                      'max': _maxPrice,
                    };
                  }
                  if (_distance < 50) {
                    newFilters['distance'] = _distance;
                  }
                  ref.read(searchProvider.notifier).updateFilters(newFilters);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPostTypeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(value: 'products', label: Text('Products')),
            ButtonSegment(value: 'requests', label: Text('Requests')),
            ButtonSegment(value: null, label: Text('Both')),
          ],
          selected: {_selectedPostType},
          onSelectionChanged: (Set<String?> selected) {
            setState(() {
              _selectedPostType = selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: 0,
          max: 100,
          divisions: 20,
          labels: RangeLabels(
            '\$${_minPrice.toStringAsFixed(0)}',
            '\$${_maxPrice.toStringAsFixed(0)}',
          ),
          onChanged: (values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance (km)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Slider(
          value: _distance,
          min: 5,
          max: 100,
          divisions: 19,
          label: '${_distance.toStringAsFixed(0)} km',
          onChanged: (value) {
            setState(() {
              _distance = value;
            });
          },
        ),
      ],
    );
  }
}
