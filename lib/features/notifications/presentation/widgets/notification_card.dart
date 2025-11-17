import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/features/notifications/data/models/notification_model.dart';
import 'package:localtrade/features/notifications/providers/notifications_provider.dart';

class NotificationCard extends ConsumerWidget {
  const NotificationCard({required this.notification, super.key});

  final NotificationModel notification;

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Mark as read
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);

    // Navigate based on type
    if (notification.relatedId == null) return;

    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        context.push('/post/${notification.relatedId}');
        break;
      case NotificationType.order:
        context.push('/orders');
        break;
      case NotificationType.message:
        context.push('/messages/chat/${notification.relatedId}');
        break;
      case NotificationType.system:
        // Show dialog with full message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).deleteNotification(
              notification.id,
            );
      },
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        child: Container(
          color: notification.isRead
              ? null
              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.iconColor.withOpacity(0.1),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 24,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

