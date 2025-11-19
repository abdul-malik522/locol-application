import 'package:flutter/material.dart';

@immutable
class ChatModel {
  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantImages = const {},
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.archivedBy = const {},
    this.mutedBy = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantImages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> archivedBy; // userId -> isArchived (per-user archiving)
  final Map<String, bool> mutedBy; // userId -> isMuted (per-user muting)
  final DateTime createdAt;

  String? getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  String? getOtherParticipantImage(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantImages[otherId];
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isArchivedBy(String userId) {
    return archivedBy[userId] ?? false;
  }

  bool isMutedBy(String userId) {
    return mutedBy[userId] ?? false;
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String?>? participantImages,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? archivedBy,
    Map<String, bool>? mutedBy,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      archivedBy: archivedBy ?? this.archivedBy,
      mutedBy: mutedBy ?? this.mutedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      participantNames: Map<String, String>.from(
        json['participantNames'] as Map<String, dynamic>,
      ),
      participantImages: Map<String, String?>.from(
        (json['participantImages'] as Map<String, dynamic>?) ?? {},
      ),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'] as String)
          : null,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      unreadCount: Map<String, int>.from(
        (json['unreadCount'] as Map<String, dynamic>?) ?? {},
      ),
      archivedBy: json['archivedBy'] != null
          ? Map<String, bool>.from(
              (json['archivedBy'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value as bool),
              ),
            )
          : {},
      mutedBy: json['mutedBy'] != null
          ? Map<String, bool>.from(
              (json['mutedBy'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value as bool),
              ),
            )
          : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'archivedBy': archivedBy,
      'mutedBy': mutedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

