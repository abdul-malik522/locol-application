import 'package:flutter/material.dart';

enum BusinessVerificationStatus {
  notStarted('Not Started', Icons.circle_outlined, Colors.grey),
  pending('Pending Review', Icons.hourglass_empty, Colors.orange),
  underReview('Under Review', Icons.search, Colors.blue),
  approved('Approved', Icons.check_circle, Colors.green),
  rejected('Rejected', Icons.cancel, Colors.red);

  const BusinessVerificationStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class BusinessVerificationModel {
  const BusinessVerificationModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessType,
    required this.licenseNumber,
    required this.licenseIssuingAuthority,
    this.licenseDocumentUrl,
    this.taxIdNumber,
    this.taxDocumentUrl,
    this.status = BusinessVerificationStatus.notStarted,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String businessName;
  final String businessType; // e.g., "Farm", "Restaurant", "Producer"
  final String licenseNumber;
  final String licenseIssuingAuthority;
  final String? licenseDocumentUrl; // URL to uploaded document
  final String? taxIdNumber;
  final String? taxDocumentUrl; // URL to uploaded tax document
  final BusinessVerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessVerificationModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessType,
    String? licenseNumber,
    String? licenseIssuingAuthority,
    String? licenseDocumentUrl,
    String? taxIdNumber,
    String? taxDocumentUrl,
    BusinessVerificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessVerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseIssuingAuthority: licenseIssuingAuthority ?? this.licenseIssuingAuthority,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      taxIdNumber: taxIdNumber ?? this.taxIdNumber,
      taxDocumentUrl: taxDocumentUrl ?? this.taxDocumentUrl,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory BusinessVerificationModel.fromJson(Map<String, dynamic> json) {
    return BusinessVerificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessName: json['businessName'] as String,
      businessType: json['businessType'] as String,
      licenseNumber: json['licenseNumber'] as String,
      licenseIssuingAuthority: json['licenseIssuingAuthority'] as String,
      licenseDocumentUrl: json['licenseDocumentUrl'] as String?,
      taxIdNumber: json['taxIdNumber'] as String?,
      taxDocumentUrl: json['taxDocumentUrl'] as String?,
      status: BusinessVerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BusinessVerificationStatus.notStarted,
      ),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'businessType': businessType,
      'licenseNumber': licenseNumber,
      'licenseIssuingAuthority': licenseIssuingAuthority,
      'licenseDocumentUrl': licenseDocumentUrl,
      'taxIdNumber': taxIdNumber,
      'taxDocumentUrl': taxDocumentUrl,
      'status': status.name,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == BusinessVerificationStatus.pending || status == BusinessVerificationStatus.underReview;
  bool get isApproved => status == BusinessVerificationStatus.approved;
  bool get isRejected => status == BusinessVerificationStatus.rejected;
}

