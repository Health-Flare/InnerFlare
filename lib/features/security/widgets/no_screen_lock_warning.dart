import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/key_protection_provider.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// "This phone has no screen lock, so anyone holding it can open Inner
/// Flare." Shown on the dashboard and in Settings for as long as that's
/// true (docs/features/unlock.feature). Renders nothing otherwise,
/// including when it can't tell.
class NoScreenLockWarning extends ConsumerWidget {
  const NoScreenLockWarning({super.key, this.padding = EdgeInsets.zero});

  /// Around the warning when it shows; nothing takes space when it doesn't.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(showNoScreenLockWarningProvider)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: Container(
        key: const Key('no_screen_lock_warning'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.emberOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.emberOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                noScreenLockWarning,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
