import 'dart:async';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';

class SearchMockDataSource {
  SearchMockDataSource._();
  static final SearchMockDataSource instance = SearchMockDataSource._();

  final Map<String, List<String>> _recentSearches = {};
  final PostsMockDataSource _postsDataSource = PostsMockDataSource.instance;
  final AuthMockDataSource _authDataSource = AuthMockDataSource.instance;

  Future<List<PostModel>> searchPosts(
    String query,
    Map<String, dynamic> filters,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all posts from mock datasource
    final allPosts = await _postsDataSource.getPosts(1, 1000, null);

    var results = allPosts.where((post) {
      // Text search
      final queryLower = query.toLowerCase();
      final matchesText = query.isEmpty ||
          post.title.toLowerCase().contains(queryLower) ||
          post.description.toLowerCase().contains(queryLower) ||
          post.userName.toLowerCase().contains(queryLower) ||
          post.category.toLowerCase().contains(queryLower);

      if (!matchesText) return false;

      // Category filter
      if (filters.containsKey('categories') &&
          filters['categories'] != null) {
        final selectedCategories = filters['categories'] as List<String>;
        if (!selectedCategories.contains(post.category)) return false;
      }

      // Post type filter
      if (filters.containsKey('postType') && filters['postType'] != null) {
        final postType = filters['postType'] as String;
        if (postType == 'products' && post.postType != PostType.product) {
          return false;
        }
        if (postType == 'requests' && post.postType != PostType.request) {
          return false;
        }
      }

      // Price range filter
      if (filters.containsKey('priceRange') &&
          filters['priceRange'] != null &&
          post.price != null) {
        final priceRange = filters['priceRange'] as Map<String, double>;
        final minPrice = priceRange['min'] ?? 0;
        final maxPrice = priceRange['max'] ?? double.infinity;
        if (post.price! < minPrice || post.price! > maxPrice) {
          return false;
        }
      }

      // Distance filter
      if (filters.containsKey('distance') &&
          filters['distance'] != null &&
          filters.containsKey('userLocation') &&
          filters['userLocation'] != null) {
        final maxDistance = filters['distance'] as double;
        final userLocation = filters['userLocation'] as Map<String, double>;
        final userLat = userLocation['lat']!;
        final userLon = userLocation['lon']!;

        final distance = LocationHelper.calculateDistance(
          userLat,
          userLon,
          post.latitude,
          post.longitude,
        );

        if (distance > maxDistance) return false;
      }

      return true;
    }).toList();

    // Sort by relevance (exact match > starts with > contains)
    results.sort((a, b) {
      final queryLower = query.toLowerCase();
      final aTitleLower = a.title.toLowerCase();
      final bTitleLower = b.title.toLowerCase();

      if (aTitleLower == queryLower && bTitleLower != queryLower) return -1;
      if (aTitleLower != queryLower && bTitleLower == queryLower) return 1;
      if (aTitleLower.startsWith(queryLower) &&
          !bTitleLower.startsWith(queryLower)) return -1;
      if (!aTitleLower.startsWith(queryLower) &&
          bTitleLower.startsWith(queryLower)) return 1;

      return 0;
    });

    return results;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all users from auth mock datasource
    final queryLower = query.toLowerCase();
    final results = <UserModel>[];

    // Since we don't have direct access to users list, we'll simulate
    // In a real app, this would query the user database
    // For now, return empty list as users are managed in auth datasource
    return results;
  }

  Future<List<String>> getRecentSearches(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _recentSearches[userId] ?? [];
  }

  Future<void> saveRecentSearch(String userId, String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final searches = _recentSearches.putIfAbsent(userId, () => []);
    searches.remove(query); // Remove if exists
    searches.insert(0, query); // Add to beginning
    if (searches.length > 10) {
      searches.removeRange(10, searches.length); // Keep only 10
    }
  }

  Future<void> clearRecentSearches(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _recentSearches.remove(userId);
  }
}

