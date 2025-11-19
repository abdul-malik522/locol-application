import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/home/data/datasources/post_reports_datasource.dart';
import 'package:localtrade/features/home/data/models/post_report_model.dart';
import 'package:localtrade/features/trust/data/models/user_report_model.dart';
import 'package:localtrade/features/trust/providers/trust_provider.dart';

class ContentModerationScreen extends ConsumerStatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  ConsumerState<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends ConsumerState<ContentModerationScreen> {
  int _selectedTab = 0; // 0 = Post Reports, 1 = User Reports

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Content Moderation'),
          bottom: TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            tabs: const [
              Tab(text: 'Post Reports', icon: Icon(Icons.article)),
              Tab(text: 'User Reports', icon: Icon(Icons.person)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPostReportsTab(),
            _buildUserReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostReportsTab() {
    final reportsAsync = ref.watch(postReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        final pendingReports = reports.where((r) => r.isActive).toList();
        if (pendingReports.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Reports',
            message: 'All post reports have been reviewed.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingReports.length,
          itemBuilder: (context, index) {
            final report = pendingReports[index];
            return _buildPostReportCard(context, report);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        error: error.toString(),
        onRetry: () => ref.invalidate(postReportsProvider),
      ),
    );
  }

  Widget _buildUserReportsTab() {
    final reportsAsync = ref.watch(pendingUserReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Reports',
            message: 'All user reports have been reviewed.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildUserReportCard(context, report);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        error: error.toString(),
        onRetry: () => ref.invalidate(pendingUserReportsProvider),
      ),
    );
  }

  Widget _buildPostReportCard(BuildContext context, PostReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(report.reason.icon, color: report.reason.color),
        title: Text('Post: ${report.postId.substring(0, 8)}...'),
        subtitle: Text('Reported by: ${report.reportedByName}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Reason', report.reason.label),
                _buildInfoRow(context, 'Description', report.description),
                _buildInfoRow(context, 'Status', report.status.label),
                _buildInfoRow(context, 'Reported', timeago.format(report.createdAt)),
                if (report.adminResponse != null)
                  _buildInfoRow(context, 'Admin Response', report.adminResponse!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reviewPostReport(context, report, true),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reviewPostReport(context, report, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReportCard(BuildContext context, UserReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(report.reason.icon, color: report.reason.color),
        title: Text('User: ${report.reportedUserName}'),
        subtitle: Text('Reported by: ${report.reportedByName}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Reason', report.reason.label),
                _buildInfoRow(context, 'Description', report.description),
                _buildInfoRow(context, 'Status', report.status.label),
                _buildInfoRow(context, 'Reported', timeago.format(report.createdAt)),
                if (report.adminResponse != null)
                  _buildInfoRow(context, 'Admin Response', report.adminResponse!),
                if (report.actionTaken != null)
                  _buildInfoRow(context, 'Action Taken', report.actionTaken!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reviewUserReport(context, report, true),
                        child: const Text('Resolve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reviewUserReport(context, report, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewPostReport(
    BuildContext context,
    PostReportModel report,
    bool approve,
  ) async {
    final responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Report' : 'Dismiss Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Admin Response (optional)',
                hintText: 'Add notes about this decision',
              ),
              maxLines: 3,
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
              final dataSource = PostReportsDataSource.instance;
              await dataSource.updateReportStatus(
                report.id,
                approve ? ReportStatus.resolved : ReportStatus.dismissed,
                adminResponse: responseController.text.trim().isNotEmpty
                    ? responseController.text.trim()
                    : null,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(postReportsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(approve ? 'Report approved' : 'Report dismissed')),
                );
              }
            },
            child: Text(approve ? 'Approve' : 'Dismiss'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewUserReport(
    BuildContext context,
    UserReportModel report,
    bool resolve,
  ) async {
    final responseController = TextEditingController();
    final actionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resolve ? 'Resolve Report' : 'Dismiss Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Admin Response (optional)',
                  hintText: 'Add notes about this decision',
                ),
                maxLines: 3,
              ),
              if (resolve) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action Taken (optional)',
                    hintText: 'e.g., User warned, Account suspended',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final dataSource = ref.read(userReportsDataSourceProvider);
              await dataSource.updateReportStatus(
                report.id,
                resolve ? UserReportStatus.resolved : UserReportStatus.dismissed,
                adminResponse: responseController.text.trim().isNotEmpty
                    ? responseController.text.trim()
                    : null,
                actionTaken: actionController.text.trim().isNotEmpty
                    ? actionController.text.trim()
                    : null,
                reviewedBy: 'admin', // In real app, get from auth
              );
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(pendingUserReportsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(resolve ? 'Report resolved' : 'Report dismissed')),
                );
              }
            },
            child: Text(resolve ? 'Resolve' : 'Dismiss'),
          ),
        ],
      ),
    );
  }
}

// Provider for post reports
final postReportsProvider = FutureProvider<List<PostReportModel>>((ref) {
  final dataSource = PostReportsDataSource.instance;
  return dataSource.getAllReports();
});

