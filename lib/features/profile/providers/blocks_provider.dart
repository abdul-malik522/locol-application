import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/profile/data/datasources/blocks_datasource.dart';

final blocksDataSourceProvider =
    Provider<BlocksDataSource>((ref) => BlocksDataSource.instance);

/// Provider to check if a user is blocked
final isBlockedProvider =
    FutureProvider.family<bool, ({String blockerId, String blockedId})>(
  (ref, params) async {
    final dataSource = ref.watch(blocksDataSourceProvider);
    return await dataSource.isBlocked(params.blockerId, params.blockedId);
  },
);

/// Provider to check if two users are mutually blocked
final isMutuallyBlockedProvider =
    FutureProvider.family<bool, ({String userId1, String userId2})>(
  (ref, params) async {
    final dataSource = ref.watch(blocksDataSourceProvider);
    return await dataSource.isMutuallyBlocked(params.userId1, params.userId2);
  },
);

/// Provider to get list of blocked users
final blockedUsersProvider =
    FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final dataSource = ref.watch(blocksDataSourceProvider);
    return await dataSource.getBlockedUsers(userId);
  },
);

/// StateNotifier for block operations
class BlocksNotifier extends StateNotifier<AsyncValue<void>> {
  BlocksNotifier(this._dataSource) : super(const AsyncValue.data(null));

  final BlocksDataSource _dataSource;

  Future<void> blockUser(String blockerId, String blockedId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.blockUser(blockerId, blockedId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> unblockUser(String blockerId, String blockedId) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.unblockUser(blockerId, blockedId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final blocksNotifierProvider =
    StateNotifierProvider<BlocksNotifier, AsyncValue<void>>(
  (ref) {
    final dataSource = ref.watch(blocksDataSourceProvider);
    return BlocksNotifier(dataSource);
  },
);

