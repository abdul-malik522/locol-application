import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/orders/data/models/dispute_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class DisputesScreen extends ConsumerStatefulWidget {
  const DisputesScreen({super.key});

  @override
  ConsumerState<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends ConsumerState<DisputesScreen> {
  DisputeStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Disputes'),
        body: Center(child: Text('Please login to view disputes')),
      );
    }

    final disputesAsync = ref.watch(disputesProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Disputes'),
      body: Column(
        children: [
          _buildFilterChips(currentUser.id),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(disputesProvider(currentUser.id));
              },
              child: disputesAsync.when(
                data: (disputes) {
                  final filtered = _selectedStatus == null
                      ? disputes
                      : disputes.where((d) => d.status == _selectedStatus).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.gavel_outlined,
                      title: 'No Disputes',
                      message: _selectedStatus == null
                          ? 'You haven\'t filed any disputes yet.'
                          : 'No disputes with this status.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final dispute = filtered[index];
                      return _buildDisputeCard(context, ref, dispute, currentUser.id);
                    },
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorView(
                  error: error.toString(),
                  onRetry: () => ref.invalidate(disputesProvider(currentUser.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedStatus == null,
              onSelected: (selected) {
                setState(() => _selectedStatus = null);
              },
            ),
            const SizedBox(width: 8),
            ...DisputeStatus.values.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status.label),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? status : null);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeCard(
    BuildContext context,
    WidgetRef ref,
    DisputeModel dispute,
    String userId,
  ) {
    final isFiledByMe = dispute.filedBy == userId;
    final status = dispute.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/dispute/${dispute.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      status.icon,
                      size: 24,
                      color: status.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispute #${dispute.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order: ${dispute.orderId.substring(0, 8)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    dispute.reason.icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dispute.reason.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dispute.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFiledByMe
                        ? 'Filed by you against ${dispute.opposingPartyName}'
                        : 'Filed by ${dispute.filedByName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Filed ${timeago.format(dispute.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              if (dispute.resolution != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dispute.resolution!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

