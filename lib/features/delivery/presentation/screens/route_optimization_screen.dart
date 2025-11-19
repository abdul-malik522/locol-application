import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/delivery/data/models/delivery_model.dart';
import 'package:localtrade/features/delivery/data/services/route_optimization_service.dart';
import 'package:localtrade/features/delivery/providers/delivery_provider.dart';
import 'package:uuid/uuid.dart';

class RouteOptimizationScreen extends ConsumerStatefulWidget {
  const RouteOptimizationScreen({super.key});

  @override
  ConsumerState<RouteOptimizationScreen> createState() => _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends ConsumerState<RouteOptimizationScreen> {
  bool _isOptimizing = false;

  Future<void> _optimizeRoutes() async {
    setState(() => _isOptimizing = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // Get pending deliveries
      final pendingDeliveries = await ref.read(
        deliveriesByStatusProvider(DeliveryStatus.scheduled).future,
      );

      if (pendingDeliveries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No scheduled deliveries to optimize')),
          );
        }
        return;
      }

      // Group deliveries by driver (in a real app, you'd have driver assignments)
      // For now, we'll optimize all deliveries together
      final routeService = RouteOptimizationService.instance;

      // Mock start location (in real app, get from driver's current location)
      final startLocation = {'lat': 37.7749, 'lon': -122.4194};

      // Convert deliveries to locations (mock - in real app, geocode addresses)
      final deliveryLocations = pendingDeliveries.map((delivery) {
        // Mock location - in real app, geocode delivery.deliveryAddress
        return DeliveryLocation(
          latitude: 37.7849 + (pendingDeliveries.indexOf(delivery) * 0.01),
          longitude: -122.4094 + (pendingDeliveries.indexOf(delivery) * 0.01),
          address: delivery.deliveryAddress,
        );
      }).toList();

      final result = await routeService.optimizeRoute(
        startLocation: startLocation,
        deliveryLocations: deliveryLocations,
      );

      // Create optimized route
      final route = DeliveryRouteModel(
        id: const Uuid().v4(),
        driverId: currentUser.id,
        deliveries: pendingDeliveries.map((d) => d.id).toList(),
        startLocation: startLocation,
        optimizedRoute: result.optimizedSequence
            .map((loc) => {'lat': loc.latitude, 'lon': loc.longitude})
            .toList(),
        estimatedDuration: result.estimatedDuration,
      );

      final dataSource = ref.read(deliveryDataSourceProvider);
      await dataSource.createRoute(route);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route optimized! ${result.optimizedSequence.length} stops, '
              '${result.totalDistance.toStringAsFixed(1)} km, '
              '${result.estimatedDuration.inMinutes} min',
            ),
          ),
        );
        ref.invalidate(deliveryRoutesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to optimize route: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOptimizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(deliveryRoutesProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Route Optimization'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimize Delivery Routes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatically optimize delivery routes for efficiency',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                CustomButton(
                  text: 'Optimize',
                  onPressed: _isOptimizing ? null : _optimizeRoutes,
                  isLoading: _isOptimizing,
                ),
              ],
            ),
          ),
          Expanded(
            child: routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return const EmptyState(
                    icon: Icons.route,
                    title: 'No Optimized Routes',
                    message: 'Optimize routes to see them here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return _buildRouteCard(context, route);
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                error: error.toString(),
                onRetry: () => ref.invalidate(deliveryRoutesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, DeliveryRouteModel route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.route, color: Colors.blue),
        title: Text('Route ${route.id.substring(0, 8)}'),
        subtitle: Text(
          '${route.deliveries.length} deliveries • '
          '${route.estimatedDuration?.inMinutes ?? 0} min',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, 'Deliveries', '${route.deliveries.length}'),
                if (route.estimatedDuration != null)
                  _buildInfoRow(
                    context,
                    'Estimated Duration',
                    '${route.estimatedDuration!.inHours}h ${route.estimatedDuration!.inMinutes.remainder(60)}m',
                  ),
                if (route.actualDuration != null)
                  _buildInfoRow(
                    context,
                    'Actual Duration',
                    '${route.actualDuration!.inHours}h ${route.actualDuration!.inMinutes.remainder(60)}m',
                  ),
                const SizedBox(height: 8),
                Text(
                  'Optimized Sequence:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...route.optimizedRoute.asMap().entries.map((entry) {
                  final index = entry.key;
                  final location = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Stop ${index + 1}'),
                    subtitle: Text(
                      '${location['lat']?.toStringAsFixed(4)}, ${location['lon']?.toStringAsFixed(4)}',
                    ),
                    dense: true,
                  );
                }).toList(),
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
            width: 140,
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
}

