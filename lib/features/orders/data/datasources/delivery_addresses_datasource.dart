import 'dart:convert';

import 'package:localtrade/features/orders/data/models/delivery_address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryAddressesDataSource {
  DeliveryAddressesDataSource._();
  static final DeliveryAddressesDataSource instance = DeliveryAddressesDataSource._();

  static const String _addressesKeyPrefix = 'delivery_addresses_';

  String _getAddressesKey(String userId) => '$_addressesKeyPrefix$userId';

  Future<List<DeliveryAddressModel>> getAddresses(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? addressesJson = prefs.getString(_getAddressesKey(userId));
    if (addressesJson == null) {
      return [];
    }
    final List<dynamic> decoded = json.decode(addressesJson);
    return decoded
        .map((e) => DeliveryAddressModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        // Default address first, then by label
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.label.compareTo(b.label);
      });
  }

  Future<void> saveAddress(DeliveryAddressModel address) async {
    final prefs = await SharedPreferences.getInstance();
    final List<DeliveryAddressModel> existingAddresses = await getAddresses(address.userId);

    // If this address is set as default, unset all other defaults
    if (address.isDefault) {
      existingAddresses.forEach((a) {
        if (a.id != address.id && a.isDefault) {
          final index = existingAddresses.indexWhere((addr) => addr.id == a.id);
          if (index != -1) {
            existingAddresses[index] = a.copyWith(isDefault: false);
          }
        }
      });
    }

    final int index = existingAddresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      existingAddresses[index] = address; // Update existing address
    } else {
      existingAddresses.add(address); // Add new address
    }

    // Sort: default first, then by label
    existingAddresses.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.label.compareTo(b.label);
    });

    final String encoded =
        json.encode(existingAddresses.map((e) => e.toJson()).toList());
    await prefs.setString(_getAddressesKey(address.userId), encoded);
  }

  Future<void> deleteAddress(String addressId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    List<DeliveryAddressModel> existingAddresses = await getAddresses(userId);
    existingAddresses.removeWhere((a) => a.id == addressId);

    final String encoded =
        json.encode(existingAddresses.map((e) => e.toJson()).toList());
    await prefs.setString(_getAddressesKey(userId), encoded);
  }

  Future<DeliveryAddressModel?> getAddress(String addressId, String userId) async {
    final List<DeliveryAddressModel> existingAddresses = await getAddresses(userId);
    try {
      return existingAddresses.firstWhere((a) => a.id == addressId);
    } catch (e) {
      return null;
    }
  }

  Future<DeliveryAddressModel?> getDefaultAddress(String userId) async {
    final addresses = await getAddresses(userId);
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  Future<void> setDefaultAddress(String addressId, String userId) async {
    final addresses = await getAddresses(userId);
    for (var address in addresses) {
      if (address.id == addressId) {
        await saveAddress(address.copyWith(isDefault: true));
      } else if (address.isDefault) {
        await saveAddress(address.copyWith(isDefault: false));
      }
    }
  }
}

