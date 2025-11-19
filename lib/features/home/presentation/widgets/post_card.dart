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
            _buildHeader(context, ref),
            _buildImageCarousel(context),
            _buildContent(context),
            _buildActions(context, ref, isRestaurantViewingSeller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
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

  void _showShareDialog(BuildContext context, PostModel post) {
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
                'Share Post',
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
                  () => _sharePost(context, post, SharePlatform.native),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.whatsapp,
                  Icons.chat,
                  () => _sharePost(context, post, SharePlatform.whatsapp),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.facebook,
                  Icons.facebook,
                  () => _sharePost(context, post, SharePlatform.facebook),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.twitter,
                  Icons.alternate_email,
                  () => _sharePost(context, post, SharePlatform.twitter),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.email,
                  Icons.email,
                  () => _sharePost(context, post, SharePlatform.email),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.sms,
                  Icons.sms,
                  () => _sharePost(context, post, SharePlatform.sms),
                ),
                _buildShareOption(
                  context,
                  SharePlatform.copyLink,
                  Icons.link,
                  () => _sharePost(context, post, SharePlatform.copyLink),
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

  Future<void> _sharePost(
    BuildContext context,
    PostModel post,
    SharePlatform platform,
  ) async {
    try {
      final shareService = PostShareService.instance;
      await shareService.shareToPlatform(post, platform);

      if (platform == SharePlatform.copyLink && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to report posts')),
        );
      }
      return;
    }

    // Check if user already reported this post
    final reportsDataSource = PostReportsDataSource.instance;
    final alreadyReported = await reportsDataSource.hasUserReportedPost(
      post.id,
      currentUser.id,
    );

    if (alreadyReported && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reported this post. Our team will review it.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final formKey = GlobalKey<FormState>();
    PostReportReason? selectedReason;
    final descriptionController = TextEditingController();
    String? customReason;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Post'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Help us understand the problem. Why are you reporting this post?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...PostReportReason.values.map((reason) {
                    return RadioListTile<PostReportReason>(
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
                        setState(() {
                          selectedReason = value;
                          if (value != PostReportReason.other) {
                            customReason = null;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  if (selectedReason == PostReportReason.other) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Please specify the reason',
                        hintText: 'Describe why you are reporting this post',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (selectedReason == PostReportReason.other &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please provide a reason';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        customReason = value.trim();
                      },
                    ),
                  ] else if (selectedReason != null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Additional details (optional)',
                        hintText: 'Provide any additional information that might help',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedReason != null) {
                  final finalDescription = selectedReason == PostReportReason.other
                      ? (customReason ?? descriptionController.text.trim())
                      : descriptionController.text.trim().isEmpty
                          ? (selectedReason?.label ?? '')
                          : descriptionController.text.trim();

                  try {
                    final report = PostReportModel(
                      id: '', // Will be generated by datasource
                      postId: post.id,
                      reportedBy: currentUser.id,
                      reportedByName: currentUser.name,
                      reason: selectedReason!,
                      description: finalDescription,
                    );

                    await reportsDataSource.fileReport(report);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Thank you for your report. Our team will review it shortly.',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    descriptionController.dispose();
  }
}

