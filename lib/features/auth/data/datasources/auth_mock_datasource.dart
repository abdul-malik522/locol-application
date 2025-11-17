import 'dart:async';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';
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
}

