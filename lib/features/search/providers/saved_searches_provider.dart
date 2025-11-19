import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart';
import 'package:localtrade/features/search/data/models/saved_search_model.dart';
import 'package:localtrade/features/search/providers/search_provider.dart';

final savedSearchesProvider =
    FutureProvider.family<List<SavedSearchModel>, String>((ref, userId) async {
  final dataSource = ref.watch(searchMockDataSourceProvider);
  return await dataSource.getSavedSearches(userId);
});

