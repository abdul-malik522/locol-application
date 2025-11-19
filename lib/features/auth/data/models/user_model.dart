import 'package:flutter/material.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/profile/data/models/business_hours_model.dart';
import 'package:localtrade/features/profile/data/models/certification_model.dart';
import 'package:localtrade/features/profile/data/models/verification_badge_model.dart';

@immutable
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.coverImageUrl,
    this.businessName,
    this.businessDescription,
    this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.isEmailVerified = false,
    this.businessHours,
    this.verificationBadges = const [],
    this.certifications = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    assert(email.contains('@'), 'Email must be valid');
    assert(rating >= 0 && rating <= 5, 'Rating must be between 0 and 5');
  }

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? businessName;
  final String? businessDescription;
  final String? phoneNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final bool isEmailVerified;
  final BusinessHoursModel? businessHours; // Operating hours for restaurants
  final List<VerificationBadgeModel> verificationBadges; // Verification badges
  final List<CertificationModel> certifications; // Certifications (organic, biodynamic, etc.)
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSeller => role == UserRole.seller;
  bool get isRestaurant => role == UserRole.restaurant;

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    String? coverImageUrl,
    String? businessName,
    String? businessDescription,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    bool? isActive,
    bool? isEmailVerified,
    BusinessHoursModel? businessHours,
    List<VerificationBadgeModel>? verificationBadges,
    List<CertificationModel>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      businessHours: businessHours ?? this.businessHours,
      verificationBadges: verificationBadges ?? this.verificationBadges,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == (json['role'] as String),
        orElse: () => UserRole.seller,
      ),
      profileImageUrl: json['profileImageUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      businessName: json['businessName'] as String?,
      businessDescription: json['businessDescription'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      businessHours: json['businessHours'] != null
          ? BusinessHoursModel.fromJson(json['businessHours'] as Map<String, dynamic>)
          : null,
      verificationBadges: (json['verificationBadges'] as List<dynamic>?)
              ?.map((e) => VerificationBadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => CertificationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'phoneNumber': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'businessHours': businessHours?.toJson(),
      'verificationBadges': verificationBadges.map((b) => b.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Check if user has any verification badges
  bool get isVerified => verificationBadges.isNotEmpty;

  /// Check if user has a specific verification type
  bool hasVerificationType(VerificationType type) {
    return verificationBadges.any((badge) => badge.type == type);
  }
}

