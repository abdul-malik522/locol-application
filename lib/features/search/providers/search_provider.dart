import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart'
    show SearchMockDataSource, SearchSuggestionType;
import 'package:localtrade/features/search/data/models/saved_search_model.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.userResults = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.isLoadingSuggestions = false,
    this.error,
    this.filters = const {},
    this.recentSearches = const [],
    this.searchType = SearchType.posts,
    this.showSuggestions = false,
    this.sortBy,
  });

  final String query;
  final List<PostModel> results;
  final List<UserModel> userResults;
  final List<String> suggestions;
  final bool isLoading;
  final bool isLoadingSuggestions;
  final String? error;
  final Map<String, dynamic> filters;
  final List<String> recentSearches;
  final SearchType searchType;
  final bool showSuggestions;
  final String? sortBy;

  SearchState copyWith({
    String? query,
    List<PostModel>? results,
    List<UserModel>? userResults,
    List<String>? suggestions,
    bool? isLoading,
    bool? isLoadingSuggestions,
    String? error,
    Map<String, dynamic>? filters,
    List<String>? recentSearches,
    SearchType? searchType,
    bool? showSuggestions,
    String? sortBy,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      userResults: userResults ?? this.userResults,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      error: error,
      filters: filters ?? this.filters,
      recentSearches: recentSearches ?? this.recentSearches,
      searchType: searchType ?? this.searchType,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum SearchType {
  posts('Posts'),
  users('Users');

  const SearchType(this.label);
  final String label;
}

final searchMockDataSourceProvider =
    Provider<SearchMockDataSource>((ref) => SearchMockDataSource.instance);

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._dataSource, this._userId) : super(const SearchState()) {
    _loadRecentSearches();
  }

  final SearchMockDataSource _dataSource;
  final String? _userId;
  Timer? _debounceTimer;
  Timer? _suggestionTimer;

  Future<void> _loadRecentSearches() async {
    if (_userId == null) return;
    final searches = await _dataSource.getRecentSearches(_userId!);
    state = state.copyWith(recentSearches: searches);
  }

  Future<void> search(String query) async {
    // Cancel previous timers
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();

    // Update query immediately for UI responsiveness
    state = state.copyWith(
      query: query,
      showSuggestions: query.isNotEmpty && state.results.isEmpty && state.userResults.isEmpty,
    );

    if (query.isEmpty) {
      state = state.copyWith(
        results: [],
        userResults: [],
        suggestions: [],
        showSuggestions: false,
      );
      return;
    }

    // Fetch suggestions immediately (faster debounce)
    _suggestionTimer = Timer(const Duration(milliseconds: 200), () async {
      await _fetchSuggestions(query);
    });

    // Debounce full search
    _debounceTimer = Timer(AppConstants.defaultDebounceDuration, () async {
      await _performSearch(query);
      // Hide suggestions after search is performed
      state = state.copyWith(showSuggestions: false);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestions: [], isLoadingSuggestions: false);
      return;
    }

    state = state.copyWith(isLoadingSuggestions: true);

    try {
      final suggestionType = state.searchType == SearchType.posts
          ? SearchSuggestionType.posts
          : SearchSuggestionType.users;
      final suggestions = await _dataSource.getSearchSuggestions(query, suggestionType);
      state = state.copyWith(
        suggestions: suggestions,
        isLoadingSuggestions: false,
        showSuggestions: suggestions.isNotEmpty && state.results.isEmpty && state.userResults.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        suggestions: [],
        isLoadingSuggestions: false,
      );
    }
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.searchType == SearchType.posts) {
        final results = await _dataSource.searchPosts(query, state.filters, sortBy: state.sortBy);
        state = state.copyWith(
          results: results,
          isLoading: false,
        );
      } else {
        final userResults = await _dataSource.searchUsers(query);
        state = state.copyWith(
          userResults: userResults,
          isLoading: false,
        );
      }

      // Save to recent searches
      if (query.isNotEmpty && _userId != null) {
        await _dataSource.saveRecentSearch(_userId!, query);
        await _loadRecentSearches();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  Future<void> setSearchType(SearchType type) async {
    state = state.copyWith(searchType: type, suggestions: [], showSuggestions: false);
    if (state.query.isNotEmpty) {
      await _performSearch(state.query);
    }
  }

  void selectSuggestion(String suggestion) {
    state = state.copyWith(
      query: suggestion,
      showSuggestions: false,
    );
    // Trigger search with selected suggestion
    search(suggestion);
  }

  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false);
  }

  Future<void> updateFilters(Map<String, dynamic> newFilters) async {
    final mergedFilters = <String, dynamic>{...state.filters};
    newFilters.forEach((key, value) {
      if (value == null) {
        mergedFilters.remove(key);
      } else {
        mergedFilters[key] = value;
      }
    });
    state = state.copyWith(filters: mergedFilters);
    if (state.query.isNotEmpty) {
      await _performSearch(state.query);
    }
  }

  Future<void> clearFilters() async {
    state = state.copyWith(filters: {}, sortBy: null);
    if (state.query.isNotEmpty) {
      await _performSearch(state.query);
    }
  }

  Future<void> setSortBy(String? sortBy) async {
    state = state.copyWith(sortBy: sortBy);
    if (state.query.isNotEmpty) {
      await _performSearch(state.query);
    }
  }

  Future<void> selectRecentSearch(String query) async {
    state = state.copyWith(query: query);
    await _performSearch(query);
  }

  Future<void> clearRecentSearches() async {
    if (_userId == null) return;
    await _dataSource.clearRecentSearches(_userId!);
    state = state.copyWith(recentSearches: []);
  }

  /// Load saved searches
  Future<void> loadSavedSearches() async {
    if (_userId == null) return;
    try {
      final savedSearches = await _dataSource.getSavedSearches(_userId!);
      // Note: We don't store saved searches in state, they're loaded on demand
    } catch (e) {
      // Handle error silently or log it
      print('Error loading saved searches: $e');
    }
  }

  /// Save current search
  Future<SavedSearchModel> saveCurrentSearch(String name) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final savedSearch = SavedSearchModel(
      id: '', // Will be generated
      userId: _userId!,
      name: name,
      query: state.query,
      filters: Map<String, dynamic>.from(state.filters),
      searchType: state.searchType,
    );

    return await _dataSource.saveSearch(savedSearch);
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String savedSearchId) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
    await _dataSource.deleteSavedSearch(savedSearchId, _userId!);
  }

  /// Load a saved search (apply its query and filters)
  Future<void> loadSavedSearch(SavedSearchModel savedSearch) async {
    state = state.copyWith(
      query: savedSearch.query,
      filters: Map<String, dynamic>.from(savedSearch.filters),
      searchType: savedSearch.searchType,
    );
    await search(savedSearch.query);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final dataSource = ref.watch(searchMockDataSourceProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  return SearchNotifier(dataSource, userId);
});

final searchResultsProvider = Provider<List<PostModel>>((ref) {
  return ref.watch(searchProvider).results;
});

final hasActiveFiltersProvider = Provider<bool>((ref) {
  final filters = ref.watch(searchProvider).filters;
  return filters.isNotEmpty;
});
