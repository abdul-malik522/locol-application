import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/profile/providers/follows_provider.dart';

class FollowersFollowingScreen extends ConsumerStatefulWidget {
  const FollowersFollowingScreen({
    required this.userId,
    required this.type, // 'followers' or 'following'
    super.key,
  });

  final String userId;
  final String type; // 'followers' or 'following'

  @override
  ConsumerState<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState
    extends ConsumerState<FollowersFollowingScreen> {
  @override
  Widget build(BuildContext context) {
    final isFollowers = widget.type == 'followers';
    final title = isFollowers ? 'Followers' : 'Following';

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: _buildBody(isFollowers),
    );
  }

  Widget _buildBody(bool isFollowers) {
    final userIdListAsync = isFollowers
        ? ref.watch(followersListProvider(widget.userId))
        : ref.watch(userFollowingListProvider(widget.userId));

    return userIdListAsync.when(
      data: (userIds) {
        if (userIds.isEmpty) {
          return EmptyState(
            icon: isFollowers ? Icons.people_outline : Icons.person_add_outlined,
            title: isFollowers ? 'No Followers Yet' : 'Not Following Anyone',
            message: isFollowers
                ? 'When people follow you, they\'ll appear here.'
                : 'Start following sellers and restaurants to see their posts!',
          );
        }
        return _buildUserList(userIds);
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        error: error.toString(),
        onRetry: () {
          if (isFollowers) {
            ref.invalidate(followersListProvider(widget.userId));
          } else {
            ref.invalidate(followingListProvider);
          }
        },
      ),
    );
  }

  Widget _buildUserList(List<String> userIds) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchUsers(userIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'No Users Found',
            message: 'Unable to load user information.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (widget.type == 'followers') {
              ref.invalidate(followersListProvider(widget.userId));
            } else {
              ref.invalidate(followingListProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(context, user);
            },
          ),
        );
      },
    );
  }

  Future<List<UserModel>> _fetchUsers(List<String> userIds) async {
    final users = <UserModel>[];
    for (final userId in userIds) {
      try {
        final user = await AuthMockDataSource.instance.getCurrentUser(userId);
        if (user != null) {
          users.add(user);
        }
      } catch (e) {
        print('Error fetching user $userId: $e');
      }
    }
    return users;
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.id == user.id;
    final isFollowingAsync = currentUser != null && !isOwnProfile
        ? ref.watch(isFollowingProvider(user.id))
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isOwnProfile) {
            context.go('/profile');
          } else {
            context.push('/user/${user.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.businessName ?? user.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.businessDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.businessDescription!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isOwnProfile && currentUser != null)
                isFollowingAsync != null
                    ? isFollowingAsync.when(
                        data: (isFollowing) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CustomButton(
                            text: isFollowing ? 'Following' : 'Follow',
                            onPressed: () => _toggleFollow(
                              context,
                              currentUser.id,
                              user.id,
                              isFollowing,
                            ),
                            variant: isFollowing
                                ? CustomButtonVariant.outlined
                                : CustomButtonVariant.filled,
                            icon: isFollowing
                                ? Icons.person_remove_outlined
                                : Icons.person_add_outlined,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CustomButton(
                            text: 'Follow',
                            onPressed: () => _toggleFollow(
                              context,
                              currentUser.id,
                              user.id,
                              false,
                            ),
                            variant: CustomButtonVariant.outlined,
                            icon: Icons.person_add_outlined,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    String currentUserId,
    String targetUserId,
    bool isCurrentlyFollowing,
  ) async {
    try {
      if (isCurrentlyFollowing) {
        await ref.read(followsNotifierProvider.notifier).unfollowUser(
              currentUserId,
              targetUserId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unfollowed')),
          );
        }
      } else {
        await ref.read(followsNotifierProvider.notifier).followUser(
              currentUserId,
              targetUserId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Following')),
          );
        }
      }

      // Invalidate providers to refresh data
      ref.invalidate(isFollowingProvider(targetUserId));
      ref.invalidate(followerCountProvider(targetUserId));
      ref.invalidate(followingCountProvider(currentUserId));
      ref.invalidate(followersListProvider(widget.userId));
      ref.invalidate(followingListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

