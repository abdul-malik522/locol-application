import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/formatters.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/models/dispute_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class DisputeDetailScreen extends ConsumerWidget {
  const DisputeDetailScreen({
    required this.disputeId,
    super.key,
  });

  final String disputeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final disputeAsync = ref.watch(disputeByIdProvider(disputeId));

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Dispute Details'),
        body: Center(child: Text('Please login to view dispute')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Dispute Details'),
      body: disputeAsync.when(
        data: (dispute) {
          if (dispute == null) {
            return const Center(child: Text('Dispute not found'));
          }

          final isFiledByMe = dispute.filedBy == currentUser.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context, dispute),
                const SizedBox(height: 16),
                _buildDisputeInfoCard(context, dispute, isFiledByMe),
                const SizedBox(height: 16),
                _buildDescriptionCard(context, dispute),
                if (dispute.adminResponse != null) ...[
                  const SizedBox(height: 16),
                  _buildAdminResponseCard(context, dispute),
                ],
                if (dispute.resolution != null) ...[
                  const SizedBox(height: 16),
                  _buildResolutionCard(context, dispute),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/order/${dispute.orderId}'),
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('View Related Order'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(error: error.toString()),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DisputeModel dispute) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dispute.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dispute.status.color,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            dispute.status.icon,
            size: 32,
            color: dispute.status.color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispute.status.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dispute.status.color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dispute #${dispute.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeInfoCard(
    BuildContext context,
    DisputeModel dispute,
    bool isFiledByMe,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispute Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.shopping_bag,
              'Order ID',
              dispute.orderId.substring(0, 8),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              dispute.reason.icon,
              'Reason',
              dispute.reason.label,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.person,
              isFiledByMe ? 'Filed Against' : 'Filed By',
              isFiledByMe ? dispute.opposingPartyName : dispute.filedByName,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Filed On',
              Formatters.formatDateTime(dispute.createdAt),
            ),
            if (dispute.resolvedAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.check_circle,
                'Resolved On',
                Formatters.formatDateTime(dispute.resolvedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, DisputeModel dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dispute.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminResponseCard(BuildContext context, DisputeModel dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin Response',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dispute.adminResponse!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard(BuildContext context, DisputeModel dispute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  size: 20,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resolution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                dispute.resolution!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

