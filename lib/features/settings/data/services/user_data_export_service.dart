import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/create/data/datasources/drafts_datasource.dart';
import 'package:localtrade/features/home/data/datasources/favorites_datasource.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/messages/data/datasources/messages_mock_datasource.dart';
import 'package:localtrade/features/notifications/data/datasources/notification_settings_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/delivery_addresses_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/disputes_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/order_templates_datasource.dart';
import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/blocks_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/follows_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/reviews_datasource.dart';
import 'package:localtrade/features/profile/data/datasources/user_reports_datasource.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart';
import 'package:localtrade/features/settings/data/datasources/privacy_settings_datasource.dart';

class UserDataExportService {
  UserDataExportService._();
  static final UserDataExportService instance = UserDataExportService._();

  /// Export all user data to JSON file
  Future<String> exportToJSON(String userId) async {
    final userData = await _collectAllUserData(userId);
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(userData);
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/user_data_export_$timestamp.json');
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  /// Export all user data to CSV file
  Future<String> exportToCSV(String userId) async {
    final userData = await _collectAllUserData(userId);
    final buffer = StringBuffer();
    
    // Write header
    buffer.writeln('Data Type,Field,Value');
    
    // Write user profile
    final user = userData['profile'] as Map<String, dynamic>;
    buffer.writeln('Profile,ID,"${user['id']}"');
    buffer.writeln('Profile,Email,"${user['email']}"');
    buffer.writeln('Profile,Name,"${user['name']}"');
    buffer.writeln('Profile,Role,"${user['role']}"');
    if (user['businessName'] != null) {
      buffer.writeln('Profile,Business Name,"${user['businessName']}"');
    }
    if (user['phoneNumber'] != null) {
      buffer.writeln('Profile,Phone,"${user['phoneNumber']}"');
    }
    if (user['address'] != null) {
      buffer.writeln('Profile,Address,"${user['address']}"');
    }
    buffer.writeln('Profile,Rating,${user['rating']}');
    buffer.writeln('Profile,Review Count,${user['reviewCount']}');
    buffer.writeln('Profile,Created At,"${user['createdAt']}"');
    
    // Write posts summary
    final posts = userData['posts'] as List;
    buffer.writeln('Posts,Total Count,${posts.length}');
    for (var i = 0; i < posts.length; i++) {
      final post = posts[i] as Map<String, dynamic>;
      buffer.writeln('Post ${i + 1},Title,"${post['title']}"');
      buffer.writeln('Post ${i + 1},Type,"${post['postType']}"');
      buffer.writeln('Post ${i + 1},Category,"${post['category']}"');
      buffer.writeln('Post ${i + 1},Created At,"${post['createdAt']}"');
    }
    
    // Write orders summary
    final orders = userData['orders'] as List;
    buffer.writeln('Orders,Total Count,${orders.length}');
    for (var i = 0; i < orders.length; i++) {
      final order = orders[i] as Map<String, dynamic>;
      buffer.writeln('Order ${i + 1},Order Number,"${order['orderNumber']}"');
      buffer.writeln('Order ${i + 1},Status,"${order['status']}"');
      buffer.writeln('Order ${i + 1},Total Amount,${order['totalAmount']}');
      buffer.writeln('Order ${i + 1},Created At,"${order['createdAt']}"');
    }
    
    // Write messages summary
    final chats = userData['chats'] as List;
    buffer.writeln('Chats,Total Count,${chats.length}');
    
    // Write reviews summary
    final reviewsReceived = userData['reviewsReceived'] as List;
    final reviewsGiven = userData['reviewsGiven'] as List;
    buffer.writeln('Reviews,Received Count,${reviewsReceived.length}');
    buffer.writeln('Reviews,Given Count,${reviewsGiven.length}');
    
    // Write other data summaries
    buffer.writeln('Favorites,Count,${(userData['favorites'] as List).length}');
    buffer.writeln('Drafts,Count,${(userData['drafts'] as List).length}');
    buffer.writeln('Saved Searches,Count,${(userData['savedSearches'] as List).length}');
    buffer.writeln('Following,Count,${(userData['following'] as List).length}');
    buffer.writeln('Followers,Count,${(userData['followers'] as List).length}');
    buffer.writeln('Blocked Users,Count,${(userData['blockedUsers'] as List).length}');
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/user_data_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());
    
    return file.path;
  }

  /// Collect all user data from various datasources
  Future<Map<String, dynamic>> _collectAllUserData(String userId) async {
    final user = await AuthMockDataSource.instance.getUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    // Collect all data in parallel
    final results = await Future.wait([
      _getUserPosts(userId),
      _getUserOrders(userId),
      _getUserChats(userId),
      _getUserReviews(userId),
      _getUserFavorites(userId),
      _getUserDrafts(userId),
      _getUserSavedSearches(userId),
      _getUserFollows(userId),
      _getUserBlockedUsers(userId),
      _getUserSettings(userId),
      _getUserOrderTemplates(userId),
      _getUserDeliveryAddresses(userId),
      _getUserDisputes(userId),
      _getUserReports(userId),
    ]);

    return {
      'exportDate': DateTime.now().toIso8601String(),
      'profile': user.toJson(),
      'posts': results[0],
      'orders': results[1],
      'chats': results[2],
      'reviewsReceived': results[3]['received'],
      'reviewsGiven': results[3]['given'],
      'favorites': results[4],
      'drafts': results[5],
      'savedSearches': results[6],
      'following': results[7]['following'],
      'followers': results[7]['followers'],
      'blockedUsers': results[8],
      'notificationSettings': results[9]['notifications'],
      'privacySettings': results[9]['privacy'],
      'orderTemplates': results[10],
      'deliveryAddresses': results[11],
      'disputes': results[12],
      'reportsFiled': results[13]['filed'],
      'reportsReceived': results[13]['received'],
    };
  }

  Future<List<Map<String, dynamic>>> _getUserPosts(String userId) async {
    final allPosts = PostsMockDataSource.instance.getAllPosts();
    final userPosts = allPosts.where((post) => post.userId == userId).toList();
    return userPosts.map((post) => post.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> _getUserOrders(String userId) async {
    final allOrders = await OrdersMockDataSource.instance.getAllOrders();
    final userOrders = allOrders
        .where((order) => order.buyerId == userId || order.sellerId == userId)
        .toList();
    return userOrders.map((order) => order.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> _getUserChats(String userId) async {
    final chats = await MessagesMockDataSource.instance.getChats(userId, includeArchived: true);
    final chatsData = <Map<String, dynamic>>[];
    
    for (final chat in chats) {
      final messages = await MessagesMockDataSource.instance.getMessages(chat.id);
      chatsData.add({
        'chat': chat.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(),
      });
    }
    
    return chatsData;
  }

  Future<Map<String, dynamic>> _getUserReviews(String userId) async {
    final reviewsReceived = await ReviewsDataSource.instance.getReviewsForUser(userId);
    final reviewsGiven = await ReviewsDataSource.instance.getReviewsByUser(userId);
    
    return {
      'received': reviewsReceived.map((r) => r.toJson()).toList(),
      'given': reviewsGiven.map((r) => r.toJson()).toList(),
    };
  }

  Future<List<String>> _getUserFavorites(String userId) async {
    return await FavoritesDataSource.instance.getFavoritePostIds(userId);
  }

  Future<List<Map<String, dynamic>>> _getUserDrafts(String userId) async {
    final drafts = await DraftsDataSource.instance.getDrafts(userId);
    return drafts.map((draft) => draft.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> _getUserSavedSearches(String userId) async {
    final savedSearches = await SearchMockDataSource.instance.getSavedSearches(userId);
    return savedSearches.map((search) => search.toJson()).toList();
  }

  Future<Map<String, dynamic>> _getUserFollows(String userId) async {
    final following = await FollowsDataSource.instance.getFollowing(userId);
    final followers = await FollowsDataSource.instance.getFollowers(userId);
    
    return {
      'following': following.map((f) => f.toJson()).toList(),
      'followers': followers.map((f) => f.toJson()).toList(),
    };
  }

  Future<List<String>> _getUserBlockedUsers(String userId) async {
    return await BlocksDataSource.instance.getBlockedUsers(userId);
  }

  Future<Map<String, dynamic>> _getUserSettings(String userId) async {
    final notificationSettings = await NotificationSettingsDataSource.instance.getSettings(userId);
    final privacySettings = await PrivacySettingsDataSource.instance.getSettings(userId);
    
    return {
      'notifications': notificationSettings.toJson(),
      'privacy': privacySettings.toJson(),
    };
  }

  Future<List<Map<String, dynamic>>> _getUserOrderTemplates(String userId) async {
    final templates = await OrderTemplatesDataSource.instance.getTemplates(userId);
    return templates.map((t) => t.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> _getUserDeliveryAddresses(String userId) async {
    final addresses = await DeliveryAddressesDataSource.instance.getAddresses(userId);
    return addresses.map((a) => a.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> _getUserDisputes(String userId) async {
    final disputes = await DisputesDataSource.instance.getDisputes(userId);
    return disputes.map((d) => d.toJson()).toList();
  }

  Future<Map<String, dynamic>> _getUserReports(String userId) async {
    final reportsFiled = await UserReportsDataSource.instance.getReportsByUser(userId);
    final reportsReceived = await UserReportsDataSource.instance.getReportsForUser(userId);
    
    return {
      'filed': reportsFiled.map((r) => r.toJson()).toList(),
      'received': reportsReceived.map((r) => r.toJson()).toList(),
    };
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'My LocalTrade Data Export',
    );
  }
}

