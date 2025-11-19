import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/data/datasources/messages_mock_datasource.dart';
import 'package:localtrade/features/messages/data/models/chat_model.dart';
import 'package:localtrade/features/messages/data/models/message_model.dart';

class MessagesState {
  const MessagesState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ChatModel> chats;
  final bool isLoading;
  final String? error;

  MessagesState copyWith({
    List<ChatModel>? chats,
    bool? isLoading,
    String? error,
  }) {
    return MessagesState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.typingUsers = const [],
  });

  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final List<String> typingUsers; // List of user IDs who are currently typing

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    List<String>? typingUsers,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

final messagesMockDataSourceProvider =
    Provider<MessagesMockDataSource>((ref) => MessagesMockDataSource.instance);

class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier(this._dataSource) : super(const MessagesState());

  final MessagesMockDataSource _dataSource;

  Future<void> loadChats(String userId, {bool includeArchived = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chats = await _dataSource.getChats(userId, includeArchived: includeArchived);
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chats: ${e.toString()}',
      );
    }
  }

  Future<void> loadArchivedChats(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chats = await _dataSource.getArchivedChats(userId);
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load archived chats: ${e.toString()}',
      );
    }
  }

  Future<void> archiveChat(String chatId, String userId, bool archive) async {
    try {
      await _dataSource.archiveChat(chatId, userId, archive);
      await loadChats(userId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to archive chat: ${e.toString()}',
      );
    }
  }

  Future<void> muteChat(String chatId, String userId, bool mute) async {
    try {
      await _dataSource.muteChat(chatId, userId, mute);
      await loadChats(userId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mute chat: ${e.toString()}',
      );
    }
  }

  Future<ChatModel> createOrGetChat(String userId1, String userId2) async {
    try {
      final chat = await _dataSource.createChat(userId1, userId2);
      await loadChats(userId1);
      return chat;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create chat: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _dataSource.markMessagesAsRead(chatId, userId);
      await loadChats(userId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to mark as read: ${e.toString()}',
      );
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _dataSource.deleteChat(chatId);
      state = state.copyWith(
        chats: state.chats.where((chat) => chat.id != chatId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete chat: ${e.toString()}',
      );
    }
  }
}

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  ChatMessagesNotifier(this._dataSource, this._chatId)
      : super(const ChatMessagesState()) {
    loadMessages();
    _startTypingStatusPolling();
  }

  final MessagesMockDataSource _dataSource;
  final String _chatId;
  Timer? _typingStatusTimer;

  void _startTypingStatusPolling() {
    // Poll typing status every 500ms
    _typingStatusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _refreshTypingStatus();
    });
  }

  @override
  void dispose() {
    _typingStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _dataSource.getMessages(_chatId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: ${e.toString()}',
      );
    }
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      // Stop typing when message is sent
      await _dataSource.setTypingStatus(_chatId, message.senderId, false);
      final sent = await _dataSource.sendMessage(message);
      state = state.copyWith(
        messages: [...state.messages, sent],
      );
      await _refreshTypingStatus();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send message: ${e.toString()}',
      );
    }
  }

  Future<void> setTypingStatus(String userId, bool isTyping) async {
    try {
      await _dataSource.setTypingStatus(_chatId, userId, isTyping);
      await _refreshTypingStatus();
    } catch (e) {
      // Silently fail typing status updates
      print('Failed to update typing status: $e');
    }
  }

  Future<void> _refreshTypingStatus() async {
    try {
      final typingUsers = await _dataSource.getTypingUsers(_chatId);
      state = state.copyWith(typingUsers: typingUsers);
    } catch (e) {
      // Silently fail typing status refresh
      print('Failed to refresh typing status: $e');
    }
  }

  Future<void> toggleReaction(String messageId, String emoji, String userId) async {
    try {
      final updatedMessage = await _dataSource.toggleReaction(_chatId, messageId, emoji, userId);
      final updatedMessages = List<MessageModel>.from(state.messages);
      final index = updatedMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        updatedMessages[index] = updatedMessage;
        state = state.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to toggle reaction: ${e.toString()}',
      );
    }
  }

  Future<void> sendTextMessage(
    String text,
    String senderId,
    String senderName,
  ) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
    await sendMessage(message);
  }

  Future<void> sendImageMessage(
    String imageUrl,
    String senderId,
    String senderName,
  ) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: senderId,
      senderName: senderName,
      imageUrl: imageUrl,
      messageType: MessageType.image,
    );
    await sendMessage(message);
  }

  Future<void> sendVoiceMessage(
    String audioUrl,
    int durationSeconds,
    String senderId,
    String senderName,
  ) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: senderId,
      senderName: senderName,
      audioUrl: audioUrl,
      durationSeconds: durationSeconds,
      messageType: MessageType.voice,
    );
    await sendMessage(message);
  }

  Future<void> sendLocationMessage(
    double latitude,
    double longitude,
    String? locationName,
    String senderId,
    String senderName,
  ) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: senderId,
      senderName: senderName,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      messageType: MessageType.location,
    );
    await sendMessage(message);
  }

  Future<void> sendPriceOffer(
    PriceOfferData priceOffer,
    String senderId,
    String senderName,
  ) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      senderId: senderId,
      senderName: senderName,
      messageType: MessageType.priceOffer,
      priceOfferData: priceOffer.toJson(),
    );
    await sendMessage(message);
  }

  Future<void> respondToPriceOffer(
    String messageId,
    PriceOfferStatus status,
    PriceOfferData? counterOffer,
  ) async {
    try {
      final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
      if (messageIndex == -1) return;

      final originalMessage = state.messages[messageIndex];
      if (originalMessage.priceOfferData == null) return;

      final offerData = PriceOfferData.fromJson(originalMessage.priceOfferData!);
      final updatedOffer = offerData.copyWith(status: status);

      // Update the original message status
      final updatedMessage = originalMessage.copyWith(
        priceOfferData: updatedOffer.toJson(),
      );

      final updatedMessages = List<MessageModel>.from(state.messages);
      updatedMessages[messageIndex] = updatedMessage;

      // If counter-offering, send a new message
      if (status == PriceOfferStatus.counterOffered && counterOffer != null) {
        // Get the current user from the chat to determine sender
        // For now, we'll need to pass sender info - this is a limitation
        // In a real app, you'd get this from auth context
        // For mock, we'll update the state and let the caller send the counter offer
        state = state.copyWith(messages: updatedMessages);
      } else {
        state = state.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to respond to price offer: ${e.toString()}',
      );
    }
  }
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  final dataSource = ref.watch(messagesMockDataSourceProvider);
  return MessagesNotifier(dataSource);
});

final chatsProvider = Provider<List<ChatModel>>((ref) {
  final state = ref.watch(messagesProvider);
  final chats = List<ChatModel>.from(state.chats);
  chats.sort((a, b) {
    final aTime = a.lastMessageTime ?? a.createdAt;
    final bTime = b.lastMessageTime ?? b.createdAt;
    return bTime.compareTo(aTime);
  });
  return chats;
});

final unreadCountProvider = Provider<int>((ref) {
  final chats = ref.watch(chatsProvider);
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;

  int total = 0;
  for (final chat in chats) {
    total += chat.getUnreadCount(currentUser.id);
  }
  return total;
});

final chatMessagesProvider =
    StateNotifierProvider.family<ChatMessagesNotifier, ChatMessagesState, String>(
  (ref, chatId) {
    final dataSource = ref.watch(messagesMockDataSourceProvider);
    return ChatMessagesNotifier(dataSource, chatId);
  },
);

// currentUserProvider is imported from auth_provider
