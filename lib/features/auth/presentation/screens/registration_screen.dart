import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/utils/location_helper.dart';
import 'package:localtrade/core/utils/validators.dart';
import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/core/widgets/custom_button.dart';
import 'package:localtrade/core/widgets/custom_text_field.dart';
import 'package:localtrade/features/auth/presentation/widgets/social_login_role_dialog.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({this.initialRole, super.key});

  final String? initialRole;

  @override
  ConsumerState<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserRole _role;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  Position? _position;

  @override
  void initState() {
    super.initState();
    _role = _parseRole(widget.initialRole);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.error != next.error && next.error != null) {
        _showSnackBar(next.error!);
      }
      if (prev?.user == null && next.user != null && mounted) {
        // Redirect to email verification instead of home
        final email = next.user!.email;
        context.go('/verify-email?email=${Uri.encodeComponent(email)}');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  UserRole _parseRole(String? roleName) {
    if (roleName == null) return UserRole.seller;
    return UserRole.values.firstWhere(
      (role) => role.name == roleName,
      orElse: () => UserRole.seller,
    );
  }

  Future<void> _pickLocation() async {
    final position = await LocationHelper.getCurrentPosition();
    if (position != null) {
      setState(() => _position = position);
      _showSnackBar('Location captured successfully.');
    } else {
      _showSnackBar('Unable to fetch location. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: _role,
          businessDetails: {
            'businessName': _businessNameController.text.trim(),
            'businessDescription': _descriptionController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'latitude': _position?.latitude,
            'longitude': _position?.longitude,
          },
        );
  }

  Future<void> _signInWithGoogle() async {
    // Show role selection for social login
    final role = await showDialog<UserRole>(
      context: context,
      builder: (context) => SocialLoginRoleDialog(
        onRoleSelected: (role) {
          Navigator.pop(context, role);
        },
      ),
    );

    if (role != null && mounted) {
      await ref.read(authProvider.notifier).signInWithGoogle(role: role);
    }
  }

  Future<void> _signInWithApple() async {
    final role = await showDialog<UserRole>(
      context: context,
      builder: (context) => SocialLoginRoleDialog(
        onRoleSelected: (role) {
          Navigator.pop(context, role);
        },
      ),
    );

    if (role != null && mounted) {
      await ref.read(authProvider.notifier).signInWithApple(role: role);
    }
  }

  Future<void> _signInWithFacebook() async {
    final role = await showDialog<UserRole>(
      context: context,
      builder: (context) => SocialLoginRoleDialog(
        onRoleSelected: (role) {
          Navigator.pop(context, role);
        },
      ),
    );

    if (role != null && mounted) {
      await ref.read(authProvider.notifier).signInWithFacebook(role: role);
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
      appBar: const CustomAppBar(title: 'Create Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(
                    _role == UserRole.seller ? 'Seller / Farmer' : 'Restaurant',
                  ),
                  avatar: Icon(
                    _role == UserRole.seller
                        ? Icons.store
                        : Icons.restaurant_menu,
                  ),
                ),
                const SizedBox(height: 24),
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
                  validator: Validators.validatePassword,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (value) => Validators.validateRequired(
                    value,
                    'confirm password',
                  ),
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Your Name',
                  validator: (value) => Validators.validateRequired(
                    value,
                    'name',
                  ),
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessNameController,
                  label: _role == UserRole.seller
                      ? 'Farm / Business Name'
                      : 'Restaurant Name',
                  validator: (value) => Validators.validateRequired(
                    value,
                    'business name',
                  ),
                  prefixIcon: Icons.business_center_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Business Description',
                  hint: 'Tell us about your specialties',
                  maxLines: 4,
                  validator: (value) => Validators.validateMinLength(
                    value,
                    10,
                    'description',
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  validator: (value) => Validators.validateRequired(
                    value,
                    'address',
                  ),
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _position != null
                            ? 'Lat: ${_position!.latitude.toStringAsFixed(3)}, '
                                'Lon: ${_position!.longitude.toStringAsFixed(3)}'
                            : 'Add your current location for better matches.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Register',
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
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

