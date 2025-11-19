import 'dart:math';
import 'package:uuid/uuid.dart';

/// Mock Two-Factor Authentication Service
/// In production, use a library like `otp` or `crypto` for TOTP generation
/// This service simulates TOTP (Time-based One-Time Password) functionality
class TwoFactorAuthService {
  TwoFactorAuthService._();
  static final TwoFactorAuthService instance = TwoFactorAuthService._();
  final _uuid = const Uuid();

  /// Generate a secret key for TOTP
  /// In production, use a cryptographically secure random generator
  String generateSecretKey() {
    // Generate a 32-character base32-like secret
    // In production, use proper base32 encoding
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 alphabet
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a QR code data URI for authenticator apps
  /// Format: otpauth://totp/AppName:Email?secret=SECRET&issuer=AppName
  String generateQRCodeDataUri({
    required String email,
    required String secretKey,
    String issuer = 'LocalTrade',
  }) {
    // In production, use a QR code library to generate actual QR code image
    // For now, return the URI string that would be encoded in QR
    return 'otpauth://totp/$issuer:$email?secret=$secretKey&issuer=$issuer';
  }

  /// Generate backup codes for account recovery
  List<String> generateBackupCodes({int count = 10}) {
    final random = Random.secure();
    return List.generate(
      count,
      (_) => List.generate(
        8,
        (_) => random.nextInt(10),
      ).join(),
    );
  }

  /// Verify a TOTP code
  /// In production, use proper TOTP verification with time windows
  /// This mock implementation simulates verification
  bool verifyCode(String secretKey, String code) {
    // Mock verification - in production, implement proper TOTP algorithm
    // For testing, accept codes that match a pattern
    if (code.length != 6) return false;
    
    // In mock mode, accept any 6-digit code that starts with the last digit of secret
    // This is just for testing - real implementation would use TOTP algorithm
    final lastChar = secretKey[secretKey.length - 1];
    final expectedStart = int.tryParse(lastChar) ?? 0;
    final codeStart = int.tryParse(code[0]) ?? -1;
    
    // For mock: accept if code starts with expected digit OR is a test code
    return codeStart == expectedStart || code == '123456' || code == '000000';
  }

  /// Verify a backup code
  bool verifyBackupCode(List<String> backupCodes, String code) {
    return backupCodes.contains(code);
  }

  /// Remove used backup code
  List<String> removeBackupCode(List<String> backupCodes, String code) {
    return backupCodes.where((c) => c != code).toList();
  }
}

