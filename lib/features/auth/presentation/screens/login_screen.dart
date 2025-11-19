import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/presentation/widgets/social_login_role_dialog.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.error != next.error && next.error != null) {
        _showSnackBar(next.error!);
      }
      if (prev?.user == null && next.user != null && mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    final needs2FA = await ref.read(authProvider.notifier).login(email, password);
    
    if (needs2FA == false && mounted) {
      // 2FA is enabled, navigate to verification screen
      context.go('/two-factor-verify?email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}');
    }
    // If needs2FA is true, login was successful and navigation is handled by listener
  }

  Future<void> _signInWithGoogle() async {
    // Check if this is a new user (we'll show role selection)
    // For now, we'll use default role and let them change it later
    // In production, you might want to show role selection dialog for new users
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  Future<void> _signInWithApple() async {
    await ref.read(authProvider.notifier).signInWithApple();
  }

  Future<void> _signInWithFacebook() async {
    await ref.read(authProvider.notifier).signInWithFacebook();
  }

  Future<void> _signInWithSocialAndSelectRole(
    Future<void> Function(UserRole) signInFunction,
  ) async {
    // Show role selection dialog for new social login users
    final role = await showDialog<UserRole>(
      context: context,
      builder: (context) => SocialLoginRoleDialog(
        onRoleSelected: (role) {
          Navigator.pop(context, role);
        },
      ),
    );

    if (role != null && mounted) {
      await signInFunction(role);
    }
  }

  Widget _buildSocialLoginButton(
    BuildContext context,
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    final authState = ref.watch(authProvider);
    
    return OutlinedButton(
      onPressed: authState.isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Login', showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue selling or sourcing locally.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  validator: (value) =>
                      Validators.validateRequired(value, 'password'),
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Login',
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSocialLoginButton(
                  context,
                  'Continue with Google',
                  Icons.g_mobiledata,
                  Colors.white,
                  Colors.black87,
                  () => _signInWithGoogle(),
                ),
                const SizedBox(height: 12),
                _buildSocialLoginButton(
                  context,
                  'Continue with Apple',
                  Icons.apple,
                  Colors.black,
                  Colors.white,
                  () => _signInWithApple(),
                ),
                const SizedBox(height: 12),
                _buildSocialLoginButton(
                  context,
                  'Continue with Facebook',
                  Icons.facebook,
                  const Color(0xFF1877F2),
                  Colors.white,
                  () => _signInWithFacebook(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () => context.go('/role-selection'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

