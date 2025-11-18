import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigate(BuildContext context, UserRole role) {
    context.go('/register?role=${role.name}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // App Logo with Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.eco,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Farmly',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0D1B0D),
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              const SizedBox(height: 24),
              // Headline
              Text(
                'How are you joining us?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: isDark ? Colors.white : const Color(0xFF0D1B0D),
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 32),
              // Role Cards
              Expanded(
                child: Column(
                  children: [
                    // Local Seller Card
                    _RoleCard(
                      title: 'Local Seller',
                      description: 'Sell your fresh ingredients directly to local kitchens.',
                      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
                      onTap: () => _navigate(context, UserRole.seller),
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.3),
                    const SizedBox(height: 16),
                    // Restaurant Card
                    _RoleCard(
                      title: 'Restaurant',
                      description: 'Source the best local ingredients for your menu.',
                      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
                      onTap: () => _navigate(context, UserRole.restaurant),
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideX(begin: 0.3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sign In Link
              TextButton(
                onPressed: () => context.go('/login'),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary.withOpacity(0.3),
                  );
                },
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Content
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
