import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/data/datasources/post_reports_datasource.dart';
import 'package:localtrade/features/home/data/models/comment_model.dart';
import 'package:localtrade/features/home/data/models/post_model.dart';
import 'package:localtrade/features/home/data/models/post_report_model.dart';
import 'package:localtrade/features/home/data/services/post_share_service.dart';
import 'package:localtrade/features/home/data/models/price_alert_model.dart';
import 'package:localtrade/features/home/data/models/stock_notification_model.dart';
import 'package:localtrade/features/home/providers/favorites_provider.dart';
import 'package:localtrade/features/home/providers/price_alerts_provider.dart';
import 'package:localtrade/features/home/providers/posts_provider.dart';
import 'package:localtrade/features/home/providers/stock_notifications_provider.dart';
import 'package:uuid/uuid.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final postId = _getPostId();
    if (postId == null) return;
    setState(() => _isLoadingComments = true);
    final comments = await ref.read(postsProvider.notifier).getComments(postId);
    setState(() {
      _comments = comments;
      _isLoadingComments = false;
    });
  }

  String? _getPostId() {
    final state = GoRouterState.of(context);
    return state.pathParameters['id'];
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postId = _getPostId();
    final currentUser = ref.read(currentUserProvider);
    if (postId == null || currentUser == null) return;

    final comment = CommentModel(
      id: _uuid.v4(),
      postId: postId,
      userId: currentUser.id,
      userName: currentUser.name,
      userProfileImage: currentUser.profileImageUrl,
      text: text,
    );

    await ref.read(postsProvider.notifier).addComment(postId, comment);
    _commentController.clear();
    await _loadComments();
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(postsProvider.notifier).deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          context.pop(); // Navigate back after deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _archivePost(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Post'),
        content: const Text(
          'This post will be hidden from the feed but can be restored later. '
          'You can view archived posts in your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(postsProvider.notifier).archivePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post archived successfully')),
          );
          context.pop(); // Navigate back after archiving
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to archive post: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _unarchivePost(
    BuildContext context,
    WidgetRef ref,
    String postId,
  ) async {
    try {
      await ref.read(postsProvider.notifier).unarchivePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post unarchived successfully')),
        );
        // Refresh the post detail
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unarchive post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = _getPostId();
    if (postId == null) {
      return const Scaffold(
        body: ErrorView(error: 'Post not found'),
      );
    }

    final postAsync = ref.watch(postByIdProvider(postId));
    final currentUser = ref.read(currentUserProvider);

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return const Scaffold(
            appBar: CustomAppBar(title: 'Post Details'),
            body: Center(child: Text('Post not found')),
          );
        }

        final isRestaurantViewingSeller =
            currentUser?.isRestaurant == true && post.userRole == UserRole.seller;
        final isOwner = currentUser?.id == post.userId;

        return _buildPostDetail(context, ref, post, isOwner, isRestaurantViewingSeller);
      },
      loading: () => const Scaffold(
        appBar: CustomAppBar(title: 'Post Details'),
        body: LoadingIndicator(),
      ),
      error: (error, _) => Scaffold(
        appBar: const CustomAppBar(title: 'Post Details'),
        body: ErrorView(error: error.toString()),
      ),
    );
  }

  Widget _buildPostDetail(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
    bool isOwner,
    bool isRestaurantViewingSeller,
  ) {
    return Scaffold(
      appBar: CustomAppBar(
        title: post.isArchived ? 'Archived Post' : 'Post Details',
        actions: [
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
                    if (mounted) {
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
                    if (mounted) {
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareDialog(context, post),
            tooltip: 'Share Post',
          ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _showReportDialog(context, ref, post),
              tooltip: 'Report Post',
            ),
          if (isOwner) ...[
            IconButton(
              icon: Icon(post.isArchived ? Icons.unarchive : Icons.archive),
              onPressed: () => post.isArchived
                  ? _unarchivePost(context, ref, post.id)
                  : _archivePost(context, ref, post.id),
              tooltip: post.isArchived ? 'Unarchive Post' : 'Archive Post',
            ),
            if (!post.isArchived)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/edit-post/${post.id}'),
                tooltip: 'Edit Post',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context, ref, post.id),
              tooltip: 'Delete Post',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (post.isArchived)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.archive,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This post is archived and hidden from the feed',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(post),
                  _buildHeader(context, post),
                  _buildContent(context, ref, post, isOwner),
                  _buildCommentsSection(context),
                ],
              ),
            ),
          ),
          if (isRestaurantViewingSeller)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Contact Seller',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat feature will be available soon'),
                    ),
                  );
                },
                fullWidth: true,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _commentController,
                  label: 'Comment',
                  hint: 'Add a comment...',
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _addComment,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(PostModel post) {
    if (post.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: post.imageUrls.length,
        itemBuilder: (context, index) => CachedImage(
          imageUrl: post.imageUrls[index],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
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
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PostModel post, bool isOwner) {
    final currentUser = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Chip(label: Text(post.category)),
          const SizedBox(height: 16),
          Text(
            post.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (post.postType == PostType.product && post.price != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    Formatters.formatCurrency(post.price!),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (post.quantity != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${post.quantity}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
          ] else if (post.quantity != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity needed: ${post.quantity}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                post.location,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text('${post.likeCount} likes'),
              const SizedBox(width: 16),
              Icon(
                Icons.comment_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text('${post.commentCount} comments'),
            ],
          ),
          if (post.price != null && !isOwner && currentUser?.isRestaurant == true) ...[
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Price Alert'),
                    onPressed: () => _showPriceAlertDialog(context, ref, post),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Stock Alert'),
                    onPressed: () => _showStockNotificationDialog(context, ref, post),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    if (_isLoadingComments) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No comments yet. Be the first to comment!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._comments.map((comment) => _CommentCard(comment: comment)),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.userProfileImage != null
                ? NetworkImage(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  comment.text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

      if (platform == SharePlatform.copyLink && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard!')),
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

      if (platform == SharePlatform.copyLink && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard!')),
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
    PostModel post,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      if (mounted) {
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

    if (alreadyReported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reported this post. Our team will review it.'),
        ),
      );
      return;
    }

    if (!mounted) return;

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

                    if (mounted) {
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
                    if (mounted) {
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

  Future<void> _showPriceAlertDialog(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || post.price == null) return;

    final priceAlertsNotifier = ref.read(priceAlertsProvider(currentUser.id).notifier);
    final hasAlert = await priceAlertsNotifier.hasAlertForPost(post.id);

    if (hasAlert) {
      // Show existing alert info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Price Alert Active'),
          content: const Text('You already have a price alert set for this product.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final alertsState = ref.read(priceAlertsProvider(currentUser.id));
                final alert = alertsState.alerts.firstWhere((a) => a.postId == post.id && a.isActive);
                await priceAlertsNotifier.deleteAlert(alert.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Price alert removed')),
                  );
                }
              },
              child: const Text('Remove Alert', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    final targetPriceController = TextEditingController(
      text: (post.price! * 0.9).toStringAsFixed(2), // Default to 10% discount
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Price Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Price: \$${post.price!.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: targetPriceController,
              decoration: const InputDecoration(
                labelText: 'Alert me when price drops to',
                prefixText: '\$',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be notified when the price drops to or below this amount.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final targetPrice = double.tryParse(targetPriceController.text);
              if (targetPrice == null || targetPrice >= post.price!) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Target price must be less than current price')),
                );
                return;
              }

              final alert = PriceAlertModel(
                id: const Uuid().v4(),
                userId: currentUser.id,
                postId: post.id,
                postTitle: post.title,
                currentPrice: post.price!,
                targetPrice: targetPrice,
              );

              await priceAlertsNotifier.createAlert(alert);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Price alert set!')),
                );
              }
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStockNotificationDialog(
    BuildContext context,
    WidgetRef ref,
    PostModel post,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Check if post is out of stock (quantity is null or empty)
    final isOutOfStock = post.quantity == null || post.quantity!.isEmpty || post.quantity == '0';

    if (!isOutOfStock) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Product In Stock'),
          content: const Text('This product is currently in stock. Stock notifications are only available for out-of-stock items.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final stockNotificationsNotifier = ref.read(stockNotificationsProvider(currentUser.id).notifier);
    final hasNotification = await stockNotificationsNotifier.hasNotificationForPost(post.id);

    if (hasNotification) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stock Notification Active'),
          content: const Text('You already have a stock notification set for this product.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final notificationsState = ref.read(stockNotificationsProvider(currentUser.id));
                final notification = notificationsState.notifications.firstWhere((n) => n.postId == post.id && n.isActive);
                await stockNotificationsNotifier.deleteNotification(notification.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock notification removed')),
                  );
                }
              },
              child: const Text('Remove Notification', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Stock Notification'),
        content: const Text('You will be notified when this product becomes available again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final notification = StockNotificationModel(
                id: const Uuid().v4(),
                userId: currentUser.id,
                postId: post.id,
                postTitle: post.title,
                wasOutOfStock: true,
              );

              await stockNotificationsNotifier.createNotification(notification);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stock notification set!')),
                );
              }
            },
            child: const Text('Set Notification'),
          ),
        ],
      ),
    );
  }
}
