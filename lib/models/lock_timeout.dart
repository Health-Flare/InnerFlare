/// How long the app can sit backgrounded before returning to it requires
/// re-authentication (docs/features/app_lock.feature). User-configurable
/// in Settings; the choice is persisted per-device, same as dashboard
/// card layout — never synced.
enum LockTimeout {
  immediately,
  after1Minute,
  after5Minutes,
  after15Minutes,
  after30Minutes,
  after1Hour,
  never;

  static const defaultValue = LockTimeout.after15Minutes;

  String get label => switch (this) {
    LockTimeout.immediately => 'Immediately',
    LockTimeout.after1Minute => 'After 1 minute',
    LockTimeout.after5Minutes => 'After 5 minutes',
    LockTimeout.after15Minutes => 'After 15 minutes',
    LockTimeout.after30Minutes => 'After 30 minutes',
    LockTimeout.after1Hour => 'After 1 hour',
    LockTimeout.never => 'Never',
  };

  /// How long backgrounded before this setting requires re-authentication
  /// on return. Null means never re-lock automatically.
  Duration? get duration => switch (this) {
    LockTimeout.immediately => Duration.zero,
    LockTimeout.after1Minute => const Duration(minutes: 1),
    LockTimeout.after5Minutes => const Duration(minutes: 5),
    LockTimeout.after15Minutes => const Duration(minutes: 15),
    LockTimeout.after30Minutes => const Duration(minutes: 30),
    LockTimeout.after1Hour => const Duration(hours: 1),
    LockTimeout.never => null,
  };

  /// The value persisted in `security_settings.lock_timeout_minutes`:
  /// minutes for a timed setting, null for [never].
  int? get storedMinutes => duration?.inMinutes;

  /// Maps a stored value back to its [LockTimeout], falling back to
  /// [defaultValue] for anything unrecognized (e.g. no row saved yet).
  static LockTimeout fromStoredMinutes(int? minutes) {
    return LockTimeout.values.firstWhere(
      (timeout) => timeout.storedMinutes == minutes,
      orElse: () => defaultValue,
    );
  }
}
