import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/background_lock_policy.dart';

void main() {
  group('shouldRelockAfterBackground', () {
    final backgroundedAt = DateTime(2026, 1, 1, 12, 0);
    const timeout = Duration(minutes: 15);

    test('a brief interruption does not require relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(seconds: 5)),
          timeout: timeout,
        ),
        isFalse,
      );
    });

    test('just under the timeout does not require relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(timeout - const Duration(seconds: 1)),
          timeout: timeout,
        ),
        isFalse,
      );
    });

    test('exactly at the timeout requires relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(timeout),
          timeout: timeout,
        ),
        isTrue,
      );
    });

    test('past the timeout requires relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(hours: 2)),
          timeout: timeout,
        ),
        isTrue,
      );
    });

    test('a shorter configured timeout is honored', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(minutes: 1)),
          timeout: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('an "Immediately" (zero) timeout relocks on any return', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt,
          timeout: Duration.zero,
        ),
        isTrue,
      );
    });

    test('a null timeout ("Never") never requires relocking', () {
      expect(
        shouldRelockAfterBackground(
          backgroundedAt: backgroundedAt,
          resumedAt: backgroundedAt.add(const Duration(days: 30)),
          timeout: null,
        ),
        isFalse,
      );
    });
  });
}
