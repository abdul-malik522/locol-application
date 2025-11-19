import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/story_model.dart';
import 'package:localtrade/features/home/providers/stories_provider.dart';

class StoriesWidget extends ConsumerWidget {
  const StoriesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesState = ref.watch(storiesProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (storiesState.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (storiesState.storiesByUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final userStories = storiesState.storiesByUsers.entries.toList();
    
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: userStories.length + 1, // +1 for "Add Story" button
        itemBuilder: (context, index) {
          if (index == 0 && currentUser?.isSeller == true) {
            // Show "Add Story" button for sellers
            return _buildAddStoryButton(context, ref);
          }
          
          final userStoryEntry = userStories[index - (currentUser?.isSeller == true ? 1 : 0)];
          final userId = userStoryEntry.key;
          final stories = userStoryEntry.value;
          final firstStory = stories.first;
          
          return _buildStoryCircle(
            context,
            firstStory,
            stories.length,
            () => _openStoryViewer(context, userId, stories),
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: currentUser?.profileImageUrl != null
                      ? NetworkImage(currentUser!.profileImageUrl!)
                      : null,
                  child: currentUser?.profileImageUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Story',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(
    BuildContext context,
    StoryModel story,
    int storyCount,
    VoidCallback onTap,
  ) {
    final hasMultipleStories = storyCount > 1;
    final isExpiringSoon = story.isExpiringSoon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isExpiringSoon
                    ? LinearGradient(
                        colors: [
                          Colors.orange,
                          Colors.red,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: ClipOval(
                  child: CachedImage(
                    imageUrl: story.userProfileImage ??
                        'https://i.pravatar.cc/150?img=${story.userId.hashCode % 70}',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    story.userName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasMultipleStories) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$storyCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(
    BuildContext context,
    String userId,
    List<StoryModel> stories,
  ) {
    context.push('/stories/$userId', extra: stories.map((s) => s).toList());
  }
}

