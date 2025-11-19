import 'package:flutter/material.dart';

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

enum PostReportReason {
  spam('Spam or misleading content', Icons.report_gmailerrorred),
  inappropriate('Inappropriate content', Icons.block),
  fake('Fake or fraudulent listing', Icons.warning_amber),
  harassment('Harassment or bullying', Icons.person_off),
  copyright('Copyright violation', Icons.copyright),
  illegal('Illegal activity', Icons.gavel),
  other('Other (please specify)', Icons.info_outline);

  const PostReportReason(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class PostReportModel {
  PostReportModel({
    required this.id,
    required this.postId,
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
  final String postId;
  final String reportedBy; // User ID who reported
  final String reportedByName; // User name who reported
  final PostReportReason reason;
  final String description;
  final ReportStatus status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isResolved => status == ReportStatus.resolved;
  bool get isActive => status == ReportStatus.pending || status == ReportStatus.underReview;

  PostReportModel copyWith({
    String? id,
    String? postId,
    String? reportedBy,
    String? reportedByName,
    PostReportReason? reason,
    String? description,
    ReportStatus? status,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostReportModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
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

  factory PostReportModel.fromJson(Map<String, dynamic> json) {
    return PostReportModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      reportedBy: json['reportedBy'] as String,
      reportedByName: json['reportedByName'] as String,
      reason: PostReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => PostReportReason.other,
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
      'postId': postId,
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

