import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/home/data/datasources/stories_mock_datasource.dart';
import 'package:localtrade/features/home/data/models/story_model.dart';

class StoriesState {
  const StoriesState({
    this.stories = const [],
    this.storiesByUsers = const {},
    this.isLoading = false,
    this.error,
  });

  final List<StoryModel> stories;
  final Map<String, List<StoryModel>> storiesByUsers;
  final bool isLoading;
  final String? error;

  StoriesState copyWith({
    List<StoryModel>? stories,
    Map<String, List<StoryModel>>? storiesByUsers,
    bool? isLoading,
    String? error,
  }) {
    return StoriesState(
      stories: stories ?? this.stories,
      storiesByUsers: storiesByUsers ?? this.storiesByUsers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final storiesDataSourceProvider =
    Provider<StoriesMockDataSource>((ref) => StoriesMockDataSource.instance);

final storiesProvider =
    StateNotifierProvider<StoriesNotifier, StoriesState>((ref) {
  final dataSource = ref.watch(storiesDataSourceProvider);
  return StoriesNotifier(dataSource);
});

class StoriesNotifier extends StateNotifier<StoriesState> {
  StoriesNotifier(this._dataSource) : super(const StoriesState()) {
    loadStories();
  }

  final StoriesMockDataSource _dataSource;

  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Clean up expired stories first
      await _dataSource.deleteExpiredStories();
      
      final stories = await _dataSource.getStories();
      final storiesByUsers = await _dataSource.getStoriesByUsers();
      
      state = state.copyWith(
        stories: stories,
        storiesByUsers: storiesByUsers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stories: ${e.toString()}',
      );
    }
  }

  Future<void> createStory(StoryModel story) async {
    try {
      await _dataSource.createStory(story);
      await loadStories();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create story: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _dataSource.deleteStory(storyId);
      await loadStories();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete story: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<StoryModel>> getStoriesByUser(String userId) async {
    return await _dataSource.getStoriesByUser(userId);
  }
}

