import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final postsState = ref.watch(postsProvider);
    final ordersState = ref.watch(ordersProvider);
    final aboutTab = _buildAboutTab(context, ref);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Profile'),
        body: Center(child: Text('Please login to view profile')),
      );
    }

    // Filter posts by current user
    final userPosts = postsState.posts
        .where((post) => post.userId == currentUser.id)
        .toList();

    // Count orders
    final userOrders = ordersState.orders
        .where((order) =>
            order.buyerId == currentUser.id || order.sellerId == currentUser.id)
        .length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, currentUser),
          SliverToBoxAdapter(
            child: _buildProfileInfo(context, currentUser),
          ),
          SliverToBoxAdapter(
            child: _buildStats(context, userPosts.length, userOrders),
          ),
          SliverToBoxAdapter(
            child: _buildActionButtons(context),
          ),
          SliverToBoxAdapter(
            child: _buildTabs(context),
          ),
          if (userPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.post_add_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first post!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(post: userPosts[index]),
                childCount: userPosts.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, currentUser) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: currentUser.coverImageUrl ??
                  'https://picsum.photos/400/200?random=cover',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.push('/edit-profile'),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: currentUser.profileImageUrl != null
                    ? NetworkImage(currentUser.profileImageUrl!)
                    : null,
                child: currentUser.profileImageUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const Spacer(),
              if (currentUser.isSeller)
                Switch(
                  value: currentUser.isActive,
                  onChanged: (value) {
                    // Update active status
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status update feature coming soon'),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.businessName ?? currentUser.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: Icon(
              currentUser.role.icon,
              size: 16,
            ),
            label: Text(currentUser.role.label),
          ),
          if (currentUser.rating > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                RatingBarIndicator(
                  rating: currentUser.rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${currentUser.rating.toStringAsFixed(1)} (${currentUser.reviewCount} reviews)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (currentUser.businessDescription != null) ...[
            const SizedBox(height: 16),
            Text(
              currentUser.businessDescription!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          if (currentUser.phoneNumber != null)
            _buildContactInfo(
              context,
              Icons.phone_outlined,
              currentUser.phoneNumber!,
            ),
          if (currentUser.address != null)
            _buildContactInfo(
              context,
              Icons.location_on_outlined,
              currentUser.address!,
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, int postsCount, int ordersCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Posts', postsCount.toString()),
          _buildStatItem(context, 'Orders', ordersCount.toString()),
          _buildStatItem(context, 'Followers', '0'), // Placeholder
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Edit Profile',
              onPressed: () => context.push('/edit-profile'),
              variant: CustomButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Share Profile',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
              variant: CustomButtonVariant.outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Reviews'),
              Tab(text: 'About'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                const Center(child: Text('Posts tab - shown above')),
                const Center(child: Text('Reviews coming soon')),
                aboutTab,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentUser.businessName != null) ...[
            Text(
              'Business Name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              currentUser.businessName!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
          if (currentUser.businessDescription != null) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              currentUser.businessDescription!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Contact Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (currentUser.phoneNumber != null)
            _buildInfoRow(context, 'Phone', currentUser.phoneNumber!),
          if (currentUser.address != null)
            _buildInfoRow(context, 'Address', currentUser.address!),
          if (currentUser.email != null)
            _buildInfoRow(context, 'Email', currentUser.email!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
