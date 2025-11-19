import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';
import 'package:localtrade/features/profile/data/models/business_hours_model.dart';
import 'package:localtrade/features/profile/data/models/certification_model.dart';
import 'package:localtrade/features/profile/data/models/review_model.dart';
import 'package:localtrade/features/profile/data/models/verification_badge_model.dart';
import 'package:localtrade/features/profile/presentation/widgets/certification_widget.dart';
import 'package:localtrade/features/profile/presentation/widgets/verification_badge_widget.dart';
import 'package:localtrade/features/profile/data/services/profile_share_service.dart'
    show ProfileShareService, SharePlatform;
import 'package:localtrade/features/profile/providers/follows_provider.dart';
import 'package:localtrade/features/profile/providers/reviews_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final postsState = ref.watch(postsProvider);
    final ordersState = ref.watch(ordersProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Profile'),
        body: Center(child: Text('Please login to view profile')),
      );
    }

    // Filter posts by current user (exclude archived)
    final userPosts = postsState.posts
        .where((post) => post.userId == currentUser.id && !post.isArchived)
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
            child: _buildStats(context, ref, userPosts.length, userOrders, currentUser.id),
          ),
          SliverToBoxAdapter(
            child: _buildActionButtons(context, ref),
          ),
          SliverToBoxAdapter(
            child: _buildTabs(context, ref),
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

  Widget _buildSliverAppBar(BuildContext context, UserModel currentUser) {
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
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () => context.push('/analytics'),
          tooltip: 'View Analytics',
        ),
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

  Widget _buildProfileInfo(BuildContext context, UserModel currentUser) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  currentUser.businessName ?? currentUser.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (currentUser.verificationBadges.isNotEmpty) ...[
                const SizedBox(width: 8),
                VerificationBadgesWidget(
                  badges: currentUser.verificationBadges,
                  size: 18,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentUser.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                avatar: Icon(
                  currentUser.role.icon,
                  size: 16,
                ),
                label: Text(currentUser.role.label),
              ),
              if (currentUser.verificationBadges.isNotEmpty) ...[
                const SizedBox(width: 8),
                VerificationBadgesWidget(
                  badges: currentUser.verificationBadges,
                  size: 16,
                  showLabel: true,
                ),
              ],
            ],
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

  Widget _buildStats(
    BuildContext context,
    WidgetRef ref,
    int postsCount,
    int ordersCount,
    String userId,
  ) {
    final followerCountAsync = ref.watch(followerCountProvider(userId));
    final followingCountAsync = ref.watch(followingCountProvider(userId));

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
          _buildStatItem(
            context,
            'Followers',
            followerCountAsync.when(
              data: (count) => count.toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            onTap: () => context.push('/followers/${userId}'),
          ),
          _buildStatItem(
            context,
            'Following',
            followingCountAsync.when(
              data: (count) => count.toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            onTap: () => context.push('/following/${userId}'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final widget = Column(
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: widget,
        ),
      );
    }

    return widget;
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      _showShareDialog(context, user);
                    }
                  },
                  variant: CustomButtonVariant.outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/qr-code-profile'),
            icon: const Icon(Icons.qr_code),
            label: const Text('Show QR Code'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/archived-posts'),
            icon: const Icon(Icons.archive),
            label: const Text('View Archived Posts'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.bookmark),
            label: const Text('View Favorites'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

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
            height: 400,
            child: TabBarView(
              children: [
                const Center(child: Text('Posts tab - shown above')),
                _buildReviewsTab(context, ref, currentUser.id),
                _buildAboutTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(BuildContext context, WidgetRef ref, String userId) {
    final reviewsAsync = ref.watch(reviewsForUserProvider(userId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Reviews Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Reviews from completed orders will appear here.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reviewsForUserProvider(userId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(context, ref, review);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading reviews: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(reviewsForUserProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    WidgetRef ref,
    ReviewModel review,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/order/${review.orderId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Order #${review.orderNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20,
                ),
              ],
            ),
            if (review.productImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: review.productImage!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              review.productName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (review.review != null && review.review!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.review!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
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
          if (currentUser.isRestaurant && currentUser.businessHours != null) ...[
            const SizedBox(height: 24),
            _buildBusinessHours(context, currentUser.businessHours!),
          ],
          if (currentUser.certifications.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildCertifications(context, currentUser.certifications),
          ],
        ],
      ),
    );
  }

  Widget _buildCertifications(BuildContext context, List<CertificationModel> certifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Certifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CertificationsWidget(
          certifications: certifications,
          wrap: true,
        ),
      ],
    );
  }

  Widget _buildBusinessHours(BuildContext context, BusinessHoursModel businessHours) {
    final isOpen = businessHours.isCurrentlyOpen();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Business Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOpen
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOpen ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOpen ? 'Open' : 'Closed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...DayOfWeek.values.map((day) {
          final dayHours = businessHours.getHoursForDay(day);
          if (dayHours == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    day.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    dayHours.displayText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dayHours.isClosed
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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

  void _showShareDialog(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Share Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildShareOption(
                  context,
                  SharePlatform.native,
                  Icons.share,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.native),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.whatsapp,
                  Icons.chat,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.whatsapp),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.facebook,
                  Icons.facebook,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.facebook),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.twitter,
                  Icons.alternate_email,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.twitter),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.email,
                  Icons.email,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.email),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.sms,
                  Icons.sms,
                  () => ProfileShareService.instance.shareToPlatform(user, SharePlatform.sms),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.copyLink,
                  Icons.link,
                  () async {
                    await ProfileShareService.instance.shareToPlatform(user, SharePlatform.copyLink);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    SharePlatform platform,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              platform.label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
