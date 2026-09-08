import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';
import 'package:inner_flare/features/dashboard/greeting.dart';
import 'package:inner_flare/features/dashboard/widgets/data_preview_card.dart';
import 'package:inner_flare/features/dashboard/widgets/log_today_hero_card.dart';
import 'package:inner_flare/features/dashboard/widgets/privacy_reassurance_card.dart';
import 'package:inner_flare/features/dashboard/widgets/unlock_error_banner.dart';

/// The dashboard's welcoming first impression. The "log today" entry point
/// is wired to the real, encrypted on-device database (see
/// lib/data/database/app_database.dart); everything else is still an
/// honest empty state, since a single logged day isn't enough for a
/// calendar or insights view yet.
///
/// The real customizable card layout (see docs/features/dashboard.feature)
/// lands separately; this screen is the UI shell that layout will slot
/// into.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logToday(BuildContext context, WidgetRef ref) async {
    await ref.read(todayLogProvider.notifier).logToday();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final result = ref.read(todayLogProvider);
    if (result.hasError) {
      debugPrint('Log today failed: ${result.error}\n${result.stackTrace}');
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.hasError
              ? "Couldn't save: ${result.error}"
              : 'Logged today.',
        ),
      ),
    );
  }

  void _retryUnlock(WidgetRef ref) {
    ref
      ..invalidate(appDatabaseProvider)
      ..invalidate(cycleDayLogRepositoryProvider)
      ..invalidate(todayLogProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final greeting = greetingForHour(now().hour);
    final todayLog = ref.watch(todayLogProvider);
    final isLoggedToday = todayLog.valueOrNull != null;
    final isBusy = todayLog.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Inner Flare Logo.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text('InnerFlare'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Customize dashboard',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showComingSoon(
              context,
              'Dashboard customization is coming soon — you\'ll be able to '
              'show, hide, and reorder every card.',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Text(
              greeting,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'This is your space — track as much or as little as feels right.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            LogTodayHeroCard(
              isLoggedToday: isLoggedToday,
              isBusy: isBusy,
              onLogToday: isLoggedToday
                  ? () => _showComingSoon(
                      context,
                      'Editing today\'s details is coming soon.',
                    )
                  : () => _logToday(context, ref),
            ),
            if (todayLog.hasError) ...[
              const SizedBox(height: 12),
              UnlockErrorBanner(
                onRetry: () => _retryUnlock(ref),
                detail: todayLog.error?.toString(),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Your data, at a glance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const DataPreviewCard(
              icon: Icons.calendar_month_rounded,
              title: 'Calendar',
              message:
                  'Nothing logged yet. Your history will show up here the '
                  'moment you log your first day.',
            ),
            const SizedBox(height: 12),
            const DataPreviewCard(
              icon: Icons.insights_rounded,
              title: 'Insights',
              message:
                  'Not enough data yet. Log a couple of cycles and you\'ll '
                  'see predictions here, plus exactly what they\'re based on.',
            ),
            const SizedBox(height: 12),
            const PrivacyReassuranceCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isBusy
            ? null
            : (isLoggedToday
                  ? () => _showComingSoon(
                      context,
                      'Editing today\'s details is coming soon.',
                    )
                  : () => _logToday(context, ref)),
        icon: Icon(isLoggedToday ? Icons.check_rounded : Icons.add_rounded),
        label: const Text('Log today'),
      ),
    );
  }
}
