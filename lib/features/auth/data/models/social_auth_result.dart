import 'package:localtrade/features/auth/data/models/user_model.dart';

class SocialAuthResult {
  const SocialAuthResult({
    required this.provider,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.providerId,
  });

  final SocialAuthProvider provider;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String? providerId; // Provider-specific user ID

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'providerId': providerId,
    };
  }
}

enum SocialAuthProvider {
  google,
  apple,
  facebook,
}

extension SocialAuthProviderX on SocialAuthProvider {
  String get displayName {
    switch (this) {
      case SocialAuthProvider.google:
        return 'Google';
      case SocialAuthProvider.apple:
        return 'Apple';
      case SocialAuthProvider.facebook:
        return 'Facebook';
    }
  }

  String get iconName {
    switch (this) {
      case SocialAuthProvider.google:
        return 'google';
      case SocialAuthProvider.apple:
        return 'apple';
      case SocialAuthProvider.facebook:
        return 'facebook';
    }
  }
}

