import 'package:flutter/material.dart';

enum SearchAlertStatus {
  active('Active', Icons.notifications_active, Colors.green),
  paused('Paused', Icons.notifications_paused, Colors.orange),
  inactive('Inactive', Icons.notifications_off, Colors.grey);

  const SearchAlertStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class SearchAlertModel {
  SearchAlertModel({
    required this.id,
    required this.userId,
    required this.savedSearchId,
    required this.savedSearchName,
    required this.query,
    required this.filters,
    required this.status,
    this.lastNotifiedAt,
    this.matchCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String savedSearchId; // Reference to saved search
  final String savedSearchName; // Name of the saved search
  final String query;
  final Map<String, dynamic> filters;
  final SearchAlertStatus status;
  final DateTime? lastNotifiedAt; // When user was last notified
  final int matchCount; // Number of new matches found
  final DateTime createdAt;
  final DateTime updatedAt;

  SearchAlertModel copyWith({
    String? id,
    String? userId,
    String? savedSearchId,
    String? savedSearchName,
    String? query,
    Map<String, dynamic>? filters,
    SearchAlertStatus? status,
    DateTime? lastNotifiedAt,
    int? matchCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SearchAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      savedSearchId: savedSearchId ?? this.savedSearchId,
      savedSearchName: savedSearchName ?? this.savedSearchName,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      status: status ?? this.status,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory SearchAlertModel.fromJson(Map<String, dynamic> json) {
    return SearchAlertModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      savedSearchId: json['savedSearchId'] as String,
      savedSearchName: json['savedSearchName'] as String,
      query: json['query'] as String,
      filters: Map<String, dynamic>.from(json['filters'] as Map),
      status: SearchAlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SearchAlertStatus.active,
      ),
      lastNotifiedAt: json['lastNotifiedAt'] != null
          ? DateTime.parse(json['lastNotifiedAt'] as String)
          : null,
      matchCount: json['matchCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'savedSearchId': savedSearchId,
      'savedSearchName': savedSearchName,
      'query': query,
      'filters': filters,
      'status': status.name,
      'lastNotifiedAt': lastNotifiedAt?.toIso8601String(),
      'matchCount': matchCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == SearchAlertStatus.active;
}

