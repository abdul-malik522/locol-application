import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localtrade/features/trust/data/datasources/business_verification_datasource.dart';
import 'package:localtrade/features/trust/data/datasources/identity_verification_datasource.dart';
import 'package:localtrade/features/trust/data/datasources/user_reports_datasource.dart';
import 'package:localtrade/features/trust/data/models/business_verification_model.dart';
import 'package:localtrade/features/trust/data/models/identity_verification_model.dart';
import 'package:localtrade/features/trust/data/models/user_report_model.dart';

// Business Verification Providers
final businessVerificationDataSourceProvider =
    Provider<BusinessVerificationDataSource>(
        (ref) => BusinessVerificationDataSource.instance);

final businessVerificationProvider =
    FutureProvider.family<BusinessVerificationModel?, String>((ref, userId) {
  final dataSource = ref.watch(businessVerificationDataSourceProvider);
  return dataSource.getVerification(userId);
});

final pendingBusinessVerificationsProvider =
    FutureProvider<List<BusinessVerificationModel>>((ref) {
  final dataSource = ref.watch(businessVerificationDataSourceProvider);
  return dataSource.getAllPendingVerifications();
});

// Identity Verification Providers
final identityVerificationDataSourceProvider =
    Provider<IdentityVerificationDataSource>(
        (ref) => IdentityVerificationDataSource.instance);

final identityVerificationProvider =
    FutureProvider.family<IdentityVerificationModel?, String>((ref, userId) {
  final dataSource = ref.watch(identityVerificationDataSourceProvider);
  return dataSource.getVerification(userId);
});

final pendingIdentityVerificationsProvider =
    FutureProvider<List<IdentityVerificationModel>>((ref) {
  final dataSource = ref.watch(identityVerificationDataSourceProvider);
  return dataSource.getAllPendingVerifications();
});

// User Reports Providers
final userReportsDataSourceProvider =
    Provider<UserReportsDataSource>((ref) => UserReportsDataSource.instance);

final userReportsProvider = FutureProvider<List<UserReportModel>>((ref) {
  final dataSource = ref.watch(userReportsDataSourceProvider);
  return dataSource.getAllReports();
});

final pendingUserReportsProvider = FutureProvider<List<UserReportModel>>((ref) {
  final dataSource = ref.watch(userReportsDataSourceProvider);
  return dataSource.getPendingReports();
});

final userReportsForUserProvider =
    FutureProvider.family<List<UserReportModel>, String>((ref, userId) {
  final dataSource = ref.watch(userReportsDataSourceProvider);
  return dataSource.getReportsForUser(userId);
});

