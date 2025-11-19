import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/home/data/datasources/price_alerts_datasource.dart';
import 'package:localtrade/features/home/data/models/price_alert_model.dart';

class PriceAlertsState {
  const PriceAlertsState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PriceAlertModel> alerts;
  final bool isLoading;
  final String? error;

  PriceAlertsState copyWith({
    List<PriceAlertModel>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return PriceAlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final priceAlertsDataSourceProvider =
    Provider<PriceAlertsDataSource>((ref) => PriceAlertsDataSource.instance);

final priceAlertsProvider =
    StateNotifierProvider.family<PriceAlertsNotifier, PriceAlertsState, String>(
        (ref, userId) {
  final dataSource = ref.watch(priceAlertsDataSourceProvider);
  return PriceAlertsNotifier(dataSource, userId);
});

class PriceAlertsNotifier extends StateNotifier<PriceAlertsState> {
  PriceAlertsNotifier(this._dataSource, this._userId)
      : super(const PriceAlertsState()) {
    loadAlerts();
  }

  final PriceAlertsDataSource _dataSource;
  final String _userId;

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final alerts = await _dataSource.getAlerts(_userId);
      state = state.copyWith(alerts: alerts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load alerts: ${e.toString()}',
      );
    }
  }

  Future<void> createAlert(PriceAlertModel alert) async {
    try {
      await _dataSource.createAlert(alert);
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create alert: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _dataSource.deleteAlert(alertId, _userId);
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete alert: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateAlert(PriceAlertModel alert) async {
    try {
      await _dataSource.updateAlert(alert);
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update alert: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> hasAlertForPost(String postId) async {
    final alerts = await _dataSource.getAlerts(_userId);
    return alerts.any((a) => a.postId == postId && a.isActive);
  }
}

