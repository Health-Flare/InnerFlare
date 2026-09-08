import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// Shown when opening the encrypted database failed — most often because
/// the biometric/passcode prompt was cancelled. Never silently retries:
/// the user decides when to try unlocking again.
class UnlockErrorBanner extends StatelessWidget {
  const UnlockErrorBanner({super.key, required this.onRetry, this.detail});

  final VoidCallback onRetry;

  /// The underlying error, shown so a problem can be diagnosed without a
  /// debugger attached — this is a local-only failure, never sent anywhere.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emberOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.emberOrange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Couldn't unlock your data.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.deepTeal.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
