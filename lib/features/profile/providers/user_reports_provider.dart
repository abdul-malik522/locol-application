import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/profile/data/datasources/user_reports_datasource.dart';
import 'package:localtrade/features/profile/data/models/user_report_model.dart';

final userReportsDataSourceProvider =
    Provider<UserReportsDataSource>((ref) => UserReportsDataSource.instance);

/// Provider to check if a user has already reported another user
final hasUserReportedUserProvider =
    FutureProvider.family<bool, ({String reportedUserId, String reporterId})>(
  (ref, params) async {
    final dataSource = ref.watch(userReportsDataSourceProvider);
    return await dataSource.hasUserReportedUser(
      params.reportedUserId,
      params.reporterId,
    );
  },
);

/// Provider to get all reports for a user
final reportsForUserProvider =
    FutureProvider.family<List<UserReportModel>, String>(
  (ref, userId) async {
    final dataSource = ref.watch(userReportsDataSourceProvider);
    return await dataSource.getReportsForUser(userId);
  },
);

/// Provider to get all reports filed by a user
final reportsByUserProvider =
    FutureProvider.family<List<UserReportModel>, String>(
  (ref, userId) async {
    final dataSource = ref.watch(userReportsDataSourceProvider);
    return await dataSource.getReportsByUser(userId);
  },
);

/// StateNotifier for user report operations
class UserReportsNotifier extends StateNotifier<AsyncValue<void>> {
  UserReportsNotifier(this._dataSource) : super(const AsyncValue.data(null));

  final UserReportsDataSource _dataSource;

  Future<UserReportModel> fileReport(UserReportModel report) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.fileReport(report);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final userReportsNotifierProvider =
    StateNotifierProvider<UserReportsNotifier, AsyncValue<void>>(
  (ref) {
    final dataSource = ref.watch(userReportsDataSourceProvider);
    return UserReportsNotifier(dataSource);
  },
);

