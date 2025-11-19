import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.email,
    this.token,
  });

  final String? email;
  final String? token;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _emailVerified = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userEmail = widget.email;
    // Auto-verify if token is provided
    if (widget.token != null && widget.email != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyEmail(widget.email!, widget.token!);
      });
    } else {
      // Get email from current user if available
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null) {
        _userEmail = currentUser.email;
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyEmail(String email, String token) async {
    final authNotifier = ref.read(authProvider.notifier);

    try {
      await authNotifier.verifyEmail(email: email, token: token);
      if (mounted) {
        setState(() {
          _emailVerified = true;
        });
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_userEmail == null) {
      _showSnackBar('Email address not found.');
      return;
    }

    final authNotifier = ref.read(authProvider.notifier);

    try {
      await authNotifier.resendVerificationEmail(_userEmail!);
      _showSnackBar('Verification email sent! Please check your inbox.');
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_emailVerified) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Email Verified'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Email Verified!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your email address has been successfully verified. You can now access all features.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Continue',
                  onPressed: () => context.go('/home'),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Verify Your Email'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _userEmail != null
                    ? 'We\'ve sent a verification link to\n$_userEmail'
                    : 'We\'ve sent a verification link to your email address.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What to do next:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      context,
                      '1',
                      'Check your email inbox',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      context,
                      '2',
                      'Click the verification link in the email',
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      context,
                      '3',
                      'Your email will be verified automatically',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Resend Verification Email',
                onPressed: authState.isLoading ? null : _resendVerificationEmail,
                isLoading: authState.isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              // Development mode: Show test verification link
              if (_userEmail != null)
                TextButton.icon(
                  onPressed: () {
                    final mockDataSource = AuthMockDataSource.instance;
                    final token = mockDataSource.getVerificationTokenForEmail(
                      _userEmail!,
                    );
                    if (token != null && mounted) {
                      context.go(
                        '/verify-email?token=$token&email=${Uri.encodeComponent(_userEmail!)}',
                      );
                    } else {
                      _showSnackBar(
                        'Please request a verification email first, then check console for token.',
                      );
                    }
                  },
                  icon: const Icon(Icons.developer_mode_outlined),
                  label: const Text('Test Verification Link (Dev Only)'),
                ),
              const SizedBox(height: 8),
              Text(
                'Note: In production, use the link from your email.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

