import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/create/data/models/draft_post_model.dart';
import 'package:localtrade/features/create/providers/drafts_provider.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Drafts'),
        body: const Center(
          child: Text('Please login to view drafts'),
        ),
      );
    }

    final drafts = ref.watch(draftsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Drafts'),
      body: drafts.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                return _buildDraftCard(context, ref, draft, currentUser.id);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drafts_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No drafts yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start creating a post and save it as a draft',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    WidgetRef ref,
    DraftPostModel draft,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _continueDraft(context, ref, draft, userId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      draft.title.isEmpty ? '(Untitled)' : draft.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Continue Editing'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _continueDraft(context, ref, draft, userId);
                      } else if (value == 'delete') {
                        _deleteDraft(context, ref, draft.id, userId);
                      }
                    },
                  ),
                ],
              ),
              if (draft.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  draft.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (draft.category != null)
                    Chip(
                      label: Text(draft.category!),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  if (draft.price != null)
                    Chip(
                      label: Text('\$${draft.price!.toStringAsFixed(2)}'),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  if (draft.quantity != null)
                    Chip(
                      label: Text(draft.quantity!),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  if (draft.imagePaths.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.image, size: 16),
                      label: Text('${draft.imagePaths.length} image(s)'),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${timeago.format(draft.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueDraft(
    BuildContext context,
    WidgetRef ref,
    DraftPostModel draft,
    String userId,
  ) async {
    // Save as current draft so it loads in create screen
    final draftsNotifier = ref.read(draftsProvider(userId).notifier);
    await draftsNotifier.saveCurrentDraft(draft);
    
    // Also save to drafts list to update timestamp
    await draftsNotifier.saveDraft(draft);
    
    // Navigate to create screen
    if (context.mounted) {
      context.push('/create');
    }
  }

  void _deleteDraft(
    BuildContext context,
    WidgetRef ref,
    String draftId,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text('Are you sure you want to delete this draft?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final draftsNotifier = ref.read(draftsProvider(userId).notifier);
      await draftsNotifier.deleteDraft(draftId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted')),
        );
      }
    }
  }
}

