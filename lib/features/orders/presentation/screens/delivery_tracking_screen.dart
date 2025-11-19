import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/features/orders/data/datasources/delivery_tracking_datasource.dart';
import 'package:localtrade/features/orders/data/models/delivery_tracking_model.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/orders/providers/orders_provider.dart';

class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  const DeliveryTrackingScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  ConsumerState<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends ConsumerState<DeliveryTrackingScreen> {
  StreamSubscription<DeliveryTrackingModel>? _trackingSubscription;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _simulationTimer?.cancel();
    DeliveryTrackingDataSource.instance.stopTracking(widget.orderId);
    super.dispose();
  }

  Future<void> _startTracking() async {
    final trackingDataSource = DeliveryTrackingDataSource.instance;
    final tracking = await trackingDataSource.getTracking(widget.orderId);
    
    if (tracking != null) {
      // Subscribe to real-time updates
      _trackingSubscription = trackingDataSource.watchTracking(widget.orderId).listen(
        (updatedTracking) {
          if (mounted) {
            setState(() {});
          }
        },
      );

      // Simulate delivery progress (for demo)
      _simulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        trackingDataSource.simulateDeliveryProgress(widget.orderId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = ref.watch(ordersMockDataSourceProvider);
    final orderFuture = dataSource.getOrderById(widget.orderId);
    final trackingDataSource = DeliveryTrackingDataSource.instance;
    final trackingFuture = trackingDataSource.getTracking(widget.orderId);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Delivery Tracking'),
      body: FutureBuilder<OrderModel?>(
        future: orderFuture,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (orderSnapshot.hasError) {
            return ErrorView(error: orderSnapshot.error.toString());
          }

          final order = orderSnapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return FutureBuilder<DeliveryTrackingModel?>(
            future: trackingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingIndicator();
              }

              if (snapshot.hasError) {
                return ErrorView(error: snapshot.error.toString());
              }

              final tracking = snapshot.data;
              if (tracking == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tracking not available',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tracking will be available once the order is accepted.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<DeliveryTrackingModel>(
                stream: trackingDataSource.watchTracking(widget.orderId),
                initialData: tracking,
                builder: (context, streamSnapshot) {
                  final currentTracking = streamSnapshot.data ?? tracking;
                  return _buildTrackingView(context, order, currentTracking);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackingView(
    BuildContext context,
    OrderModel order,
    DeliveryTrackingModel tracking,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(context, tracking),
          const SizedBox(height: 16),

          // Map Placeholder
          _buildMapPlaceholder(context, tracking, order),
          const SizedBox(height: 16),

          // Delivery Information
          _buildDeliveryInfoCard(context, tracking),
          const SizedBox(height: 16),

          // Timeline
          _buildTimeline(context, tracking),
          const SizedBox(height: 16),

          // Actions
          if (tracking.deliveryPersonPhone != null)
            OutlinedButton.icon(
              onPressed: () => _callDeliveryPerson(tracking.deliveryPersonPhone!),
              icon: const Icon(Icons.phone),
              label: const Text('Call Delivery Person'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DeliveryTrackingModel tracking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tracking.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tracking.status.color,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tracking.status.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tracking.status.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracking.status.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tracking.status.color,
                      ),
                ),
                if (tracking.estimatedDeliveryTime != null && !tracking.isDelivered) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Estimated delivery: ${_formatTime(tracking.estimatedDeliveryTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (tracking.isDelivered && tracking.actualDeliveryTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Delivered at: ${_formatTime(tracking.actualDeliveryTime!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(
    BuildContext context,
    DeliveryTrackingModel tracking,
    OrderModel order,
  ) {
    // Mock destination coordinates (in real app, geocode the address)
    final destinationLat = 37.7849;
    final destinationLon = -122.4094;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // Map placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Map View',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'In a real app, this would show a map with delivery route',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Open in Maps button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openInMaps(
                tracking.currentLocation.latitude,
                tracking.currentLocation.longitude,
              ),
              icon: const Icon(Icons.map),
              label: const Text('Open in Maps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(
    BuildContext context,
    DeliveryTrackingModel tracking,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (tracking.deliveryPersonName != null) ...[
              _buildInfoRow(
                context,
                Icons.person,
                'Delivery Person',
                tracking.deliveryPersonName!,
              ),
              const SizedBox(height: 12),
            ],
            if (tracking.deliveryPersonPhone != null) ...[
              _buildInfoRow(
                context,
                Icons.phone,
                'Contact',
                tracking.deliveryPersonPhone!,
              ),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              context,
              Icons.location_on,
              'Current Location',
              tracking.currentLocation.address ??
                  '${tracking.currentLocation.latitude.toStringAsFixed(4)}, ${tracking.currentLocation.longitude.toStringAsFixed(4)}',
            ),
            if (tracking.estimatedDeliveryTime != null && !tracking.isDelivered) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.schedule,
                'Estimated Delivery',
                _formatDateTime(tracking.estimatedDeliveryTime!),
              ),
            ],
            if (tracking.notes != null && tracking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.note,
                'Notes',
                tracking.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, DeliveryTrackingModel tracking) {
    final statuses = DeliveryStatus.values;
    final currentIndex = statuses.indexOf(tracking.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return _buildTimelineItem(
                context,
                status,
                isCompleted,
                isCurrent,
                index < statuses.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    DeliveryStatus status,
    bool isCompleted,
    bool isCurrent,
    bool showLine,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? (isCurrent ? status.color : Colors.green)
                    : Colors.grey.shade300,
                border: Border.all(
                  color: isCurrent ? status.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      isCurrent ? status.icon : Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted
                            ? (isCurrent ? status.color : Colors.grey.shade700)
                            : Colors.grey.shade400,
                      ),
                ),
                if (isCurrent)
                  Text(
                    'In progress...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: status.color,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  Future<void> _openInMaps(double lat, double lon) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callDeliveryPerson(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

