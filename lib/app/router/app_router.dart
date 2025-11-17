import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/app/router/bottom_nav_shell.dart';
import 'package:localtrade/features/auth/presentation/screens/login_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/registration_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/splash_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/welcome_screen.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/create/presentation/screens/create_post_screen.dart';
import 'package:localtrade/features/home/presentation/screens/home_feed_screen.dart';
import 'package:localtrade/features/home/presentation/screens/post_detail_screen.dart';
import 'package:localtrade/features/messages/presentation/screens/chat_screen.dart';
import 'package:localtrade/features/messages/presentation/screens/messages_screen.dart';
import 'package:localtrade/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/orders_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/profile_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:localtrade/features/search/presentation/screens/search_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/settings_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.handleRedirect,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) =>
            _buildFadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) =>
            _buildFadePage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const RoleSelectionScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          return _buildSlidePage(
            state,
            RegistrationScreen(initialRole: roleParam),
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const LoginScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) =>
                    _buildFadePage(state, const HomeFeedScreen()),
                routes: [
                  GoRoute(
                    path: 'post/:id',
                    name: 'post-detail',
                    pageBuilder: (context, state) =>
                        _buildSlidePage(state, const PostDetailScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                pageBuilder: (context, state) =>
                    _buildFadePage(state, const SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                name: 'create',
                pageBuilder: (context, state) =>
                    _buildSlidePage(state, const CreatePostScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                name: 'messages',
                pageBuilder: (context, state) =>
                    _buildFadePage(state, const MessagesScreen()),
                routes: [
                  GoRoute(
                    path: 'chat/:chatId',
                    name: 'chat',
                    pageBuilder: (context, state) =>
                        _buildSlidePage(state, const ChatScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) =>
                    _buildFadePage(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'user-profile',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const UserProfileScreen()),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'post-detail-full',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PostDetailScreen()),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) =>
            _buildFadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const OrdersScreen()),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 48),
            const SizedBox(height: 12),
            Text(state.error?.toString() ?? 'Page not found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;

  String? handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthed = ref.read(isAuthenticatedProvider);
    final loggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/role-selection' ||
        state.matchedLocation == '/welcome';
    final atSplash = state.matchedLocation == '/splash';

    if (!isAuthed && !loggingIn && !atSplash) {
      return '/welcome';
    }

    if (isAuthed && loggingIn) {
      return '/home';
    }

    return null;
  }
}

Page<void> _buildFadePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

Page<void> _buildSlidePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation);
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

