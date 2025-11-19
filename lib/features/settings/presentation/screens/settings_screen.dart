import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/core/providers/theme_provider.dart';
import 'package:localtrade/features/profile/providers/blocks_provider.dart';
import 'package:localtrade/features/settings/providers/language_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/edit-profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final twoFactorAuth = ref.watch(authProvider.notifier).getTwoFactorAuth();
              final isEnabled = twoFactorAuth?.isEnabled ?? false;
              
              return SwitchListTile(
                secondary: const Icon(Icons.security),
                title: const Text('Two-Factor Authentication'),
                subtitle: Text(isEnabled ? 'Enabled' : 'Disabled'),
                value: isEnabled,
                onChanged: (value) {
                  if (value) {
                    context.push('/two-factor-setup');
                  } else {
                    _showDisable2FADialog(context, ref);
                  }
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business Verification'),
            subtitle: const Text('Verify your business credentials'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/business-verification'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Identity Verification (KYC)'),
            subtitle: const Text('Verify your identity for high-value transactions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/identity-verification'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: Text(isDarkMode ? 'Dark' : 'Light'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final currentLanguage = ref.watch(languageProvider);
              return ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: Text('${currentLanguage.flag} ${currentLanguage.displayName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/language-selection'),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notification-settings'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'App'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/about'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms-of-service'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help-support'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Payments'),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/payment-methods'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Wallet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/wallet'),
          ),
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Payouts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/payouts'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Invoices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/invoices'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Inventory'),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Inventory Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/inventory'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Stock Alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stock-alerts'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Availability Calendar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/availability-calendar'),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Pre-Orders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pre-orders'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Delivery'),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Delivery Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/delivery-management'),
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Route Optimization'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/route-optimization'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Account Management'),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Blocked Users'),
            subtitle: Consumer(
              builder: (context, ref, _) {
                final currentUser = ref.watch(currentUserProvider);
                if (currentUser == null) {
                  return const Text('0 blocked');
                }
                final blockedUsersAsync = ref.watch(blockedUsersProvider(currentUser.id));
                return blockedUsersAsync.when(
                  data: (blockedIds) => Text('${blockedIds.length} blocked'),
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error'),
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/blocked-users'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Download all your data in JSON or CSV format'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/data-export'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About LocalTrade'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LocalTrade Marketplace'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
              'Connecting local sellers with restaurants. '
              'A modern platform for local commerce.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDisable2FADialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? '
          'This will make your account less secure.',
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
                await ref.read(authProvider.notifier).disableTwoFactorAuth();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('2FA disabled successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to disable 2FA: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('This action cannot be undone. All of your data will be permanently deleted, including:'),
            SizedBox(height: 8),
            Text('• Your profile and account information'),
            Text('• All your posts'),
            Text('• All your orders'),
            Text('• All your messages and chats'),
            Text('• All your reviews'),
            Text('• Your favorites, drafts, and saved searches'),
            Text('• Your settings and preferences'),
            SizedBox(height: 16),
            Text(
              'You will be logged out immediately after deletion.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
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
              Navigator.pop(context);
              
              // Show loading dialog
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await ref.read(authProvider.notifier).deleteAccount();
                
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Navigate to welcome/login screen
                if (context.mounted) {
                  context.go('/welcome');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account has been permanently deleted'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
