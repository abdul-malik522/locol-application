import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/profile/data/datasources/blocks_datasource.dart';
import 'package:localtrade/features/profile/providers/blocks_provider.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Blocked Users'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final blockedUsersAsync = ref.watch(blockedUsersProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Blocked Users'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(blockedUsersProvider(currentUser.id));
        },
        child: blockedUsersAsync.when(
          data: (blockedUserIds) {
            if (blockedUserIds.isEmpty) {
              return const EmptyState(
                icon: Icons.block_outlined,
                title: 'No Blocked Users',
                message: 'You haven\'t blocked any users yet.',
              );
            }
            return _buildBlockedUsersList(context, ref, blockedUserIds, currentUser.id);
          },
          loading: () => const LoadingIndicator(),
          error: (error, stack) => ErrorView(
            error: error.toString(),
            onRetry: () => ref.invalidate(blockedUsersProvider(currentUser.id)),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedUsersList(
    BuildContext context,
    WidgetRef ref,
    List<String> blockedUserIds,
    String currentUserId,
  ) {
    return FutureBuilder<List<UserModel?>>(
      future: _fetchUserDetails(blockedUserIds),
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
        final validUsers = users.whereType<UserModel>().toList();

        if (validUsers.isEmpty) {
          return const EmptyState(
            icon: Icons.block_outlined,
            title: 'No Blocked Users',
            message: 'You haven\'t blocked any users yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: validUsers.length,
          itemBuilder: (context, index) {
            final user = validUsers[index];
            return _buildBlockedUserCard(context, ref, user, currentUserId);
          },
        );
      },
    );
  }

  Future<List<UserModel?>> _fetchUserDetails(List<String> userIds) async {
    final authDataSource = AuthMockDataSource.instance;
    final futures = userIds.map((userId) => authDataSource.getUserById(userId));
    return await Future.wait(futures);
  }

  Widget _buildBlockedUserCard(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    String currentUserId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          user.businessName ?? user.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name),
            if (user.businessDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                user.businessDescription!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              user.role.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () => _showUnblockDialog(context, ref, user, currentUserId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Unblock'),
        ),
        onTap: () {
          // Navigate to user profile (even though blocked, user can still view to unblock)
          context.push('/profile/${user.id}');
        },
      ),
    );
  }

  void _showUnblockDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    String currentUserId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${user.businessName ?? user.name}? '
          'You will be able to see their posts, send messages, and place orders with them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(blocksNotifierProvider.notifier).unblockUser(
                      currentUserId,
                      user.id,
                    );
                
                // Invalidate providers to refresh UI
                ref.invalidate(blockedUsersProvider(currentUserId));
                ref.invalidate(isBlockedProvider((blockerId: currentUserId, blockedId: user.id)));
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.businessName ?? user.name} has been unblocked'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to unblock user: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}

