import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class ScheduledPostsScreen extends ConsumerStatefulWidget {
  const ScheduledPostsScreen({super.key});

  @override
  ConsumerState<ScheduledPostsScreen> createState() => _ScheduledPostsScreenState();
}

class _ScheduledPostsScreenState extends ConsumerState<ScheduledPostsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh scheduled posts when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduledPosts();
    });
  }

  Future<void> _refreshScheduledPosts() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      // Trigger publish check
      await ref.read(postsProvider.notifier).loadPosts(refresh: true);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelScheduledPost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scheduled Post'),
        content: const Text(
          'Are you sure you want to cancel this scheduled post? '
          'You can reschedule it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Scheduled'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(postsProvider.notifier).cancelScheduledPost(postId);
        if (mounted) {
          _showSnackBar('Scheduled post cancelled');
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to cancel: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _publishNow(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Now'),
        content: const Text(
          'Publish this post immediately instead of waiting for the scheduled time?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Scheduled'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(postsProvider.notifier).cancelScheduledPost(postId);
        if (mounted) {
          _showSnackBar('Post published now');
          setState(() {}); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to publish: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Scheduled Posts'),
        body: const Center(
          child: Text('Please login to view scheduled posts'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scheduled Posts',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshScheduledPosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<PostModel>>(
        future: ref.read(postsProvider.notifier).getScheduledPosts(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshScheduledPosts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final scheduledPosts = snapshot.data ?? [];

          if (scheduledPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled posts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schedule posts to publish them automatically at a specific time',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Post'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshScheduledPosts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scheduledPosts.length,
              itemBuilder: (context, index) {
                final post = scheduledPosts[index];
                return _buildScheduledPostCard(context, post);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduledPostCard(BuildContext context, PostModel post) {
    final timeUntilPublish = post.scheduledAt != null
        ? post.scheduledAt!.difference(DateTime.now())
        : null;
    final isOverdue = timeUntilPublish != null && timeUntilPublish.isNegative;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CachedImage(
                imageUrl: post.imageUrls.first,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'publish_now',
                          child: const Row(
                            children: [
                              Icon(Icons.publish, size: 20),
                              SizedBox(width: 8),
                              Text('Publish Now'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancel',
                          child: const Row(
                            children: [
                              Icon(Icons.cancel, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancel', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.push('/edit-post/${post.id}');
                        } else if (value == 'publish_now') {
                          _publishNow(post.id);
                        } else if (value == 'cancel') {
                          _cancelScheduledPost(post.id);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (post.description.isNotEmpty)
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(post.category),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                    if (post.price != null)
                      Chip(
                        label: Text('\$${post.price!.toStringAsFixed(2)}'),
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.orange.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverdue
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning : Icons.schedule,
                        color: isOverdue
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverdue
                                  ? 'Overdue - Should have published'
                                  : 'Scheduled for',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.scheduledAt != null
                                  ? DateFormat('MMM dd, yyyy • hh:mm a')
                                      .format(post.scheduledAt!)
                                  : 'Not scheduled',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (timeUntilPublish != null && !isOverdue) ...[
                              const SizedBox(height: 4),
                              Text(
                                'In ${_formatTimeUntil(timeUntilPublish)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _publishNow(post.id),
                        child: const Text('Publish Now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/edit-post/${post.id}'),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeUntil(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Less than a minute';
    }
  }
}

