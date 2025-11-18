import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/theme/app_colors.dart';
import 'package:localtrade/core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  // App Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 48,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Connecting Local Sellers with Restaurants',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Discover the freshest ingredients from local producers and get them delivered directly to your kitchen.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2),
                  const Spacer(),
                  // Buttons
                  Column(
                    children: [
                      // Sign Up Button (Accent color)
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Sign Up',
                          onPressed: () => context.go('/role-selection'),
                          variant: CustomButtonVariant.secondary,
                          fullWidth: true,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideY(begin: 0.3),
                      const SizedBox(height: 12),
                      // Log In Button (Transparent)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 700.ms).slideY(begin: 0.3),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
