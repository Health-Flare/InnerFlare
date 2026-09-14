import 'package:flutter/material.dart';

/// TODO(unlock.feature): the dedicated, full-screen unlock prompt shown
/// while the encrypted database is opening or has failed to open — first
/// open of a session and any later re-open alike. See
/// docs/features/unlock.feature and test/widget/app_unlock_gate_test.dart
/// for the target behavior; this is a placeholder that renders nothing,
/// so [AppUnlockGate] has something to show while that's built out.
class AppUnlockScreen extends StatelessWidget {
  const AppUnlockScreen({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
