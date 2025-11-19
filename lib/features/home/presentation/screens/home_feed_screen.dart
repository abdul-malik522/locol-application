import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/presentation/widgets/stories_widget.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postsProvider.notifier).loadPosts(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(postsProvider.notifier).loadMorePosts();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(postsProvider.notifier).loadPosts(refresh: true);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(postsState),
      ),
    );
  }

  Widget _buildBody(PostsState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && state.posts.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () => ref.read(postsProvider.notifier).loadPosts(refresh: true),
      );
    }

    if (state.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.feed_outlined,
        title: 'No Posts Yet',
        message: 'Be the first to share your products or requests!',
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: const StoriesWidget(),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedSellersSection(),
        ),
        SliverToBoxAdapter(
          child: _buildFilterChips(),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < state.posts.length) {
                return PostCard(post: state.posts[index]);
              }
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return null;
            },
            childCount: state.posts.length + (state.isLoading ? 1 : 0),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSellersSection() {
    final featuredPostsAsync = ref.watch(featuredSellerPostsProvider);

    return featuredPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Featured Sellers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: InkWell(
                        onTap: () => context.push('/post/${post.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.imageUrls.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  post.imageUrls.first,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.userName,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (post.price != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${post.price!.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(postsProvider).filter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == 'all',
            onTap: () => ref.read(postsProvider.notifier).setFilter('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sellers',
            isSelected: currentFilter == 'sellers',
            onTap: () => ref.read(postsProvider.notifier).setFilter('sellers'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Restaurants',
            isSelected: currentFilter == 'restaurants',
            onTap: () =>
                ref.read(postsProvider.notifier).setFilter('restaurants'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Trending',
            isSelected: currentFilter == 'trending',
            onTap: () => ref.read(postsProvider.notifier).setFilter('trending'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Posts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('More filter options coming soon...'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
