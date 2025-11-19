import 'dart:async';

import 'package:localtrade/features/profile/data/models/block_model.dart';

class BlocksDataSource {
  BlocksDataSource._();
  static final BlocksDataSource instance = BlocksDataSource._();

  final List<BlockModel> _blocks = [];

  /// Block a user
  Future<void> blockUser(String blockerId, String blockedId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (blockerId == blockedId) {
      throw Exception('Cannot block yourself');
    }
    
    // Check if already blocked
    final alreadyBlocked = _blocks.any(
      (block) => block.blockerId == blockerId && block.blockedId == blockedId,
    );
    
    if (alreadyBlocked) {
      return; // Already blocked
    }
    
    _blocks.add(BlockModel(
      blockerId: blockerId,
      blockedId: blockedId,
      createdAt: DateTime.now(),
    ));
  }

  /// Unblock a user
  Future<void> unblockUser(String blockerId, String blockedId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _blocks.removeWhere(
      (block) => block.blockerId == blockerId && block.blockedId == blockedId,
    );
  }

  /// Check if a user is blocked by another user
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _blocks.any(
      (block) => block.blockerId == blockerId && block.blockedId == blockedId,
    );
  }

  /// Check if two users have blocked each other (mutual block)
  Future<bool> isMutuallyBlocked(String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user1BlockedUser2 = await isBlocked(userId1, userId2);
    final user2BlockedUser1 = await isBlocked(userId2, userId1);
    return user1BlockedUser2 || user2BlockedUser1;
  }

  /// Get all blocked user IDs for a user
  Future<List<String>> getBlockedUsers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _blocks
        .where((block) => block.blockerId == userId)
        .map((block) => block.blockedId)
        .toList();
  }

  /// Get all users who have blocked a specific user
  Future<List<String>> getBlockedByUsers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _blocks
        .where((block) => block.blockedId == userId)
        .map((block) => block.blockerId)
        .toList();
  }
}

