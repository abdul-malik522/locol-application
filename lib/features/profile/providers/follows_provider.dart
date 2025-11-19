import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/profile/data/datasources/follows_datasource.dart';

final followsDataSourceProvider =
    Provider<FollowsDataSource>((ref) => FollowsDataSource.instance);

/// Provider for checking if current user is following a specific user
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, followingId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.isFollowing(currentUser.id, followingId);
});

/// Provider for getting list of users that current user is following
final followingListProvider = FutureProvider<List<String>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.getFollowing(currentUser.id);
});

/// Provider for getting list of users that a specific user is following
final userFollowingListProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.getFollowing(userId);
});

/// Provider for getting list of users following a specific user
final followersListProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.getFollowers(userId);
});

/// Provider for getting follower count for a user
final followerCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.getFollowerCount(userId);
});

/// Provider for getting following count for a user
final followingCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final dataSource = ref.watch(followsDataSourceProvider);
  return await dataSource.getFollowingCount(userId);
});

/// Notifier for managing follow/unfollow actions
class FollowsNotifier extends StateNotifier<AsyncValue<void>> {
  FollowsNotifier(this._dataSource) : super(const AsyncValue.data(null));

  final FollowsDataSource _dataSource;

  Future<void> followUser(String followerId, String followingId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.followUser(followerId, followingId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.unfollowUser(followerId, followingId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final followsNotifierProvider =
    StateNotifierProvider<FollowsNotifier, AsyncValue<void>>((ref) {
  final dataSource = ref.watch(followsDataSourceProvider);
  return FollowsNotifier(dataSource);
});

