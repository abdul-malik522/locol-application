import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/settings/data/models/privacy_settings_model.dart';
import 'package:localtrade/features/settings/providers/privacy_settings_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Privacy Settings'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final privacySettingsAsync = ref.watch(privacySettingsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Privacy Settings'),
      body: privacySettingsAsync.when(
        data: (settings) => _buildSettingsContent(context, ref, settings, currentUser.id),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(privacySettingsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    WidgetRef ref,
    PrivacySettingsModel settings,
    String userId,
  ) {
    return ListView(
      children: [
        _buildSectionHeader(context, 'Profile Visibility'),
        _buildProfileVisibilityTile(context, ref, settings, userId),
        const Divider(),
        _buildSectionHeader(context, 'Contact Information'),
        SwitchListTile(
          secondary: const Icon(Icons.email_outlined),
          title: const Text('Show Email'),
          subtitle: const Text('Display your email address on your profile'),
          value: settings.showEmail,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateShowEmail(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.phone_outlined),
          title: const Text('Show Phone Number'),
          subtitle: const Text('Display your phone number on your profile'),
          value: settings.showPhoneNumber,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateShowPhoneNumber(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.location_on_outlined),
          title: const Text('Show Location'),
          subtitle: const Text('Display your location on your profile and posts'),
          value: settings.showLocation,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateShowLocation(value);
          },
        ),
        const Divider(),
        _buildSectionHeader(context, 'Discovery'),
        SwitchListTile(
          secondary: const Icon(Icons.search),
          title: const Text('Allow Profile Discovery'),
          subtitle: const Text('Allow your profile to appear in search results'),
          value: settings.allowProfileDiscovery,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateAllowProfileDiscovery(value);
          },
        ),
        const Divider(),
        _buildSectionHeader(context, 'Messaging'),
        _buildMessagePrivacyTile(context, ref, settings, userId),
        SwitchListTile(
          secondary: const Icon(Icons.visibility_outlined),
          title: const Text('Show Read Receipts'),
          subtitle: const Text('Let others know when you\'ve read their messages'),
          value: settings.showReadReceipts,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateShowReadReceipts(value);
          },
        ),
        const Divider(),
        _buildSectionHeader(context, 'Activity'),
        SwitchListTile(
          secondary: const Icon(Icons.access_time),
          title: const Text('Show Activity Status'),
          subtitle: const Text('Show when you were last active'),
          value: settings.showActivityStatus,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateShowActivityStatus(value);
          },
        ),
        const Divider(),
        _buildSectionHeader(context, 'Data Sharing'),
        SwitchListTile(
          secondary: const Icon(Icons.analytics_outlined),
          title: const Text('Analytics Data Sharing'),
          subtitle: const Text('Share anonymous data to help improve the app'),
          value: settings.allowAnalyticsDataSharing,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateAllowAnalyticsDataSharing(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.share_outlined),
          title: const Text('Third-Party Data Sharing'),
          subtitle: const Text('Allow sharing data with third-party services'),
          value: settings.allowThirdPartyDataSharing,
          onChanged: (value) {
            ref.read(privacySettingsProvider(userId).notifier).updateAllowThirdPartyDataSharing(value);
          },
        ),
        const Divider(),
        _buildSectionHeader(context, 'Actions'),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.orange),
          title: const Text('Reset to Defaults'),
          subtitle: const Text('Reset all privacy settings to default values'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetDialog(context, ref, userId),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildProfileVisibilityTile(
    BuildContext context,
    WidgetRef ref,
    PrivacySettingsModel settings,
    String userId,
  ) {
    return ListTile(
      leading: Icon(settings.profileVisibility.icon),
      title: const Text('Profile Visibility'),
      subtitle: Text(settings.profileVisibility.description),
      trailing: DropdownButton<ProfileVisibility>(
        value: settings.profileVisibility,
        underline: const SizedBox.shrink(),
        items: ProfileVisibility.values.map((visibility) {
          return DropdownMenuItem(
            value: visibility,
            child: Row(
              children: [
                Icon(visibility.icon, size: 20),
                const SizedBox(width: 8),
                Text(visibility.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(privacySettingsProvider(userId).notifier).updateProfileVisibility(value);
          }
        },
      ),
    );
  }

  Widget _buildMessagePrivacyTile(
    BuildContext context,
    WidgetRef ref,
    PrivacySettingsModel settings,
    String userId,
  ) {
    return ListTile(
      leading: Icon(settings.messagePrivacy.icon),
      title: const Text('Who Can Message You'),
      subtitle: Text(settings.messagePrivacy.description),
      trailing: DropdownButton<MessagePrivacy>(
        value: settings.messagePrivacy,
        underline: const SizedBox.shrink(),
        items: MessagePrivacy.values.map((privacy) {
          return DropdownMenuItem(
            value: privacy,
            child: Row(
              children: [
                Icon(privacy.icon, size: 20),
                const SizedBox(width: 8),
                Text(privacy.label),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(privacySettingsProvider(userId).notifier).updateMessagePrivacy(value);
          }
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
          'Are you sure you want to reset all privacy settings to their default values? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(privacySettingsProvider(userId).notifier).resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings reset to defaults')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reset settings: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

