import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'dart:io';

import 'package:localtrade/features/analytics/data/models/analytics_model.dart';
import 'package:localtrade/features/analytics/data/services/analytics_reports_service.dart';
import 'package:localtrade/features/analytics/providers/analytics_provider.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/datasources/orders_mock_datasource.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:share_plus/share_plus.dart';

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isSeller) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Analytics'),
        body: const ErrorView(error: 'Analytics only available for sellers'),
      );
    }

    final analyticsAsync = ref.watch(sellerAnalyticsProvider(currentUser.id));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Analytics Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              analyticsAsync.whenData((analytics) {
                _showExportDialog(context, ref, currentUser.id, analytics);
              });
            },
            tooltip: 'Export Reports',
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildAnalyticsContent(context, analytics),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(sellerAnalyticsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, SellerAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Analytics Summary
          _buildSectionHeader(context, 'Order Analytics'),
          _buildOrderSummaryCards(context, analytics.orderAnalytics),
          const SizedBox(height: 24),
          
          // Customer Analytics
          _buildSectionHeader(context, 'Customer Analytics'),
          _buildCustomerSummaryCards(context, analytics.customerAnalytics),
          const SizedBox(height: 24),
          
          // Profile Analytics
          _buildSectionHeader(context, 'Profile Analytics'),
          _buildProfileSummaryCards(context, analytics.profileAnalytics),
          const SizedBox(height: 24),
          
          // Post Analytics
          _buildSectionHeader(context, 'Post Performance'),
          if (analytics.postAnalytics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No posts yet'),
            )
          else
            ...analytics.postAnalytics.map((post) => _buildPostAnalyticsCard(context, post)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildOrderSummaryCards(BuildContext context, OrderAnalytics orderAnalytics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Orders',
          orderAnalytics.totalOrders.toString(),
          Icons.shopping_bag_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Total Revenue',
          Formatters.formatCurrency(orderAnalytics.totalRevenue),
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Avg Order Value',
          Formatters.formatCurrency(orderAnalytics.averageOrderValue),
          Icons.trending_up,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Completion Rate',
          '${orderAnalytics.completionRate.toStringAsFixed(1)}%',
          Icons.check_circle_outline,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildCustomerSummaryCards(BuildContext context, CustomerAnalytics customerAnalytics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Customers',
          customerAnalytics.totalCustomers.toString(),
          Icons.people_outline,
          Colors.teal,
        ),
        _buildStatCard(
          context,
          'New Customers',
          customerAnalytics.newCustomers.toString(),
          Icons.person_add_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Retention Rate',
          '${customerAnalytics.customerRetentionRate.toStringAsFixed(1)}%',
          Icons.repeat,
          Colors.indigo,
        ),
        _buildStatCard(
          context,
          'Avg CLV',
          Formatters.formatCurrency(customerAnalytics.averageCustomerLifetimeValue),
          Icons.star_outline,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildProfileSummaryCards(BuildContext context, ProfileAnalytics profileAnalytics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Profile Views',
          profileAnalytics.profileViews.toString(),
          Icons.visibility_outlined,
          Colors.cyan,
        ),
        _buildStatCard(
          context,
          'Followers',
          profileAnalytics.followers.toString(),
          Icons.favorite_outline,
          Colors.pink,
        ),
        _buildStatCard(
          context,
          'Following',
          profileAnalytics.following.toString(),
          Icons.person_outline,
          Colors.blueGrey,
        ),
        _buildStatCard(
          context,
          'Search Appearances',
          profileAnalytics.searchAppearances.toString(),
          Icons.search,
          Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostAnalyticsCard(BuildContext context, PostAnalytics postAnalytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Post ID: ${postAnalytics.postId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${postAnalytics.engagementRate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMiniStat(context, Icons.visibility, postAnalytics.views.toString(), 'Views'),
                const SizedBox(width: 16),
                _buildMiniStat(context, Icons.favorite, postAnalytics.likes.toString(), 'Likes'),
                const SizedBox(width: 16),
                _buildMiniStat(context, Icons.comment, postAnalytics.comments.toString(), 'Comments'),
                const SizedBox(width: 16),
                _buildMiniStat(context, Icons.share, postAnalytics.shares.toString(), 'Shares'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    SellerAnalytics analytics,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Sales Report (PDF)'),
              subtitle: const Text('Export order and revenue data'),
              onTap: () async {
                Navigator.pop(context);
                await _exportSalesReport(context, ref, userId, analytics, 'pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Sales Report (CSV)'),
              subtitle: const Text('Export order data as spreadsheet'),
              onTap: () async {
                Navigator.pop(context);
                await _exportSalesReport(context, ref, userId, analytics, 'csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customer Report (PDF)'),
              subtitle: const Text('Export customer analytics'),
              onTap: () async {
                Navigator.pop(context);
                await _exportCustomerReport(context, ref, userId, analytics);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSalesReport(
    BuildContext context,
    WidgetRef ref,
    String userId,
    SellerAnalytics analytics,
    String format,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get all orders for the seller
      final ordersDataSource = OrdersMockDataSource.instance;
      final allOrders = await ordersDataSource.getAllOrders();
      final sellerOrders = allOrders.where((o) => o.sellerId == userId).toList();

      final reportsService = AnalyticsReportsService.instance;
      String filePath;

      if (format == 'pdf') {
        filePath = await reportsService.exportSalesReportToPDF(
          analytics: analytics,
          orders: sellerOrders,
        );
      } else {
        filePath = await reportsService.exportSalesReportToCSV(
          orders: sellerOrders,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Text('Report exported to:\n${filePath.split('/').last}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(filePath)], text: 'Sales Report');
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportCustomerReport(
    BuildContext context,
    WidgetRef ref,
    String userId,
    SellerAnalytics analytics,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final reportsService = AnalyticsReportsService.instance;
      final filePath = await reportsService.exportCustomerReportToPDF(
        analytics: analytics.customerAnalytics,
        orders: [], // Not needed for customer report
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Text('Report exported to:\n${filePath.split('/').last}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(filePath)], text: 'Sales Report');
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: ${e.toString()}')),
        );
      }
    }
  }
}

