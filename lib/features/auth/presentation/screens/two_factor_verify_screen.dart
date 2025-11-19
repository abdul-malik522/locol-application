import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class TwoFactorVerifyScreen extends ConsumerStatefulWidget {
  const TwoFactorVerifyScreen({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  ConsumerState<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends ConsumerState<TwoFactorVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showSnackBar('Please enter a 6-digit code');
      return;
    }

    try {
      await ref.read(authProvider.notifier).verifyTwoFactorAndLogin(
        email: widget.email,
        password: widget.password,
        code: code,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      _showSnackBar('Verification failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Two-Factor Authentication', showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Enter Verification Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Open your authenticator app and enter the 6-digit code to complete login.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _codeController,
                  label: 'Verification Code',
                  hint: '000000',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter verification code';
                    }
                    if (value.trim().length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Show backup code option
                    _showBackupCodeDialog();
                  },
                  child: const Text('Use backup code instead'),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Verify',
                  onPressed: authState.isLoading ? null : _verify,
                  isLoading: authState.isLoading,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Having trouble? You can use one of your backup codes to sign in.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBackupCodeDialog() {
    final backupCodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Backup Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter one of your backup codes:'),
            const SizedBox(height: 16),
            TextField(
              controller: backupCodeController,
              decoration: const InputDecoration(
                labelText: 'Backup Code',
                hintText: 'Enter 8-digit backup code',
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = backupCodeController.text.trim();
              if (code.length == 8) {
                Navigator.pop(context);
                _codeController.text = code;
                await _verify();
              } else {
                _showSnackBar('Backup code must be 8 digits');
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}

