import 'dart:async';
import 'dart:convert';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/search/data/models/saved_search_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

enum SearchSuggestionType {
  posts,
  users,
}

class SearchMockDataSource {
  SearchMockDataSource._();
  static final SearchMockDataSource instance = SearchMockDataSource._();

  final _uuid = const Uuid();
  final Map<String, List<String>> _recentSearches = {};
  final PostsMockDataSource _postsDataSource = PostsMockDataSource.instance;
  final AuthMockDataSource _authDataSource = AuthMockDataSource.instance;

  static const String _savedSearchesKeyPrefix = 'saved_searches_';

  String _getSavedSearchesKey(String userId) => '$_savedSearchesKeyPrefix$userId';

  Future<List<PostModel>> searchPosts(
    String query,
    Map<String, dynamic> filters, {
    String? sortBy,
  }) async {
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

      // Seller rating filter
      if (filters.containsKey('minRating') &&
          filters['minRating'] != null) {
        final minRating = filters['minRating'] as double;
        // Get user rating from auth datasource
        // Note: In a real app, this would be async, but for mock we'll check synchronously
        // For now, we'll skip this filter in the where clause and apply it after
        // This is a limitation of the mock implementation
      }

      // Availability filter
      if (filters.containsKey('availability') &&
          filters['availability'] != null) {
        final availability = filters['availability'] as String;
        // Check if post has inventory/stock info
        // For now, we'll use a simple check - in a real app, this would check inventory
        if (availability == 'inStock' && post.quantity != null && post.quantity!.isEmpty) {
          return false;
        }
        if (availability == 'outOfStock' && post.quantity != null && post.quantity!.isNotEmpty) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply seller rating filter after initial filtering (since it requires async call)
    if (filters.containsKey('minRating') && filters['minRating'] != null) {
      final minRating = filters['minRating'] as double;
      final filteredResults = <PostModel>[];
      for (final post in results) {
        final user = await _authDataSource.getUserById(post.userId);
        if (user != null && user.rating >= minRating) {
          filteredResults.add(post);
        }
      }
      results = filteredResults;
    }

    // Apply sorting
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          results.sort((a, b) {
            final aPrice = a.price ?? 0;
            final bPrice = b.price ?? 0;
            return aPrice.compareTo(bPrice);
          });
          break;
        case 'price_desc':
          results.sort((a, b) {
            final aPrice = a.price ?? 0;
            final bPrice = b.price ?? 0;
            return bPrice.compareTo(aPrice);
          });
          break;
        case 'distance':
          if (filters.containsKey('userLocation') &&
              filters['userLocation'] != null) {
            final userLocation = filters['userLocation'] as Map<String, double>;
            final userLat = userLocation['lat']!;
            final userLon = userLocation['lon']!;
            results.sort((a, b) {
              final aDistance = LocationHelper.calculateDistance(
                userLat,
                userLon,
                a.latitude,
                a.longitude,
              );
              final bDistance = LocationHelper.calculateDistance(
                userLat,
                userLon,
                b.latitude,
                b.longitude,
              );
              return aDistance.compareTo(bDistance);
            });
          }
          break;
        case 'rating':
          // Sort by seller rating (would need to fetch user ratings)
          results.sort((a, b) {
            // Mock: return 0 for now, in real app would compare user ratings
            return 0;
          });
          break;
        case 'newest':
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'oldest':
          results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        default:
          // Default: Sort by relevance (exact match > starts with > contains)
          results.sort((a, b) {
            final queryLower = query.toLowerCase();
            final aTitleLower = a.title.toLowerCase();
            final bTitleLower = b.title.toLowerCase();

            if (aTitleLower == queryLower && bTitleLower != queryLower) {
              return -1;
            }
            if (aTitleLower != queryLower && bTitleLower == queryLower) {
              return 1;
            }
            if (aTitleLower.startsWith(queryLower) &&
                !bTitleLower.startsWith(queryLower)) {
              return -1;
            }
            if (!aTitleLower.startsWith(queryLower) &&
                bTitleLower.startsWith(queryLower)) {
              return 1;
            }

            return 0;
          });
      }
    } else {
      // Default: Sort by relevance
      results.sort((a, b) {
        final queryLower = query.toLowerCase();
        final aTitleLower = a.title.toLowerCase();
        final bTitleLower = b.title.toLowerCase();

        if (aTitleLower == queryLower && bTitleLower != queryLower) {
          return -1;
        }
        if (aTitleLower != queryLower && bTitleLower == queryLower) {
          return 1;
        }
        if (aTitleLower.startsWith(queryLower) &&
            !bTitleLower.startsWith(queryLower)) {
          return -1;
        }
        if (!aTitleLower.startsWith(queryLower) &&
            bTitleLower.startsWith(queryLower)) {
          return 1;
        }

        return 0;
      });
    }

    return results;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase();
    final results = <UserModel>[];

    // Get all users from auth mock datasource
    // In a real app, this would query the user database
    // For mock, we'll create a list of sample users based on existing mock data
    final allUsers = _getMockUsers();

    // Filter users by name, business name, or email
    for (final user in allUsers) {
      final matchesName = user.name.toLowerCase().contains(queryLower);
      final matchesBusiness = (user.businessName ?? '').toLowerCase().contains(queryLower);
      final matchesEmail = user.email.toLowerCase().contains(queryLower);

      if (matchesName || matchesBusiness || matchesEmail) {
        results.add(user);
      }
    }

    // Sort by relevance (exact match > starts with > contains)
    results.sort((a, b) {
      final aNameLower = a.name.toLowerCase();
      final bNameLower = b.name.toLowerCase();
      final aBusinessLower = (a.businessName ?? '').toLowerCase();
      final bBusinessLower = (b.businessName ?? '').toLowerCase();

      // Exact match priority
      if (aNameLower == queryLower && bNameLower != queryLower) return -1;
      if (aNameLower != queryLower && bNameLower == queryLower) return 1;
      if (aBusinessLower == queryLower && bBusinessLower != queryLower) return -1;
      if (aBusinessLower != queryLower && bBusinessLower == queryLower) return 1;

      // Starts with priority
      if (aNameLower.startsWith(queryLower) && !bNameLower.startsWith(queryLower)) return -1;
      if (!aNameLower.startsWith(queryLower) && bNameLower.startsWith(queryLower)) return 1;
      if (aBusinessLower.startsWith(queryLower) && !bBusinessLower.startsWith(queryLower)) return -1;
      if (!aBusinessLower.startsWith(queryLower) && bBusinessLower.startsWith(queryLower)) return 1;

      // Alphabetical order for same relevance
      return aNameLower.compareTo(bNameLower);
    });

    return results;
  }

  /// Get mock users for search (simulates user database)
  List<UserModel> _getMockUsers() {
    // In a real app, this would fetch from a user database
    // For mock, we'll return a list based on the users that exist in posts
    // This is a simplified approach - in production, you'd have a proper user service
    return [
      UserModel(
        id: 'user-001',
        email: 'amelia@example.com',
        name: 'Amelia Fields',
        role: UserRole.seller,
        businessName: 'Fields Farm',
        businessDescription: 'Organic produce farm',
        phoneNumber: '+1 (555) 123-4567',
        address: '123 Farm Road, Green Valley',
        latitude: 37.7749,
        longitude: -122.4194,
        profileImageUrl: 'https://i.pravatar.cc/150?img=5',
        rating: 4.8,
      ),
      UserModel(
        id: 'user-002',
        email: 'james@example.com',
        name: 'James Restaurant',
        role: UserRole.restaurant,
        businessName: 'Farm to Table Bistro',
        businessDescription: 'Local ingredients restaurant',
        phoneNumber: '+1 (555) 234-5678',
        address: '456 Main Street, Downtown',
        latitude: 37.7849,
        longitude: -122.4094,
        profileImageUrl: 'https://i.pravatar.cc/150?img=12',
        rating: 4.9,
      ),
      UserModel(
        id: 'user-003',
        email: 'maria@example.com',
        name: 'Maria Garcia',
        role: UserRole.seller,
        businessName: 'Garcia Gardens',
        businessDescription: 'Fresh vegetables and herbs',
        phoneNumber: '+1 (555) 345-6789',
        address: '789 Garden Lane, Riverside',
        latitude: 37.7949,
        longitude: -122.3994,
        profileImageUrl: 'https://i.pravatar.cc/150?img=20',
        rating: 4.7,
      ),
      UserModel(
        id: 'user-004',
        email: 'chef@example.com',
        name: 'Chef Michael',
        role: UserRole.restaurant,
        businessName: 'The Local Kitchen',
        businessDescription: 'Seasonal menu with local produce',
        phoneNumber: '+1 (555) 456-7890',
        address: '321 Culinary Avenue, Food District',
        latitude: 37.8049,
        longitude: -122.3894,
        profileImageUrl: 'https://i.pravatar.cc/150?img=33',
        rating: 4.6,
      ),
      UserModel(
        id: 'user-005',
        email: 'tom@example.com',
        name: 'Tom Anderson',
        role: UserRole.seller,
        businessName: 'Anderson Orchard',
        businessDescription: 'Fresh fruits and vegetables',
        phoneNumber: '+1 (555) 567-8901',
        address: '654 Orchard Way, Countryside',
        latitude: 37.8149,
        longitude: -122.3794,
        profileImageUrl: 'https://i.pravatar.cc/150?img=47',
        rating: 4.5,
      ),
    ];
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query, SearchSuggestionType type) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (query.isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase();
    final suggestions = <String>[];

    if (type == SearchSuggestionType.posts) {
      // Get suggestions from post titles, categories, and user names
      final allPosts = await _postsDataSource.getPosts(1, 1000, null);
      
      // Collect unique suggestions
      final seen = <String>{};
      
      for (final post in allPosts) {
        // Title suggestions
        if (post.title.toLowerCase().contains(queryLower) && 
            post.title.toLowerCase().startsWith(queryLower)) {
          if (!seen.contains(post.title)) {
            suggestions.add(post.title);
            seen.add(post.title);
          }
        }
        
        // Category suggestions
        if (post.category.toLowerCase().contains(queryLower) && 
            post.category.toLowerCase().startsWith(queryLower)) {
          if (!seen.contains(post.category)) {
            suggestions.add(post.category);
            seen.add(post.category);
          }
        }
        
        // User name suggestions
        if (post.userName.toLowerCase().contains(queryLower) && 
            post.userName.toLowerCase().startsWith(queryLower)) {
          if (!seen.contains(post.userName)) {
            suggestions.add(post.userName);
            seen.add(post.userName);
          }
        }
      }
    } else {
      // Get suggestions from user names and business names
      final allUsers = _getMockUsers();
      final seen = <String>{};
      
      for (final user in allUsers) {
        // Name suggestions
        if (user.name.toLowerCase().contains(queryLower) && 
            user.name.toLowerCase().startsWith(queryLower)) {
          if (!seen.contains(user.name)) {
            suggestions.add(user.name);
            seen.add(user.name);
          }
        }
        
        // Business name suggestions
        if (user.businessName != null && 
            user.businessName!.toLowerCase().contains(queryLower) && 
            user.businessName!.toLowerCase().startsWith(queryLower)) {
          if (!seen.contains(user.businessName!)) {
            suggestions.add(user.businessName!);
            seen.add(user.businessName!);
          }
        }
      }
    }

    // Sort by relevance (starts with > contains) and limit to 5
    suggestions.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      final aStartsWith = aLower.startsWith(queryLower);
      final bStartsWith = bLower.startsWith(queryLower);
      
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      
      return aLower.compareTo(bLower);
    });

    return suggestions.take(5).toList();
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

  /// Get all saved searches for a user
  Future<List<SavedSearchModel>> getSavedSearches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? searchesJson = prefs.getString(_getSavedSearchesKey(userId));
    if (searchesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(searchesJson);
    return decoded
        .map((e) => SavedSearchModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Most recent first
  }

  /// Save a search query with filters
  Future<SavedSearchModel> saveSearch(SavedSearchModel savedSearch) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SavedSearchModel> existingSearches = await getSavedSearches(savedSearch.userId);

    // Generate ID if not provided
    final searchWithId = savedSearch.id.isEmpty
        ? savedSearch.copyWith(id: _uuid.v4())
        : savedSearch;

    // Check if a search with the same query and filters already exists
    final existingIndex = existingSearches.indexWhere((s) =>
        s.query == searchWithId.query &&
        _mapsEqual(s.filters, searchWithId.filters) &&
        s.searchType == searchWithId.searchType);

    if (existingIndex != -1) {
      // Update existing saved search
      existingSearches[existingIndex] = searchWithId.copyWith(
        updatedAt: DateTime.now(),
      );
    } else {
      // Add new saved search
      existingSearches.add(searchWithId);
    }

    // Sort by most recent first
    existingSearches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final String encoded =
        json.encode(existingSearches.map((e) => e.toJson()).toList());
    await prefs.setString(_getSavedSearchesKey(searchWithId.userId), encoded);

    return searchWithId;
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String savedSearchId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<SavedSearchModel> existingSearches = await getSavedSearches(userId);
    existingSearches.removeWhere((s) => s.id == savedSearchId);

    final String encoded =
        json.encode(existingSearches.map((e) => e.toJson()).toList());
    await prefs.setString(_getSavedSearchesKey(userId), encoded);
  }

  /// Helper method to compare maps
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      if (map1[key] != map2[key]) {
        // Handle list comparison
        if (map1[key] is List && map2[key] is List) {
          final list1 = map1[key] as List;
          final list2 = map2[key] as List;
          if (list1.length != list2.length) return false;
          for (int i = 0; i < list1.length; i++) {
            if (list1[i] != list2[i]) return false;
          }
        } else if (map1[key] is Map && map2[key] is Map) {
          if (!_mapsEqual(
              map1[key] as Map<String, dynamic>,
              map2[key] as Map<String, dynamic>)) {
            return false;
          }
        } else {
          return false;
        }
      }
    }
    return true;
  }
}
