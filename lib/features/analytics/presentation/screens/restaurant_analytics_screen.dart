import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/analytics/data/models/analytics_model.dart';
import 'package:localtrade/features/analytics/providers/analytics_provider.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class RestaurantAnalyticsScreen extends ConsumerWidget {
  const RestaurantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isRestaurant) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Analytics'),
        body: const ErrorView(error: 'Analytics only available for restaurants'),
      );
    }

    final analyticsAsync = ref.watch(restaurantAnalyticsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Analytics Dashboard'),
      body: analyticsAsync.when(
        data: (analytics) => _buildAnalyticsContent(context, analytics),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(restaurantAnalyticsProvider(currentUser.id)),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, RestaurantAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovery Analytics
          _buildSectionHeader(context, 'Discovery Analytics'),
          _buildDiscoverySummaryCards(context, analytics.discoveryAnalytics),
          const SizedBox(height: 24),
          
          // Order Analytics Summary
          _buildSectionHeader(context, 'Order Analytics'),
          _buildOrderSummaryCards(context, analytics.orderAnalytics),
          const SizedBox(height: 24),
          
          // Engagement Analytics
          _buildSectionHeader(context, 'Engagement Analytics'),
          _buildEngagementSummaryCards(context, analytics.engagementAnalytics),
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

  Widget _buildDiscoverySummaryCards(BuildContext context, DiscoveryAnalytics discoveryAnalytics) {
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
          'Search Appearances',
          discoveryAnalytics.searchAppearances.toString(),
          Icons.search,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Profile Views',
          discoveryAnalytics.profileViews.toString(),
          Icons.visibility_outlined,
          Colors.cyan,
        ),
        _buildStatCard(
          context,
          'Post Views from Search',
          discoveryAnalytics.postViewsFromSearch.toString(),
          Icons.remove_red_eye_outlined,
          Colors.teal,
        ),
        _buildStatCard(
          context,
          'Clicks to Profile',
          discoveryAnalytics.clicksToProfile.toString(),
          Icons.touch_app_outlined,
          Colors.orange,
        ),
      ],
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
          'Total Spent',
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

  Widget _buildEngagementSummaryCards(BuildContext context, EngagementAnalytics engagementAnalytics) {
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
          'Messages Sent',
          engagementAnalytics.messagesSent.toString(),
          Icons.send_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Messages Received',
          engagementAnalytics.messagesReceived.toString(),
          Icons.inbox_outlined,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Avg Response Time',
          '${engagementAnalytics.averageResponseTime.toStringAsFixed(0)} min',
          Icons.access_time,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Active Conversations',
          engagementAnalytics.activeConversations.toString(),
          Icons.chat_bubble_outline,
          Colors.purple,
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
}

