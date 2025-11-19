import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/data/datasources/two_factor_auth_service.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final _codeController = TextEditingController();
  String? _secretKey;
  String? _qrCodeDataUri;
  List<String>? _backupCodes;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initializeSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initializeSetup() async {
    try {
      final twoFactorAuth = await ref.read(authProvider.notifier).setupTwoFactorAuth();
      setState(() {
        _secretKey = twoFactorAuth.secretKey;
        _backupCodes = twoFactorAuth.backupCodes;
      });

      // Generate QR code data URI
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null && _secretKey != null) {
        final twoFactorService = TwoFactorAuthService.instance;
        final qrDataUri = twoFactorService.generateQRCodeDataUri(
          email: currentUser.email,
          secretKey: _secretKey!,
        );
        setState(() {
          _qrCodeDataUri = qrDataUri;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to setup 2FA: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _verifyAndEnable() async {
    if (_codeController.text.trim().length != 6) {
      _showSnackBar('Please enter a 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await ref.read(authProvider.notifier).verifyAndEnableTwoFactorAuth(
        _codeController.text.trim(),
      );

      if (mounted) {
        _showBackupCodesDialog();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Verification failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showBackupCodesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('2FA Enabled Successfully'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Save these backup codes in a safe place. You can use them to access your account if you lose access to your authenticator app.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_backupCodes ?? []).map(
                (code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _backupCodes!.join('\n')));
              _showSnackBar('Backup codes copied to clipboard');
            },
            child: const Text('Copy All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Setup Two-Factor Authentication'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure your account with two-factor authentication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan the QR code with an authenticator app like Google Authenticator or Authy.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            // QR Code placeholder
            if (_qrCodeDataUri != null) ...[
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 100, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'QR Code',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Mock - In production, display actual QR code)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Secret key display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secret Key (if you can\'t scan QR code):',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _secretKey ?? '',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _secretKey ?? ''));
                            _showSnackBar('Secret key copied');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter the 6-digit code from your authenticator app:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _codeController,
                label: 'Verification Code',
                hint: '000000',
                keyboardType: TextInputType.number,
                maxLength: 6,
                prefixIcon: Icons.lock_outline,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Verify and Enable',
                onPressed: _isVerifying || authState.isLoading ? null : _verifyAndEnable,
                isLoading: _isVerifying || authState.isLoading,
                fullWidth: true,
              ),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to use 2FA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep('1', 'Install an authenticator app (Google Authenticator, Authy, etc.)'),
                  _buildInstructionStep('2', 'Scan the QR code above with the app'),
                  _buildInstructionStep('3', 'Enter the 6-digit code from the app'),
                  _buildInstructionStep('4', 'Save your backup codes in a safe place'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

