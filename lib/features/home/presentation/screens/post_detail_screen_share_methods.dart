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

