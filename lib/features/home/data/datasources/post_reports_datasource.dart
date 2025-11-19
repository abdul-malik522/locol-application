import 'dart:async';

import 'package:localtrade/features/home/data/models/post_report_model.dart';
import 'package:uuid/uuid.dart';

class PostReportsDataSource {
  PostReportsDataSource._();
  static final PostReportsDataSource instance = PostReportsDataSource._();
  final _uuid = const Uuid();

  final List<PostReportModel> _reports = [];

  /// File a report for a post
  Future<PostReportModel> fileReport(PostReportModel report) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newReport = report.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _reports.add(newReport);
    return newReport;
  }

  /// Get all reports for a specific post
  Future<List<PostReportModel>> getReportsForPost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports
        .where((r) => r.postId == postId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all reports filed by a user
  Future<List<PostReportModel>> getReportsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports
        .where((r) => r.reportedBy == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all reports (admin view)
  Future<List<PostReportModel>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a specific report by ID
  Future<PostReportModel?> getReportById(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _reports.firstWhere((r) => r.id == reportId);
    } catch (_) {
      return null;
    }
  }

  /// Check if user has already reported this post
  Future<bool> hasUserReportedPost(String postId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reports.any((r) => r.postId == postId && r.reportedBy == userId);
  }

  /// Update report status (admin action)
  Future<PostReportModel> updateReportStatus(
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

