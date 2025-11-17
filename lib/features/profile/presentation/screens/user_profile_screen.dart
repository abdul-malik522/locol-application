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
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
          Text(
            _user!.businessName ?? _user!.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _user!.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: Icon(
              _user!.role.icon,
              size: 16,
            ),
            label: Text(_user!.role.label),
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

  Widget _buildStats(BuildContext context, int postsCount) {
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
              text: 'Contact',
              onPressed: _startChat,
              icon: Icons.chat_bubble_outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Follow',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Follow feature coming soon')),
                );
              },
              variant: CustomButtonVariant.outlined,
              icon: Icons.person_add_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
