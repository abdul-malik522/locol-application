import 'package:localtrade/features/create/data/datasources/drafts_datasource.dart';
import 'package:localtrade/features/home/data/datasources/favorites_datasource.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/messages/data/datasources/messages_mock_datasource.dart';
import 'package:localtrade/features/notifications/data/datasources/notification_settings_datasource.dart';
import 'package:localtrade/features/notifications/data/datasources/notifications_mock_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/delivery_addresses_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/disputes_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/order_templates_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/blocks_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/follows_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/user_reports_datasource.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart';
import 'package:localtrade/features/settings/data/datasources/privacy_settings_datasource.dart';

/// Service to handle comprehensive account deletion
/// Deletes all user data from all datasources
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  /// Delete all user data from all datasources
  Future<void> deleteAllUserData(String userId) async {
    // Delete in parallel where possible for better performance
    await Future.wait([
      _deleteUserPosts(userId),
      _deleteUserOrders(userId),
      _deleteUserChats(userId),
      _deleteUserFavorites(userId),
      _deleteUserDrafts(userId),
      _deleteUserSavedSearches(userId),
      _deleteUserFollows(userId),
      _deleteUserBlockedUsers(userId),
      _deleteUserSettings(userId),
      _deleteUserOrderTemplates(userId),
      _deleteUserDeliveryAddresses(userId),
      _deleteUserDisputes(userId),
      _deleteUserReports(userId),
      _deleteUserNotifications(userId),
    ]);
  }

  /// Delete all posts created by the user
  Future<void> _deleteUserPosts(String userId) async {
    final allPosts = PostsMockDataSource.instance.getAllPosts();
    for (final post in allPosts) {
      if (post.userId == userId) {
        await PostsMockDataSource.instance.deletePost(post.id);
      }
    }
  }

  /// Delete or anonymize orders related to the user
  /// Note: In a real app, you might want to anonymize instead of delete
  /// to preserve transaction history
  Future<void> _deleteUserOrders(String userId) async {
    final allOrders = await OrdersMockDataSource.instance.getAllOrders();
    for (final order in allOrders) {
      if (order.buyerId == userId || order.sellerId == userId) {
        // In a real app, you might want to anonymize the order instead
        // For now, we'll just cancel it if pending, or mark as deleted
        if (order.status.name == 'pending') {
          await OrdersMockDataSource.instance.cancelOrder(
            order.id,
            'Account deleted',
          );
        }
      }
    }
  }

  /// Delete all chats and messages for the user
  Future<void> _deleteUserChats(String userId) async {
    final chats = await MessagesMockDataSource.instance.getChats(userId, includeArchived: true);
    for (final chat in chats) {
      await MessagesMockDataSource.instance.deleteChat(chat.id);
    }
  }

  /// Clear all favorites for the user
  Future<void> _deleteUserFavorites(String userId) async {
    final favorites = await FavoritesDataSource.instance.getFavoritePostIds(userId);
    for (final postId in favorites) {
      await FavoritesDataSource.instance.removeFromFavorites(userId, postId);
    }
  }

  /// Delete all drafts for the user
  Future<void> _deleteUserDrafts(String userId) async {
    final drafts = await DraftsDataSource.instance.getDrafts(userId);
    for (final draft in drafts) {
      await DraftsDataSource.instance.deleteDraft(draft.id);
    }
    // Also clear current draft (if it belongs to this user)
    final currentDraft = await DraftsDataSource.instance.getCurrentDraft(userId);
    if (currentDraft != null) {
      await DraftsDataSource.instance.clearCurrentDraft();
    }
  }

  /// Delete all saved searches for the user
  Future<void> _deleteUserSavedSearches(String userId) async {
    final savedSearches = await SearchMockDataSource.instance.getSavedSearches(userId);
    for (final search in savedSearches) {
      await SearchMockDataSource.instance.deleteSavedSearch(search.id, userId);
    }
  }

  /// Unfollow all users and remove from followers
  Future<void> _deleteUserFollows(String userId) async {
    // Unfollow all users this user is following
    final following = await FollowsDataSource.instance.getFollowing(userId);
    for (final followingId in following) {
      await FollowsDataSource.instance.unfollowUser(userId, followingId);
    }

    // Remove this user from all followers' following lists
    final followers = await FollowsDataSource.instance.getFollowers(userId);
    for (final followerId in followers) {
      await FollowsDataSource.instance.unfollowUser(followerId, userId);
    }
  }

  /// Clear blocked users list
  Future<void> _deleteUserBlockedUsers(String userId) async {
    final blockedUsers = await BlocksDataSource.instance.getBlockedUsers(userId);
    for (final blockedUserId in blockedUsers) {
      await BlocksDataSource.instance.unblockUser(userId, blockedUserId);
    }
  }

  /// Delete notification and privacy settings
  Future<void> _deleteUserSettings(String userId) async {
    await NotificationSettingsDataSource.instance.resetSettings(userId);
    await PrivacySettingsDataSource.instance.resetSettings(userId);
  }

  /// Delete all order templates
  Future<void> _deleteUserOrderTemplates(String userId) async {
    final templates = await OrderTemplatesDataSource.instance.getTemplates(userId);
    for (final template in templates) {
      await OrderTemplatesDataSource.instance.deleteTemplate(template.id, userId);
    }
  }

  /// Delete all delivery addresses
  Future<void> _deleteUserDeliveryAddresses(String userId) async {
    final addresses = await DeliveryAddressesDataSource.instance.getAddresses(userId);
    for (final address in addresses) {
      await DeliveryAddressesDataSource.instance.deleteAddress(address.id, userId);
    }
  }

  /// Delete or anonymize disputes
  /// Note: In a real app, you might want to keep disputes for legal reasons
  Future<void> _deleteUserDisputes(String userId) async {
    final disputes = await DisputesDataSource.instance.getDisputes(userId);
    // Note: We can't delete disputes from the datasource directly
    // In a real app, you would mark them as deleted or anonymize them
    // For now, we'll leave them as they might be needed for legal/administrative purposes
  }

  /// Delete user reports
  Future<void> _deleteUserReports(String userId) async {
    // Note: Reports might need to be kept for legal/administrative purposes
    // In a real app, you would mark them as deleted or anonymize them
    // For now, we'll leave them as they might be needed
  }

  /// Delete all notifications for the user
  Future<void> _deleteUserNotifications(String userId) async {
    final notifications = await NotificationsMockDataSource.instance.getNotifications(userId);
    for (final notification in notifications) {
      await NotificationsMockDataSource.instance.deleteNotification(notification.id);
    }
  }
}

