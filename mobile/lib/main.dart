<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() {
  // Wrap startup in runZonedGuarded to catch unhandled asynchronous exceptions
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch framework-level Flutter UI errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('🔴 Flutter Framework Error: ${details.exception}');
    };

    // Firebase Initialization — commented out until native iOS/Android configuration files are present
    /*
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🟢 Firebase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization skipped: $e');
    }
    */

    runApp(
      const ProviderScope(
        child: JusticeNowApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('🔴 Unhandled Async Error: $error');
    debugPrint(stackTrace.toString());
  });
}

=======
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase — skip gracefully if not configured yet
  // Run `flutterfire configure` in mobile/ to set up Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('⚠️ Firebase not configured: $e');
    debugPrint('   → Run: flutterfire configure');
  }

  runApp(
    // Wrap entire app with ProviderScope for Riverpod
    const ProviderScope(
      child: JusticeNowApp(),
    ),
  );
}


>>>>>>> origin/feat/Human-Rights-Case-Reporting
class JusticeNowApp extends ConsumerWidget {
  const JusticeNowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'JusticeNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> origin/feat/Human-Rights-Case-Reporting
