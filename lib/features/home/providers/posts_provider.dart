import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/home/data/models/comment_model.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/profile/providers/follows_provider.dart';

class PostsState {
  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.filter = 'all',
  });

  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final String filter;

  PostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    String? filter,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
    );
  }
}

final postsMockDataSourceProvider =
    Provider<PostsMockDataSource>((ref) => PostsMockDataSource.instance);

class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier(this._dataSource, this.ref) : super(const PostsState());

  final PostsMockDataSource _dataSource;
  final Ref ref;

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        posts: [],
        hasMore: true,
        error: null,
      );
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check and publish scheduled posts before loading
      await _dataSource.publishScheduledPosts();
      
      List<String>? followingUserIds;
      if (state.filter == 'following') {
        // Get list of users that current user is following
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          final followsDataSource = ref.read(followsDataSourceProvider);
          followingUserIds = await followsDataSource.getFollowing(currentUser.id);
        }
      }
      
      final isTrending = state.filter == 'trending';
      final newPosts = await _dataSource.getPosts(
        state.currentPage,
        AppConstants.paginationLimit,
        state.filter == 'all' || state.filter == 'following' || state.filter == 'trending' ? null : state.filter,
        followingUserIds: followingUserIds,
        trending: isTrending,
      );

      // Filter out scheduled posts that aren't published yet
      final publishedPosts = newPosts.where((p) => p.isPublished).toList();

      state = state.copyWith(
        posts: refresh ? publishedPosts : [...state.posts, ...publishedPosts],
        isLoading: false,
        hasMore: newPosts.length >= AppConstants.paginationLimit,
        currentPage: refresh ? 2 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load posts: ${e.toString()}',
      );
    }
  }

  Future<void> loadMorePosts() async {
    if (!state.hasMore || state.isLoading) return;
    await loadPosts();
  }

  Future<void> setFilter(String filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await loadPosts(refresh: true);
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      final updated = await _dataSource.likePost(postId, userId);
      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final updatedPosts = List<PostModel>.from(state.posts);
        updatedPosts[index] = updated;
        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to like post: ${e.toString()}');
    }
  }

  Future<void> createPost(PostModel post) async {
    try {
      final created = await _dataSource.createPost(post);
      
      // Only add to feed if it's published (not scheduled)
      if (created.isPublished) {
        state = state.copyWith(
          posts: [created, ...state.posts],
        );
      } else {
        // Scheduled post - don't add to feed yet, but update state to trigger refresh
        state = state.copyWith(posts: state.posts);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create post: ${e.toString()}');
    }
  }

  Future<List<PostModel>> getScheduledPosts(String userId) async {
    return _dataSource.getScheduledPosts(userId);
  }

  Future<void> cancelScheduledPost(String postId) async {
    try {
      // Get the post and update it to remove scheduling
      final posts = state.posts;
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = posts[postIndex];
        final updated = post.copyWith(isScheduled: false, scheduledAt: null);
        await _dataSource.updatePost(updated);
        await loadPosts(refresh: true);
      } else {
        // Post might be in scheduled list, try to find and update
        final allPosts = await _dataSource.getPosts(1, 1000, null);
        final post = allPosts.firstWhere((p) => p.id == postId);
        final updated = post.copyWith(isScheduled: false, scheduledAt: null);
        await _dataSource.updatePost(updated);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel scheduled post: ${e.toString()}');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _dataSource.deletePost(postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete post: ${e.toString()}');
    }
  }

  Future<void> archivePost(String postId) async {
    try {
      final post = state.posts.firstWhere((p) => p.id == postId);
      final updated = post.copyWith(isArchived: true);
      await _dataSource.updatePost(updated);
      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final updatedPosts = List<PostModel>.from(state.posts);
        updatedPosts[index] = updated;
        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to archive post: ${e.toString()}');
    }
  }

  Future<void> unarchivePost(String postId) async {
    try {
      // Get post directly from datasource (including archived)
      final post = await _dataSource.getPostById(postId);
      if (post == null) {
        throw Exception('Post not found');
      }
      final updated = post.copyWith(isArchived: false);
      await _dataSource.updatePost(updated);
      // Refresh posts to include unarchived post
      await loadPosts(refresh: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to unarchive post: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<PostModel>> getArchivedPosts(String userId) async {
    return _dataSource.getArchivedPosts(userId);
  }

  Future<void> updatePost(PostModel post) async {
    try {
      final updated = await _dataSource.updatePost(post);
      final index = state.posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        final updatedPosts = List<PostModel>.from(state.posts);
        updatedPosts[index] = updated;
        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update post: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    return await _dataSource.getComments(postId);
  }

  Future<CommentModel> addComment(String postId, CommentModel comment) async {
    final added = await _dataSource.addComment(postId, comment);
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final updatedPosts = List<PostModel>.from(state.posts);
      updatedPosts[index] = updatedPosts[index].copyWith(
        commentCount: updatedPosts[index].commentCount + 1,
      );
      state = state.copyWith(posts: updatedPosts);
    }
    return added;
  }
}

final postsProvider =
    StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  final dataSource = ref.watch(postsMockDataSourceProvider);
  return PostsNotifier(dataSource, ref);
});

/// Provider for featured seller posts
final featuredSellerPostsProvider = FutureProvider<List<PostModel>>((ref) {
  final dataSource = ref.watch(postsMockDataSourceProvider);
  return dataSource.getFeaturedSellerPosts(10);
});

final filteredPostsProvider = Provider<List<PostModel>>((ref) {
  final state = ref.watch(postsProvider);
  return state.posts;
});

final postByIdProvider = FutureProvider.family<PostModel?, String>((ref, postId) async {
  final dataSource = ref.watch(postsMockDataSourceProvider);
  return await dataSource.getPostById(postId);
});

