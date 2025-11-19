import 'package:flutter/material.dart';

enum IdentityVerificationStatus {
  notStarted('Not Started', Icons.circle_outlined, Colors.grey),
  pending('Pending Review', Icons.hourglass_empty, Colors.orange),
  underReview('Under Review', Icons.search, Colors.blue),
  approved('Approved', Icons.check_circle, Colors.green),
  rejected('Rejected', Icons.cancel, Colors.red);

  const IdentityVerificationStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum IdentityDocumentType {
  passport('Passport', Icons.book),
  driversLicense('Driver\'s License', Icons.credit_card),
  nationalId('National ID', Icons.badge),
  other('Other', Icons.description);

  const IdentityDocumentType(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class IdentityVerificationModel {
  IdentityVerificationModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.documentType,
    required this.documentNumber,
    required this.documentIssuingCountry,
    this.documentFrontUrl,
    this.documentBackUrl,
    this.selfieUrl,
    this.status = IdentityVerificationStatus.notStarted,
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
  final String fullName;
  final DateTime dateOfBirth;
  final IdentityDocumentType documentType;
  final String documentNumber;
  final String documentIssuingCountry;
  final String? documentFrontUrl; // URL to uploaded document front
  final String? documentBackUrl; // URL to uploaded document back
  final String? selfieUrl; // URL to uploaded selfie for verification
  final IdentityVerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  IdentityVerificationModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    IdentityDocumentType? documentType,
    String? documentNumber,
    String? documentIssuingCountry,
    String? documentFrontUrl,
    String? documentBackUrl,
    String? selfieUrl,
    IdentityVerificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdentityVerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentIssuingCountry: documentIssuingCountry ?? this.documentIssuingCountry,
      documentFrontUrl: documentFrontUrl ?? this.documentFrontUrl,
      documentBackUrl: documentBackUrl ?? this.documentBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
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

  factory IdentityVerificationModel.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      documentType: IdentityDocumentType.values.firstWhere(
        (e) => e.name == json['documentType'],
        orElse: () => IdentityDocumentType.other,
      ),
      documentNumber: json['documentNumber'] as String,
      documentIssuingCountry: json['documentIssuingCountry'] as String,
      documentFrontUrl: json['documentFrontUrl'] as String?,
      documentBackUrl: json['documentBackUrl'] as String?,
      selfieUrl: json['selfieUrl'] as String?,
      status: IdentityVerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IdentityVerificationStatus.notStarted,
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
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'documentIssuingCountry': documentIssuingCountry,
      'documentFrontUrl': documentFrontUrl,
      'documentBackUrl': documentBackUrl,
      'selfieUrl': selfieUrl,
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

  bool get isPending => status == IdentityVerificationStatus.pending || status == IdentityVerificationStatus.underReview;
  bool get isApproved => status == IdentityVerificationStatus.approved;
  bool get isRejected => status == IdentityVerificationStatus.rejected;
}

