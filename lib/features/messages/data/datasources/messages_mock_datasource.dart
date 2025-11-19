import 'dart:async';

import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/messages/data/models/chat_model.dart';
import 'package:localtrade/features/messages/data/models/message_model.dart';
import 'package:uuid/uuid.dart';

class MessagesMockDataSource {
  MessagesMockDataSource._() {
    _initializeMockData();
  }
  static final MessagesMockDataSource instance = MessagesMockDataSource._();
  final _uuid = const Uuid();

  final List<ChatModel> _chats = [];
  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, Set<String>> _typingUsers = {}; // chatId -> Set of userIds who are typing

  void _initializeMockData() {
    final now = DateTime.now();
    final authDataSource = AuthMockDataSource.instance;

    // Create sample chats
    final chat1 = ChatModel(
      id: 'chat-001',
      participants: ['user-001', 'user-004'],
      participantNames: {
        'user-001': 'Amelia Fields',
        'user-004': 'Lena Rivers',
      },
      participantImages: {
        'user-001': 'https://i.pravatar.cc/150?img=5',
        'user-004': 'https://i.pravatar.cc/150?img=20',
      },
      lastMessage: 'Great! I can deliver tomorrow morning.',
      lastMessageTime: now.subtract(const Duration(minutes: 15)),
      lastMessageSenderId: 'user-001',
      unreadCount: {'user-004': 1},
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final chat2 = ChatModel(
      id: 'chat-002',
      participants: ['user-002', 'user-005'],
      participantNames: {
        'user-002': 'Carlos Green',
        'user-005': 'Marco Bianchi',
      },
      participantImages: {
        'user-002': 'https://i.pravatar.cc/150?img=11',
        'user-005': 'https://i.pravatar.cc/150?img=14',
      },
      lastMessage: 'The basil looks perfect!',
      lastMessageTime: now.subtract(const Duration(hours: 2)),
      lastMessageSenderId: 'user-005',
      unreadCount: {},
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final chat3 = ChatModel(
      id: 'chat-003',
      participants: ['user-003', 'user-006'],
      participantNames: {
        'user-003': 'Rita Stone',
        'user-006': 'Derrick Cole',
      },
      participantImages: {
        'user-003': 'https://i.pravatar.cc/150?img=9',
        'user-006': 'https://i.pravatar.cc/150?img=16',
      },
      lastMessage: 'Can you deliver 50kg by Friday?',
      lastMessageTime: now.subtract(const Duration(hours: 5)),
      lastMessageSenderId: 'user-006',
      unreadCount: {'user-003': 2},
      createdAt: now.subtract(const Duration(days: 1)),
    );

    final chat4 = ChatModel(
      id: 'chat-004',
      participants: ['user-007', 'user-010'],
      participantNames: {
        'user-007': 'Tara Bloom',
        'user-010': 'Jonah Reed',
      },
      participantImages: {
        'user-007': 'https://i.pravatar.cc/150?img=18',
        'user-010': 'https://i.pravatar.cc/150?img=30',
      },
      lastMessage: 'The honey is amazing!',
      lastMessageTime: now.subtract(const Duration(days: 1)),
      lastMessageSenderId: 'user-010',
      unreadCount: {},
      createdAt: now.subtract(const Duration(days: 7)),
    );

    _chats.addAll([chat1, chat2, chat3, chat4]);

    // Create sample messages for chat1
    _messages['chat-001'] = [
      MessageModel(
        id: 'msg-001',
        chatId: 'chat-001',
        senderId: 'user-004',
        senderName: 'Lena Rivers',
        text: 'Hi! I saw your post about fresh tomatoes. Are they still available?',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-002',
        chatId: 'chat-001',
        senderId: 'user-001',
        senderName: 'Amelia Fields',
        text: 'Yes, they are! I have 5kg available. Would you like to place an order?',
        createdAt: now.subtract(const Duration(days: 2, hours: 2, minutes: 45)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-003',
        chatId: 'chat-001',
        senderId: 'user-004',
        senderName: 'Lena Rivers',
        text: 'Perfect! Can you deliver to 88 Cherry Ln, Seattle?',
        createdAt: now.subtract(const Duration(days: 2, hours: 2, minutes: 30)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-004',
        chatId: 'chat-001',
        senderId: 'user-001',
        senderName: 'Amelia Fields',
        text: 'Great! I can deliver tomorrow morning.',
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
    ];

    // Create sample messages for chat2
    _messages['chat-002'] = [
      MessageModel(
        id: 'msg-005',
        chatId: 'chat-002',
        senderId: 'user-005',
        senderName: 'Marco Bianchi',
        text: 'Hello! I need fresh basil for my restaurant. Do you have any available?',
        createdAt: now.subtract(const Duration(days: 5, hours: 2)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-006',
        chatId: 'chat-002',
        senderId: 'user-002',
        senderName: 'Carlos Green',
        text: 'Yes, I have fresh basil! How much do you need?',
        createdAt: now.subtract(const Duration(days: 5, hours: 1, minutes: 45)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-007',
        chatId: 'chat-002',
        senderId: 'user-005',
        senderName: 'Marco Bianchi',
        text: 'I need 2kg weekly. Can you provide that?',
        createdAt: now.subtract(const Duration(days: 5, hours: 1, minutes: 30)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-008',
        chatId: 'chat-002',
        senderId: 'user-002',
        senderName: 'Carlos Green',
        text: 'Absolutely! I can deliver every Monday morning.',
        createdAt: now.subtract(const Duration(days: 5, hours: 1)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-009',
        chatId: 'chat-002',
        senderId: 'user-005',
        senderName: 'Marco Bianchi',
        text: 'The basil looks perfect!',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ];

    // Create sample messages for chat3
    _messages['chat-003'] = [
      MessageModel(
        id: 'msg-010',
        chatId: 'chat-003',
        senderId: 'user-006',
        senderName: 'Derrick Cole',
        text: 'Hi Rita! I saw your post about free-range chicken. Interested in bulk orders?',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-011',
        chatId: 'chat-003',
        senderId: 'user-003',
        senderName: 'Rita Stone',
        text: 'Yes! I can provide bulk orders. What quantity are you looking for?',
        createdAt: now.subtract(const Duration(days: 1, hours: 3, minutes: 45)),
        isRead: true,
      ),
      MessageModel(
        id: 'msg-012',
        chatId: 'chat-003',
        senderId: 'user-006',
        senderName: 'Derrick Cole',
        text: 'Can you deliver 50kg by Friday?',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),
    ];
  }

  Future<List<ChatModel>> getChats(String userId, {bool includeArchived = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _chats
        .where((chat) {
          if (!chat.participants.contains(userId)) return false;
          if (includeArchived) return true;
          return !chat.isArchivedBy(userId);
        })
        .toList();
  }

  Future<List<ChatModel>> getArchivedChats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _chats
        .where((chat) => 
            chat.participants.contains(userId) && 
            chat.isArchivedBy(userId))
        .toList();
  }

  Future<ChatModel?> getChatById(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (_) {
      return null;
    }
  }

  Future<ChatModel> createChat(String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if chat already exists
    final existing = _chats.firstWhere(
      (chat) =>
          chat.participants.contains(userId1) &&
          chat.participants.contains(userId2),
      orElse: () => ChatModel(
        id: '',
        participants: [],
        participantNames: {},
      ),
    );

    if (existing.id.isNotEmpty) {
      return existing;
    }

    // Get user names from auth datasource (simplified - in real app would fetch)
    final chat = ChatModel(
      id: _uuid.v4(),
      participants: [userId1, userId2],
      participantNames: {
        userId1: 'User $userId1',
        userId2: 'User $userId2',
      },
      participantImages: {},
      createdAt: DateTime.now(),
    );

    _chats.add(chat);
    _messages[chat.id] = [];
    return chat;
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final messages = _messages[chatId] ?? [];
    return messages..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<MessageModel> sendMessage(MessageModel message) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final messages = _messages.putIfAbsent(message.chatId, () => []);
    messages.add(message);

    // Update chat's last message
    final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      final otherParticipantId = chat.participants.firstWhere(
        (id) => id != message.senderId,
        orElse: () => chat.participants.first,
      );

      _chats[chatIndex] = chat.copyWith(
        lastMessage: message.text ?? 'Image',
        lastMessageTime: message.createdAt,
        lastMessageSenderId: message.senderId,
        unreadCount: {
          ...chat.unreadCount,
          otherParticipantId: (chat.unreadCount[otherParticipantId] ?? 0) + 1,
        },
      );
    }

    return message;
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final messages = _messages[chatId];
    if (messages != null) {
      final readTimestamp = DateTime.now();
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].senderId != userId && !messages[i].isRead) {
          messages[i] = messages[i].copyWith(
            isRead: true,
            readAt: readTimestamp,
          );
        }
      }
    }

    // Update chat unread count
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      final updatedUnread = Map<String, int>.from(chat.unreadCount);
      updatedUnread[userId] = 0;
      _chats[chatIndex] = chat.copyWith(unreadCount: updatedUnread);
    }
  }

  Future<void> deleteChat(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _chats.removeWhere((chat) => chat.id == chatId);
    _messages.remove(chatId);
    _typingUsers.remove(chatId);
  }

  /// Set typing status for a user in a chat
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!_typingUsers.containsKey(chatId)) {
      _typingUsers[chatId] = <String>{};
    }
    
    if (isTyping) {
      _typingUsers[chatId]!.add(userId);
    } else {
      _typingUsers[chatId]!.remove(userId);
    }
  }

  /// Get list of users currently typing in a chat
  Future<List<String>> getTypingUsers(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _typingUsers[chatId]?.toList() ?? [];
  }

  /// Archive or unarchive a chat for a specific user
  Future<ChatModel> archiveChat(String chatId, String userId, bool archive) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) {
      throw Exception('Chat not found');
    }

    final chat = _chats[chatIndex];
    final updatedArchivedBy = Map<String, bool>.from(chat.archivedBy);
    updatedArchivedBy[userId] = archive;

    final updatedChat = chat.copyWith(archivedBy: updatedArchivedBy);
    _chats[chatIndex] = updatedChat;
    return updatedChat;
  }

  /// Mute or unmute a chat for a specific user
  Future<ChatModel> muteChat(String chatId, String userId, bool mute) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) {
      throw Exception('Chat not found');
    }

    final chat = _chats[chatIndex];
    final updatedMutedBy = Map<String, bool>.from(chat.mutedBy);
    updatedMutedBy[userId] = mute;

    final updatedChat = chat.copyWith(mutedBy: updatedMutedBy);
    _chats[chatIndex] = updatedChat;
    return updatedChat;
  }

  /// Add or remove a reaction to a message
  Future<MessageModel> toggleReaction(
    String chatId,
    String messageId,
    String emoji,
    String userId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final messages = _messages[chatId];
    if (messages == null) {
      throw Exception('Chat not found');
    }

    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) {
      throw Exception('Message not found');
    }

    final message = messages[messageIndex];
    final currentReactions = Map<String, List<String>>.from(message.reactions);
    
    // Get or create list of users who reacted with this emoji
    final usersWhoReacted = List<String>.from(currentReactions[emoji] ?? []);
    
    // Toggle reaction: if user already reacted, remove; otherwise add
    if (usersWhoReacted.contains(userId)) {
      usersWhoReacted.remove(userId);
      if (usersWhoReacted.isEmpty) {
        currentReactions.remove(emoji);
      } else {
        currentReactions[emoji] = usersWhoReacted;
      }
    } else {
      usersWhoReacted.add(userId);
      currentReactions[emoji] = usersWhoReacted;
    }

    final updatedMessage = message.copyWith(reactions: currentReactions);
    messages[messageIndex] = updatedMessage;
    return updatedMessage;
  }
}

