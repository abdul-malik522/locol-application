import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/features/settings/data/datasources/privacy_settings_datasource.dart';
import 'package:localtrade/features/settings/data/models/privacy_settings_model.dart';

final privacySettingsDataSourceProvider =
    Provider<PrivacySettingsDataSource>((ref) => PrivacySettingsDataSource.instance);

final privacySettingsProvider =
    StateNotifierProvider.family<PrivacySettingsNotifier, AsyncValue<PrivacySettingsModel>, String>(
        (ref, userId) {
  final dataSource = ref.watch(privacySettingsDataSourceProvider);
  return PrivacySettingsNotifier(dataSource, userId);
});

class PrivacySettingsNotifier extends StateNotifier<AsyncValue<PrivacySettingsModel>> {
  PrivacySettingsNotifier(this._dataSource, this._userId) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  final PrivacySettingsDataSource _dataSource;
  final String _userId;

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _dataSource.getSettings(_userId);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(PrivacySettingsModel settings) async {
    try {
      await _dataSource.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateProfileVisibility(ProfileVisibility visibility) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(profileVisibility: visibility));
  }

  Future<void> updateShowEmail(bool show) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showEmail: show));
  }

  Future<void> updateShowPhoneNumber(bool show) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showPhoneNumber: show));
  }

  Future<void> updateShowLocation(bool show) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showLocation: show));
  }

  Future<void> updateAllowProfileDiscovery(bool allow) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(allowProfileDiscovery: allow));
  }

  Future<void> updateAllowAnalyticsDataSharing(bool allow) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(allowAnalyticsDataSharing: allow));
  }

  Future<void> updateAllowThirdPartyDataSharing(bool allow) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(allowThirdPartyDataSharing: allow));
  }

  Future<void> updateShowActivityStatus(bool show) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showActivityStatus: show));
  }

  Future<void> updateShowReadReceipts(bool show) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(showReadReceipts: show));
  }

  Future<void> updateMessagePrivacy(MessagePrivacy privacy) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(messagePrivacy: privacy));
  }

  Future<void> resetToDefaults() async {
    try {
      await _dataSource.resetSettings(_userId);
      await loadSettings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

