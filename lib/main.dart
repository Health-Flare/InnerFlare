import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/security/app_lock_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/loading/screens/loading_screen.dart';

void main() {
  runApp(const ProviderScope(child: InnerFlareApp()));
}

class InnerFlareApp extends StatelessWidget {
  const InnerFlareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inner Flare',
      theme: AppTheme.light,
      home: const LoadingScreen(),
      // Covers whatever screen is on top with a lock screen after the app
      // has spent too long backgrounded (docs/features/app_lock.feature),
      // regardless of navigation depth. Deliberately does NOT also wrap
      // AppUnlockGate here: that would start watching appDatabaseProvider
      // (and so trigger the biometric/passcode prompt) the instant the app
      // boots, before LoadingScreen's own splash has painted a single frame.
      // AppUnlockGate is applied to the screen LoadingScreen hands off to
      // instead, so the prompt only fires once the splash has had its
      // moment (see loading_screen.dart).
      builder: (context, child) => AppLockGate(child: child!),
    );
  }
}
