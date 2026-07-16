import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/presentation/splash_screen.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Owns MaterialApp.router and the theme configuration.
///
/// Uses [ThemeMode.system] to follow the OS light/dark preference.
class RiimindApp extends StatefulWidget {
  const RiimindApp({super.key});

  @override
  State<RiimindApp> createState() => _RiimindAppState();
}

class _RiimindAppState extends State<RiimindApp> {
  bool _showSplash = !kDebugMode;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (_showSplash) {
      _splashTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() => _showSplash = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kDebugMode ? 'Riimind Beta' : 'Riimind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        if (_showSplash) {
          return const SplashScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
