import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/messages/data/models/chat_model.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';

class ChatCard extends ConsumerWidget {
  const ChatCard({
    required this.chat,
    required this.currentUserId,
    super.key,
  });

  final ChatModel chat;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherParticipantName = chat.getOtherParticipantName(currentUserId);
    final otherParticipantImage = chat.getOtherParticipantImage(currentUserId);
    final unreadCount = chat.getUnreadCount(currentUserId);
    final isUnread = unreadCount > 0;
    final lastMessage = chat.lastMessage ?? 'No messages yet';
    final lastMessageTime = chat.lastMessageTime;
    final isSentByMe = chat.lastMessageSenderId == currentUserId;

    final isArchived = chat.isArchivedBy(currentUserId);
    final isMuted = chat.isMutedBy(currentUserId);

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: isArchived ? Colors.green : Colors.orange,
        child: Icon(
          isArchived ? Icons.unarchive : Icons.archive,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive/Unarchive
          return true;
        } else {
          // Delete
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Chat'),
              content: const Text('Are you sure you want to delete this chat?'),
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
          ) ?? false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Archive/Unarchive
          ref.read(messagesProvider.notifier).archiveChat(
            chat.id,
            currentUserId,
            !isArchived,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isArchived ? 'Chat unarchived' : 'Chat archived'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(messagesProvider.notifier).archiveChat(
                    chat.id,
                    currentUserId,
                    isArchived,
                  );
                },
              ),
            ),
          );
        } else {
          // Delete
          ref.read(messagesProvider.notifier).deleteChat(chat.id);
        }
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: otherParticipantImage != null
                  ? NetworkImage(otherParticipantImage)
                  : null,
              child: otherParticipantImage == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            if (isArchived)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.archive,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherParticipantName,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isArchived
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
            if (isArchived)
              Icon(
                Icons.archive,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            if (isMuted)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.notifications_off,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        subtitle: Text(
          isSentByMe ? 'You: $lastMessage' : lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUnread
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessageTime != null)
              Text(
                timeago.format(lastMessageTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () => context.push('/messages/chat/${chat.id}'),
        tileColor: isUnread
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
            : null,
      ),
    );
  }
}

