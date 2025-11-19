import 'package:flutter/material.dart';

enum VerificationType {
  business('Business Verified', Icons.business, Colors.blue),
  identity('Identity Verified', Icons.verified_user, Colors.green),
  premium('Premium Member', Icons.star, Colors.amber);

  const VerificationType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class VerificationBadgeModel {
  const VerificationBadgeModel({
    required this.type,
    this.verifiedAt,
    this.verifiedBy,
  });

  final VerificationType type;
  final DateTime? verifiedAt; // When the verification was granted
  final String? verifiedBy; // Admin or system that verified

  VerificationBadgeModel copyWith({
    VerificationType? type,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return VerificationBadgeModel(
      type: type ?? this.type,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  factory VerificationBadgeModel.fromJson(Map<String, dynamic> json) {
    return VerificationBadgeModel(
      type: VerificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VerificationType.business,
      ),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      verifiedBy: json['verifiedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }
}

