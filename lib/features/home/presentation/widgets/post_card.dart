import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/datasources/post_reports_datasource.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/data/models/post_report_model.dart';
import 'package:localtrade/features/home/data/services/post_share_service.dart';
import 'package:localtrade/features/home/providers/favorites_provider.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';

class PostCard extends ConsumerWidget {
  const PostCard({required this.post, super.key});

  final PostModel post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isRestaurantViewingSeller =
        currentUser?.isRestaurant == true && post.userRole == UserRole.seller;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/post/${post.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildImageCarousel(context),
            _buildContent(context),
            _buildActions(context, ref, isRestaurantViewingSeller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: post.userProfileImage != null
                ? NetworkImage(post.userProfileImage!)
                : null,
            child: post.userProfileImage == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${post.location} • ${timeago.format(post.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'share') {
                _showShareDialog(context, post);
              } else if (value == 'report') {
                _showReportDialog(context, ref, post);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    if (post.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: post.imageUrls.length,
        itemBuilder: (_, index) => CachedImage(
          imageUrl: post.imageUrls[index],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Chip(
                label: Text(post.category),
                labelStyle: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.postType == PostType.product && post.price != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  Formatters.formatCurrency(post.price!),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (post.quantity != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${post.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ] else if (post.quantity != null) ...[
            const SizedBox(height: 8),
            Text(
              'Quantity needed: ${post.quantity}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          if (post.expiresAt != null && !post.isExpired) ...[
            const SizedBox(height: 8),
            _buildExpirationIndicator(context),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    bool showContactButton,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : null,
            ),
            onPressed: () {
              final userId = ref.read(currentUserProvider)?.id ?? '';
              HapticFeedback.lightImpact();
              ref.read(postsProvider.notifier).likePost(post.id, userId);
            },
          ),
          Text('${post.likeCount}'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () => context.push('/post/${post.id}'),
          ),
          Text('${post.commentCount}'),
          const SizedBox(width: 16),
          Consumer(
            builder: (context, ref, _) {
              final currentUser = ref.watch(currentUserProvider);
              if (currentUser == null) return const SizedBox.shrink();
              
              final favoritesAsync = ref.watch(favoritesNotifierProvider(currentUser.id));
              final isFavorited = favoritesAsync.valueOrNull?.contains(post.id) ?? false;
              
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: isFavorited ? Colors.amber : null,
                ),
                onPressed: () async {
                  final favoritesNotifier = ref.read(favoritesNotifierProvider(currentUser.id).notifier);
                  try {
                    await favoritesNotifier.toggleFavorite(post.id);
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorited
                                ? 'Removed from favorites'
                                : 'Added to favorites',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update favorites: ${e.toString()}')),
                      );
                    }
                  }
                },
                tooltip: isFavorited ? 'Remove from favorites' : 'Add to favorites',
              );
            },
          ),
          const Spacer(),
          if (showContactButton)
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat feature will be available soon'),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Contact Seller'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpirationIndicator(BuildContext context) {
    final timeUntilExpiry = post.expiresAt!.difference(DateTime.now());
    final isExpiringSoon = post.isExpiringSoon;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? Colors.orange.withOpacity(0.1)
            : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.orange
              : Theme.of(context).colorScheme.secondary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: isExpiringSoon
                ? Colors.orange
                : Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTimeUntilExpiry(timeUntilExpiry),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isExpiringSoon
                      ? Colors.orange
                      : Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTimeUntilExpiry(Duration duration) {
    if (duration.inDays > 0) {
      return 'Expires in ${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'Expires in ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return 'Expires in ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Expires soon';
    }
  }
}

