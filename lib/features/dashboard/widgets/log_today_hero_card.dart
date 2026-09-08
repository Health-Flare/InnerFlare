import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';

/// The dashboard's main invitation to log today: always the most prominent
/// thing on screen, since logging is the one entry point that must never be
/// hidden (see docs/features/dashboard.feature and docs/features/log.feature).
class LogTodayHeroCard extends StatelessWidget {
  const LogTodayHeroCard({
    super.key,
    required this.onLogToday,
    this.isLoggedToday = false,
    this.isBusy = false,
  });

  final VoidCallback onLogToday;

  /// Whether today already has a saved entry.
  final bool isLoggedToday;

  /// True while a save (or the initial unlock) is in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLoggedToday
              ? [AppColors.midTeal, AppColors.deepTeal]
              : [AppColors.emberOrange, AppColors.softOrange],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isLoggedToday ? AppColors.deepTeal : AppColors.emberOrange)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLoggedToday
                ? Icons.check_circle_rounded
                : Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            isLoggedToday ? 'Today is logged' : 'Ready when you are',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedToday
                ? 'Nice work. You can come back and add more detail to '
                      'today whenever you want.'
                : 'Logging today takes one tap. Nothing is required — add '
                      'as much or as little as you want.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onLogToday,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isLoggedToday
                  ? AppColors.deepTeal
                  : AppColors.emberOrange,
            ),
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isLoggedToday ? Icons.edit_rounded : Icons.add_rounded),
            label: Text(isLoggedToday ? 'Edit today' : 'Log today'),
          ),
        ],
      ),
    );
  }
}
