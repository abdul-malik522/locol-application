import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.filters = const {},
    this.recentSearches = const [],
  });

  final String query;
  final List<PostModel> results;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> filters;
  final List<String> recentSearches;

  SearchState copyWith({
    String? query,
    List<PostModel>? results,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? filters,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
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

  Future<void> _loadRecentSearches() async {
    if (_userId == null) return;
    final searches = await _dataSource.getRecentSearches(_userId!);
    state = state.copyWith(recentSearches: searches);
  }

  Future<void> search(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately for UI responsiveness
    state = state.copyWith(query: query);

    if (query.isEmpty) {
      state = state.copyWith(results: []);
      return;
    }

    // Debounce search
    _debounceTimer = Timer(AppConstants.defaultDebounceDuration, () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _dataSource.searchPosts(query, state.filters);
      state = state.copyWith(
        results: results,
        isLoading: false,
      );

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
    state = state.copyWith(filters: {});
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

