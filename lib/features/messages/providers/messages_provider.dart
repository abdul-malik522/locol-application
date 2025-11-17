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
  });

  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final messagesMockDataSourceProvider =
    Provider<MessagesMockDataSource>((ref) => MessagesMockDataSource.instance);

class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier(this._dataSource) : super(const MessagesState());

  final MessagesMockDataSource _dataSource;

  Future<void> loadChats(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chats = await _dataSource.getChats(userId);
      state = state.copyWith(chats: chats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chats: ${e.toString()}',
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
  }

  final MessagesMockDataSource _dataSource;
  final String _chatId;

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
      final sent = await _dataSource.sendMessage(message);
      state = state.copyWith(
        messages: [...state.messages, sent],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to send message: ${e.toString()}',
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
