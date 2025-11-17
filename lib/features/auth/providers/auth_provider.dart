import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._localDataSource, this._mockDataSource)
      : super(const AuthState());

  final AuthLocalDataSource _localDataSource;
  final AuthMockDataSource _mockDataSource;
  final _uuid = const Uuid();

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _mockDataSource.login(email, password);
      await _persistAuthData(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to login. ${e.toString()}',
      );
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
  return AuthNotifier(local, mock);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

