import 'package:flutter/material.dart';

enum UserReportReason {
  spam('Spam or Fake Account', Icons.report, Colors.orange),
  harassment('Harassment or Bullying', Icons.block, Colors.red),
  inappropriateContent('Inappropriate Content', Icons.warning, Colors.amber),
  scam('Scam or Fraud', Icons.gavel, Colors.red),
  impersonation('Impersonation', Icons.person_off, Colors.purple),
  other('Other', Icons.more_horiz, Colors.grey);

  const UserReportReason(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum UserReportStatus {
  pending('Pending Review', Icons.hourglass_empty, Colors.orange),
  underReview('Under Review', Icons.search, Colors.blue),
  resolved('Resolved', Icons.check_circle, Colors.green),
  dismissed('Dismissed', Icons.cancel, Colors.grey);

  const UserReportStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
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
    this.status = UserReportStatus.pending,
    this.adminResponse,
    this.actionTaken,
    this.reviewedAt,
    this.reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String reportedUserId; // User being reported
  final String reportedUserName;
  final String reportedBy; // User who filed the report
  final String reportedByName;
  final UserReportReason reason;
  final String description;
  final UserReportStatus status;
  final String? adminResponse;
  final String? actionTaken; // e.g., "User warned", "Account suspended"
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReportModel copyWith({
    String? id,
    String? reportedUserId,
    String? reportedUserName,
    String? reportedBy,
    String? reportedByName,
    UserReportReason? reason,
    String? description,
    UserReportStatus? status,
    String? adminResponse,
    String? actionTaken,
    DateTime? reviewedAt,
    String? reviewedBy,
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
      actionTaken: actionTaken ?? this.actionTaken,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
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
      status: UserReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserReportStatus.pending,
      ),
      adminResponse: json['adminResponse'] as String?,
      actionTaken: json['actionTaken'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedBy: json['reviewedBy'] as String?,
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
      'actionTaken': actionTaken,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isResolved => status == UserReportStatus.resolved || status == UserReportStatus.dismissed;
  bool get isActive => status == UserReportStatus.pending || status == UserReportStatus.underReview;
}

