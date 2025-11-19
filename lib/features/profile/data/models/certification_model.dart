import 'package:flutter/material.dart';

enum CertificationType {
  organic('Organic Certified', Icons.eco, Colors.green, 'USDA Organic'),
  biodynamic('Biodynamic', Icons.auto_awesome, Colors.purple, 'Demeter Certified'),
  fairTrade('Fair Trade', Icons.handshake, Colors.orange, 'Fair Trade Certified'),
  nonGMO('Non-GMO', Icons.verified, Colors.blue, 'Non-GMO Project Verified'),
  kosher('Kosher', Icons.restaurant, Colors.indigo, 'Kosher Certified'),
  halal('Halal', Icons.mosque, Colors.teal, 'Halal Certified'),
  local('Local Producer', Icons.location_on, Colors.red, 'Local Producer'),
  sustainable('Sustainable', Icons.forest, Colors.green, 'Sustainable Farming'),
  grassFed('Grass-Fed', Icons.pets, Colors.brown, 'Grass-Fed Certified'),
  freeRange('Free-Range', Icons.agriculture, Colors.amber, 'Free-Range Certified');

  const CertificationType(
    this.label,
    this.icon,
    this.color,
    this.description,
  );
  final String label;
  final IconData icon;
  final Color color;
  final String description;
}

@immutable
class CertificationModel {
  CertificationModel({
    required this.type,
    this.certificationNumber,
    this.issuingOrganization,
    this.issuedDate,
    this.expiryDate,
    this.certificateUrl,
  });

  final CertificationType type;
  final String? certificationNumber; // Certificate ID or number
  final String? issuingOrganization; // Organization that issued the certification
  final DateTime? issuedDate; // When the certification was issued
  final DateTime? expiryDate; // When the certification expires (if applicable)
  final String? certificateUrl; // URL to view/download the certificate

  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get isExpiringSoon {
    if (expiryDate == null || isExpired) return false;
    final timeUntilExpiry = expiryDate!.difference(DateTime.now());
    return timeUntilExpiry.inDays <= 30 && timeUntilExpiry.inDays > 0;
  }

  CertificationModel copyWith({
    CertificationType? type,
    String? certificationNumber,
    String? issuingOrganization,
    DateTime? issuedDate,
    DateTime? expiryDate,
    String? certificateUrl,
  }) {
    return CertificationModel(
      type: type ?? this.type,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      issuingOrganization: issuingOrganization ?? this.issuingOrganization,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      certificateUrl: certificateUrl ?? this.certificateUrl,
    );
  }

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      type: CertificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CertificationType.organic,
      ),
      certificationNumber: json['certificationNumber'] as String?,
      issuingOrganization: json['issuingOrganization'] as String?,
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      certificateUrl: json['certificateUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'certificationNumber': certificationNumber,
      'issuingOrganization': issuingOrganization,
      'issuedDate': issuedDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'certificateUrl': certificateUrl,
    };
  }
}

