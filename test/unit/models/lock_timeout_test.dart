import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/models/lock_timeout.dart';

void main() {
  group('LockTimeout', () {
    test('storedMinutes round-trips through fromStoredMinutes', () {
      for (final timeout in LockTimeout.values) {
        expect(LockTimeout.fromStoredMinutes(timeout.storedMinutes), timeout);
      }
    });

    test('never stores as null minutes', () {
      expect(LockTimeout.never.storedMinutes, isNull);
      expect(LockTimeout.never.duration, isNull);
    });

    test('immediately stores as zero minutes, not null', () {
      expect(LockTimeout.immediately.storedMinutes, 0);
      expect(LockTimeout.immediately.duration, Duration.zero);
    });

    test('an unrecognized stored value falls back to the default', () {
      expect(LockTimeout.fromStoredMinutes(9999), LockTimeout.defaultValue);
    });

    test('no saved row (represented as never having been read) defaults '
        'to 15 minutes', () {
      expect(LockTimeout.defaultValue, LockTimeout.after15Minutes);
    });
  });
}
