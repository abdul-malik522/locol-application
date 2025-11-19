import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:localtrade/core/widgets/cached_image.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/messages/presentation/widgets/chat_card.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';
import 'package:localtrade/features/search/data/datasources/search_mock_datasource.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool _showArchived = false;

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
      if (_showArchived) {
        await ref.read(messagesProvider.notifier).loadArchivedChats(currentUser.id);
      } else {
        await ref.read(messagesProvider.notifier).loadChats(currentUser.id);
      }
    }
  }

  void _toggleArchivedView() {
    setState(() {
      _showArchived = !_showArchived;
    });
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      if (_showArchived) {
        ref.read(messagesProvider.notifier).loadArchivedChats(currentUser.id);
      } else {
        ref.read(messagesProvider.notifier).loadChats(currentUser.id);
      }
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
        title: _showArchived ? 'Archived Chats' : 'Messages',
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inbox : Icons.archive),
            onPressed: _toggleArchivedView,
            tooltip: _showArchived ? 'Show Active Chats' : 'Show Archived Chats',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showUserSearchDialog(context),
            tooltip: 'Search Users',
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
      return EmptyState(
        icon: _showArchived ? Icons.archive_outlined : Icons.chat_bubble_outline,
        title: _showArchived ? 'No Archived Chats' : 'No Messages Yet',
        message: _showArchived
            ? 'You haven\'t archived any chats yet'
            : 'Start a conversation by contacting a seller or restaurant',
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

  Future<void> _showUserSearchDialog(BuildContext context) async {
    final searchController = TextEditingController();
    final searchDataSource = SearchMockDataSource.instance;
    List<UserModel> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Search Users'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or business...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onChanged: (value) async {
                    if (value.trim().isEmpty) {
                      setState(() {
                        searchResults = [];
                        isSearching = false;
                      });
                      return;
                    }

                    setState(() {
                      isSearching = true;
                    });

                    final results = await searchDataSource.searchUsers(value.trim());
                    setState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (searchController.text.trim().isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Start typing to search for users...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No users found'),
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return _buildUserSearchItem(context, user);
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );

    searchController.dispose();
  }

  Widget _buildUserSearchItem(BuildContext context, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : null,
        child: user.profileImageUrl == null
            ? Icon(user.role.icon)
            : null,
      ),
      title: Text(
        user.businessName ?? user.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.businessName != null)
            Text(user.name),
          Row(
            children: [
              Icon(
                user.role.icon,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                user.role.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        context.push('/profile/${user.id}');
      },
    );
  }
}
