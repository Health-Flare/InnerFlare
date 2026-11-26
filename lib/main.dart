import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/app_restart.dart';
import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:inner_flare/core/security/app_lock_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/features/loading/screens/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Remove export files an earlier run left behind (docs/features/
  // export.feature, issue #100). Runs before anything can open the
  // database or start a share, so nothing can be using them. Never throws.
  await ScratchFiles.sweep();
  runApp(rootApp());
}

/// The widget tree [main] runs. [AppRestartScope] sits above
/// [ProviderScope] so Erase all data can throw away every provider and
/// the navigator and start over as on a fresh install
/// (docs/features/erase_data.feature).
Widget rootApp() =>
    const AppRestartScope(child: ProviderScope(child: InnerFlareApp()));

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
