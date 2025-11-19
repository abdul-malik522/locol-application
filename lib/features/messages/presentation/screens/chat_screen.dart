import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/core/utils/image_helper.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/data/models/chat_model.dart';
import 'package:localtrade/features/messages/data/models/message_model.dart';
import 'package:localtrade/features/messages/data/services/audio_recorder_service.dart';
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
  final _searchController = TextEditingController();
  bool _isRecordingVoice = false;
  int _recordingDuration = 0;
  StreamSubscription<int>? _recordingDurationSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSearchMode = false;
  String _searchQuery = '';
  int _currentSearchIndex = -1;
  List<int> _searchResultIndices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _scrollToBottom();
    });

    // Listen to recording duration updates
    _recordingDurationSubscription = AudioRecorderService.instance.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _recordingDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _recordingDurationSubscription?.cancel();
    _typingTimer?.cancel();
    _stopTyping();
    AudioRecorderService.instance.dispose();
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

    _stopTyping(); // Stop typing indicator when sending message

    await ref
        .read(chatMessagesProvider(chatId).notifier)
        .sendTextMessage(text, currentUser.id, currentUser.name);

    _messageController.clear();
    _scrollToBottom();
  }

  void _onTextChanged(String text) {
    final chatId = _getChatId();
    final currentUser = ref.read(currentUserProvider);
    if (chatId == null || currentUser == null) return;

    if (text.trim().isNotEmpty && !_isTyping) {
      _startTyping(chatId, currentUser.id);
    } else if (text.trim().isEmpty && _isTyping) {
      _stopTyping();
    } else if (text.trim().isNotEmpty) {
      // Reset typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _stopTyping();
      });
    }
  }

  void _startTyping(String chatId, String userId) {
    if (_isTyping) return;
    
    _isTyping = true;
    ref.read(chatMessagesProvider(chatId).notifier).setTypingStatus(userId, true);
    
    // Auto-stop typing after 3 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (!_isTyping) return;
    
    _isTyping = false;
    _typingTimer?.cancel();
    
    final chatId = _getChatId();
    final currentUser = ref.read(currentUserProvider);
    if (chatId != null && currentUser != null) {
      ref.read(chatMessagesProvider(chatId).notifier).setTypingStatus(currentUser.id, false);
    }
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

  Future<void> _showPriceOfferDialog(String chatId) async {
    final originalPriceController = TextEditingController();
    final offeredPriceController = TextEditingController();
    final postTitleController = TextEditingController();
    final quantityController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Price Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: postTitleController,
                decoration: const InputDecoration(
                  labelText: 'Product/Post Title',
                  hintText: 'e.g., Fresh Organic Tomatoes',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: originalPriceController,
                decoration: const InputDecoration(
                  labelText: 'Original Price',
                  prefixText: '\$',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: offeredPriceController,
                decoration: const InputDecoration(
                  labelText: 'Your Offer',
                  prefixText: '\$',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (optional)',
                  hintText: 'e.g., 5 kg',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Add a note to your offer...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final originalPrice = double.tryParse(originalPriceController.text);
              final offeredPrice = double.tryParse(offeredPriceController.text);

              if (originalPrice == null || offeredPrice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid prices')),
                );
                return;
              }

              if (offeredPrice >= originalPrice) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offered price must be less than original price'),
                  ),
                );
                return;
              }

              final currentUser = ref.read(currentUserProvider);
              if (currentUser == null) return;

              final priceOffer = PriceOfferData(
                originalPrice: originalPrice,
                offeredPrice: offeredPrice,
                postTitle: postTitleController.text.trim().isEmpty
                    ? null
                    : postTitleController.text.trim(),
                quantity: quantityController.text.trim().isEmpty
                    ? null
                    : quantityController.text.trim(),
                message: messageController.text.trim().isEmpty
                    ? null
                    : messageController.text.trim(),
              );

              await ref
                  .read(chatMessagesProvider(chatId).notifier)
                  .sendPriceOffer(priceOffer, currentUser.id, currentUser.name);

              Navigator.pop(context);
              _scrollToBottom();
            },
            child: const Text('Send Offer'),
          ),
        ],
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

  Future<void> _startVoiceRecording() async {
    try {
      final hasPermission = await AudioRecorderService.instance.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record voice messages')),
          );
        }
        return;
      }

      await AudioRecorderService.instance.startRecording();
      if (mounted) {
        setState(() {
          _isRecordingVoice = true;
          _recordingDuration = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (!_isRecordingVoice) return;

    final audioPath = await AudioRecorderService.instance.stopRecording();
    
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
      });
    }

    if (audioPath != null && _recordingDuration > 0) {
      final chatId = _getChatId();
      final currentUser = ref.read(currentUserProvider);
      if (chatId != null && currentUser != null) {
        // In a real app, upload audio file to server and get URL
        // For now, use the local file path as a placeholder
        final audioUrl = audioPath;

        await ref
            .read(chatMessagesProvider(chatId).notifier)
            .sendVoiceMessage(audioUrl, _recordingDuration, currentUser.id, currentUser.name);

        _scrollToBottom();
      }
    }

    _recordingDuration = 0;
  }

  Future<void> _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;

    await AudioRecorderService.instance.cancelRecording();
    
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordingDuration = 0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _shareLocation(String chatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      final position = await LocationHelper.getCurrentPosition();
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your location. Please check location permissions.'),
            ),
          );
        }
        return;
      }

      // Optional: Get address name from coordinates (reverse geocoding)
      // For now, we'll use a simple location name
      final locationName = 'My Location';

      await ref
          .read(chatMessagesProvider(chatId).notifier)
          .sendLocationMessage(
            position.latitude,
            position.longitude,
            locationName,
            currentUser.id,
            currentUser.name,
          );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share location: ${e.toString()}')),
        );
      }
    }
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
    if (_isSearchMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearchMode = false;
              _searchQuery = '';
              _searchController.clear();
              _currentSearchIndex = -1;
              _searchResultIndices = [];
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _currentSearchIndex = -1;
                        _searchResultIndices = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentSearchIndex = -1;
              _performSearch();
            });
          },
        ),
        actions: [
          if (_searchResultIndices.isNotEmpty) ...[
            Text(
              '${_currentSearchIndex + 1}/${_searchResultIndices.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _currentSearchIndex > 0
                  ? () {
                      setState(() {
                        _currentSearchIndex--;
                        _scrollToSearchResult();
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: _currentSearchIndex < _searchResultIndices.length - 1
                  ? () {
                      setState(() {
                        _currentSearchIndex++;
                        _scrollToSearchResult();
                      });
                    }
                  : null,
            ),
          ],
        ],
      );
    }

    // In a real app, fetch chat details to show other participant info
    return CustomAppBar(
      title: 'Chat',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchMode = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call feature coming soon')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'mute' || value == 'unmute') {
              _toggleMute(context, chatId);
            }
          },
          itemBuilder: (context) {
            final currentUser = ref.read(currentUserProvider);
            if (currentUser == null) return [];
            
            // Get chat to check mute status
            final chats = ref.read(chatsProvider);
            final chat = chats.firstWhere(
              (c) => c.id == chatId,
              orElse: () => ChatModel(
                id: '',
                participants: [],
                participantNames: {},
              ),
            );
            
            final isMuted = chat.id.isNotEmpty && chat.isMutedBy(currentUser.id);
            
            return [
              PopupMenuItem(
                value: isMuted ? 'unmute' : 'mute',
                child: Row(
                  children: [
                    Icon(isMuted ? Icons.notifications : Icons.notifications_off),
                    const SizedBox(width: 12),
                    Text(isMuted ? 'Unmute Notifications' : 'Mute Notifications'),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _performSearch() {
    final chatId = _getChatId();
    if (chatId == null || _searchQuery.isEmpty) {
      _searchResultIndices = [];
      _currentSearchIndex = -1;
      return;
    }

    final messagesState = ref.read(chatMessagesProvider(chatId));
    final messages = messagesState.messages;
    final query = _searchQuery.toLowerCase();

    _searchResultIndices = [];
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      // Search in text messages
      if (message.text != null && message.text!.toLowerCase().contains(query)) {
        _searchResultIndices.add(i);
      }
      // Search in sender name
      if (message.senderName.toLowerCase().contains(query)) {
        if (!_searchResultIndices.contains(i)) {
          _searchResultIndices.add(i);
        }
      }
    }

    if (_searchResultIndices.isNotEmpty) {
      _currentSearchIndex = 0;
      _scrollToSearchResult();
    } else {
      _currentSearchIndex = -1;
    }
  }

  void _scrollToSearchResult() {
    if (_searchResultIndices.isEmpty || _currentSearchIndex < 0) return;

    final targetIndex = _searchResultIndices[_currentSearchIndex];
    if (_scrollController.hasClients) {
      // Calculate approximate scroll position
      // This is a simplified calculation - in a real app, you'd measure actual item heights
      final itemHeight = 100.0; // Approximate height per message
      final targetPosition = targetIndex * itemHeight;

      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessagesList(List<MessageModel> messages, String currentUserId) {
    final chatId = _getChatId();
    final messagesState = chatId != null 
        ? ref.watch(chatMessagesProvider(chatId))
        : null;
    final typingUsers = messagesState?.typingUsers ?? [];
    final otherUserTyping = typingUsers.isNotEmpty && 
        typingUsers.any((userId) => userId != currentUserId);

    // Filter messages if in search mode
    final displayMessages = _isSearchMode && _searchQuery.isNotEmpty
        ? messages.where((msg) {
            final query = _searchQuery.toLowerCase();
            return (msg.text != null && msg.text!.toLowerCase().contains(query)) ||
                   msg.senderName.toLowerCase().contains(query);
          }).toList()
        : messages;

    if (displayMessages.isEmpty && !otherUserTyping && !_isSearchMode) {
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

    if (_isSearchMode && _searchQuery.isNotEmpty && displayMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
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
      itemCount: displayMessages.length + (otherUserTyping && !_isSearchMode ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator at the end
        if (index == displayMessages.length && otherUserTyping && !_isSearchMode) {
          return _buildTypingIndicator(currentUserId);
        }
        
        final message = displayMessages[index];
        final isSentByMe = message.senderId == currentUserId;
        final originalIndex = messages.indexOf(message);
        final isHighlighted = _isSearchMode && 
            _searchQuery.isNotEmpty && 
            _searchResultIndices.contains(originalIndex) &&
            originalIndex == (_currentSearchIndex >= 0 && _currentSearchIndex < _searchResultIndices.length
                ? _searchResultIndices[_currentSearchIndex]
                : -1);

        // Group messages by date
        final showDateSeparator = index == 0 ||
            _isDifferentDay(displayMessages[index - 1].createdAt, message.createdAt);

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
            Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
              padding: isHighlighted ? const EdgeInsets.all(4) : EdgeInsets.zero,
              child: MessageBubble(
                message: message,
                isSentByMe: isSentByMe,
                searchQuery: _isSearchMode && _searchQuery.isNotEmpty ? _searchQuery : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput(String chatId) {
    if (_isRecordingVoice) {
      return _buildVoiceRecordingUI();
    }

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
            PopupMenuButton<String>(
              icon: const Icon(Icons.attach_file),
              onSelected: (value) {
                if (value == 'image') {
                  _sendImage();
                } else if (value == 'location') {
                  _shareLocation(chatId);
                } else if (value == 'price_offer') {
                  _showPriceOfferDialog(chatId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 8),
                      Text('Send Image'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'location',
                  child: Row(
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8),
                      Text('Share Location'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'price_offer',
                  child: Row(
                    children: [
                      Icon(Icons.attach_money),
                      SizedBox(width: 8),
                      Text('Make Price Offer'),
                    ],
                  ),
                ),
              ],
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
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: _startVoiceRecording,
              onLongPressEnd: (_) => _stopVoiceRecording(),
              child: IconButton(
                icon: const Icon(Icons.mic),
                onPressed: null, // Disable tap, only long press works
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Hold to record voice message',
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

  Widget _buildVoiceRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
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
            Icon(
              Icons.mic,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Recording...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopVoiceRecording,
              color: Theme.of(context).colorScheme.onErrorContainer,
              tooltip: 'Stop and send',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelVoiceRecording,
              color: Theme.of(context).colorScheme.onErrorContainer,
              tooltip: 'Cancel',
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

  Widget _buildTypingIndicator(String currentUserId) {
    final chatId = _getChatId();
    if (chatId == null) return const SizedBox.shrink();
    
    final messagesState = ref.watch(chatMessagesProvider(chatId));
    final typingUsers = messagesState.typingUsers;
    final otherUserIds = typingUsers.where((userId) => userId != currentUserId).toList();
    
    if (otherUserIds.isEmpty) return const SizedBox.shrink();

    // Get the other user's name (in a real app, fetch from user data)
    final otherUserName = 'Someone'; // Placeholder - would fetch actual name

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$otherUserName is typing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(width: 8),
            _buildTypingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 40,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTypingDot(0),
          const SizedBox(width: 4),
          _buildTypingDot(1),
          const SizedBox(width: 4),
          _buildTypingDot(2),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animationValue = ((value + delay) % 1.0);
        final opacity = animationValue < 0.5 
            ? animationValue * 2 
            : 2 - (animationValue * 2);
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _toggleMute(BuildContext context, String chatId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final chats = ref.read(chatsProvider);
    final chat = chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => ChatModel(
        id: '',
        participants: [],
        participantNames: {},
      ),
    );

    if (chat.id.isEmpty) return;

    final isMuted = chat.isMutedBy(currentUser.id);
    ref.read(messagesProvider.notifier).muteChat(chatId, currentUser.id, !isMuted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isMuted ? 'Chat unmuted' : 'Chat muted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(messagesProvider.notifier).muteChat(chatId, currentUser.id, isMuted);
          },
        ),
      ),
    );
  }
}
