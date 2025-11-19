import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/notifications/data/models/notification_model.dart';
import 'package:localtrade/features/notifications/data/models/notification_settings_model.dart';
import 'package:localtrade/features/notifications/providers/notification_settings_provider.dart';
import 'package:localtrade/features/notifications/providers/push_notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Notification Settings'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final settingsAsync = ref.watch(notificationSettingsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Notification Settings'),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsContent(context, ref, settings, currentUser.id),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(notificationSettingsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Master Toggle
          _buildMasterToggle(context, ref, settings, userId),
          const Divider(),
          // Push Notification Status
          _buildSectionHeader(context, 'Push Notifications'),
          _buildPushNotificationStatus(context, ref, userId),
          const Divider(),
          // Quiet Hours
          _buildSectionHeader(context, 'Quiet Hours'),
          _buildQuietHoursSection(context, ref, settings, userId),
          const Divider(),
          // Channel Master Toggles
          _buildSectionHeader(context, 'Notification Channels'),
          _buildChannelToggle(
            context,
            ref,
            settings,
            userId,
            NotificationChannel.push,
            settings.pushEnabled,
          ),
          _buildChannelToggle(
            context,
            ref,
            settings,
            userId,
            NotificationChannel.email,
            settings.emailEnabled,
          ),
          _buildChannelToggle(
            context,
            ref,
            settings,
            userId,
            NotificationChannel.inApp,
            settings.inAppEnabled,
          ),
          const Divider(),
          // Notification Type Settings
          _buildSectionHeader(context, 'Notification Types'),
          _buildTypeSettings(
            context,
            ref,
            settings,
            userId,
            NotificationType.like,
            settings.likeNotifications,
          ),
          _buildTypeSettings(
            context,
            ref,
            settings,
            userId,
            NotificationType.comment,
            settings.commentNotifications,
          ),
          _buildTypeSettings(
            context,
            ref,
            settings,
            userId,
            NotificationType.order,
            settings.orderNotifications,
          ),
          _buildTypeSettings(
            context,
            ref,
            settings,
            userId,
            NotificationType.message,
            settings.messageNotifications,
          ),
          _buildTypeSettings(
            context,
            ref,
            settings,
            userId,
            NotificationType.system,
            settings.systemNotifications,
          ),
          _buildExtendedTypeSettings(
            context,
            ref,
            settings,
            userId,
            ExtendedNotificationType.follow,
            settings.followNotifications,
          ),
          _buildExtendedTypeSettings(
            context,
            ref,
            settings,
            userId,
            ExtendedNotificationType.review,
            settings.reviewNotifications,
          ),
          const Divider(),
          // Reset Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context, ref, userId),
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
  ) {
    return SwitchListTile(
      secondary: Icon(
        settings.enableAll ? Icons.notifications_active : Icons.notifications_off,
        color: settings.enableAll
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: const Text(
        'Enable All Notifications',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        settings.enableAll
            ? 'All notifications are enabled'
            : 'All notifications are disabled',
      ),
      value: settings.enableAll,
      onChanged: (value) {
        ref.read(notificationSettingsProvider(userId).notifier).updateEnableAll(value);
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
      ),
    );
  }

  Widget _buildChannelToggle(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
    NotificationChannel channel,
    bool enabled,
  ) {
    return SwitchListTile(
      secondary: Icon(
        channel.icon,
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(channel.label),
      subtitle: Text(
        enabled
            ? '${channel.label} are enabled'
            : '${channel.label} are disabled',
      ),
      value: enabled && settings.enableAll,
      onChanged: settings.enableAll
          ? (value) {
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateChannelMaster(channel, value);
            }
          : null,
    );
  }

  Widget _buildTypeSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
    NotificationType type,
    NotificationChannelSettings typeSettings,
  ) {
    final isEnabled = settings.enableAll && typeSettings.enabled;

    return ExpansionTile(
      leading: Icon(
        type.icon,
        color: type.color,
      ),
      title: Text(type.label),
      subtitle: Text(
        isEnabled ? 'Enabled' : 'Disabled',
      ),
      initiallyExpanded: false,
      children: [
        // Master toggle for this type
        SwitchListTile(
          title: Text('Enable ${type.label}'),
          value: isEnabled,
          onChanged: settings.enableAll
              ? (value) {
                  final updated = typeSettings.copyWith(enabled: value);
                  ref
                      .read(notificationSettingsProvider(userId).notifier)
                      .updateTypeSettings(type, updated);
                }
              : null,
        ),
        const Divider(height: 1),
        // Channel toggles for this type
        if (isEnabled && settings.pushEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.push.label),
            subtitle: Text('Push notifications'),
            value: typeSettings.pushEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(pushEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateTypeSettings(type, updated);
            },
          ),
        if (isEnabled && settings.emailEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.email.label),
            subtitle: Text('Email notifications'),
            value: typeSettings.emailEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(emailEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateTypeSettings(type, updated);
            },
          ),
        if (isEnabled && settings.inAppEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.inApp.label),
            subtitle: Text('In-app notifications'),
            value: typeSettings.inAppEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(inAppEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateTypeSettings(type, updated);
            },
          ),
      ],
    );
  }

  Widget _buildExtendedTypeSettings(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
    ExtendedNotificationType type,
    NotificationChannelSettings typeSettings,
  ) {
    final isEnabled = settings.enableAll && typeSettings.enabled;

    return ExpansionTile(
      leading: Icon(
        type.icon,
        color: type.color,
      ),
      title: Text(type.label),
      subtitle: Text(
        isEnabled ? 'Enabled' : 'Disabled',
      ),
      initiallyExpanded: false,
      children: [
        // Master toggle for this type
        SwitchListTile(
          title: Text('Enable ${type.label}'),
          value: isEnabled,
          onChanged: settings.enableAll
              ? (value) {
                  final updated = typeSettings.copyWith(enabled: value);
                  ref
                      .read(notificationSettingsProvider(userId).notifier)
                      .updateExtendedTypeSettings(type, updated);
                }
              : null,
        ),
        const Divider(height: 1),
        // Channel toggles for this type
        if (isEnabled && settings.pushEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.push.label),
            subtitle: Text('Push notifications'),
            value: typeSettings.pushEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(pushEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateExtendedTypeSettings(type, updated);
            },
          ),
        if (isEnabled && settings.emailEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.email.label),
            subtitle: Text('Email notifications'),
            value: typeSettings.emailEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(emailEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateExtendedTypeSettings(type, updated);
            },
          ),
        if (isEnabled && settings.inAppEnabled)
          SwitchListTile(
            title: Text(NotificationChannel.inApp.label),
            subtitle: Text('In-app notifications'),
            value: typeSettings.inAppEnabled,
            onChanged: (value) {
              final updated = typeSettings.copyWith(inAppEnabled: value);
              ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .updateExtendedTypeSettings(type, updated);
            },
          ),
      ],
    );
  }

  Widget _buildPushNotificationStatus(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final pushStatus = ref.watch(pushNotificationStatusProvider);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            pushStatus.hasPermission
                ? Icons.notifications_active
                : Icons.notifications_off,
            color: pushStatus.hasPermission
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          title: const Text('Push Notifications'),
          subtitle: Text(
            pushStatus.hasPermission
                ? pushStatus.deviceToken != null
                    ? 'Enabled and registered'
                    : 'Enabled but not registered'
                : 'Permission not granted',
          ),
          trailing: pushStatus.hasPermission
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await ref
                        .read(pushNotificationStatusProvider.notifier)
                        .requestPermission();
                  },
                  tooltip: 'Request Permission',
                ),
        ),
        if (pushStatus.deviceToken != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Token',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pushStatus.deviceToken!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: pushStatus.deviceToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device token copied to clipboard'),
                          ),
                        );
                      },
                      tooltip: 'Copy Token',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (pushStatus.error != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pushStatus.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!pushStatus.hasPermission) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(pushNotificationStatusProvider.notifier)
                    .requestPermission();
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Enable Push Notifications'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuietHoursSection(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId,
  ) {
    final quietHours = settings.quietHours;
    final isCurrentlyQuiet = quietHours.enabled && quietHours.isCurrentlyQuiet();

    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(
            quietHours.enabled ? Icons.bedtime : Icons.bedtime_outlined,
            color: quietHours.enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          title: const Text('Enable Quiet Hours'),
          subtitle: Text(
            quietHours.enabled
                ? quietHours.startTime != null && quietHours.endTime != null
                    ? '${_formatTime(quietHours.startTime!)} - ${_formatTime(quietHours.endTime!)}'
                    : 'Set start and end times'
                : 'Mute notifications during specific hours',
          ),
          value: quietHours.enabled,
          onChanged: (value) {
            final updated = quietHours.copyWith(
              enabled: value,
              startTime: value && quietHours.startTime == null
                  ? const TimeOfDay(hour: 22, minute: 0) // Default: 10 PM
                  : quietHours.startTime,
              endTime: value && quietHours.endTime == null
                  ? const TimeOfDay(hour: 8, minute: 0) // Default: 8 AM
                  : quietHours.endTime,
            );
            ref
                .read(notificationSettingsProvider(userId).notifier)
                .updateQuietHours(updated);
          },
        ),
        if (quietHours.enabled) ...[
          const SizedBox(height: 8),
          if (isCurrentlyQuiet)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bedtime,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quiet hours are active - notifications are muted',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Start Time'),
            subtitle: Text(
              quietHours.startTime != null
                  ? _formatTime(quietHours.startTime!)
                  : 'Not set',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectQuietHoursTime(
              context,
              ref,
              settings,
              userId,
              isStartTime: true,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End Time'),
            subtitle: Text(
              quietHours.endTime != null
                  ? _formatTime(quietHours.endTime!)
                  : 'Not set',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectQuietHoursTime(
              context,
              ref,
              settings,
              userId,
              isStartTime: false,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectQuietHoursTime(
    BuildContext context,
    WidgetRef ref,
    NotificationSettingsModel settings,
    String userId, {
    required bool isStartTime,
  }) async {
    final currentTime = isStartTime
        ? settings.quietHours.startTime ?? const TimeOfDay(hour: 22, minute: 0)
        : settings.quietHours.endTime ?? const TimeOfDay(hour: 8, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime == null) return;

    final updated = settings.quietHours.copyWith(
      startTime: isStartTime ? pickedTime : settings.quietHours.startTime,
      endTime: !isStartTime ? pickedTime : settings.quietHours.endTime,
    );

    ref.read(notificationSettingsProvider(userId).notifier).updateQuietHours(updated);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Notification Settings'),
        content: const Text(
          'Are you sure you want to reset all notification settings to defaults? '
          'This will enable all notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(notificationSettingsProvider(userId).notifier)
                  .resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

