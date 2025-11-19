import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/features/auth/data/models/user_model.dart';

class QRCodeService {
  QRCodeService._();
  static final QRCodeService instance = QRCodeService._();

  /// Generate a profile URL for QR code
  /// In production, this would be the actual app URL or deep link
  String generateProfileUrl(UserModel user) {
    // In production, this would be a real URL like:
    // https://localtrade.app/user/${user.id}
    // or a deep link like: localtrade://user/${user.id}
    return 'https://localtrade.app/user/${user.id}';
  }

  /// Generate QR code data for a user profile
  /// This is the data that will be encoded in the QR code
  String generateProfileQRData(UserModel user) {
    final url = generateProfileUrl(user);
    // Include additional metadata that can be parsed when scanning
    return url;
  }

  /// Generate a shareable text with profile information
  String generateShareText(UserModel user) {
    final buffer = StringBuffer();
    buffer.writeln('Check out ${user.name}\'s profile on LocalTrade!');
    if (user.businessName != null && user.businessName!.isNotEmpty) {
      buffer.writeln('Business: ${user.businessName}');
    }
    if (user.businessDescription != null && user.businessDescription!.isNotEmpty) {
      buffer.writeln('"${user.businessDescription}"');
    }
    buffer.writeln('Role: ${user.role.label}');
    if (user.rating > 0) {
      buffer.writeln('Rating: ${user.rating.toStringAsFixed(1)} (${user.reviewCount} reviews)');
    }
    buffer.writeln('');
    buffer.writeln('View profile: ${generateProfileUrl(user)}');
    return buffer.toString();
  }
}

