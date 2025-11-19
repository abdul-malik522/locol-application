import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/features/analytics/presentation/screens/restaurant_analytics_screen.dart';
import 'package:localtrade/features/analytics/presentation/screens/seller_analytics_screen.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class AnalyticsRouter extends ConsumerWidget {
  const AnalyticsRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    if (currentUser.isSeller) {
      return const SellerAnalyticsScreen();
    } else if (currentUser.isRestaurant) {
      return const RestaurantAnalyticsScreen();
    } else {
      return const Scaffold(
        body: ErrorView(error: 'Analytics not available for this user type'),
      );
    }
  }
}

