import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:inner_flare/core/security/secure_key_store.dart';

/// How the key that opened the database is protected right now.
enum KeyProtection {
  /// Held in the slot the OS only releases after face, fingerprint, or
  /// the phone's screen lock. The OS prompt is the unlock.
  bound,

  /// The phone has no screen lock, so there's nothing to bind to. Anyone
  /// holding the phone can open the app; the UI says so.
  noScreenLock,

  /// The key is in the old, unbound slot behind the app's own
  /// `local_auth` prompt: platforms that can't bind (Android 9 and 10,
  /// desktop), or a migration that didn't complete and will be retried.
  promptOnly,
}

/// The passphrase that opens the database, and how it's protected.
@immutable
class DbKey {
  const DbKey(this.passphrase, this.protection);

  final String passphrase;
  final KeyProtection protection;
}

/// The database file exists but no key for it was found. Never answered
/// by making a new key: a new key can't open the old file, and on a later
/// unlock it could be copied over a real key that is only temporarily
/// unreadable (see [DbPassphraseStore]).
class DatabaseKeyUnavailable implements Exception {
  const DatabaseKeyUnavailable({required this.screenLockOff});

  /// True when the phone currently has no screen lock: the likely cause
  /// is that the key was tied to the screen lock and it was turned off.
  final bool screenLockOff;

  static const screenLockOffMessage =
      "Inner Flare's key was tied to this phone's screen lock, and the "
      "screen lock is now off. Turn it back on in your phone's settings and "
      "tap Unlock. If your data still doesn't open, the phone removed the "
      'key when the screen lock was turned off, and only a backup you '
      'exported earlier can bring it back.';

  static const notFoundMessage =
      "Inner Flare couldn't find the key for your data on this phone, so "
      'it stays locked. Tap Unlock to try again. If this keeps happening, '
      'import a backup you exported earlier.';

  String get message => screenLockOff ? screenLockOffMessage : notFoundMessage;

  @override
  String toString() => message;
}

/// Thrown when the user cancels or fails the app's own biometric/passcode
/// prompt, on platforms where the key isn't bound to the OS prompt.
class BiometricAuthenticationFailure implements Exception {
  const BiometricAuthenticationFailure();

  @override
  String toString() =>
      'Biometric authentication was cancelled or failed, so the encrypted '
      'database was not opened.';
}

/// Generates, finds, and protects the passphrase that encrypts the
/// on-device SQLite file. The passphrase lives only in the platform
/// secure key store, never in the database file or plain app storage.
///
/// Two slots, same key name:
/// - **unbound** (every install before key binding): readable by the app
///   without any prompt.
/// - **bound**: the OS releases it only after face, fingerprint, or the
///   phone's screen lock (see [FlutterSecureKeyStore.bound]).
///
/// [unlock] moves an existing key from unbound to bound without ever
/// risking it: write the bound copy, read it back, compare, and only then
/// delete the unbound one. Until that whole sequence succeeds the unbound
/// copy is the source of truth, so a failure at any step (or the app
/// being killed between steps) leaves the user's data opening exactly as
/// before, and the move is tried again on the next unlock.
///
/// Invariant that makes "unbound wins" safe: a new key is only ever made
/// when the database file doesn't exist yet, so an unbound key, when
/// present, is always the one the file was encrypted with.
class DbPassphraseStore {
  DbPassphraseStore({
    SecureKeyStore? unbound,
    SecureKeyStore? bound,
    ScreenLockProbe? screenLock,
    KeyBindingSupport? keyBinding,
    BiometricGate? legacyGate,
    String Function()? generate,
  }) : _unbound = unbound ?? FlutterSecureKeyStore.unbound(),
       _bound = bound ?? FlutterSecureKeyStore.bound(),
       _screenLock = screenLock ?? LocalAuthScreenLockProbe(),
       _keyBinding = keyBinding ?? PlatformKeyBindingSupport(),
       _legacyGate = legacyGate ?? LocalAuthBiometricGate(),
       _generate = generate ?? _generatePassphrase;

  static const key = 'inner_flare.db_passphrase';

  final SecureKeyStore _unbound;
  final SecureKeyStore _bound;
  final ScreenLockProbe _screenLock;
  final KeyBindingSupport _keyBinding;
  final BiometricGate _legacyGate;
  final String Function() _generate;

  /// Returns the passphrase once the user has proved who they are (or the
  /// phone has no screen lock to prove it with), creating one on first
  /// run, and moving an unbound key into the bound slot when it can.
  ///
  /// Shows exactly one prompt on every normal path: the OS prompt when
  /// the key is bound, or the app's own `local_auth` prompt when it isn't.
  ///
  /// [databaseExists]: whether the encrypted file is already on disk. A
  /// new key is only ever made when it isn't.
  ///
  /// Throws, leaving the data locked for the user to retry:
  /// [KeyStoreAuthenticationFailed] or [BiometricAuthenticationFailure]
  /// when the prompt was cancelled or failed; [ScreenLockCheckFailure]
  /// when it couldn't tell whether the phone has a screen lock;
  /// [DatabaseKeyUnavailable]; or the storage error itself.
  Future<DbKey> unlock({required bool databaseExists}) async {
    if (!await _keyBinding.isSupported()) {
      return _unlockPromptOnly(databaseExists);
    }

    final bool hasScreenLock;
    try {
      hasScreenLock = await _screenLock.hasScreenLock();
    } on Exception catch (e) {
      // Can't tell, so can't pick a slot safely: guessing "no screen
      // lock" would hand out the unbound key with no prompt at all.
      throw ScreenLockCheckFailure(e);
    }

    if (!hasScreenLock) return _unlockWithoutScreenLock(databaseExists);

    final existing = await _unbound.read(key);
    if (existing == null) return _unlockBound(databaseExists);
    return _migrate(existing);
  }

  /// Deletes the key from both slots, for erasing all data.
  ///
  /// Tries both slots even if one fails, then rethrows the first failure.
  /// One exception: on a phone with no screen lock the bound slot can't
  /// even be opened (and its key can't be released without a screen
  /// lock), so a failure there is logged rather than blocking the erase.
  Future<void> delete() async {
    Object? firstError;
    StackTrace? firstStack;

    try {
      await _unbound.delete(key);
    } catch (e, s) {
      firstError = e;
      firstStack = s;
    }

    try {
      await _bound.delete(key);
    } catch (e, s) {
      if (await _phoneHasNoScreenLock()) {
        debugPrint('Bound key slot not reachable without a screen lock: $e');
      } else {
        firstError ??= e;
        firstStack ??= s;
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
  }

  Future<bool> _phoneHasNoScreenLock() async {
    try {
      return !await _screenLock.hasScreenLock();
    } on Exception {
      return false;
    }
  }

  /// Steady state on a phone with a screen lock: only the bound slot.
  /// Reading it is what shows the OS prompt.
  Future<DbKey> _unlockBound(bool databaseExists) async {
    final stored = await _bound.read(key);
    if (stored != null) return DbKey(stored, KeyProtection.bound);

    if (databaseExists) {
      throw const DatabaseKeyUnavailable(screenLockOff: false);
    }

    // First run (no data yet): straight into the bound slot, checked
    // before use.
    final generated = _generate();
    try {
      await _bound.write(key, generated);
      final readBack = await _bound.read(key);
      if (readBack == generated) {
        return DbKey(generated, KeyProtection.bound);
      }
      debugPrint('New bound key did not read back; using the old slot');
    } on KeyStoreAuthenticationFailed {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Could not create a bound key, using the old slot: $e');
    }
    // The bound slot doesn't work on this phone right now. Rather than
    // leave the app unusable, start in the old slot behind the app's own
    // prompt; the next unlock tries to move it, the same way an update
    // does.
    return _createUnboundBehindPrompt();
  }

  /// An unbound key exists and the phone has a screen lock: move it.
  ///
  /// The bound slot is read first: if a previous attempt already wrote a
  /// matching copy (and the app was killed before deleting the unbound
  /// one), only the delete is left, with no rewrite.
  Future<DbKey> _migrate(String existing) async {
    final bool copied;
    try {
      copied = await _copyIntoBound(existing);
    } on KeyStoreAuthenticationFailed {
      // The user cancelled or failed the OS prompt: fail closed. The
      // unbound copy is untouched and the next tap of Unlock retries.
      rethrow;
    } on Exception catch (e) {
      // Couldn't read or write the bound slot. Keep using the unbound
      // copy, behind the app's own prompt as before, and retry next time.
      debugPrint('Key migration failed, keeping the old key: $e');
      return _promptThenUse(existing);
    }

    if (!copied) {
      // Not our key back (or nothing at all, which means the OS may never
      // have asked who the user is). Keep the unbound copy as the truth,
      // ask with the app's own prompt, retry next time.
      debugPrint('Key migration: bound copy did not match; kept the old');
      return _promptThenUse(existing);
    }

    // The bound copy is confirmed identical, and reading it needed the
    // OS prompt. Only now is the unbound copy redundant.
    try {
      await _unbound.delete(key);
    } on Exception catch (e) {
      // Both copies match, so this is safe to leave: the next unlock
      // finds them equal and only retries this delete.
      debugPrint('Key migration: could not remove the old copy yet: $e');
    }
    return DbKey(existing, KeyProtection.bound);
  }

  /// Makes the bound slot hold [existing] and confirms it by reading it
  /// back. True only when the bound slot ends up returning exactly it.
  Future<bool> _copyIntoBound(String existing) async {
    final current = await _bound.read(key);
    if (current == existing) return true;
    await _bound.write(key, existing);
    return await _bound.read(key) == existing;
  }

  /// A phone with no screen lock: nothing to bind to, so the unbound slot,
  /// with no prompt (there's nothing to prompt with).
  Future<DbKey> _unlockWithoutScreenLock(bool databaseExists) async {
    final existing = await _unbound.read(key);
    if (existing != null) return DbKey(existing, KeyProtection.noScreenLock);

    if (databaseExists) {
      // Most likely the key was bound and the screen lock was then turned
      // off. Never make a new key here: if the bound copy is only
      // unreadable until the lock comes back, a new unbound key would be
      // "migrated" over it on the next unlock and the data lost for good.
      throw const DatabaseKeyUnavailable(screenLockOff: true);
    }

    final generated = _generate();
    await _unbound.write(key, generated);
    return DbKey(generated, KeyProtection.noScreenLock);
  }

  /// Platforms that can't bind: the app's own prompt, then the unbound
  /// slot, as before key binding.
  Future<DbKey> _unlockPromptOnly(bool databaseExists) async {
    await _requireLegacyPrompt();
    final existing = await _unbound.read(key);
    if (existing != null) return DbKey(existing, KeyProtection.promptOnly);

    if (databaseExists) {
      throw const DatabaseKeyUnavailable(screenLockOff: false);
    }
    final generated = _generate();
    await _unbound.write(key, generated);
    return DbKey(generated, KeyProtection.promptOnly);
  }

  Future<DbKey> _createUnboundBehindPrompt() async {
    await _requireLegacyPrompt();
    final generated = _generate();
    await _unbound.write(key, generated);
    return DbKey(generated, KeyProtection.promptOnly);
  }

  Future<DbKey> _promptThenUse(String existing) async {
    await _requireLegacyPrompt();
    return DbKey(existing, KeyProtection.promptOnly);
  }

  Future<void> _requireLegacyPrompt() async {
    if (!await _legacyGate.authenticate()) {
      throw const BiometricAuthenticationFailure();
    }
  }

  static String _generatePassphrase() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
