import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/image_helper.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/data/models/message_model.dart';
import 'package:localtrade/features/messages/presentation/widgets/message_bubble.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _getChatId() {
    final state = GoRouterState.of(context);
    return state.pathParameters['chatId'];
  }

  void _markAsRead() {
    final chatId = _getChatId();
    final currentUser = ref.read(currentUserProvider);
    if (chatId != null && currentUser != null) {
      ref.read(messagesProvider.notifier).markChatAsRead(chatId, currentUser.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatId = _getChatId();
    final currentUser = ref.read(currentUserProvider);
    if (chatId == null || currentUser == null) return;

    await ref
        .read(chatMessagesProvider(chatId).notifier)
        .sendTextMessage(text, currentUser.id, currentUser.name);

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromGallery();
                if (image != null) {
                  await _sendImageMessage(image.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImageHelper.pickImageFromCamera();
                if (image != null) {
                  await _sendImageMessage(image.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImageMessage(String imagePath) async {
    final chatId = _getChatId();
    final currentUser = ref.read(currentUserProvider);
    if (chatId == null || currentUser == null) return;

    // In a real app, upload image to server and get URL
    // For now, use placeholder
    final imageUrl = 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';

    await ref
        .read(chatMessagesProvider(chatId).notifier)
        .sendImageMessage(imageUrl, currentUser.id, currentUser.name);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = _getChatId();
    if (chatId == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Chat'),
        body: Center(child: Text('Chat not found')),
      );
    }

    final messagesState = ref.watch(chatMessagesProvider(chatId));
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Chat'),
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, chatId),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(messagesState.messages, currentUser.id),
          ),
          _buildMessageInput(chatId),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String chatId) {
    // In a real app, fetch chat details to show other participant info
    return CustomAppBar(
      title: 'Chat',
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('More options coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages, String currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSentByMe = message.senderId == currentUserId;

        // Group messages by date
        final showDateSeparator = index == 0 ||
            _isDifferentDay(messages[index - 1].createdAt, message.createdAt);

        return Column(
          children: [
            if (showDateSeparator)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatDate(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
            MessageBubble(
              message: message,
              isSentByMe: isSentByMe,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput(String chatId) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _sendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return timeago.format(date);
    }
  }
}
