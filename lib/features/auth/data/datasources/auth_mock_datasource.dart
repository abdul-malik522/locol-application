import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/datasources/two_factor_auth_service.dart';
import 'package:localtrade/features/auth/data/models/two_factor_auth_model.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
import 'package:localtrade/features/profile/data/models/business_hours_model.dart';
import 'package:localtrade/features/profile/data/models/certification_model.dart';
import 'package:localtrade/features/profile/data/models/verification_badge_model.dart';
import 'package:uuid/uuid.dart';

class AuthMockDataSource {
  AuthMockDataSource._();
  static final AuthMockDataSource instance = AuthMockDataSource._();
  final _uuid = const Uuid();

  final List<UserModel> _users = [
    UserModel(
      id: 'user-001',
      email: 'freshfarm@example.com',
      name: 'Amelia Fields',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=5',
      businessName: 'Fresh Farm Produce',
      businessDescription: 'Organic veggies and herbs harvested daily.',
      phoneNumber: '+1 555 201 1234',
      address: '120 Maple St, Springfield',
      latitude: 37.7749,
      longitude: -122.4194,
      rating: 4.8,
      reviewCount: 120,
      verificationBadges: [
        VerificationBadgeModel(
          type: VerificationType.business,
          verifiedAt: DateTime.now().subtract(const Duration(days: 90)),
          verifiedBy: 'admin',
        ),
      ],
      certifications: [
        CertificationModel(
          type: CertificationType.organic,
          certificationNumber: 'USDA-ORG-2024-001',
          issuingOrganization: 'USDA',
          issuedDate: DateTime.now().subtract(const Duration(days: 180)),
          expiryDate: DateTime.now().add(const Duration(days: 185)),
        ),
        CertificationModel(
          type: CertificationType.local,
          issuedDate: DateTime.now().subtract(const Duration(days: 365)),
        ),
      ],
    ),
    UserModel(
      id: 'user-002',
      email: 'organicveggies@example.com',
      name: 'Carlos Green',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=11',
      businessName: 'Organic Veggies Co',
      businessDescription: 'Specialty greens and seasonal produce.',
      phoneNumber: '+1 555 202 7890',
      address: '45 River Rd, Portland',
      latitude: 45.5152,
      longitude: -122.6784,
      rating: 4.7,
      reviewCount: 95,
      certifications: [
        CertificationModel(
          type: CertificationType.organic,
          certificationNumber: 'USDA-ORG-2024-045',
          issuingOrganization: 'USDA',
          issuedDate: DateTime.now().subtract(const Duration(days: 120)),
          expiryDate: DateTime.now().add(const Duration(days: 245)),
        ),
        CertificationModel(
          type: CertificationType.sustainable,
          issuedDate: DateTime.now().subtract(const Duration(days: 200)),
        ),
      ],
    ),
    UserModel(
      id: 'user-003',
      email: 'meatmarket@example.com',
      name: 'Rita Stone',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=9',
      businessName: 'Local Meat Market',
      businessDescription: 'Grass-fed beef and free-range poultry.',
      phoneNumber: '+1 555 203 2233',
      address: '10 Lakeview Ave, Austin',
      latitude: 30.2672,
      longitude: -97.7431,
      rating: 4.6,
      reviewCount: 80,
      certifications: [
        CertificationModel(
          type: CertificationType.grassFed,
          certificationNumber: 'GF-2024-012',
          issuingOrganization: 'American Grassfed Association',
          issuedDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().add(const Duration(days: 305)),
        ),
        CertificationModel(
          type: CertificationType.freeRange,
          issuedDate: DateTime.now().subtract(const Duration(days: 90)),
        ),
      ],
    ),
    UserModel(
      id: 'user-004',
      email: 'greenkitchen@example.com',
      name: 'Lena Rivers',
      role: UserRole.restaurant,
      profileImageUrl: 'https://i.pravatar.cc/150?img=20',
      businessName: 'The Green Kitchen',
      businessDescription: 'Farm-to-table vegetarian restaurant.',
      phoneNumber: '+1 555 301 9988',
      address: '88 Cherry Ln, Seattle',
      latitude: 47.6062,
      longitude: -122.3321,
      rating: 4.9,
      reviewCount: 210,
      verificationBadges: [
        VerificationBadgeModel(
          type: VerificationType.business,
          verifiedAt: DateTime.now().subtract(const Duration(days: 30)),
          verifiedBy: 'admin',
        ),
      ],
      businessHours: BusinessHoursModel(
        hours: [
          DayHours(
            day: DayOfWeek.monday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.tuesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.wednesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.thursday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.friday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 23, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.saturday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 10, minute: 0),
            closeTime: const TimeOfDay(hour: 23, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.sunday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 10, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
        ],
      ),
    ),
    UserModel(
      id: 'user-005',
      email: 'pastaparadise@example.com',
      name: 'Marco Bianchi',
      role: UserRole.restaurant,
      profileImageUrl: 'https://i.pravatar.cc/150?img=14',
      businessName: 'Pasta Paradise',
      businessDescription: 'Authentic Italian pasta house.',
      phoneNumber: '+1 555 302 4567',
      address: '77 Olive St, Boston',
      latitude: 42.3601,
      longitude: -71.0589,
      rating: 4.7,
      reviewCount: 150,
      verificationBadges: [
        VerificationBadgeModel(
          type: VerificationType.business,
          verifiedAt: DateTime.now().subtract(const Duration(days: 60)),
          verifiedBy: 'admin',
        ),
        VerificationBadgeModel(
          type: VerificationType.premium,
          verifiedAt: DateTime.now().subtract(const Duration(days: 15)),
          verifiedBy: 'system',
        ),
      ],
      businessHours: BusinessHoursModel(
        hours: [
          DayHours(day: DayOfWeek.monday, isOpen: false),
          DayHours(
            day: DayOfWeek.tuesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 17, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.wednesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 17, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.thursday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 17, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.friday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 17, minute: 0),
            closeTime: const TimeOfDay(hour: 23, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.saturday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 17, minute: 0),
            closeTime: const TimeOfDay(hour: 23, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.sunday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 16, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
        ],
      ),
    ),
    UserModel(
      id: 'user-006',
      email: 'burgerhaven@example.com',
      name: 'Derrick Cole',
      role: UserRole.restaurant,
      profileImageUrl: 'https://i.pravatar.cc/150?img=16',
      businessName: 'Burger Haven',
      businessDescription: 'Gourmet burgers with local ingredients.',
      phoneNumber: '+1 555 303 6543',
      address: '310 Pine St, Denver',
      latitude: 39.7392,
      longitude: -104.9903,
      rating: 4.5,
      reviewCount: 130,
      businessHours: BusinessHoursModel(
        hours: [
          DayHours(
            day: DayOfWeek.monday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.tuesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.wednesday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.thursday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 21, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.friday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(
            day: DayOfWeek.saturday,
            isOpen: true,
            openTime: const TimeOfDay(hour: 11, minute: 0),
            closeTime: const TimeOfDay(hour: 22, minute: 0),
          ),
          DayHours(day: DayOfWeek.sunday, isOpen: false),
        ],
      ),
    ),
    UserModel(
      id: 'user-007',
      email: 'honeybee@example.com',
      name: 'Tara Bloom',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=18',
      businessName: 'Local Honey Bee',
      businessDescription: 'Raw honey and beeswax products.',
      phoneNumber: '+1 555 204 7788',
      address: '600 Meadow Dr, Boulder',
      latitude: 40.01499,
      longitude: -105.27055,
      rating: 4.9,
      reviewCount: 60,
    ),
    UserModel(
      id: 'user-008',
      email: 'artisancheese@example.com',
      name: 'Nora Fields',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=21',
      businessName: 'Artisan Cheese House',
      businessDescription: 'Handcrafted cheeses and dairy products.',
      phoneNumber: '+1 555 205 8844',
      address: '14 Valley Rd, Madison',
      latitude: 43.0731,
      longitude: -89.4012,
      rating: 4.8,
      reviewCount: 110,
    ),
    UserModel(
      id: 'user-009',
      email: 'fusionbistro@example.com',
      name: 'Sakura Watanabe',
      role: UserRole.restaurant,
      profileImageUrl: 'https://i.pravatar.cc/150?img=32',
      businessName: 'Fusion Bistro',
      businessDescription: 'Asian fusion comfort food.',
      phoneNumber: '+1 555 304 6677',
      address: '950 Sunset Blvd, Los Angeles',
      latitude: 34.0522,
      longitude: -118.2437,
      rating: 4.6,
      reviewCount: 175,
    ),
    UserModel(
      id: 'user-010',
      email: 'plantpower@example.com',
      name: 'Jonah Reed',
      role: UserRole.restaurant,
      profileImageUrl: 'https://i.pravatar.cc/150?img=30',
      businessName: 'Plant Power Cafe',
      businessDescription: 'Vegan bowls and smoothies.',
      phoneNumber: '+1 555 305 2255',
      address: '220 Ocean Ave, Miami',
      latitude: 25.7617,
      longitude: -80.1918,
      rating: 4.4,
      reviewCount: 90,
    ),
    UserModel(
      id: 'user-011',
      email: 'grainharvest@example.com',
      name: 'Luca Martinez',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=34',
      businessName: 'Grain Harvest Co',
      businessDescription: 'Organic grains and flour blends.',
      phoneNumber: '+1 555 206 5511',
      address: '480 Harvest Ln, Omaha',
      latitude: 41.2565,
      longitude: -95.9345,
      rating: 4.3,
      reviewCount: 70,
    ),
    UserModel(
      id: 'user-012',
      email: 'spiceworld@example.com',
      name: 'Priya Nair',
      role: UserRole.seller,
      profileImageUrl: 'https://i.pravatar.cc/150?img=37',
      businessName: 'Spice World Collective',
      businessDescription: 'Rare spices and custom blends.',
      phoneNumber: '+1 555 207 3399',
      address: '12 Spice Market, Houston',
      latitude: 29.7604,
      longitude: -95.3698,
      rating: 4.9,
      reviewCount: 140,
    ),
  ];

  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => UserModel(
        id: _uuid.v4(),
        email: normalizedEmail,
        name: 'New User',
        role: UserRole.restaurant,
      ),
    );
    if (!_users.contains(user)) {
      _users.add(user);
    }
    // Store password for change password functionality
    _storePassword(user.id, password);
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    Map<String, dynamic>? businessDetails,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();
    final existing = _users
        .where((u) => u.email.toLowerCase() == normalizedEmail)
        .toList();
    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }
    final user = UserModel(
      id: _uuid.v4(),
      email: normalizedEmail,
      name: name,
      role: role,
      businessName: businessDetails?['businessName'] as String?,
      businessDescription:
          businessDetails?['businessDescription'] as String?,
      phoneNumber: businessDetails?['phoneNumber'] as String?,
      address: businessDetails?['address'] as String?,
      profileImageUrl:
          'https://i.pravatar.cc/150?u=${normalizedEmail.hashCode}',
      latitude: businessDetails?['latitude'] as double?,
      longitude: businessDetails?['longitude'] as double?,
    );
    _users.add(user);
    // Store password for change password functionality
    _storePassword(user.id, password);
    // Send verification email
    await sendVerificationEmail(normalizedEmail);
    return user;
  }

  Future<UserModel?> getCurrentUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) {
      throw Exception('User not found');
    }

    final current = _users[index];
    final updated = current.copyWith(
      name: updates['name'] as String? ?? current.name,
      businessName: updates['businessName'] as String? ?? current.businessName,
      businessDescription:
          updates['businessDescription'] as String? ??
              current.businessDescription,
      phoneNumber: updates['phoneNumber'] as String? ?? current.phoneNumber,
      address: updates['address'] as String? ?? current.address,
      profileImageUrl:
          updates['profileImageUrl'] as String? ?? current.profileImageUrl,
      coverImageUrl:
          updates['coverImageUrl'] as String? ?? current.coverImageUrl,
      latitude: updates['latitude'] as double? ?? current.latitude,
      longitude: updates['longitude'] as double? ?? current.longitude,
      isActive: updates['isActive'] as bool? ?? current.isActive,
    );

    _users[index] = updated;
    return updated;
  }

  List<UserModel> get allUsers => List.unmodifiable(_users);

  /// Delete a user account permanently
  /// This removes the user from the system
  Future<void> deleteAccount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _users.removeWhere((user) => user.id == userId);
    // Also remove password if stored
    _passwords.remove(userId);
  }

  // Password reset token storage (in-memory for mock)
  final Map<String, String> _resetTokens = {}; // email -> token
  final Map<String, DateTime> _resetTokenExpiry = {}; // email -> expiry

  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();
    
    // Check if user exists
    final userExists = _users.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    
    if (!userExists) {
      // For security, don't reveal if email exists or not
      // Just simulate sending email
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Generate reset token
    final token = _uuid.v4();
    _resetTokens[normalizedEmail] = token;
    _resetTokenExpiry[normalizedEmail] = DateTime.now().add(
      const Duration(hours: 1), // Token expires in 1 hour
    );

    // In a real app, this would send an email
    // For mock, we'll just log it (in production, email service would be called)
    print('Password reset email sent to $normalizedEmail');
    print('Reset token: $token (for testing only)');
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Validate token
    final storedToken = _resetTokens[normalizedEmail];
    final expiry = _resetTokenExpiry[normalizedEmail];

    if (storedToken == null || storedToken != token) {
      throw Exception('Invalid or expired reset token.');
    }

    if (expiry == null || expiry.isBefore(DateTime.now())) {
      _resetTokens.remove(normalizedEmail);
      _resetTokenExpiry.remove(normalizedEmail);
      throw Exception('Reset token has expired. Please request a new one.');
    }

    // Find user and update (in real app, password would be hashed)
    final userIndex = _users.indexWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );

    if (userIndex == -1) {
      throw Exception('User not found.');
    }

    // In a real app, we would hash the password here
    // For mock, we just store it (not recommended for production)
    print('Password reset for $normalizedEmail (mock - password not actually stored)');

    // Clean up token
    _resetTokens.remove(normalizedEmail);
    _resetTokenExpiry.remove(normalizedEmail);
  }

  // Helper method to get reset token for testing (should not exist in production)
  String? getResetTokenForEmail(String email) {
    return _resetTokens[email.trim().toLowerCase()];
  }

  // Password storage (in-memory for mock - in production, passwords would be hashed)
  final Map<String, String> _passwords = {}; // userId -> password (hashed in production)

  // Store password for a user (called during registration/login)
  void _storePassword(String userId, String password) {
    // In production, this would hash the password
    _passwords[userId] = password;
  }

  // Verify current password
  Future<bool> verifyPassword(String userId, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final storedPassword = _passwords[userId];
    
    // If no password is stored (for existing mock users), allow any password for testing
    if (storedPassword == null) {
      // For existing mock users without stored passwords, accept any password
      // In production, this would never happen
      return true;
    }
    
    // In production, this would compare hashed passwords
    return storedPassword == password;
  }

  // Change password
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Verify current password
    final isValid = await verifyPassword(userId, currentPassword);
    if (!isValid) {
      throw Exception('Current password is incorrect.');
    }

    // Check if new password is different
    final storedPassword = _passwords[userId];
    if (storedPassword != null && storedPassword == newPassword) {
      throw Exception('New password must be different from current password.');
    }

    // Update password (in production, this would hash the password)
    _storePassword(userId, newPassword);
    print('Password changed for user $userId (mock - password stored in memory)');
  }

  // Initialize password for existing users (for testing)
  void initializePasswordForUser(String userId, String password) {
    if (!_passwords.containsKey(userId)) {
      _storePassword(userId, password);
    }
  }

  // Email verification token storage (in-memory for mock)
  final Map<String, String> _verificationTokens = {}; // email -> token
  final Map<String, DateTime> _verificationTokenExpiry = {}; // email -> expiry

  // Send verification email
  Future<void> sendVerificationEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Generate verification token
    final token = _uuid.v4();
    _verificationTokens[normalizedEmail] = token;
    _verificationTokenExpiry[normalizedEmail] = DateTime.now().add(
      const Duration(days: 7), // Token expires in 7 days
    );

    // In a real app, this would send an email
    // For mock, we'll just log it
    print('Verification email sent to $normalizedEmail');
    print('Verification token: $token (for testing only)');
  }

  // Verify email with token
  Future<void> verifyEmail({
    required String email,
    required String token,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Validate token
    final storedToken = _verificationTokens[normalizedEmail];
    final expiry = _verificationTokenExpiry[normalizedEmail];

    if (storedToken == null || storedToken != token) {
      throw Exception('Invalid or expired verification token.');
    }

    if (expiry == null || expiry.isBefore(DateTime.now())) {
      _verificationTokens.remove(normalizedEmail);
      _verificationTokenExpiry.remove(normalizedEmail);
      throw Exception('Verification token has expired. Please request a new one.');
    }

    // Find user and mark email as verified
    final userIndex = _users.indexWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );

    if (userIndex == -1) {
      throw Exception('User not found.');
    }

    final user = _users[userIndex];
    _users[userIndex] = user.copyWith(isEmailVerified: true);

    // Clean up token
    _verificationTokens.remove(normalizedEmail);
    _verificationTokenExpiry.remove(normalizedEmail);

    print('Email verified for $normalizedEmail');
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    await sendVerificationEmail(email);
  }

  // Helper method to get verification token for testing (should not exist in production)
  String? getVerificationTokenForEmail(String email) {
    return _verificationTokens[email.trim().toLowerCase()];
  }

  // Social login storage (in-memory for mock)
  final Map<String, String> _socialAuthLinks = {}; // providerId -> userId

  // 2FA storage (in-memory for mock)
  final Map<String, TwoFactorAuthModel> _twoFactorAuth = {}; // userId -> 2FA data

  // Social login - Google
  Future<UserModel> signInWithGoogle({
    required String email,
    required String name,
    String? profileImageUrl,
    String? providerId,
    UserRole? role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Check if user exists with this email
    final existingUser = _users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => UserModel(
        id: _uuid.v4(),
        email: normalizedEmail,
        name: name,
        role: role ?? UserRole.restaurant, // Use provided role or default
      ),
    );

    // If user doesn't exist, create new user
    if (!_users.contains(existingUser)) {
      final newUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl ??
            'https://i.pravatar.cc/150?u=${normalizedEmail.hashCode}',
        isEmailVerified: true, // Social logins are pre-verified
      );
      _users.add(newUser);
      
      // Link social account
      if (providerId != null) {
        _socialAuthLinks['google_$providerId'] = newUser.id;
      }
      
      print('Google sign-in: New user created - $normalizedEmail');
      return newUser;
    }

    // Link social account to existing user
    if (providerId != null) {
      _socialAuthLinks['google_$providerId'] = existingUser.id;
    }

    // Update profile image if provided and different
    if (profileImageUrl != null && 
        existingUser.profileImageUrl != profileImageUrl) {
      final updatedUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl,
        isEmailVerified: true, // Mark as verified
      );
      final index = _users.indexWhere((u) => u.id == existingUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
        return updatedUser;
      }
    }

    print('Google sign-in: Existing user - $normalizedEmail');
    return existingUser;
  }

  // Social login - Apple
  Future<UserModel> signInWithApple({
    required String email,
    required String name,
    String? profileImageUrl,
    String? providerId,
    UserRole? role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Check if user exists with this email
    final existingUser = _users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => UserModel(
        id: _uuid.v4(),
        email: normalizedEmail,
        name: name,
        role: role ?? UserRole.restaurant, // Use provided role or default
      ),
    );

    // If user doesn't exist, create new user
    if (!_users.contains(existingUser)) {
      final newUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl ??
            'https://i.pravatar.cc/150?u=${normalizedEmail.hashCode}',
        isEmailVerified: true, // Social logins are pre-verified
      );
      _users.add(newUser);
      
      // Link social account
      if (providerId != null) {
        _socialAuthLinks['apple_$providerId'] = newUser.id;
      }
      
      print('Apple sign-in: New user created - $normalizedEmail');
      return newUser;
    }

    // Link social account to existing user
    if (providerId != null) {
      _socialAuthLinks['apple_$providerId'] = existingUser.id;
    }

    // Update profile image if provided
    if (profileImageUrl != null && 
        existingUser.profileImageUrl != profileImageUrl) {
      final updatedUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl,
        isEmailVerified: true,
      );
      final index = _users.indexWhere((u) => u.id == existingUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
        return updatedUser;
      }
    }

    print('Apple sign-in: Existing user - $normalizedEmail');
    return existingUser;
  }

  // Social login - Facebook
  Future<UserModel> signInWithFacebook({
    required String email,
    required String name,
    String? profileImageUrl,
    String? providerId,
    UserRole? role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final normalizedEmail = email.trim().toLowerCase();

    // Check if user exists with this email
    final existingUser = _users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => UserModel(
        id: _uuid.v4(),
        email: normalizedEmail,
        name: name,
        role: role ?? UserRole.restaurant, // Use provided role or default
      ),
    );

    // If user doesn't exist, create new user
    if (!_users.contains(existingUser)) {
      final newUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl ??
            'https://i.pravatar.cc/150?u=${normalizedEmail.hashCode}',
        isEmailVerified: true, // Social logins are pre-verified
      );
      _users.add(newUser);
      
      // Link social account
      if (providerId != null) {
        _socialAuthLinks['facebook_$providerId'] = newUser.id;
      }
      
      print('Facebook sign-in: New user created - $normalizedEmail');
      return newUser;
    }

    // Link social account to existing user
    if (providerId != null) {
      _socialAuthLinks['facebook_$providerId'] = existingUser.id;
    }

    // Update profile image if provided
    if (profileImageUrl != null && 
        existingUser.profileImageUrl != profileImageUrl) {
      final updatedUser = existingUser.copyWith(
        profileImageUrl: profileImageUrl,
        isEmailVerified: true,
      );
      final index = _users.indexWhere((u) => u.id == existingUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
        return updatedUser;
      }
    }

    print('Facebook sign-in: Existing user - $normalizedEmail');
    return existingUser;
  }

  // Two-Factor Authentication methods

  /// Setup 2FA for a user
  Future<TwoFactorAuthModel> setupTwoFactorAuth(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final twoFactorService = TwoFactorAuthService.instance;
    final secretKey = twoFactorService.generateSecretKey();
    final backupCodes = twoFactorService.generateBackupCodes();
    
    final twoFactorAuth = TwoFactorAuthModel(
      isEnabled: false, // Not enabled until verified
      secretKey: secretKey,
      backupCodes: backupCodes,
      setupDate: DateTime.now(),
    );
    
    _twoFactorAuth[userId] = twoFactorAuth;
    print('2FA setup initiated for user $userId');
    return twoFactorAuth;
  }

  /// Get 2FA status for a user
  TwoFactorAuthModel? getTwoFactorAuth(String userId) {
    return _twoFactorAuth[userId];
  }

  /// Verify and enable 2FA
  Future<void> verifyAndEnableTwoFactorAuth({
    required String userId,
    required String code,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final twoFactorAuth = _twoFactorAuth[userId];
    if (twoFactorAuth == null || twoFactorAuth.secretKey == null) {
      throw Exception('2FA setup not found. Please setup 2FA first.');
    }

    final twoFactorService = TwoFactorAuthService.instance;
    final isValid = twoFactorService.verifyCode(twoFactorAuth.secretKey!, code);
    
    if (!isValid) {
      throw Exception('Invalid verification code.');
    }

    // Enable 2FA
    _twoFactorAuth[userId] = twoFactorAuth.copyWith(
      isEnabled: true,
    );
    
    print('2FA enabled for user $userId');
  }

  /// Disable 2FA
  Future<void> disableTwoFactorAuth(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    _twoFactorAuth.remove(userId);
    print('2FA disabled for user $userId');
  }

  /// Verify 2FA code during login
  Future<bool> verifyTwoFactorCode({
    required String userId,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final twoFactorAuth = _twoFactorAuth[userId];
    if (twoFactorAuth == null || !twoFactorAuth.isEnabled) {
      return true; // 2FA not enabled, allow login
    }

    if (twoFactorAuth.secretKey == null) {
      return false;
    }

    final twoFactorService = TwoFactorAuthService.instance;
    
    // Try TOTP code first
    final isValidTotp = twoFactorService.verifyCode(twoFactorAuth.secretKey!, code);
    if (isValidTotp) {
      return true;
    }

    // Try backup code
    if (twoFactorAuth.backupCodes != null) {
      final isValidBackup = twoFactorService.verifyBackupCode(
        twoFactorAuth.backupCodes!,
        code,
      );
      
      if (isValidBackup) {
        // Remove used backup code
        final updatedCodes = twoFactorService.removeBackupCode(
          twoFactorAuth.backupCodes!,
          code,
        );
        _twoFactorAuth[userId] = twoFactorAuth.copyWith(
          backupCodes: updatedCodes,
        );
        return true;
      }
    }

    return false;
  }

  /// Regenerate backup codes
  Future<List<String>> regenerateBackupCodes(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final twoFactorAuth = _twoFactorAuth[userId];
    if (twoFactorAuth == null || !twoFactorAuth.isEnabled) {
      throw Exception('2FA is not enabled.');
    }

    final twoFactorService = TwoFactorAuthService.instance;
    final newBackupCodes = twoFactorService.generateBackupCodes();
    
    _twoFactorAuth[userId] = twoFactorAuth.copyWith(
      backupCodes: newBackupCodes,
    );
    
    print('Backup codes regenerated for user $userId');
    return newBackupCodes;
  }
}

