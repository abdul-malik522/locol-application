import 'package:flutter/material.dart';

import 'package:localtrade/features/search/providers/search_provider.dart';

@immutable
class SavedSearchModel {
  const SavedSearchModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.query,
    required this.filters,
    required this.searchType,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String name; // User-friendly name for the saved search
  final String query;
  final Map<String, dynamic> filters;
  final SearchType searchType;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedSearchModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? query,
    Map<String, dynamic>? filters,
    SearchType? searchType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedSearchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      searchType: searchType ?? this.searchType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory SavedSearchModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      query: json['query'] as String,
      filters: Map<String, dynamic>.from(json['filters'] as Map),
      searchType: SearchType.values.firstWhere(
        (e) => e.name == json['searchType'],
        orElse: () => SearchType.posts,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'query': query,
      'filters': filters,
      'searchType': searchType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

