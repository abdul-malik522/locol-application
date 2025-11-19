import 'dart:async';

import 'package:localtrade/features/trust/data/models/user_report_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class UserReportsDataSource {
  UserReportsDataSource._();
  static final UserReportsDataSource instance = UserReportsDataSource._();
  final _uuid = const Uuid();

  static const String _reportsKey = 'user_reports';

  Future<List<UserReportModel>> getAllReports() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsJson = prefs.getString(_reportsKey);
    if (reportsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(reportsJson) as List<dynamic>;
      return decoded
          .map((e) => UserReportModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }

  Future<void> fileReport(UserReportModel report) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UserReportModel> existingReports = await getAllReports();
    existingReports.add(report);

    final String encoded = json.encode(existingReports.map((e) => e.toJson()).toList());
    await prefs.setString(_reportsKey, encoded);
  }

  Future<List<UserReportModel>> getReportsForUser(String userId) async {
    final allReports = await getAllReports();
    return allReports.where((r) => r.reportedUserId == userId).toList();
  }

  Future<List<UserReportModel>> getReportsByUser(String userId) async {
    final allReports = await getAllReports();
    return allReports.where((r) => r.reportedBy == userId).toList();
  }

  Future<List<UserReportModel>> getPendingReports() async {
    final allReports = await getAllReports();
    return allReports.where((r) => r.isActive).toList();
  }

  Future<UserReportModel?> getReportById(String reportId) async {
    final allReports = await getAllReports();
    try {
      return allReports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasUserReportedUser(String reportedUserId, String reporterUserId) async {
    final allReports = await getAllReports();
    return allReports.any((r) => r.reportedUserId == reportedUserId && r.reportedBy == reporterUserId);
  }

  Future<UserReportModel> updateReportStatus(
    String reportId,
    UserReportStatus newStatus, {
    String? adminResponse,
    String? actionTaken,
    String? reviewedBy,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<UserReportModel> allReports = await getAllReports();
    final index = allReports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Report not found');

    final updated = allReports[index].copyWith(
      status: newStatus,
      adminResponse: adminResponse,
      actionTaken: actionTaken,
      reviewedAt: DateTime.now(),
      reviewedBy: reviewedBy,
    );
    allReports[index] = updated;

    final String encoded = json.encode(allReports.map((e) => e.toJson()).toList());
    await prefs.setString(_reportsKey, encoded);

    return updated;
  }
}

