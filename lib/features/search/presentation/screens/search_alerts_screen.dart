import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/search/data/models/search_alert_model.dart';
import 'package:localtrade/features/search/data/models/saved_search_model.dart';
import 'package:localtrade/features/search/providers/search_alerts_provider.dart';
import 'package:localtrade/features/search/providers/search_provider.dart';
import 'package:uuid/uuid.dart';

class SearchAlertsScreen extends ConsumerStatefulWidget {
  const SearchAlertsScreen({super.key});

  @override
  ConsumerState<SearchAlertsScreen> createState() => _SearchAlertsScreenState();
}

class _SearchAlertsScreenState extends ConsumerState<SearchAlertsScreen> {
  SearchAlertStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Search Alerts'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final alertsAsync = ref.watch(searchAlertsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Search Alerts'),
      body: Column(
        children: [
          _buildStatusFilter(context),
          Expanded(
            child: alertsAsync.when(
              data: (alerts) {
                final filtered = _filterStatus == null
                    ? alerts
                    : alerts.where((a) => a.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_outlined,
                    title: 'No Search Alerts',
                    message: _filterStatus == null
                        ? 'Create search alerts to get notified when new posts match your saved searches.'
                        : 'No alerts with this status.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final alert = filtered[index];
                    return _buildAlertCard(context, ref, alert, currentUser.id);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                error: error.toString(),
                onRetry: () => ref.invalidate(searchAlertsProvider(currentUser.id)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alert),
        label: const Text('Create Alert'),
        onPressed: () => _showCreateAlertDialog(context, ref, currentUser.id),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(context, 'All', null),
          const SizedBox(width: 8),
          ...SearchAlertStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(context, status.label, status),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, SearchAlertStatus? status) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    WidgetRef ref,
    SearchAlertModel alert,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(alert.status.icon, color: alert.status.color),
        ),
        title: Text(alert.savedSearchName),
        subtitle: Text(
          alert.query.isNotEmpty ? alert.query : 'No query',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Status', alert.status.label),
                _buildInfoRow(context, 'Query', alert.query.isNotEmpty ? alert.query : 'N/A'),
                if (alert.matchCount > 0)
                  _buildInfoRow(context, 'New Matches', '${alert.matchCount}'),
                if (alert.lastNotifiedAt != null)
                  _buildInfoRow(
                    context,
                    'Last Notified',
                    timeago.format(alert.lastNotifiedAt!),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('View Results'),
                        onPressed: () {
                          // Load the saved search
                          ref.read(searchProvider.notifier).loadSavedSearch(
                            SavedSearchModel(
                              id: alert.savedSearchId,
                              userId: userId,
                              name: alert.savedSearchName,
                              query: alert.query,
                              filters: alert.filters,
                              searchType: SearchType.posts,
                            ),
                          );
                          context.pop();
                          context.go('/search');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(alert.isActive ? Icons.pause : Icons.play_arrow),
                        label: Text(alert.isActive ? 'Pause' : 'Resume'),
                        onPressed: () => _toggleAlert(context, ref, alert, userId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () => _deleteAlert(context, ref, alert, userId),
                  ),
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

  Future<void> _toggleAlert(
    BuildContext context,
    WidgetRef ref,
    SearchAlertModel alert,
    String userId,
  ) async {
    try {
      final dataSource = ref.read(searchAlertsDataSourceProvider);
      final newStatus = alert.isActive
          ? SearchAlertStatus.paused
          : SearchAlertStatus.active;
      await dataSource.updateSearchAlert(alert.copyWith(status: newStatus));
      ref.invalidate(searchAlertsProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == SearchAlertStatus.active
                ? 'Alert activated'
                : 'Alert paused'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    SearchAlertModel alert,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this search alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataSource = ref.read(searchAlertsDataSourceProvider);
                await dataSource.deleteSearchAlert(alert.id, userId);
                ref.invalidate(searchAlertsProvider(userId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAlertDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final searchState = ref.read(searchProvider);
    if (searchState.query.isEmpty && searchState.filters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please perform a search first to create an alert'),
        ),
      );
      return;
    }

    final nameController = TextEditingController(
      text: searchState.query.isNotEmpty
          ? searchState.query
          : 'Saved Search Alert',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Search Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Alert Name',
                hintText: 'Enter a name for this alert',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will be notified when new posts match your current search.',
              style: Theme.of(context).textTheme.bodySmall,
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an alert name')),
                );
                return;
              }

              try {
                final dataSource = ref.read(searchAlertsDataSourceProvider);
                final alert = SearchAlertModel(
                  id: const Uuid().v4(),
                  userId: userId,
                  savedSearchId: '', // Would link to saved search if exists
                  savedSearchName: nameController.text.trim(),
                  query: searchState.query,
                  filters: Map<String, dynamic>.from(searchState.filters),
                  status: SearchAlertStatus.active,
                );
                await dataSource.createSearchAlert(alert);

                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(searchAlertsProvider(userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search alert created')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create alert: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

