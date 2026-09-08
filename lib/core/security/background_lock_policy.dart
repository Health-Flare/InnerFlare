/// How long the app can sit backgrounded before returning to it requires
/// re-authentication (see docs/features/app_lock.feature).
const Duration backgroundLockTimeout = Duration(minutes: 15);

/// Whether resuming at [resumedAt], having been backgrounded since
/// [backgroundedAt], should require the user to re-authenticate before
/// they can see their data again.
///
/// Pure — no `DateTime.now()` inside — so it's exhaustively unit-testable
/// without faking app lifecycle events (same rule CLAUDE.md sets for the
/// cycle-math functions).
bool shouldRelockAfterBackground({
  required DateTime backgroundedAt,
  required DateTime resumedAt,
  Duration timeout = backgroundLockTimeout,
}) {
  return !resumedAt.isBefore(backgroundedAt.add(timeout));
}
