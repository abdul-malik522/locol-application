import 'dart:async';
import 'dart:math';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/home/data/models/comment_model.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:uuid/uuid.dart';

class PostsMockDataSource {
  PostsMockDataSource._() {
    _initializeMockData();
  }
  static final PostsMockDataSource instance = PostsMockDataSource._();
  final _uuid = const Uuid();
  final _random = Random();

  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _comments = {};

  void _initializeMockData() {
    final now = DateTime.now();
    final basePosts = [
      PostModel(
        id: 'post-001',
        userId: 'user-001',
        userName: 'Amelia Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=5',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Fresh Organic Tomatoes',
        description:
            'Just harvested this morning! Perfect for salads, sauces, and canning. Grown without pesticides, naturally ripened on the vine.',
        imageUrls: [
          'https://picsum.photos/400/300?random=1',
          'https://picsum.photos/400/300?random=2',
        ],
        category: 'Vegetables',
        price: 4.50,
        quantity: '5 kg',
        location: '120 Maple St, Springfield',
        latitude: 37.7749,
        longitude: -122.4194,
        likeCount: 42,
        commentCount: 8,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      PostModel(
        id: 'post-002',
        userId: 'user-002',
        userName: 'Carlos Green',
        userProfileImage: 'https://i.pravatar.cc/150?img=11',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Mixed Leafy Greens Bundle',
        description:
            'Arugula, spinach, kale, and romaine. Perfect for fresh salads. Picked daily, delivered fresh.',
        imageUrls: ['https://picsum.photos/400/300?random=3'],
        category: 'Vegetables',
        price: 6.00,
        quantity: '1 bundle',
        location: '45 River Rd, Portland',
        latitude: 45.5152,
        longitude: -122.6784,
        likeCount: 28,
        commentCount: 5,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      PostModel(
        id: 'post-003',
        userId: 'user-004',
        userName: 'Lena Rivers',
        userProfileImage: 'https://i.pravatar.cc/150?img=20',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Need 20kg Potatoes - Urgent',
        description:
            'Looking for high-quality potatoes for our weekend special. Need delivery by Friday. Prefer organic if available.',
        imageUrls: ['https://picsum.photos/400/300?random=4'],
        category: 'Vegetables',
        quantity: '20 kg',
        location: '88 Cherry Ln, Seattle',
        latitude: 47.6062,
        longitude: -122.3321,
        likeCount: 15,
        commentCount: 12,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      PostModel(
        id: 'post-004',
        userId: 'user-003',
        userName: 'Rita Stone',
        userProfileImage: 'https://i.pravatar.cc/150?img=9',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Free-Range Chicken - Whole Birds',
        description:
            'Grass-fed, free-range chickens. Raised without antibiotics. Available whole or cut. Perfect for roasting.',
        imageUrls: [
          'https://picsum.photos/400/300?random=5',
          'https://picsum.photos/400/300?random=6',
        ],
        category: 'Meat',
        price: 18.00,
        quantity: '1 whole bird (3-4 lbs)',
        location: '10 Lakeview Ave, Austin',
        latitude: 30.2672,
        longitude: -97.7431,
        likeCount: 67,
        commentCount: 14,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      PostModel(
        id: 'post-005',
        userId: 'user-008',
        userName: 'Nora Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=21',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Artisan Cheddar Cheese',
        description:
            'Aged 6 months. Sharp, creamy, perfect for sandwiches and charcuterie boards. Made with local milk.',
        imageUrls: ['https://picsum.photos/400/300?random=7'],
        category: 'Dairy',
        price: 12.50,
        quantity: '500g block',
        location: '14 Valley Rd, Madison',
        latitude: 43.0731,
        longitude: -89.4012,
        likeCount: 89,
        commentCount: 19,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PostModel(
        id: 'post-006',
        userId: 'user-005',
        userName: 'Marco Bianchi',
        userProfileImage: 'https://i.pravatar.cc/150?img=14',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Looking for Fresh Basil',
        description:
            'Need fresh basil for our pasta dishes. Looking for regular supplier. Minimum 2kg per week.',
        imageUrls: ['https://picsum.photos/400/300?random=8'],
        category: 'Herbs',
        quantity: '2 kg weekly',
        location: '77 Olive St, Boston',
        latitude: 42.3601,
        longitude: -71.0589,
        likeCount: 23,
        commentCount: 7,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      PostModel(
        id: 'post-007',
        userId: 'user-007',
        userName: 'Tara Bloom',
        userProfileImage: 'https://i.pravatar.cc/150?img=18',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Raw Local Honey',
        description:
            'Unfiltered, unpasteurized honey from our hives. Rich flavor, great for baking and tea. Available in 500g and 1kg jars.',
        imageUrls: [
          'https://picsum.photos/400/300?random=9',
          'https://picsum.photos/400/300?random=10',
        ],
        category: 'Condiments',
        price: 15.00,
        quantity: '500g jar',
        location: '600 Meadow Dr, Boulder',
        latitude: 40.01499,
        longitude: -105.27055,
        likeCount: 124,
        commentCount: 31,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PostModel(
        id: 'post-008',
        userId: 'user-006',
        userName: 'Derrick Cole',
        userProfileImage: 'https://i.pravatar.cc/150?img=16',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Bulk Onions Required',
        description:
            'Need 50kg yellow onions for next month. Looking for competitive pricing and reliable delivery.',
        imageUrls: ['https://picsum.photos/400/300?random=11'],
        category: 'Vegetables',
        quantity: '50 kg',
        location: '310 Pine St, Denver',
        latitude: 39.7392,
        longitude: -104.9903,
        likeCount: 18,
        commentCount: 9,
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      PostModel(
        id: 'post-009',
        userId: 'user-001',
        userName: 'Amelia Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=5',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Organic Carrots - Baby Size',
        description:
            'Sweet, tender baby carrots. Great for snacking, roasting, or juicing. Grown in organic soil.',
        imageUrls: ['https://picsum.photos/400/300?random=12'],
        category: 'Vegetables',
        price: 3.75,
        quantity: '2 kg bag',
        location: '120 Maple St, Springfield',
        latitude: 37.7749,
        longitude: -122.4194,
        likeCount: 35,
        commentCount: 6,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      PostModel(
        id: 'post-010',
        userId: 'user-012',
        userName: 'Priya Nair',
        userProfileImage: 'https://i.pravatar.cc/150?img=37',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Premium Spice Blend - Garam Masala',
        description:
            'Authentic garam masala blend. Perfect for curries and stews. Made with freshly ground spices.',
        imageUrls: ['https://picsum.photos/400/300?random=13'],
        category: 'Spices',
        price: 8.50,
        quantity: '100g jar',
        location: '12 Spice Market, Houston',
        latitude: 29.7604,
        longitude: -95.3698,
        likeCount: 56,
        commentCount: 11,
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      PostModel(
        id: 'post-011',
        userId: 'user-009',
        userName: 'Sakura Watanabe',
        userProfileImage: 'https://i.pravatar.cc/150?img=32',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Fresh Ginger - Regular Supply',
        description:
            'Looking for fresh ginger supplier. Need 5kg weekly. Quality is important for our Asian fusion dishes.',
        imageUrls: ['https://picsum.photos/400/300?random=14'],
        category: 'Spices',
        quantity: '5 kg weekly',
        location: '950 Sunset Blvd, Los Angeles',
        latitude: 34.0522,
        longitude: -118.2437,
        likeCount: 19,
        commentCount: 4,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      PostModel(
        id: 'post-012',
        userId: 'user-011',
        userName: 'Luca Martinez',
        userProfileImage: 'https://i.pravatar.cc/150?img=34',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Organic Whole Wheat Flour',
        description:
            'Stone-ground whole wheat flour. Perfect for bread baking. Available in 5kg and 10kg bags.',
        imageUrls: ['https://picsum.photos/400/300?random=15'],
        category: 'Grains',
        price: 7.25,
        quantity: '5 kg bag',
        location: '480 Harvest Ln, Omaha',
        latitude: 41.2565,
        longitude: -95.9345,
        likeCount: 44,
        commentCount: 8,
        createdAt: now.subtract(const Duration(days: 1, hours: 10)),
      ),
      PostModel(
        id: 'post-013',
        userId: 'user-002',
        userName: 'Carlos Green',
        userProfileImage: 'https://i.pravatar.cc/150?img=11',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Fresh Bell Peppers - Mixed Colors',
        description:
            'Red, yellow, and green bell peppers. Crisp and sweet. Great for salads, stir-fries, and roasting.',
        imageUrls: [
          'https://picsum.photos/400/300?random=16',
          'https://picsum.photos/400/300?random=17',
        ],
        category: 'Vegetables',
        price: 5.50,
        quantity: '1 kg',
        location: '45 River Rd, Portland',
        latitude: 45.5152,
        longitude: -122.6784,
        likeCount: 38,
        commentCount: 7,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      PostModel(
        id: 'post-014',
        userId: 'user-010',
        userName: 'Jonah Reed',
        userProfileImage: 'https://i.pravatar.cc/150?img=30',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Organic Avocados - Bulk Order',
        description:
            'Need 30kg ripe avocados for our smoothie bowls. Looking for consistent quality and fair pricing.',
        imageUrls: ['https://picsum.photos/400/300?random=18'],
        category: 'Fruits',
        quantity: '30 kg',
        location: '220 Ocean Ave, Miami',
        latitude: 25.7617,
        longitude: -80.1918,
        likeCount: 27,
        commentCount: 13,
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      PostModel(
        id: 'post-015',
        userId: 'user-003',
        userName: 'Rita Stone',
        userProfileImage: 'https://i.pravatar.cc/150?img=9',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Grass-Fed Ground Beef',
        description:
            'Premium ground beef from grass-fed cattle. 80/20 lean-to-fat ratio. Perfect for burgers and meatballs.',
        imageUrls: ['https://picsum.photos/400/300?random=19'],
        category: 'Meat',
        price: 14.00,
        quantity: '1 lb',
        location: '10 Lakeview Ave, Austin',
        latitude: 30.2672,
        longitude: -97.7431,
        likeCount: 92,
        commentCount: 22,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      PostModel(
        id: 'post-016',
        userId: 'user-008',
        userName: 'Nora Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=21',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Fresh Mozzarella Cheese',
        description:
            'Handmade mozzarella. Soft, creamy, perfect for caprese salads and pizza. Made fresh weekly.',
        imageUrls: ['https://picsum.photos/400/300?random=20'],
        category: 'Dairy',
        price: 9.50,
        quantity: '250g ball',
        location: '14 Valley Rd, Madison',
        latitude: 43.0731,
        longitude: -89.4012,
        likeCount: 71,
        commentCount: 15,
        createdAt: now.subtract(const Duration(hours: 7)),
      ),
      PostModel(
        id: 'post-017',
        userId: 'user-001',
        userName: 'Amelia Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=5',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Fresh Cucumbers - English Style',
        description:
            'Crisp, seedless English cucumbers. Perfect for salads and pickling. Grown in our greenhouse.',
        imageUrls: ['https://picsum.photos/400/300?random=21'],
        category: 'Vegetables',
        price: 2.50,
        quantity: '1 lb',
        location: '120 Maple St, Springfield',
        latitude: 37.7749,
        longitude: -122.4194,
        likeCount: 29,
        commentCount: 5,
        createdAt: now.subtract(const Duration(hours: 11)),
      ),
      PostModel(
        id: 'post-018',
        userId: 'user-004',
        userName: 'Lena Rivers',
        userProfileImage: 'https://i.pravatar.cc/150?img=20',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'Fresh Cilantro - Weekly Supply',
        description:
            'Need fresh cilantro for our vegetarian dishes. Looking for reliable weekly delivery. Minimum 1kg per week.',
        imageUrls: ['https://picsum.photos/400/300?random=22'],
        category: 'Herbs',
        quantity: '1 kg weekly',
        location: '88 Cherry Ln, Seattle',
        latitude: 47.6062,
        longitude: -122.3321,
        likeCount: 14,
        commentCount: 6,
        createdAt: now.subtract(const Duration(hours: 15)),
      ),
      PostModel(
        id: 'post-019',
        userId: 'user-007',
        userName: 'Tara Bloom',
        userProfileImage: 'https://i.pravatar.cc/150?img=18',
        userRole: UserRole.seller,
        postType: PostType.product,
        title: 'Wildflower Honey - Limited Batch',
        description:
            'Special batch from spring wildflowers. Unique flavor profile. Limited availability. 1kg jars only.',
        imageUrls: [
          'https://picsum.photos/400/300?random=23',
          'https://picsum.photos/400/300?random=24',
        ],
        category: 'Condiments',
        price: 18.00,
        quantity: '1 kg jar',
        location: '600 Meadow Dr, Boulder',
        latitude: 40.01499,
        longitude: -105.27055,
        likeCount: 103,
        commentCount: 28,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PostModel(
        id: 'post-020',
        userId: 'user-005',
        userName: 'Marco Bianchi',
        userProfileImage: 'https://i.pravatar.cc/150?img=14',
        userRole: UserRole.restaurant,
        postType: PostType.request,
        title: 'San Marzano Tomatoes - Bulk',
        description:
            'Looking for authentic San Marzano tomatoes for our pasta sauces. Need 100kg for next month.',
        imageUrls: ['https://picsum.photos/400/300?random=25'],
        category: 'Vegetables',
        quantity: '100 kg',
        location: '77 Olive St, Boston',
        latitude: 42.3601,
        longitude: -71.0589,
        likeCount: 31,
        commentCount: 10,
        createdAt: now.subtract(const Duration(hours: 20)),
      ),
    ];

    _posts.addAll(basePosts);

    // Add some comments
    _comments['post-001'] = [
      CommentModel(
        id: 'comment-001',
        postId: 'post-001',
        userId: 'user-004',
        userName: 'Lena Rivers',
        userProfileImage: 'https://i.pravatar.cc/150?img=20',
        text: 'These look amazing! Can you deliver?',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      CommentModel(
        id: 'comment-002',
        postId: 'post-001',
        userId: 'user-005',
        userName: 'Marco Bianchi',
        userProfileImage: 'https://i.pravatar.cc/150?img=14',
        text: 'Perfect for our pasta sauce!',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ];

    _comments['post-003'] = [
      CommentModel(
        id: 'comment-003',
        postId: 'post-003',
        userId: 'user-001',
        userName: 'Amelia Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=5',
        text: 'I can supply! Check my profile.',
        createdAt: now.subtract(const Duration(minutes: 50)),
      ),
    ];
  }

  Future<List<PostModel>> getPosts(
    int page,
    int limit,
    String? filter, {
    List<String>? followingUserIds,
    bool trending = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var filtered = List<PostModel>.from(_posts);

    if (filter == 'sellers') {
      filtered = filtered.where((p) => p.userRole == UserRole.seller).toList();
    } else if (filter == 'restaurants') {
      filtered =
          filtered.where((p) => p.userRole == UserRole.restaurant).toList();
    } else if (followingUserIds != null && followingUserIds.isNotEmpty) {
      // Filter to show only posts from followed users
      filtered = filtered.where((p) => followingUserIds.contains(p.userId)).toList();
    }

    // Filter out scheduled posts that aren't published yet
    filtered = filtered.where((p) => p.isPublished).toList();
    
    // Filter out expired posts
    filtered = filtered.where((p) => !p.isExpired).toList();
    
    // Filter out archived posts
    filtered = filtered.where((p) => !p.isArchived).toList();

    // Sort by trending score if requested
    if (trending) {
      filtered.sort((a, b) {
        final scoreA = _calculateTrendingScore(a);
        final scoreB = _calculateTrendingScore(b);
        return scoreB.compareTo(scoreA);
      });
    } else {
      // Default: sort by newest first
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final start = (page - 1) * limit;
    final end = start + limit;
    return filtered.sublist(
      start.clamp(0, filtered.length),
      end.clamp(0, filtered.length),
    );
  }

  /// Calculate trending score based on engagement and recency
  double _calculateTrendingScore(PostModel post) {
    final now = DateTime.now();
    final hoursSinceCreation = now.difference(post.createdAt).inHours;
    
    // Engagement score: likes and comments weighted
    final engagementScore = (post.likeCount * 2.0) + (post.commentCount * 3.0);
    
    // Recency score: newer posts get higher score (decay over time)
    // Posts from last 24 hours get full recency boost
    final recencyScore = hoursSinceCreation < 24
        ? 100.0 * (1.0 - (hoursSinceCreation / 24.0))
        : 0.0;
    
    // Combined score
    return engagementScore + recencyScore;
  }

  /// Get trending posts (top posts by engagement and recency)
  Future<List<PostModel>> getTrendingPosts(int limit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return await getPosts(1, limit, null, trending: true);
  }

  /// Get featured sellers (verified or premium sellers)
  Future<List<String>> getFeaturedSellerIds() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, this would query users with verification badges
    // For mock, we return seller IDs that have verification badges
    // This would be integrated with AuthMockDataSource in a real implementation
    return ['user-001', 'user-002', 'user-003']; // Sample featured sellers
  }

  /// Get posts from featured sellers
  Future<List<PostModel>> getFeaturedSellerPosts(int limit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final featuredSellerIds = await getFeaturedSellerIds();
    var filtered = _posts.where((p) => 
      featuredSellerIds.contains(p.userId) && 
      p.isPublished && 
      !p.isExpired && 
      !p.isArchived
    ).toList();
    
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered.take(limit).toList();
  }

  /// Get all posts (for internal use, e.g., analytics)
  List<PostModel> getAllPosts() {
    return List.unmodifiable(_posts);
  }

  Future<PostModel?> getPostById(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (_) {
      return null;
    }
  }

  Future<PostModel> createPost(PostModel post) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // If post is scheduled, don't add to main feed yet
    // It will be published when scheduledAt time arrives
    if (post.isScheduled && post.scheduledAt != null) {
      _posts.insert(0, post);
      print('Post scheduled for ${post.scheduledAt}');
    } else {
      // Immediate publication
    _posts.insert(0, post);
    }
    
    return post;
  }

  /// Publish scheduled posts that are due
  Future<void> publishScheduledPosts() async {
    final now = DateTime.now();
    for (var post in _posts) {
      if (post.isScheduled && 
          post.scheduledAt != null && 
          now.isAfter(post.scheduledAt!)) {
        // Mark as published
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWith(isScheduled: false, scheduledAt: null);
          print('Published scheduled post: ${post.id}');
        }
      }
    }
  }

  /// Get scheduled posts for a user
  List<PostModel> getScheduledPosts(String userId) {
    return _posts
        .where((p) => p.userId == userId && p.isScheduled && p.scheduledAt != null)
        .toList()
      ..sort((a, b) => (a.scheduledAt ?? DateTime.now())
          .compareTo(b.scheduledAt ?? DateTime.now()));
  }

  /// Get archived posts for a user (includes archived posts)
  List<PostModel> getArchivedPosts(String userId) {
    return _posts
        .where((p) => p.userId == userId && p.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }


  Future<PostModel> updatePost(PostModel updatedPost) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index == -1) {
      throw Exception('Post not found');
    }

    // Preserve engagement metrics and timestamps
    final existingPost = _posts[index];
    final updated = updatedPost.copyWith(
      likeCount: existingPost.likeCount,
      commentCount: existingPost.commentCount,
      isLiked: existingPost.isLiked,
      createdAt: existingPost.createdAt,
      updatedAt: DateTime.now(),
    );

    _posts[index] = updated;
    return updated;
  }

  Future<void> deletePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _posts.removeWhere((p) => p.id == postId);
    _comments.remove(postId);
  }

  Future<PostModel> likePost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) throw Exception('Post not found');
    final post = _posts[index];
    final isLiked = post.isLiked;
    final updated = post.copyWith(
      isLiked: !isLiked,
      likeCount: isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    _posts[index] = updated;
    return updated;
  }

  Future<List<CommentModel>> getComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _comments[postId] ?? [];
  }

  Future<CommentModel> addComment(String postId, CommentModel comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final comments = _comments.putIfAbsent(postId, () => []);
    comments.add(comment);
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      _posts[postIndex] = post.copyWith(
        commentCount: post.commentCount + 1,
      );
    }
    return comment;
  }
}

