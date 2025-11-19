import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/empty_state.dart';
import 'package:localtrade/core/widgets/error_view.dart';
import 'package:localtrade/core/widgets/loading_indicator.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/home/presentation/widgets/post_card.dart';
import 'package:localtrade/features/home/providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        body: ErrorView(error: 'User not authenticated'),
      );
    }

    final favoritesAsync = ref.watch(favoritePostsProvider(currentUser.id));

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Favorites'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoritePostsProvider(currentUser.id));
          ref.invalidate(favoritesNotifierProvider(currentUser.id));
        },
        child: favoritesAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const EmptyState(
                icon: Icons.bookmark_border,
                title: 'No Favorites Yet',
                message: 'Start bookmarking posts you like to see them here.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(post: post);
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, stack) => ErrorView(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(favoritePostsProvider(currentUser.id));
            },
          ),
        ),
      ),
    );
  }
}

