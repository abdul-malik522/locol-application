import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/settings/data/services/user_data_export_service.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _isExporting = false;
  String? _exportError;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Export Data'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Export Data'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Your Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export all your LocalTrade data including profile, posts, orders, messages, reviews, and more.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              context,
              Icons.info_outline,
              'What\'s Included',
              [
                'Profile information',
                'Posts (created by you)',
                'Orders (as buyer and seller)',
                'Messages and chats',
                'Reviews (given and received)',
                'Favorites',
                'Drafts',
                'Saved searches',
                'Follows and followers',
                'Blocked users',
                'Settings (notifications, privacy)',
                'Order templates',
                'Delivery addresses',
                'Disputes',
                'Reports',
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              Icons.security,
              'Privacy & Security',
              [
                'Your data is exported locally on your device',
                'Files are saved in your app documents folder',
                'You can share the file securely',
                'No data is sent to external servers',
              ],
            ),
            const SizedBox(height: 32),
            if (_exportError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportError!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Export as JSON',
              icon: Icons.code,
              onPressed: _isExporting ? null : () => _exportData('json'),
              isLoading: _isExporting,
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Export as CSV',
              icon: Icons.table_chart,
              variant: CustomButtonVariant.outlined,
              onPressed: _isExporting ? null : () => _exportData('csv'),
              isLoading: _isExporting,
              fullWidth: true,
            ),
            const SizedBox(height: 24),
            Text(
              'Note: Large exports may take a few moments to generate.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    List<String> items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(String format) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isExporting = true;
      _exportError = null;
    });

    try {
      final exportService = UserDataExportService.instance;
      String filePath;

      if (format == 'json') {
        filePath = await exportService.exportToJSON(currentUser.id);
      } else {
        filePath = await exportService.exportToCSV(currentUser.id);
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data has been exported successfully!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    filePath.split('/').last,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await exportService.shareFile(filePath);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportError = 'Failed to export data: ${e.toString()}';
        });
      }
    }
  }
}

