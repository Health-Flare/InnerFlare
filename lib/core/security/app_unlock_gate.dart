import 'package:flutter/material.dart';

/// TODO(unlock.feature): will cover [child] with a dedicated unlock screen
/// while `appDatabaseProvider` is opening or has failed, instead of the
/// dashboard flashing partially-loaded content behind the diagnostic
/// AppBar icon/banner it shows today. See docs/features/unlock.feature and
/// test/widget/app_unlock_gate_test.dart for the target behavior.
///
/// Currently a pass-through — deliberately not wired into `main.dart` yet.
class AppUnlockGate extends StatelessWidget {
  const AppUnlockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
