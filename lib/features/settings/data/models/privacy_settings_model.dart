import 'package:flutter/material.dart';

enum ProfileVisibility {
  public('Public', 'Anyone can view your profile', Icons.public),
  followers('Followers Only', 'Only your followers can view your profile', Icons.people),
  private('Private', 'Only you can view your profile', Icons.lock);

  const ProfileVisibility(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

enum MessagePrivacy {
  everyone('Everyone', 'Anyone can send you messages', Icons.chat_bubble_outline),
  followers('Followers Only', 'Only your followers can send you messages', Icons.people_outline),
  none('No One', 'No one can send you messages', Icons.block);

  const MessagePrivacy(this.label, this.description, this.icon);
  final String label;
  final String description;
  final IconData icon;
}

@immutable
class PrivacySettingsModel {
  const PrivacySettingsModel({
    required this.userId,
    this.profileVisibility = ProfileVisibility.public,
    this.showEmail = false,
    this.showPhoneNumber = false,
    this.showLocation = true,
    this.allowProfileDiscovery = true,
    this.allowAnalyticsDataSharing = true,
    this.allowThirdPartyDataSharing = false,
    this.showActivityStatus = true,
    this.showReadReceipts = true,
    this.messagePrivacy = MessagePrivacy.everyone,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String userId;
  final ProfileVisibility profileVisibility;
  final bool showEmail;
  final bool showPhoneNumber;
  final bool showLocation;
  final bool allowProfileDiscovery; // Allow profile to appear in search results
  final bool allowAnalyticsDataSharing; // Share data for analytics purposes
  final bool allowThirdPartyDataSharing; // Share data with third-party services
  final bool showActivityStatus; // Show when user was last active
  final bool showReadReceipts; // Show read receipts in messages
  final MessagePrivacy messagePrivacy; // Who can send messages
  final DateTime updatedAt;

  PrivacySettingsModel copyWith({
    String? userId,
    ProfileVisibility? profileVisibility,
    bool? showEmail,
    bool? showPhoneNumber,
    bool? showLocation,
    bool? allowProfileDiscovery,
    bool? allowAnalyticsDataSharing,
    bool? allowThirdPartyDataSharing,
    bool? showActivityStatus,
    bool? showReadReceipts,
    MessagePrivacy? messagePrivacy,
    DateTime? updatedAt,
  }) {
    return PrivacySettingsModel(
      userId: userId ?? this.userId,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showLocation: showLocation ?? this.showLocation,
      allowProfileDiscovery: allowProfileDiscovery ?? this.allowProfileDiscovery,
      allowAnalyticsDataSharing: allowAnalyticsDataSharing ?? this.allowAnalyticsDataSharing,
      allowThirdPartyDataSharing: allowThirdPartyDataSharing ?? this.allowThirdPartyDataSharing,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      messagePrivacy: messagePrivacy ?? this.messagePrivacy,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsModel(
      userId: json['userId'] as String,
      profileVisibility: ProfileVisibility.values.firstWhere(
        (e) => e.name == json['profileVisibility'],
        orElse: () => ProfileVisibility.public,
      ),
      showEmail: json['showEmail'] as bool? ?? false,
      showPhoneNumber: json['showPhoneNumber'] as bool? ?? false,
      showLocation: json['showLocation'] as bool? ?? true,
      allowProfileDiscovery: json['allowProfileDiscovery'] as bool? ?? true,
      allowAnalyticsDataSharing: json['allowAnalyticsDataSharing'] as bool? ?? true,
      allowThirdPartyDataSharing: json['allowThirdPartyDataSharing'] as bool? ?? false,
      showActivityStatus: json['showActivityStatus'] as bool? ?? true,
      showReadReceipts: json['showReadReceipts'] as bool? ?? true,
      messagePrivacy: MessagePrivacy.values.firstWhere(
        (e) => e.name == json['messagePrivacy'],
        orElse: () => MessagePrivacy.everyone,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileVisibility': profileVisibility.name,
      'showEmail': showEmail,
      'showPhoneNumber': showPhoneNumber,
      'showLocation': showLocation,
      'allowProfileDiscovery': allowProfileDiscovery,
      'allowAnalyticsDataSharing': allowAnalyticsDataSharing,
      'allowThirdPartyDataSharing': allowThirdPartyDataSharing,
      'showActivityStatus': showActivityStatus,
      'showReadReceipts': showReadReceipts,
      'messagePrivacy': messagePrivacy.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

