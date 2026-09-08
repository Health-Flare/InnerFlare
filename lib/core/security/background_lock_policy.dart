/// Whether resuming at [resumedAt], having been backgrounded since
/// [backgroundedAt], should require the user to re-authenticate before
/// they can see their data again.
///
/// [timeout] is the user's configured `LockTimeout.duration`
/// (docs/features/app_lock.feature); null means "Never" — the app should
/// not re-lock on its own.
///
/// Pure — no `DateTime.now()` inside — so it's exhaustively unit-testable
/// without faking app lifecycle events (same rule CLAUDE.md sets for the
/// cycle-math functions).
bool shouldRelockAfterBackground({
  required DateTime backgroundedAt,
  required DateTime resumedAt,
  required Duration? timeout,
}) {
  if (timeout == null) return false;
  return !resumedAt.isBefore(backgroundedAt.add(timeout));
}
