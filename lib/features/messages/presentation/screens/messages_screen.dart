import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/presentation/widgets/chat_card.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.read(messagesProvider.notifier).loadChats(currentUser.id);
      }
    });
  }

  Future<void> _onRefresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await ref.read(messagesProvider.notifier).loadChats(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesProvider);
    final chats = ref.watch(chatsProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Messages'),
        body: Center(
          child: Text('Please login to view messages'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Messages',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(messagesState, chats, currentUser.id),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start new chat feature coming soon'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(MessagesState state, List chats, String currentUserId) {
    if (state.isLoading && chats.isEmpty) {
      return const LoadingIndicator();
    }

    if (state.error != null && chats.isEmpty) {
      return ErrorView(
        error: state.error!,
        onRetry: () {
          ref.read(messagesProvider.notifier).loadChats(currentUserId);
        },
      );
    }

    if (chats.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No Messages Yet',
        message: 'Start a conversation by contacting a seller or restaurant',
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatCard(
          chat: chat,
          currentUserId: currentUserId,
        );
      },
    );
  }
}
