import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/app/router/app_router.dart';
import 'package:localtrade/core/providers/theme_provider.dart';
import 'package:localtrade/core/theme/app_theme.dart';
import 'package:localtrade/features/settings/providers/language_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'LocalTrade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
        Locale('it'), // Italian
        Locale('pt', 'BR'), // Portuguese (Brazil)
        Locale('zh', 'CN'), // Chinese (Simplified)
        Locale('ja'), // Japanese
        Locale('ko'), // Korean
        Locale('ar'), // Arabic
        Locale('hi'), // Hindi
        Locale('ru'), // Russian
      ],
      routerConfig: router,
    );
  }
}

