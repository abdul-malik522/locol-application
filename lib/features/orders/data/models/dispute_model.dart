import 'package:flutter/material.dart';

enum DisputeStatus {
  pending('Pending Review', Icons.pending_outlined, Colors.orange),
  underReview('Under Review', Icons.visibility, Colors.blue),
  resolved('Resolved', Icons.check_circle, Colors.green),
  rejected('Rejected', Icons.cancel, Colors.red),
  closed('Closed', Icons.close, Colors.grey);

  const DisputeStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum DisputeReason {
  wrongProduct('Wrong product received', Icons.error_outline),
  damagedProduct('Product damaged or defective', Icons.broken_image),
  missingItems('Missing items from order', Icons.inventory_2_outlined),
  qualityIssue('Quality not as described', Icons.thumb_down),
  deliveryIssue('Delivery problem', Icons.local_shipping_outlined),
  paymentIssue('Payment problem', Icons.payment),
  sellerUnresponsive('Seller unresponsive', Icons.person_off_outlined),
  other('Other', Icons.more_horiz);

  const DisputeReason(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class DisputeModel {
  DisputeModel({
    required this.id,
    required this.orderId,
    required this.filedBy,
    required this.filedByName,
    required this.opposingParty,
    required this.opposingPartyName,
    required this.reason,
    required this.description,
    required this.status,
    this.adminResponse,
    this.resolution,
    this.resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String orderId;
  final String filedBy; // User ID who filed the dispute
  final String filedByName;
  final String opposingParty; // User ID of the other party
  final String opposingPartyName;
  final DisputeReason reason;
  final String description;
  final DisputeStatus status;
  final String? adminResponse;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isResolved => status == DisputeStatus.resolved || status == DisputeStatus.closed;
  bool get isActive => status == DisputeStatus.pending || status == DisputeStatus.underReview;

  DisputeModel copyWith({
    String? id,
    String? orderId,
    String? filedBy,
    String? filedByName,
    String? opposingParty,
    String? opposingPartyName,
    DisputeReason? reason,
    String? description,
    DisputeStatus? status,
    String? adminResponse,
    String? resolution,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DisputeModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      filedBy: filedBy ?? this.filedBy,
      filedByName: filedByName ?? this.filedByName,
      opposingParty: opposingParty ?? this.opposingParty,
      opposingPartyName: opposingPartyName ?? this.opposingPartyName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      resolution: resolution ?? this.resolution,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      filedBy: json['filedBy'] as String,
      filedByName: json['filedByName'] as String,
      opposingParty: json['opposingParty'] as String,
      opposingPartyName: json['opposingPartyName'] as String,
      reason: DisputeReason.values.firstWhere(
        (r) => r.name == (json['reason'] as String),
        orElse: () => DisputeReason.other,
      ),
      description: json['description'] as String,
      status: DisputeStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => DisputeStatus.pending,
      ),
      adminResponse: json['adminResponse'] as String?,
      resolution: json['resolution'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'filedBy': filedBy,
      'filedByName': filedByName,
      'opposingParty': opposingParty,
      'opposingPartyName': opposingPartyName,
      'reason': reason.name,
      'description': description,
      'status': status.name,
      'adminResponse': adminResponse,
      'resolution': resolution,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

