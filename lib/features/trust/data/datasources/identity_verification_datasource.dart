import 'dart:async';

import 'package:localtrade/features/trust/data/models/identity_verification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class IdentityVerificationDataSource {
  IdentityVerificationDataSource._();
  static final IdentityVerificationDataSource instance = IdentityVerificationDataSource._();
  final _uuid = const Uuid();

  static const String _verificationsKeyPrefix = 'identity_verifications_';

  String _getVerificationsKey(String userId) => '$_verificationsKeyPrefix$userId';

  Future<IdentityVerificationModel?> getVerification(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? verificationJson = prefs.getString(_getVerificationsKey(userId));
    if (verificationJson == null) {
      return null;
    }
    try {
      final decoded = json.decode(verificationJson) as Map<String, dynamic>;
      return IdentityVerificationModel.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<void> submitVerification(IdentityVerificationModel verification) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(verification.toJson());
    await prefs.setString(_getVerificationsKey(verification.userId), encoded);
  }

  Future<void> updateVerification(IdentityVerificationModel verification) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(verification.toJson());
    await prefs.setString(_getVerificationsKey(verification.userId), encoded);
  }

  // Admin methods (would be in a separate admin datasource in production)
  Future<List<IdentityVerificationModel>> getAllPendingVerifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_verificationsKeyPrefix));
    
    final List<IdentityVerificationModel> verifications = [];
    for (final key in keys) {
      final String? verificationJson = prefs.getString(key);
      if (verificationJson != null) {
        try {
          final decoded = json.decode(verificationJson) as Map<String, dynamic>;
          final verification = IdentityVerificationModel.fromJson(decoded);
          if (verification.isPending) {
            verifications.add(verification);
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
    }
    
    return verifications..sort((a, b) => (a.submittedAt ?? DateTime.now()).compareTo(b.submittedAt ?? DateTime.now()));
  }
}

