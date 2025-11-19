import 'dart:convert';

import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesDataSource {
  FavoritesDataSource._();
  static final FavoritesDataSource instance = FavoritesDataSource._();

  static const String _favoritesKeyPrefix = 'user_favorites_';

  String _getFavoritesKey(String userId) => '$_favoritesKeyPrefix$userId';

  /// Get all favorite post IDs for a user
  Future<List<String>> getFavoritePostIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_getFavoritesKey(userId));
    if (favoritesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(favoritesJson);
    return decoded.map((e) => e as String).toList();
  }

  /// Check if a post is favorited by user
  Future<bool> isPostFavorited(String userId, String postId) async {
    final favorites = await getFavoritePostIds(userId);
    return favorites.contains(postId);
  }

  /// Add a post to favorites
  Future<void> addToFavorites(String userId, String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = await getFavoritePostIds(userId);
    
    if (!favorites.contains(postId)) {
      favorites.add(postId);
      final String encoded = json.encode(favorites);
      await prefs.setString(_getFavoritesKey(userId), encoded);
    }
  }

  /// Remove a post from favorites
  Future<void> removeFromFavorites(String userId, String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = await getFavoritePostIds(userId);
    
    favorites.remove(postId);
    final String encoded = json.encode(favorites);
    await prefs.setString(_getFavoritesKey(userId), encoded);
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String userId, String postId) async {
    final isFavorited = await isPostFavorited(userId, postId);
    if (isFavorited) {
      await removeFromFavorites(userId, postId);
      return false;
    } else {
      await addToFavorites(userId, postId);
      return true;
    }
  }

  /// Get all favorite posts (requires posts data source to resolve IDs to PostModel)
  Future<List<PostModel>> getFavoritePosts(
    String userId,
    List<PostModel> allPosts,
  ) async {
    final favoriteIds = await getFavoritePostIds(userId);
    return allPosts.where((post) => favoriteIds.contains(post.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

