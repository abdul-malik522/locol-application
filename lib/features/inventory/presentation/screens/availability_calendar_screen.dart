import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart'; // Optional: Add if needed for calendar widget

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/inventory/data/models/inventory_model.dart';
import 'package:localtrade/features/inventory/providers/inventory_provider.dart';
import 'package:uuid/uuid.dart';

class AvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  ConsumerState<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends ConsumerState<AvailabilityCalendarScreen> {

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Availability Calendar'),
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final calendarsAsync = ref.watch(availabilityCalendarsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Availability Calendar'),
      body: calendarsAsync.when(
        data: (calendars) {
          if (calendars.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_today,
              title: 'No Availability Calendars',
              message: 'Create an availability calendar to manage product availability.',
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = calendars[index];
                    return _buildCalendarCard(context, ref, calendar, currentUser.id);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(availabilityCalendarsProvider(currentUser.id)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Calendar'),
        onPressed: () => _showCreateCalendarDialog(context, ref, currentUser.id),
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    WidgetRef ref,
    AvailabilityCalendarModel calendar,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          calendar.isSeasonal ? Icons.wb_sunny : Icons.calendar_today,
          color: calendar.isSeasonal ? Colors.orange : Colors.blue,
        ),
        title: Text(calendar.productName),
        subtitle: Text(
          calendar.isSeasonal
              ? 'Seasonal: ${_formatDateRange(calendar.seasonalStart, calendar.seasonalEnd)}'
              : '${calendar.availableDates.length} available dates',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (calendar.isSeasonal && calendar.seasonalStart != null && calendar.seasonalEnd != null) ...[
                  _buildInfoRow(context, 'Seasonal Start', DateFormat('MMM dd, yyyy').format(calendar.seasonalStart!)),
                  _buildInfoRow(context, 'Seasonal End', DateFormat('MMM dd, yyyy').format(calendar.seasonalEnd!)),
                ],
                if (calendar.availableDates.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Available Dates:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: calendar.availableDates.take(10).map((date) {
                      return Chip(
                        label: Text(DateFormat('MMM dd').format(date)),
                        labelStyle: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                  if (calendar.availableDates.length > 10)
                    Text(
                      '... and ${calendar.availableDates.length - 10} more',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () => _showEditCalendarDialog(context, ref, calendar, userId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        onPressed: () => _deleteCalendar(context, ref, calendar, userId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
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
            width: 120,
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

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'N/A';
    return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
  }

  Future<void> _showCreateCalendarDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final postIdController = TextEditingController();
    final productNameController = TextEditingController();
    bool isSeasonal = false;
    DateTime? seasonalStart;
    DateTime? seasonalEnd;
    List<DateTime> selectedDates = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Availability Calendar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: postIdController,
                  label: 'Post ID',
                  hint: 'Enter post ID',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: productNameController,
                  label: 'Product Name',
                  hint: 'Enter product name',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Seasonal Product'),
                  subtitle: const Text('Product available during specific season'),
                  value: isSeasonal,
                  onChanged: (value) {
                    setState(() {
                      isSeasonal = value;
                    });
                  },
                ),
                if (isSeasonal) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Season Start'),
                    subtitle: Text(seasonalStart != null
                        ? DateFormat('MMM dd, yyyy').format(seasonalStart!)
                        : 'Select date'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          seasonalStart = date;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Season End'),
                    subtitle: Text(seasonalEnd != null
                        ? DateFormat('MMM dd, yyyy').format(seasonalEnd!)
                        : 'Select date'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: seasonalStart ?? DateTime.now(),
                        firstDate: seasonalStart ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          seasonalEnd = date;
                        });
                      }
                    },
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
                try {
                  final dataSource = ref.read(inventoryDataSourceProvider);
                  final calendar = AvailabilityCalendarModel(
                    id: const Uuid().v4(),
                    postId: postIdController.text.trim(),
                    productName: productNameController.text.trim(),
                    availableDates: selectedDates,
                    seasonalStart: seasonalStart,
                    seasonalEnd: seasonalEnd,
                    isSeasonal: isSeasonal,
                  );
                  await dataSource.createAvailabilityCalendar(calendar);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(availabilityCalendarsProvider(userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Availability calendar created')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create calendar: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCalendarDialog(
    BuildContext context,
    WidgetRef ref,
    AvailabilityCalendarModel calendar,
    String userId,
  ) async {
    // Similar to create dialog but pre-filled
    _showCreateCalendarDialog(context, ref, userId);
  }

  Future<void> _deleteCalendar(
    BuildContext context,
    WidgetRef ref,
    AvailabilityCalendarModel calendar,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Calendar'),
        content: const Text('Are you sure you want to delete this availability calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dataSource = ref.read(inventoryDataSourceProvider);
                await dataSource.deleteAvailabilityCalendar(calendar.id, userId);
                ref.invalidate(availabilityCalendarsProvider(userId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calendar deleted')),
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
}

