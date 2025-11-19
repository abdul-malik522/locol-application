import 'dart:async';

import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/notifications/data/datasources/notifications_mock_datasource.dart';
import 'package:localtrade/features/notifications/data/models/notification_model.dart';
import 'package:localtrade/features/profile/data/models/follow_model.dart';

class FollowsDataSource {
  FollowsDataSource._();
  static final FollowsDataSource instance = FollowsDataSource._();

  final List<FollowModel> _follows = [];

  /// Get list of user IDs that a user is following
  Future<List<String>> getFollowing(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _follows
        .where((follow) => follow.followerId == userId)
        .map((follow) => follow.followingId)
        .toList();
  }

  /// Get list of user IDs that are following a user
  Future<List<String>> getFollowers(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _follows
        .where((follow) => follow.followingId == userId)
        .map((follow) => follow.followerId)
        .toList();
  }

  /// Check if a user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.any(
      (follow) =>
          follow.followerId == followerId &&
          follow.followingId == followingId,
    );
  }

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Check if already following
    final alreadyFollowing = _follows.any(
      (follow) =>
          follow.followerId == followerId &&
          follow.followingId == followingId,
    );

    if (alreadyFollowing) {
      return; // Already following
    }

    // Prevent self-follow
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    _follows.add(FollowModel(
      followerId: followerId,
      followingId: followingId,
      createdAt: DateTime.now(),
    ));

    // Create follow notification for the user being followed
    await _createFollowNotification(followerId, followingId);
  }

  /// Create a notification when someone follows a user
  Future<void> _createFollowNotification(
    String followerId,
    String followingId,
  ) async {
    try {
      // Get follower's name from auth datasource
      final authDataSource = AuthMockDataSource.instance;
      final follower = await authDataSource.getUserById(followerId);
      
      if (follower == null) return;

      final followerName = follower.businessName ?? follower.name;

      // Create notification for the user being followed
      await NotificationsMockDataSource.instance.createNotification(
        userId: followingId,
        type: NotificationType.follow,
        title: 'New Follower',
        body: '$followerName started following you',
        imageUrl: follower.profileImageUrl,
        relatedId: followerId, // Link to follower's profile
      );
    } catch (e) {
      // Silently fail - notification creation shouldn't break follow functionality
      print('Failed to create follow notification: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _follows.removeWhere(
      (follow) =>
          follow.followerId == followerId &&
          follow.followingId == followingId,
    );
  }

  /// Get follower count for a user
  Future<int> getFollowerCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.where((follow) => follow.followingId == userId).length;
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _follows.where((follow) => follow.followerId == userId).length;
  }
}

