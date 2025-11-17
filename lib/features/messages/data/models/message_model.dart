import 'package:flutter/material.dart';

enum MessageType {
  text,
  image,
  order,
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
    this.messageType = MessageType.text,
    this.orderData,
    this.isRead = false,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        assert(
          text != null || imageUrl != null || orderData != null,
          'Message must have text, imageUrl, or orderData',
        );

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? text;
  final String? imageUrl;
  final MessageType messageType;
  final Map<String, dynamic>? orderData;
  final bool isRead;
  final DateTime createdAt;

  bool get isTextMessage => messageType == MessageType.text && text != null;
  bool get isImageMessage => messageType == MessageType.image && imageUrl != null;
  bool get isOrderMessage => messageType == MessageType.order && orderData != null;

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    String? imageUrl,
    MessageType? messageType,
    Map<String, dynamic>? orderData,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      messageType: messageType ?? this.messageType,
      orderData: orderData ?? this.orderData,
      isRead: isRead ?? this.isRead,
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
      messageType: MessageType.values.firstWhere(
        (type) => type.name == (json['messageType'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      orderData: json['orderData'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
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
      'messageType': messageType.name,
      'orderData': orderData,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

