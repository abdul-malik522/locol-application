import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/home/data/datasources/favorites_datasource.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

final favoritesDataSourceProvider =
    Provider<FavoritesDataSource>((ref) => FavoritesDataSource.instance);

/// Provider to get favorite post IDs for a user
final favoritePostIdsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final dataSource = ref.watch(favoritesDataSourceProvider);
  return await dataSource.getFavoritePostIds(userId);
});

/// Provider to check if a post is favorited
final isPostFavoritedProvider =
    FutureProvider.family<bool, ({String userId, String postId})>((ref, params) async {
  final dataSource = ref.watch(favoritesDataSourceProvider);
  return await dataSource.isPostFavorited(params.userId, params.postId);
});

/// Provider to get all favorite posts for a user
final favoritePostsProvider =
    FutureProvider.family<List<PostModel>, String>((ref, userId) async {
  final dataSource = ref.watch(favoritesDataSourceProvider);
  final postsNotifier = ref.watch(postsProvider.notifier);
  
  // Get all posts (we'll filter favorites from this)
  final allPosts = ref.watch(postsProvider).posts;
  
  return await dataSource.getFavoritePosts(userId, allPosts);
});

/// Notifier for managing favorites state
class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  FavoritesNotifier(this._dataSource, this._userId)
      : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  final FavoritesDataSource _dataSource;
  final String _userId;

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final favorites = await _dataSource.getFavoritePostIds(_userId);
      state = AsyncValue.data(favorites);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> toggleFavorite(String postId) async {
    try {
      final newStatus = await _dataSource.toggleFavorite(_userId, postId);
      await loadFavorites(); // Reload to update state
      return newStatus;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addToFavorites(String postId) async {
    try {
      await _dataSource.addToFavorites(_userId, postId);
      await loadFavorites();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String postId) async {
    try {
      await _dataSource.removeFromFavorites(_userId, postId);
      await loadFavorites();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final favoritesNotifierProvider =
    StateNotifierProvider.family<FavoritesNotifier, AsyncValue<List<String>>, String>(
        (ref, userId) {
  final dataSource = ref.watch(favoritesDataSourceProvider);
  return FavoritesNotifier(dataSource, userId);
});

