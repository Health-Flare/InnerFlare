import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_provider.g.dart';

/// Whether the app-level lock screen is currently covering the app,
/// having tripped the idle-background timeout (docs/features/app_lock.feature).
///
/// Starts unlocked: the very first unlock of a session happens through
/// [AppDatabase]'s own biometric gate the first time data is read, not
/// through this — this provider only covers re-locking after the app has
/// already been in use.
@riverpod
class AppLock extends _$AppLock {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}
