import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/app/router/bottom_nav_shell.dart';
import 'package:localtrade/features/auth/presentation/screens/change_password_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/login_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/registration_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/splash_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/two_factor_setup_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/two_factor_verify_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:localtrade/features/auth/presentation/screens/welcome_screen.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';
import 'package:localtrade/features/create/presentation/screens/create_post_screen.dart';
import 'package:localtrade/features/create/presentation/screens/drafts_screen.dart';
import 'package:localtrade/features/create/presentation/screens/edit_post_screen.dart';
import 'package:localtrade/features/create/presentation/screens/scheduled_posts_screen.dart';
import 'package:localtrade/features/home/presentation/screens/favorites_screen.dart';
import 'package:localtrade/features/home/presentation/screens/home_feed_screen.dart';
import 'package:localtrade/features/home/data/models/story_model.dart';
import 'package:localtrade/features/home/presentation/screens/post_detail_screen.dart';
import 'package:localtrade/features/home/presentation/screens/story_viewer_screen.dart';
import 'package:localtrade/features/messages/presentation/screens/chat_screen.dart';
import 'package:localtrade/features/messages/presentation/screens/messages_screen.dart';
import 'package:localtrade/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:localtrade/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/delivery_addresses_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/delivery_tracking_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/dispute_detail_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/disputes_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/order_templates_screen.dart';
import 'package:localtrade/features/orders/presentation/screens/orders_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/archived_posts_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/followers_following_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/profile_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/qr_code_profile_screen.dart';
import 'package:localtrade/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:localtrade/features/search/presentation/screens/search_screen.dart';
import 'package:localtrade/app/router/analytics_router.dart';
import 'package:localtrade/features/analytics/presentation/screens/restaurant_analytics_screen.dart';
import 'package:localtrade/features/analytics/presentation/screens/seller_analytics_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/about_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/blocked_users_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/data_export_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/help_support_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:localtrade/features/trust/presentation/screens/business_verification_screen.dart';
import 'package:localtrade/features/trust/presentation/screens/content_moderation_screen.dart';
import 'package:localtrade/features/trust/presentation/screens/dispute_resolution_screen.dart';
import 'package:localtrade/features/trust/presentation/screens/identity_verification_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/add_payment_method_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/invoices_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/payment_methods_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/payment_processing_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/payouts_screen.dart';
import 'package:localtrade/features/payment/presentation/screens/wallet_screen.dart';
import 'package:localtrade/features/orders/data/models/order_model.dart';
import 'package:localtrade/features/inventory/presentation/screens/availability_calendar_screen.dart';
import 'package:localtrade/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:localtrade/features/inventory/presentation/screens/pre_orders_screen.dart';
import 'package:localtrade/features/inventory/presentation/screens/stock_alerts_screen.dart';
import 'package:localtrade/features/delivery/presentation/screens/delivery_management_screen.dart';
import 'package:localtrade/features/delivery/presentation/screens/delivery_scheduling_screen.dart';
import 'package:localtrade/features/delivery/presentation/screens/proof_of_delivery_screen.dart';
import 'package:localtrade/features/delivery/presentation/screens/route_optimization_screen.dart';
import 'package:localtrade/features/search/presentation/screens/search_alerts_screen.dart';
import 'package:localtrade/features/create/presentation/screens/image_editor_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/settings_screen.dart';
import 'package:localtrade/features/settings/presentation/screens/terms_of_service_screen.dart';

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
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final email = state.uri.queryParameters['email'];
          return _buildSlidePage(
            state,
            ResetPasswordScreen(token: token, email: email),
          );
        },
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
                routes: [
                  GoRoute(
                    path: 'drafts',
                    name: 'drafts',
                    pageBuilder: (context, state) =>
                        _buildSlidePage(state, const DraftsScreen()),
                  ),
                  GoRoute(
                    path: 'scheduled',
                    name: 'scheduled-posts',
                    pageBuilder: (context, state) =>
                        _buildSlidePage(state, const ScheduledPostsScreen()),
                  ),
                ],
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
        path: '/analytics',
        name: 'analytics',
        pageBuilder: (context, state) {
          // Route to appropriate analytics screen based on user role
          return _buildSlidePage(state, const AnalyticsRouter());
        },
      ),
      GoRoute(
        path: '/followers/:userId',
        name: 'followers',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _buildSlidePage(
            state,
            FollowersFollowingScreen(userId: userId, type: 'followers'),
          );
        },
      ),
      GoRoute(
        path: '/following/:userId',
        name: 'following',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _buildSlidePage(
            state,
            FollowersFollowingScreen(userId: userId, type: 'following'),
          );
        },
      ),
      GoRoute(
        path: '/post/:id',
        name: 'post-detail-full',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PostDetailScreen()),
      ),
      GoRoute(
        path: '/stories/:userId',
        name: 'story-viewer',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final stories = state.extra;
          if (stories == null || stories is! List) {
            return _buildSlidePage(state, const SizedBox());
          }
          return _buildSlidePage(
            state,
            StoryViewerScreen(
              userId: userId,
              stories: (stories as List).cast<StoryModel>(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) =>
            _buildFadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/language-selection',
        name: 'language-selection',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const LanguageSelectionScreen()),
      ),
      GoRoute(
        path: '/privacy-settings',
        name: 'privacy-settings',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PrivacySettingsScreen()),
      ),
      GoRoute(
        path: '/blocked-users',
        name: 'blocked-users',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const BlockedUsersScreen()),
      ),
      GoRoute(
        path: '/data-export',
        name: 'data-export',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const DataExportScreen()),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const TermsOfServiceScreen()),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const HelpSupportScreen()),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const AboutScreen()),
      ),
      GoRoute(
        path: '/business-verification',
        name: 'business-verification',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const BusinessVerificationScreen()),
      ),
      GoRoute(
        path: '/identity-verification',
        name: 'identity-verification',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const IdentityVerificationScreen()),
      ),
      GoRoute(
        path: '/content-moderation',
        name: 'content-moderation',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const ContentModerationScreen()),
      ),
      GoRoute(
        path: '/dispute-resolution',
        name: 'dispute-resolution',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const DisputeResolutionScreen()),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PaymentMethodsScreen()),
      ),
      GoRoute(
        path: '/add-payment-method',
        name: 'add-payment-method',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const AddPaymentMethodScreen()),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const WalletScreen()),
      ),
      GoRoute(
        path: '/payouts',
        name: 'payouts',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PayoutsScreen()),
      ),
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const InvoicesScreen()),
      ),
      GoRoute(
        path: '/payment-processing',
        name: 'payment-processing',
        pageBuilder: (context, state) {
          final order = state.extra as OrderModel;
          return _buildSlidePage(state, PaymentProcessingScreen(order: order));
        },
      ),
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const InventoryScreen()),
      ),
      GoRoute(
        path: '/stock-alerts',
        name: 'stock-alerts',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const StockAlertsScreen()),
      ),
      GoRoute(
        path: '/availability-calendar',
        name: 'availability-calendar',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const AvailabilityCalendarScreen()),
      ),
      GoRoute(
        path: '/pre-orders',
        name: 'pre-orders',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const PreOrdersScreen()),
      ),
      GoRoute(
        path: '/delivery-management',
        name: 'delivery-management',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const DeliveryManagementScreen()),
      ),
      GoRoute(
        path: '/delivery-scheduling',
        name: 'delivery-scheduling',
        pageBuilder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          return _buildSlidePage(
            state,
            DeliverySchedulingScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/route-optimization',
        name: 'route-optimization',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const RouteOptimizationScreen()),
      ),
      GoRoute(
        path: '/proof-of-delivery/:id',
        name: 'proof-of-delivery',
        pageBuilder: (context, state) {
          final deliveryId = state.pathParameters['id'] ?? '';
          return _buildSlidePage(
            state,
            ProofOfDeliveryScreen(deliveryId: deliveryId),
          );
        },
      ),
      GoRoute(
        path: '/search-alerts',
        name: 'search-alerts',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const SearchAlertsScreen()),
      ),
      GoRoute(
        path: '/image-editor',
        name: 'image-editor',
        pageBuilder: (context, state) {
          final imagePath = state.uri.queryParameters['path'] ?? '';
          return _buildSlidePage(
            state,
            ImageEditorScreen(imagePath: imagePath),
          );
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const OrdersScreen()),
      ),
      GoRoute(
        path: '/order/:id',
        name: 'order-detail',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return _buildSlidePage(
            state,
            OrderDetailScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/order-templates',
        name: 'order-templates',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const OrderTemplatesScreen()),
      ),
      GoRoute(
        path: '/delivery-addresses',
        name: 'delivery-addresses',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const DeliveryAddressesScreen()),
      ),
      GoRoute(
        path: '/disputes',
        name: 'disputes',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const DisputesScreen()),
      ),
      GoRoute(
        path: '/dispute/:id',
        name: 'dispute-detail',
        pageBuilder: (context, state) {
          final disputeId = state.pathParameters['id'] ?? '';
          return _buildSlidePage(
            state,
            DisputeDetailScreen(disputeId: disputeId),
          );
        },
      ),
      GoRoute(
        path: '/tracking/:id',
        name: 'delivery-tracking',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return _buildSlidePage(
            state,
            DeliveryTrackingScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/qr-code-profile',
        name: 'qr-code-profile',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const QRCodeProfileScreen()),
      ),
      GoRoute(
        path: '/archived-posts',
        name: 'archived-posts',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const ArchivedPostsScreen()),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const FavoritesScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: '/edit-post/:id',
        name: 'edit-post',
        pageBuilder: (context, state) {
          final postId = state.pathParameters['id'] ?? '';
          return _buildSlidePage(
            state,
            EditPostScreen(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final email = state.uri.queryParameters['email'];
          return _buildSlidePage(
            state,
            VerifyEmailScreen(token: token, email: email),
          );
        },
      ),
      GoRoute(
        path: '/two-factor-setup',
        name: 'two-factor-setup',
        pageBuilder: (context, state) =>
            _buildSlidePage(state, const TwoFactorSetupScreen()),
      ),
      GoRoute(
        path: '/two-factor-verify',
        name: 'two-factor-verify',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final password = state.uri.queryParameters['password'] ?? '';
          return _buildSlidePage(
            state,
            TwoFactorVerifyScreen(email: email, password: password),
          );
        },
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
        state.matchedLocation == '/welcome' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/reset-password' ||
        state.matchedLocation == '/verify-email' ||
        state.matchedLocation == '/two-factor-verify';
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

