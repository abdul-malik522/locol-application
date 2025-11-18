import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:localtrade/core/constants/app_constants.dart';
import 'package:localtrade/core/theme/app_colors.dart';
import 'package:localtrade/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _init();
  }

  Future<void> _init() async {
    await ref.read(authProvider.notifier).checkAuthStatus();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final isAuthed = ref.read(isAuthenticatedProvider);
    context.go(isAuthed ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo - Blue rounded square with triangle
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8), // Blue from design
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_upward,
                size: 64,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
            const Spacer(),
            // Loading dots animation at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.grey[600] 
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(),
                  ).fadeIn(
                    duration: 500.ms,
                    delay: Duration(milliseconds: index * 150),
                  ).then(
                    delay: 500.ms,
                  ).fadeOut(
                    duration: 500.ms,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

