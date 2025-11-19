import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/search/data/datasources/search_alerts_datasource.dart';
import 'package:localtrade/features/search/data/models/search_alert_model.dart';

final searchAlertsDataSourceProvider =
    Provider<SearchAlertsDataSource>((ref) => SearchAlertsDataSource.instance);

final searchAlertsProvider =
    FutureProvider.family<List<SearchAlertModel>, String>((ref, userId) {
  final dataSource = ref.watch(searchAlertsDataSourceProvider);
  return dataSource.getSearchAlerts(userId);
});

final activeSearchAlertsProvider =
    FutureProvider.family<List<SearchAlertModel>, String>((ref, userId) {
  final dataSource = ref.watch(searchAlertsDataSourceProvider);
  return dataSource.getActiveAlerts(userId);
});

