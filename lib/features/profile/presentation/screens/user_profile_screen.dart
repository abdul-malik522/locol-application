import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';
import 'package:localtrade/features/profile/data/models/business_hours_model.dart';
import 'package:localtrade/features/profile/data/models/certification_model.dart';
import 'package:localtrade/features/profile/data/models/user_report_model.dart';
import 'package:localtrade/features/profile/data/models/verification_badge_model.dart';
import 'package:localtrade/features/profile/presentation/widgets/certification_widget.dart';
import 'package:localtrade/features/profile/presentation/widgets/verification_badge_widget.dart';
import 'package:localtrade/features/profile/data/services/profile_share_service.dart';
import 'package:localtrade/features/profile/providers/blocks_provider.dart';
import 'package:localtrade/features/profile/data/datasources/follows_datasource.dart';
import 'package:localtrade/features/profile/providers/follows_provider.dart';
import 'package:localtrade/features/profile/providers/user_reports_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:uuid/uuid.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = _getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Check if viewing own profile
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.id == userId) {
      if (mounted) {
        context.go('/profile');
      }
      return;
    }

    try {
      final user = await AuthMockDataSource.instance.getCurrentUser(userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String? _getUserId() {
    final state = GoRouterState.of(context);
    return state.pathParameters['userId'];
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _user == null) return;

    // Navigate to chat or create new chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting chat...')),
    );
    // In real app, would create chat and navigate
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Profile'),
        body: LoadingIndicator(),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Profile'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('User not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final postsState = ref.watch(postsProvider);
    final userPosts = postsState.posts
        .where((post) => post.userId == _user!.id)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildProfileInfo(context),
          ),
          SliverToBoxAdapter(
            child: _buildStats(context, userPosts.length),
          ),
          SliverToBoxAdapter(
            child: _buildActionButtons(context),
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

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: () {
            // Show QR code for this user's profile
            // Note: In a real app, this would generate a QR code for the viewed user
            // For now, we'll show a message that QR codes are only for own profile
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR codes are available for your own profile only'),
              ),
            );
          },
          tooltip: 'QR Code',
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => _showShareDialog(context),
          tooltip: 'Share Profile',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: _user!.coverImageUrl ??
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
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
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
                backgroundImage: _user!.profileImageUrl != null
                    ? NetworkImage(_user!.profileImageUrl!)
                    : null,
                child: _user!.profileImageUrl == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _user!.businessName ?? _user!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (_user!.verificationBadges.isNotEmpty) ...[
                const SizedBox(width: 8),
                VerificationBadgesWidget(
                  badges: _user!.verificationBadges,
                  size: 18,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _user!.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                avatar: Icon(
                  _user!.role.icon,
                  size: 16,
                ),
                label: Text(_user!.role.label),
              ),
              if (_user!.verificationBadges.isNotEmpty) ...[
                const SizedBox(width: 8),
                VerificationBadgesWidget(
                  badges: _user!.verificationBadges,
                  size: 16,
                  showLabel: true,
                ),
              ],
            ],
          ),
          if (_user!.rating > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                RatingBarIndicator(
                  rating: _user!.rating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_user!.rating.toStringAsFixed(1)} (${_user!.reviewCount} reviews)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (_user!.businessDescription != null) ...[
            const SizedBox(height: 16),
            Text(
              _user!.businessDescription!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          if (_user!.phoneNumber != null)
            _buildContactInfo(
              context,
              Icons.phone_outlined,
              _user!.phoneNumber!,
            ),
          if (_user!.address != null)
            _buildContactInfo(
              context,
              Icons.location_on_outlined,
              _user!.address!,
            ),
          if (_user!.isRestaurant && _user!.businessHours != null) ...[
            const SizedBox(height: 16),
            _buildBusinessHours(context),
          ],
          if (_user!.certifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCertifications(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCertifications(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
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
          certifications: _user!.certifications,
          wrap: true,
        ),
      ],
    );
  }

  Widget _buildBusinessHours(BuildContext context) {
    final businessHours = _user!.businessHours!;
    final isOpen = businessHours.isCurrentlyOpen();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
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

  Widget _buildStats(BuildContext context, int postsCount) {
    final followerCountAsync = ref.watch(followerCountProvider(_user!.id));
    final followingCountAsync = ref.watch(followingCountProvider(_user!.id));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Posts', postsCount.toString()),
          _buildStatItem(context, 'Orders', '0'), // Placeholder
          _buildStatItem(
            context,
            'Followers',
            followerCountAsync.when(
              data: (count) => count.toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            onTap: () => context.push('/followers/${_user!.id}'),
          ),
          _buildStatItem(
            context,
            'Following',
            followingCountAsync.when(
              data: (count) => count.toString(),
              loading: () => '...',
              error: (_, __) => '0',
            ),
            onTap: () => context.push('/following/${_user!.id}'),
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

  Widget _buildActionButtons(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || currentUser.id == _user!.id) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingProvider(_user!.id));
    final isBlockedAsync = ref.watch(
      isBlockedProvider(
        (blockerId: currentUser.id, blockedId: _user!.id),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Contact',
                  onPressed: isBlockedAsync.valueOrNull == true ? null : _startChat,
                  icon: Icons.chat_bubble_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isFollowingAsync.when(
                  data: (isFollowing) => CustomButton(
                    text: isFollowing ? 'Following' : 'Follow',
                    onPressed: isBlockedAsync.valueOrNull == true
                        ? null
                        : () => _toggleFollow(context, currentUser.id, _user!.id, isFollowing),
                    variant: isFollowing
                        ? CustomButtonVariant.outlined
                        : CustomButtonVariant.filled,
                    icon: isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                  ),
                  loading: () => CustomButton(
                    text: 'Loading...',
                    onPressed: null,
                    variant: CustomButtonVariant.outlined,
                    icon: Icons.person_add_outlined,
                  ),
                  error: (_, __) => CustomButton(
                    text: 'Follow',
                    onPressed: isBlockedAsync.valueOrNull == true
                        ? null
                        : () => _toggleFollow(context, currentUser.id, _user!.id, false),
                    variant: CustomButtonVariant.outlined,
                    icon: Icons.person_add_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: isBlockedAsync.when(
                  data: (isBlocked) => OutlinedButton.icon(
                    onPressed: () => isBlocked
                        ? _unblockUser(context, currentUser.id, _user!.id)
                        : _blockUser(context, currentUser.id, _user!.id),
                    icon: Icon(isBlocked ? Icons.block : Icons.block_outlined),
                    label: Text(isBlocked ? 'Unblock' : 'Block'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: isBlocked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  loading: () => OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('Loading...'),
                  ),
                  error: (_, __) => OutlinedButton.icon(
                    onPressed: () => _blockUser(context, currentUser.id, _user!.id),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Block'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReportDialog(context, ref, currentUser.id, _user!.id),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _blockUser(
    BuildContext context,
    String blockerId,
    String blockedId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${_user?.name ?? 'this user'}? '
          'You won\'t be able to see their posts, send messages, or place orders with them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(blocksNotifierProvider.notifier).blockUser(blockerId, blockedId);
      
      // Unfollow if following
      final followsDataSource = ref.read(followsDataSourceProvider);
      final isFollowing = await followsDataSource.isFollowing(blockerId, blockedId);
      if (isFollowing) {
        await ref.read(followsNotifierProvider.notifier).unfollowUser(blockerId, blockedId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_user?.name ?? 'User'} has been blocked')),
        );
        
        // Invalidate providers to refresh UI
        ref.invalidate(isBlockedProvider((blockerId: blockerId, blockedId: blockedId)));
        ref.invalidate(isFollowingProvider(blockedId));
        ref.invalidate(followerCountProvider(blockedId));
        ref.invalidate(followingCountProvider(blockerId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _unblockUser(
    BuildContext context,
    String blockerId,
    String blockedId,
  ) async {
    try {
      await ref.read(blocksNotifierProvider.notifier).unblockUser(blockerId, blockedId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_user?.name ?? 'User'} has been unblocked')),
        );
        
        // Invalidate providers to refresh UI
        ref.invalidate(isBlockedProvider((blockerId: blockerId, blockedId: blockedId)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user: ${e.toString()}')),
        );
      }
    }
  }

  void _showShareDialog(BuildContext context) {
    if (_user == null) return;

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
                  () => _shareProfile(context, SharePlatform.native),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.whatsapp,
                  Icons.chat,
                  () => _shareProfile(context, SharePlatform.whatsapp),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.facebook,
                  Icons.facebook,
                  () => _shareProfile(context, SharePlatform.facebook),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.twitter,
                  Icons.alternate_email,
                  () => _shareProfile(context, SharePlatform.twitter),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.email,
                  Icons.email,
                  () => _shareProfile(context, SharePlatform.email),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.sms,
                  Icons.sms,
                  () => _shareProfile(context, SharePlatform.sms),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.copyLink,
                  Icons.link,
                  () => _shareProfile(context, SharePlatform.copyLink),
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
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              platform.label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProfile(
    BuildContext context,
    SharePlatform platform,
  ) async {
    if (_user == null) return;

    try {
      await ProfileShareService.instance.shareToPlatform(_user!, platform);
      if (mounted) {
        final message = platform == SharePlatform.copyLink
            ? 'Profile link copied to clipboard!'
            : 'Profile shared via ${platform.label}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    String reporterId,
    String reportedUserId,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to report users')),
        );
      }
      return;
    }

    // Check if user already reported this user
    final reportsDataSource = ref.read(userReportsDataSourceProvider);
    final alreadyReported = await reportsDataSource.hasUserReportedUser(
      reportedUserId,
      reporterId,
    );

    if (alreadyReported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reported this user'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    UserReportReason? selectedReason;
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why are you reporting ${_user?.name ?? 'this user'}?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...UserReportReason.values.map((reason) {
                    return RadioListTile<UserReportReason>(
                      title: Row(
                        children: [
                          Icon(reason.icon, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(reason.label)),
                        ],
                      ),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: (value) {
                        setState(() => selectedReason = value);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Additional details (optional)',
                      hintText: 'Please provide more information...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                descriptionController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a reason')),
                  );
                  return;
                }

                final description = descriptionController.text.trim();
                if (description.isEmpty && selectedReason == UserReportReason.other) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide details for "Other" reason'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final report = UserReportModel(
                    id: _uuid.v4(),
                    reportedUserId: reportedUserId,
                    reportedUserName: _user?.name ?? 'Unknown User',
                    reportedBy: reporterId,
                    reportedByName: currentUser.name,
                    reason: selectedReason!,
                    description: description.isEmpty
                        ? 'No additional details provided'
                        : description,
                  );

                  await ref.read(userReportsNotifierProvider.notifier).fileReport(report);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User reported successfully. Thank you for keeping our community safe.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to report user: ${e.toString()}')),
                    );
                  }
                } finally {
                  descriptionController.dispose();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }
}
