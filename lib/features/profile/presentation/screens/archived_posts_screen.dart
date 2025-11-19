import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class ArchivedPostsScreen extends ConsumerStatefulWidget {
  const ArchivedPostsScreen({super.key});

  @override
  ConsumerState<ArchivedPostsScreen> createState() => _ArchivedPostsScreenState();
}

class _ArchivedPostsScreenState extends ConsumerState<ArchivedPostsScreen> {
  List<PostModel> _archivedPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedPosts();
  }

  Future<void> _loadArchivedPosts() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final posts = await ref.read(postsProvider.notifier).getArchivedPosts(currentUser.id);
      setState(() {
        _archivedPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load archived posts: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Archived Posts'),
        body: const Center(
          child: Text('Please login to view archived posts'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Archived Posts',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArchivedPosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No archived posts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Archived posts will appear here',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadArchivedPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archivedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _archivedPosts[index];
                      return Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              PostCard(post: post),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.archive,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Archived',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(postsProvider.notifier)
                                      .unarchivePost(post.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Post unarchived successfully'),
                                      ),
                                    );
                                    _loadArchivedPosts();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to unarchive: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.unarchive),
                              label: const Text('Unarchive'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}

