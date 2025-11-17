import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/notifications/presentation/widgets/notification_card.dart';
import 'package:localtrade/features/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref
            .read(notificationsProvider.notifier)
            .loadNotifications(currentUser.id);
      }
    });
  }

  Future<void> _onRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref
          .read(notificationsProvider.notifier)
          .loadNotifications(currentUser.id);
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Mark all as read'),
              onTap: () {
                Navigator.pop(context);
                final currentUser = ref.read(currentUserProvider);
                if (currentUser != null) {
                  ref
                      .read(notificationsProvider.notifier)
                      .markAllAsRead(currentUser.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear all'),
              onTap: () {
                Navigator.pop(context);
                _showClearAllDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                ref
                    .read(notificationsProvider.notifier)
                    .clearAll(currentUser.id);
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Notifications'),
        body: Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(notificationsState),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            ref
                .read(notificationsProvider.notifier)
                .loadNotifications(currentUser.id);
          }
        },
      );
    }

    if (state.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        message: 'You\'re all caught up!',
      );
    }

    return ListView.builder(
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return NotificationCard(notification: notification);
      },
    );
  }
}
