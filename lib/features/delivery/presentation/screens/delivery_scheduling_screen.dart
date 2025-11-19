import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/delivery/data/models/delivery_model.dart';
import 'package:localtrade/features/delivery/providers/delivery_provider.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';
import 'package:uuid/uuid.dart';

class DeliverySchedulingScreen extends ConsumerStatefulWidget {
  const DeliverySchedulingScreen({
    this.orderId,
    super.key,
  });

  final String? orderId;

  @override
  ConsumerState<DeliverySchedulingScreen> createState() => _DeliverySchedulingScreenState();
}

class _DeliverySchedulingScreenState extends ConsumerState<DeliverySchedulingScreen> {
  DeliveryMethod? _selectedMethod;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final _instructionsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _scheduledDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _scheduledTime = time;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery method')),
      );
      return;
    }

    if (_scheduledDate == null || _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final orderId = widget.orderId;
      if (orderId == null) {
        throw Exception('Order ID is required');
      }

      final orderAsync = await ref.read(orderByIdProvider(orderId).future);
      if (orderAsync == null) {
        throw Exception('Order not found');
      }

      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      final delivery = DeliveryModel(
        id: const Uuid().v4(),
        orderId: orderId,
        method: _selectedMethod!,
        status: DeliveryStatus.scheduled,
        deliveryAddress: orderAsync.deliveryAddress,
        scheduledDate: scheduledDateTime,
        deliveryInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
      );

      final dataSource = ref.read(deliveryDataSourceProvider);
      await dataSource.createDelivery(delivery);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery scheduled successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule delivery: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Schedule Delivery'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Delivery Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...DeliveryMethod.values.map((method) {
              return RadioListTile<DeliveryMethod>(
                title: Text(method.label),
                subtitle: Text(_getMethodDescription(method)),
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value;
                  });
                },
                secondary: Icon(method.icon, color: method.color),
              );
            }).toList(),
            const SizedBox(height: 24),
            Text(
              'Schedule Date & Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                _scheduledDate != null
                    ? DateFormat('MMM dd, yyyy').format(_scheduledDate!)
                    : 'Select date',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(
                _scheduledTime != null
                    ? _scheduledTime!.format(context)
                    : 'Select time',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _instructionsController,
              label: 'Delivery Instructions (Optional)',
              hint: 'e.g., Leave at front door, Ring doorbell',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Schedule Delivery',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.pickup:
        return 'Customer will pick up from your location';
      case DeliveryMethod.delivery:
        return 'You will deliver to customer';
      case DeliveryMethod.thirdParty:
        return 'Third-party delivery service will handle delivery';
    }
  }
}

