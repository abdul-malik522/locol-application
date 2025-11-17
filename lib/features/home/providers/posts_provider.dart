import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/home/data/datasources/posts_mock_datasource.dart';
import 'package:localtrade/features/home/data/models/comment_model.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';

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
  PostsNotifier(this._dataSource) : super(const PostsState());

  final PostsMockDataSource _dataSource;

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
      final newPosts = await _dataSource.getPosts(
        state.currentPage,
        AppConstants.paginationLimit,
        state.filter == 'all' ? null : state.filter,
      );

      state = state.copyWith(
        posts: refresh ? newPosts : [...state.posts, ...newPosts],
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
      state = state.copyWith(
        posts: [created, ...state.posts],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to create post: ${e.toString()}');
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
  return PostsNotifier(dataSource);
});

final filteredPostsProvider = Provider<List<PostModel>>((ref) {
  final state = ref.watch(postsProvider);
  return state.posts;
});

final postByIdProvider = Provider.family<PostModel?, String>((ref, postId) {
  final posts = ref.watch(filteredPostsProvider);
  try {
    return posts.firstWhere((p) => p.id == postId);
  } catch (_) {
    return null;
  }
});

