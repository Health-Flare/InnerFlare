import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/background_lock_policy.dart';

void main() {
  group('shouldRelockAfterBackground', () {
    final backgroundedAt = DateTime(2026, 1, 1, 12, 0);

    test('a brief interruption does not require relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(seconds: 5)),
        ),
        isFalse,
      );
    });

    test('just under the timeout does not require relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(
            backgroundLockTimeout - const Duration(seconds: 1),
          ),
        ),
        isFalse,
      );
    });

    test('exactly at the timeout requires relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(backgroundLockTimeout),
        ),
        isTrue,
      );
    });

    test('past the timeout requires relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(hours: 2)),
        ),
        isTrue,
      );
    });

    test('a custom timeout is honored', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(minutes: 1)),
          timeout: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });
  });
}
