import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/search/data/models/saved_search_model.dart';
import 'package:localtrade/features/search/providers/saved_searches_provider.dart';
import 'package:localtrade/features/search/providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isGridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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
          if (searchState.query.isNotEmpty || searchState.filters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () => _showSaveSearchDialog(context, searchState),
              tooltip: 'Save Search',
            ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _showSavedSearchesDialog(context),
            tooltip: 'Saved Searches',
          ),
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(context, searchState),
              _buildSearchTypeTabs(context, searchState),
              if (hasActiveFilters && searchState.searchType == SearchType.posts)
                _buildActiveFilters(context, searchState),
              Expanded(
                child: _buildBody(context, searchState),
              ),
            ],
          ),
          if (searchState.showSuggestions && searchState.query.isNotEmpty)
            Stack(
              children: [
                // Backdrop
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(searchProvider.notifier).hideSuggestions();
                      _focusNode.unfocus();
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
                // Suggestions overlay
                _buildSuggestionsOverlay(context, searchState),
              ],
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
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: state.searchType == SearchType.posts
              ? 'Search products, sellers...'
              : 'Search users by name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).search('');
                    _focusNode.unfocus();
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
        onTap: () {
          if (state.query.isNotEmpty && state.suggestions.isNotEmpty) {
            final notifier = ref.read(searchProvider.notifier);
            notifier.state = notifier.state.copyWith(showSuggestions: true);
          }
        },
        onSubmitted: (value) {
          ref.read(searchProvider.notifier).hideSuggestions();
          _focusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildSuggestionsOverlay(BuildContext context, SearchState state) {
    return Positioned(
      top: 80, // Below search bar
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: state.isLoadingSuggestions
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : state.suggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No suggestions found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.suggestions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = state.suggestions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.search,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            ref.read(searchProvider.notifier).selectSuggestion(suggestion);
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
        ),
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
          if (filters.containsKey('minRating') && filters['minRating'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('Rating ≥ ${(filters['minRating'] as double).toStringAsFixed(1)}'),
                onDeleted: () {
                  ref.read(searchProvider.notifier).updateFilters({
                    'minRating': null,
                  });
                },
              ),
            ),
          if (filters.containsKey('availability') && filters['availability'] != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(filters['availability'] == 'inStock' ? 'In Stock' : 'Out of Stock'),
                onDeleted: () {
                  ref.read(searchProvider.notifier).updateFilters({
                    'availability': null,
                  });
                },
              ),
            ),
          if (state.sortBy != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_getSortLabel(state.sortBy!)),
                onDeleted: () {
                  ref.read(searchProvider.notifier).setSortBy(null);
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

    if (state.searchType == SearchType.posts) {
      if (state.results.isEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'No Results Found',
          message: 'No posts match your search "${state.query}"',
        );
      }

      return _buildPostResults(context, state);
    } else {
      if (state.userResults.isEmpty) {
        return EmptyState(
          icon: Icons.person_off,
          title: 'No Users Found',
          message: 'No users match your search "${state.query}"',
        );
      }

      return _buildUserResults(context, state);
    }
  }

  Widget _buildPostResults(BuildContext context, SearchState state) {
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

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'price_asc':
        return 'Price: Low to High';
      case 'price_desc':
        return 'Price: High to Low';
      case 'distance':
        return 'Distance';
      case 'rating':
        return 'Rating';
      default:
        return 'Relevance';
    }
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

  Widget _buildSearchTypeTabs(BuildContext context, SearchState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              context,
              'Posts',
              SearchType.posts,
              state.searchType == SearchType.posts,
              Icons.grid_view,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              context,
              'Users',
              SearchType.users,
              state.searchType == SearchType.users,
              Icons.people,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String label,
    SearchType type,
    bool isSelected,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        ref.read(searchProvider.notifier).setSearchType(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserResults(BuildContext context, SearchState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${state.userResults.length} users found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.userResults.length,
            itemBuilder: (context, index) {
              final user = state.userResults[index];
              return _buildUserCard(context, user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/profile/${user.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Icon(
                        user.role.icon,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.businessName ?? user.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.rating > 0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                    if (user.businessName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          user.role.icon,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.role.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    if (user.businessDescription != null &&
                        user.businessDescription!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.businessDescription!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaveSearchDialog(BuildContext context, SearchState state) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Search'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Search Name',
              hintText: 'e.g., Fresh Vegetables Near Me',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a name for this search';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login to save searches')),
            );
          }
          return;
        }

        await ref.read(searchProvider.notifier).saveCurrentSearch(nameController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search saved successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save search: ${e.toString()}')),
          );
        }
      }
    }

    nameController.dispose();
  }

  Future<void> _showSavedSearchesDialog(BuildContext context) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view saved searches')),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved Searches',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final savedSearchesAsync = ref.watch(savedSearchesProvider(currentUser.id));

                    return savedSearchesAsync.when(
                      data: (savedSearches) {
                        if (savedSearches.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Saved Searches',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Save your frequent searches for quick access',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: savedSearches.length,
                          itemBuilder: (context, index) {
                            final savedSearch = savedSearches[index];
                            return _buildSavedSearchItem(context, ref, savedSearch, currentUser.id, _searchController);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading saved searches: ${error.toString()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSearchItem(
    BuildContext context,
    WidgetRef ref,
    SavedSearchModel savedSearch,
    String userId,
    TextEditingController searchController,
  ) {
    final hasFilters = savedSearch.filters.isNotEmpty;
    final filterCount = savedSearch.filters.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          savedSearch.searchType == SearchType.posts ? Icons.grid_view : Icons.people,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          savedSearch.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (savedSearch.query.isNotEmpty)
              Text(
                'Query: "${savedSearch.query}"',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (hasFilters)
              Text(
                '$filterCount filter${filterCount > 1 ? 's' : ''} applied',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'load') {
              await ref.read(searchProvider.notifier).loadSavedSearch(savedSearch);
              searchController.text = savedSearch.query;
              Navigator.pop(context); // Close saved searches dialog
            } else if (value == 'delete') {
              _deleteSavedSearch(context, ref, savedSearch.id, userId);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'load',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Load Search'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          await ref.read(searchProvider.notifier).loadSavedSearch(savedSearch);
          searchController.text = savedSearch.query;
          Navigator.pop(context); // Close saved searches dialog
        },
      ),
    );
  }

  Future<void> _deleteSavedSearch(
    BuildContext context,
    WidgetRef ref,
    String savedSearchId,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: const Text('Are you sure you want to delete this saved search?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(searchProvider.notifier).deleteSavedSearch(savedSearchId);
        ref.invalidate(savedSearchesProvider(userId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved search deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
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
  double _minRating = 0;
  String? _availability;
  String? _sortBy;
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
    if (filters.containsKey('minRating') && filters['minRating'] != null) {
      _minRating = filters['minRating'] as double;
    }
    if (filters.containsKey('availability') && filters['availability'] != null) {
      _availability = filters['availability'] as String;
    }
    final searchState = ref.read(searchProvider);
    _sortBy = searchState.sortBy;
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
          _buildRatingFilter(context),
          const SizedBox(height: 24),
          _buildAvailabilityFilter(context),
          const SizedBox(height: 24),
          _buildSortOptions(context),
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
                  if (_minRating > 0) {
                    newFilters['minRating'] = _minRating;
                  }
                  if (_availability != null) {
                    newFilters['availability'] = _availability;
                  }
                  ref.read(searchProvider.notifier).updateFilters(newFilters);
                  if (_sortBy != null) {
                    ref.read(searchProvider.notifier).setSortBy(_sortBy);
                  }
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

  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Seller Rating',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                  });
                },
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                _minRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(value: 'inStock', label: Text('In Stock')),
            ButtonSegment(value: 'outOfStock', label: Text('Out of Stock')),
            ButtonSegment(value: null, label: Text('All')),
          ],
          selected: {_availability},
          onSelectionChanged: (Set<String?> selected) {
            setState(() {
              _availability = selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Relevance')),
            ButtonSegment(value: 'newest', label: Text('Newest')),
            ButtonSegment(value: 'price_asc', label: Text('Price ↑')),
            ButtonSegment(value: 'price_desc', label: Text('Price ↓')),
            ButtonSegment(value: 'distance', label: Text('Distance')),
            ButtonSegment(value: 'rating', label: Text('Rating')),
          ],
          selected: {_sortBy},
          onSelectionChanged: (Set<String?> selected) {
            setState(() {
              _sortBy = selected.first;
            });
          },
        ),
      ],
    );
  }
}
