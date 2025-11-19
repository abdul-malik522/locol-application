import 'package:flutter/material.dart';

enum MessageType {
  text,
  image,
  voice,
  location,
  order,
  priceOffer,
}

@immutable
class MessageModel {
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.text,
    this.imageUrl,
    this.audioUrl,
    this.durationSeconds,
    this.latitude,
    this.longitude,
    this.locationName,
    this.messageType = MessageType.text,
    this.orderData,
    this.priceOfferData,
    this.isRead = false,
    this.readAt,
    this.reactions = const {},
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        assert(
          text != null || imageUrl != null || audioUrl != null || (latitude != null && longitude != null) || orderData != null || priceOfferData != null,
          'Message must have text, imageUrl, audioUrl, location (lat/lng), orderData, or priceOfferData',
        );

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final String? audioUrl;
  final int? durationSeconds; // Duration in seconds for voice messages
  final double? latitude; // For location messages
  final double? longitude; // For location messages
  final String? locationName; // Optional address/name for location
  final MessageType messageType;
  final Map<String, dynamic>? orderData;
  final Map<String, dynamic>? priceOfferData;
  final bool isRead;
  final DateTime? readAt; // Timestamp when message was read
  final Map<String, List<String>> reactions; // emoji -> list of user IDs who reacted
  final DateTime createdAt;

  bool get isTextMessage => messageType == MessageType.text && text != null;
  bool get isImageMessage => messageType == MessageType.image && imageUrl != null;
  bool get isVoiceMessage => messageType == MessageType.voice && audioUrl != null;
  bool get isLocationMessage => messageType == MessageType.location && latitude != null && longitude != null;
  bool get isOrderMessage => messageType == MessageType.order && orderData != null;
  bool get isPriceOfferMessage => messageType == MessageType.priceOffer && priceOfferData != null;

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    String? imageUrl,
    String? audioUrl,
    int? durationSeconds,
    double? latitude,
    double? longitude,
    String? locationName,
    MessageType? messageType,
    Map<String, dynamic>? orderData,
    Map<String, dynamic>? priceOfferData,
    bool? isRead,
    DateTime? readAt,
    Map<String, List<String>>? reactions,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      messageType: messageType ?? this.messageType,
      orderData: orderData ?? this.orderData,
      priceOfferData: priceOfferData ?? this.priceOfferData,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == (json['messageType'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      orderData: json['orderData'] as Map<String, dynamic>?,
      priceOfferData: json['priceOfferData'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      reactions: json['reactions'] != null
          ? Map<String, List<String>>.from(
              (json['reactions'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  List<String>.from(value as List),
                ),
              ),
            )
          : {},
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'messageType': messageType.name,
      'orderData': orderData,
      'priceOfferData': priceOfferData,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Model for price offer data in messages
@immutable
class PriceOfferData {
  const PriceOfferData({
    required this.originalPrice,
    required this.offeredPrice,
    this.postId,
    this.postTitle,
    this.quantity,
    this.status = PriceOfferStatus.pending,
    this.message,
  });

  final double originalPrice;
  final double offeredPrice;
  final String? postId;
  final String? postTitle;
  final String? quantity;
  final PriceOfferStatus status;
  final String? message;

  PriceOfferData copyWith({
    double? originalPrice,
    double? offeredPrice,
    String? postId,
    String? postTitle,
    String? quantity,
    PriceOfferStatus? status,
    String? message,
  }) {
    return PriceOfferData(
      originalPrice: originalPrice ?? this.originalPrice,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPrice': originalPrice,
      'offeredPrice': offeredPrice,
      'postId': postId,
      'postTitle': postTitle,
      'quantity': quantity,
      'status': status.name,
      'message': message,
    };
  }

  factory PriceOfferData.fromJson(Map<String, dynamic> json) {
    return PriceOfferData(
      originalPrice: (json['originalPrice'] as num).toDouble(),
      offeredPrice: (json['offeredPrice'] as num).toDouble(),
      postId: json['postId'] as String?,
      postTitle: json['postTitle'] as String?,
      quantity: json['quantity'] as String?,
      status: PriceOfferStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PriceOfferStatus.pending,
      ),
      message: json['message'] as String?,
    );
  }
}

enum PriceOfferStatus {
  pending,
  accepted,
  rejected,
  counterOffered,
}

