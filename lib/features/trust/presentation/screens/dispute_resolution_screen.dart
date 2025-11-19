import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/orders/data/datasources/disputes_datasource.dart';
import 'package:localtrade/features/orders/data/models/dispute_model.dart';

class DisputeResolutionScreen extends ConsumerWidget {
  const DisputeResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputesAsync = ref.watch(allDisputesProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Dispute Resolution'),
      body: disputesAsync.when(
        data: (disputes) {
          final activeDisputes = disputes.where((d) => d.isActive).toList();
          if (activeDisputes.isEmpty) {
            return const EmptyState(
              icon: Icons.gavel,
              title: 'No Active Disputes',
              message: 'All disputes have been resolved.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDisputes.length,
            itemBuilder: (context, index) {
              final dispute = activeDisputes[index];
              return _buildDisputeCard(context, ref, dispute);
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(allDisputesProvider),
        ),
      ),
    );
  }

  Widget _buildDisputeCard(BuildContext context, WidgetRef ref, DisputeModel dispute) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(dispute.status.icon, color: dispute.status.color),
        title: Text('Order: ${dispute.orderId.substring(0, 8)}...'),
        subtitle: Text('${dispute.reason.label} • ${timeago.format(dispute.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Filed By', dispute.filedByName),
                _buildInfoRow(context, 'Against', dispute.opposingPartyName),
                _buildInfoRow(context, 'Reason', dispute.reason.label),
                _buildInfoRow(context, 'Description', dispute.description),
                _buildInfoRow(context, 'Status', dispute.status.label),
                if (dispute.adminResponse != null)
                  _buildInfoRow(context, 'Admin Response', dispute.adminResponse!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Resolve'),
                        onPressed: () => _showResolveDialog(context, ref, dispute),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => _showRejectDialog(context, ref, dispute),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Order Details'),
                    onPressed: () => context.push('/order/${dispute.orderId}'),
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

  Future<void> _showResolveDialog(
    BuildContext context,
    WidgetRef ref,
    DisputeModel dispute,
  ) async {
    final responseController = TextEditingController();
    final resolutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: responseController,
                label: 'Admin Response',
                hint: 'Add your response to the dispute',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: resolutionController,
                label: 'Resolution',
                hint: 'Describe the resolution (e.g., Refund issued, Replacement sent)',
                maxLines: 3,
              ),
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
              if (responseController.text.trim().isEmpty || resolutionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              final disputesDataSource = ref.read(disputesDataSourceProvider);
              await disputesDataSource.updateDisputeStatus(
                dispute.id,
                DisputeStatus.resolved,
                adminResponse: responseController.text.trim(),
                resolution: resolutionController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(allDisputesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute resolved')),
                );
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    DisputeModel dispute,
  ) async {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this dispute?'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: responseController,
              label: 'Reason for Rejection',
              hint: 'Explain why this dispute is being rejected',
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
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              final disputesDataSource = DisputesDataSource.instance;
              await disputesDataSource.updateDisputeStatus(
                dispute.id,
                DisputeStatus.rejected,
                adminResponse: responseController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(allDisputesProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute rejected')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// Provider for all disputes
final allDisputesProvider = FutureProvider<List<DisputeModel>>((ref) {
  final disputesDataSource = DisputesDataSource.instance;
  return disputesDataSource.getAllDisputes();
});

