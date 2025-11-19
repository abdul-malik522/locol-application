import 'package:flutter/material.dart';

enum UserReportReason {
  spam('Spam or fake account', Icons.report_gmailerrorred),
  harassment('Harassment or bullying', Icons.person_off),
  inappropriate('Inappropriate behavior', Icons.block),
  scam('Scam or fraud', Icons.warning_amber),
  impersonation('Impersonation', Icons.person_outline),
  illegal('Illegal activity', Icons.gavel),
  other('Other (please specify)', Icons.info_outline);

  const UserReportReason(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class UserReportModel {
  const UserReportModel({
    required this.id,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.reportedBy,
    required this.reportedByName,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    this.adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String reportedUserId; // User ID who was reported
  final String reportedUserName; // User name who was reported
  final String reportedBy; // User ID who reported
  final String reportedByName; // User name who reported
  final UserReportReason reason;
  final String description;
  final ReportStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isResolved => status == ReportStatus.resolved;
  bool get isActive => status == ReportStatus.pending || status == ReportStatus.underReview;

  UserReportModel copyWith({
    String? id,
    String? reportedUserId,
    String? reportedUserName,
    String? reportedBy,
    String? reportedByName,
    UserReportReason? reason,
    String? description,
    ReportStatus? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserReportModel(
      id: id ?? this.id,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedUserName: reportedUserName ?? this.reportedUserName,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory UserReportModel.fromJson(Map<String, dynamic> json) {
    return UserReportModel(
      id: json['id'] as String,
      reportedUserId: json['reportedUserId'] as String,
      reportedUserName: json['reportedUserName'] as String,
      reportedBy: json['reportedBy'] as String,
      reportedByName: json['reportedByName'] as String,
      reason: UserReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => UserReportReason.other,
      ),
      description: json['description'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      adminResponse: json['adminResponse'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedUserId': reportedUserId,
      'reportedUserName': reportedUserName,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'adminResponse': adminResponse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Reuse ReportStatus from post_report_model
enum ReportStatus {
  pending('Pending Review', Icons.pending_outlined, Colors.orange),
  underReview('Under Review', Icons.visibility, Colors.blue),
  resolved('Resolved', Icons.check_circle, Colors.green),
  rejected('Rejected', Icons.cancel, Colors.red),
  dismissed('Dismissed', Icons.close, Colors.grey);

  const ReportStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

