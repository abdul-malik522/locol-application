import 'package:localtrade/features/auth/data/models/social_auth_result.dart';

/// Mock social authentication service
/// In production, this would use actual SDKs:
/// - google_sign_in for Google
/// - sign_in_with_apple for Apple
/// - flutter_facebook_auth for Facebook
class SocialAuthService {
  SocialAuthService._();
  static final SocialAuthService instance = SocialAuthService._();

  /// Mock Google Sign-In
  /// In production, use: GoogleSignIn().signIn()
  Future<SocialAuthResult> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate Google sign-in flow
    // In production, this would:
    // 1. Show Google sign-in dialog
    // 2. Get user info from Google
    // 3. Return SocialAuthResult
    
    // For mock, we'll simulate a user
    return SocialAuthResult(
      provider: SocialAuthProvider.google,
      email: 'user@gmail.com',
      name: 'Google User',
      profileImageUrl: 'https://i.pravatar.cc/150?img=12',
      providerId: 'google_123456789',
    );
  }

  /// Mock Apple Sign-In
  /// In production, use: SignInWithApple.getAppleIDCredential()
  Future<SocialAuthResult> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate Apple sign-in flow
    // In production, this would:
    // 1. Show Apple sign-in dialog
    // 2. Get user info from Apple
    // 3. Return SocialAuthResult
    
    // For mock, we'll simulate a user
    return SocialAuthResult(
      provider: SocialAuthProvider.apple,
      email: 'user@icloud.com',
      name: 'Apple User',
      profileImageUrl: null, // Apple doesn't provide profile images
      providerId: 'apple_987654321',
    );
  }

  /// Mock Facebook Sign-In
  /// In production, use: FacebookAuth.instance.login()
  Future<SocialAuthResult> signInWithFacebook() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate Facebook sign-in flow
    // In production, this would:
    // 1. Show Facebook login dialog
    // 2. Get user info from Facebook Graph API
    // 3. Return SocialAuthResult
    
    // For mock, we'll simulate a user
    return SocialAuthResult(
      provider: SocialAuthProvider.facebook,
      email: 'user@facebook.com',
      name: 'Facebook User',
      profileImageUrl: 'https://i.pravatar.cc/150?img=15',
      providerId: 'facebook_456789123',
    );
  }

  /// Sign out from all social providers
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In production, sign out from all active providers
    print('Signed out from all social providers');
  }
}

