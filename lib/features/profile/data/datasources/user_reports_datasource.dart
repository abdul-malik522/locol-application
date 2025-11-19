import 'dart:async';

import 'package:localtrade/features/profile/data/models/user_report_model.dart';
import 'package:uuid/uuid.dart';

class UserReportsDataSource {
  UserReportsDataSource._();
  static final UserReportsDataSource instance = UserReportsDataSource._();
  final _uuid = const Uuid();

  final List<UserReportModel> _reports = [];

  /// File a report for a user
  Future<UserReportModel> fileReport(UserReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newReport = report.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _reports.add(newReport);
    return newReport;
  }

  /// Get all reports for a specific user
  Future<List<UserReportModel>> getReportsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports
        .where((r) => r.reportedUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all reports filed by a user
  Future<List<UserReportModel>> getReportsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports
        .where((r) => r.reportedBy == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all reports (admin view)
  Future<List<UserReportModel>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a specific report by ID
  Future<UserReportModel?> getReportById(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _reports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  /// Check if user has already reported this user
  Future<bool> hasUserReportedUser(String reportedUserId, String reporterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reports.any(
      (r) => r.reportedUserId == reportedUserId && r.reportedBy == reporterId,
    );
  }

  /// Update report status (admin action)
  Future<UserReportModel> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? adminResponse,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Report not found');

    final updated = _reports[index].copyWith(
      status: newStatus,
      adminResponse: adminResponse,
      updatedAt: DateTime.now(),
    );
    _reports[index] = updated;
    return updated;
  }
}

