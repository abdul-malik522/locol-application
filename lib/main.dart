import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:localtrade/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences with error handling
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Failed to initialize SharedPreferences: $e');
    // Continue anyway - SharedPreferences will be initialized lazily when needed
  }

  // Set up error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Set up zone error handling
  runZoned(
    () {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      runApp(const ProviderScope(child: App()));
    },
    zoneSpecification: ZoneSpecification(
      handleUncaughtError: (self, parent, zone, error, stackTrace) {
        debugPrint('Uncaught error in zone: $error');
        debugPrint('Stack trace: $stackTrace');
        parent.handleUncaughtError(zone, error, stackTrace);
      },
    ),
  );
}

