import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/datasources/social_auth_service.dart';
import 'package:localtrade/features/auth/data/models/social_auth_result.dart';
import 'package:localtrade/features/auth/data/models/two_factor_auth_model.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/settings/data/services/account_deletion_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource.instance;
});

final authMockDataSourceProvider = Provider<AuthMockDataSource>((ref) {
  return AuthMockDataSource.instance;
});

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService.instance;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._localDataSource,
    this._mockDataSource,
    this._socialAuthService,
  ) : super(const AuthState());

  final AuthLocalDataSource _localDataSource;
  final AuthMockDataSource _mockDataSource;
  final SocialAuthService _socialAuthService;
  final _uuid = const Uuid();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _mockDataSource.login(email, password);
      
      // Check if 2FA is enabled
      final twoFactorAuth = _mockDataSource.getTwoFactorAuth(user.id);
      if (twoFactorAuth != null && twoFactorAuth.isEnabled) {
        // 2FA is enabled, return false to indicate verification needed
        state = state.copyWith(isLoading: false);
        return false;
      }
      
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to login. ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> verifyTwoFactorAndLogin({
    required String email,
    required String password,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _mockDataSource.login(email, password);
      
      // Verify 2FA code
      final isValid = await _mockDataSource.verifyTwoFactorCode(
        userId: user.id,
        code: code,
      );
      
      if (!isValid) {
        throw Exception('Invalid verification code.');
      }
      
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '2FA verification failed. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required Map<String, dynamic> businessDetails,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _mockDataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
        businessDetails: businessDetails,
      );
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. ${e.toString()}',
      );
    }
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    final token = await _localDataSource.getAuthToken();
    final userId = await _localDataSource.getUserId();
    if (token == null || userId == null) {
      state = const AuthState();
      return;
    }
    final user = await _mockDataSource.getCurrentUser(userId);
    if (user == null) {
      await _localDataSource.clearAll();
      state = const AuthState();
      return;
    }
    state = state.copyWith(user: user, isLoading: false);
  }

  Future<void> logout() async {
    await _localDataSource.clearAll();
    state = const AuthState();
  }

  /// Delete the current user's account permanently
  /// This will delete all user data and log them out
  Future<void> deleteAccount() async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Delete all user data first
      final accountDeletionService = AccountDeletionService.instance;
      await accountDeletionService.deleteAllUserData(currentUser.id);

      // Then delete the user account
      await _mockDataSource.deleteAccount(currentUser.id);

      // Clear local auth data
      await _localDataSource.clearAll();

      // Reset state
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _mockDataSource.updateProfile(currentUser.id, updates);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Update failed. ${e.toString()}',
      );
    }
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.requestPasswordReset(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset email. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset failed. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.changePassword(
        userId: currentUser.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password change failed. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> sendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.sendVerificationEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send verification email. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.verifyEmail(email: email, token: token);
      // Update user state if current user's email was verified
      final currentUser = state.user;
      if (currentUser != null && 
          currentUser.email.toLowerCase() == email.toLowerCase()) {
        final updatedUser = currentUser.copyWith(isEmailVerified: true);
        state = state.copyWith(user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email verification failed. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    await sendVerificationEmail(email);
  }

  Future<void> signInWithGoogle({UserRole? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Authenticate with Google
      final socialResult = await _socialAuthService.signInWithGoogle();
      
      // Step 2: Create or get user from our system
      final user = await _mockDataSource.signInWithGoogle(
        email: socialResult.email,
        name: socialResult.name,
        profileImageUrl: socialResult.profileImageUrl,
        providerId: socialResult.providerId,
        role: role,
      );
      
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed. ${e.toString()}',
      );
    }
  }

  Future<void> signInWithApple({UserRole? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Authenticate with Apple
      final socialResult = await _socialAuthService.signInWithApple();
      
      // Step 2: Create or get user from our system
      final user = await _mockDataSource.signInWithApple(
        email: socialResult.email,
        name: socialResult.name,
        profileImageUrl: socialResult.profileImageUrl,
        providerId: socialResult.providerId,
        role: role,
      );
      
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Apple sign-in failed. ${e.toString()}',
      );
    }
  }

  Future<void> signInWithFacebook({UserRole? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Authenticate with Facebook
      final socialResult = await _socialAuthService.signInWithFacebook();
      
      // Step 2: Create or get user from our system
      final user = await _mockDataSource.signInWithFacebook(
        email: socialResult.email,
        name: socialResult.name,
        profileImageUrl: socialResult.profileImageUrl,
        providerId: socialResult.providerId,
        role: role,
      );
      
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Facebook sign-in failed. ${e.toString()}',
      );
    }
  }

  // Two-Factor Authentication methods

  Future<TwoFactorAuthModel> setupTwoFactorAuth() async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final twoFactorAuth = await _mockDataSource.setupTwoFactorAuth(currentUser.id);
      state = state.copyWith(isLoading: false);
      return twoFactorAuth;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to setup 2FA. ${e.toString()}',
      );
      rethrow;
    }
  }

  TwoFactorAuthModel? getTwoFactorAuth() {
    final currentUser = state.user;
    if (currentUser == null) return null;
    return _mockDataSource.getTwoFactorAuth(currentUser.id);
  }

  Future<void> verifyAndEnableTwoFactorAuth(String code) async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.verifyAndEnableTwoFactorAuth(
        userId: currentUser.id,
        code: code,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable 2FA. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> disableTwoFactorAuth() async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _mockDataSource.disableTwoFactorAuth(currentUser.id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disable 2FA. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<List<String>> regenerateBackupCodes() async {
    final currentUser = state.user;
    if (currentUser == null) {
      throw Exception('User not authenticated.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final codes = await _mockDataSource.regenerateBackupCodes(currentUser.id);
      state = state.copyWith(isLoading: false);
      return codes;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to regenerate backup codes. ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> _persistAuthData(UserModel user) async {
    final token = 'mock-token-${_uuid.v4()}';
    await _localDataSource.saveAuthToken(token);
    await _localDataSource.saveUserId(user.id);
    await _localDataSource.saveUserRole(user.role);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final local = ref.watch(authLocalDataSourceProvider);
  final mock = ref.watch(authMockDataSourceProvider);
  final social = ref.watch(socialAuthServiceProvider);
  return AuthNotifier(local, mock, social);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

