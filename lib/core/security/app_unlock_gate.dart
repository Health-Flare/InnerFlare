import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/features/security/screens/app_unlock_screen.dart';

/// Covers [child] with [AppUnlockScreen] whenever `appDatabaseProvider`
/// isn't open yet — opening for the first time this session, or retrying
/// after a failure — instead of letting the dashboard flash partially
/// loaded behind a diagnostic AppBar icon/banner (docs/features/unlock.feature).
///
/// The wrapped [child] keeps running underneath, same as [AppLockGate]:
/// nothing downstream needs to know it might be covered.
class AppUnlockGate extends ConsumerWidget {
  const AppUnlockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(appDatabaseProvider).hasValue;
    return Stack(children: [child, if (!isOpen) const AppUnlockScreen()]);
  }
}
