import 'dart:async';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/home/data/models/story_model.dart';
import 'package:uuid/uuid.dart';

class StoriesMockDataSource {
  StoriesMockDataSource._() {
    _initializeMockData();
  }
  static final StoriesMockDataSource instance = StoriesMockDataSource._();
  final _uuid = const Uuid();

  final List<StoryModel> _stories = [];

  void _initializeMockData() {
    final now = DateTime.now();
    
    // Create sample stories for sellers
    _stories.addAll([
      StoryModel(
        id: 'story-001',
        userId: 'user-001',
        userName: 'Amelia Fields',
        userProfileImage: 'https://i.pravatar.cc/150?img=5',
        userRole: UserRole.seller,
        imageUrl: 'https://picsum.photos/400/700?random=101',
        text: 'Fresh harvest today! 🥬',
        textPosition: TextPosition.top,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      StoryModel(
        id: 'story-002',
        userId: 'user-002',
        userName: 'Carlos Green',
        userProfileImage: 'https://i.pravatar.cc/150?img=11',
        userRole: UserRole.seller,
        imageUrl: 'https://picsum.photos/400/700?random=102',
        text: 'New organic vegetables available',
        textPosition: TextPosition.center,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      StoryModel(
        id: 'story-003',
        userId: 'user-003',
        userName: 'Rita Stone',
        userProfileImage: 'https://i.pravatar.cc/150?img=9',
        userRole: UserRole.seller,
        imageUrl: 'https://picsum.photos/400/700?random=103',
        text: 'Grass-fed beef special',
        textPosition: TextPosition.bottom,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      StoryModel(
        id: 'story-004',
        userId: 'user-007',
        userName: 'Tara Bloom',
        userProfileImage: 'https://i.pravatar.cc/150?img=18',
        userRole: UserRole.seller,
        imageUrl: 'https://picsum.photos/400/700?random=104',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
    ]);
  }

  /// Get all active (non-expired) stories
  Future<List<StoryModel>> getStories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return _stories
        .where((story) => story.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get stories for a specific user
  Future<List<StoryModel>> getStoriesByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return _stories
        .where((story) =>
            story.userId == userId && story.expiresAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get stories grouped by user
  Future<Map<String, List<StoryModel>>> getStoriesByUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stories = await getStories();
    final Map<String, List<StoryModel>> grouped = {};
    
    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []).add(story);
    }
    
    // Sort stories within each user group by creation time
    for (final userId in grouped.keys) {
      grouped[userId]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return grouped;
  }

  /// Create a new story
  Future<StoryModel> createStory(StoryModel story) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _stories.insert(0, story);
    return story;
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _stories.removeWhere((story) => story.id == storyId);
  }

  /// Delete expired stories (cleanup)
  Future<void> deleteExpiredStories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    _stories.removeWhere((story) => story.expiresAt.isBefore(now));
  }

  /// Get a story by ID
  Future<StoryModel?> getStoryById(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _stories.firstWhere((story) => story.id == storyId);
    } catch (_) {
      return null;
    }
  }
}

