import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/features/dashboard/greeting.dart';

void main() {
  group('greetingForHour', () {
    test('greets morning hours', () {
      expect(greetingForHour(8), 'Good morning');
    });

    test('greets afternoon hours', () {
      expect(greetingForHour(14), 'Good afternoon');
    });

    test('greets evening hours', () {
      expect(greetingForHour(19), 'Good evening');
    });

    test('greets very early hours', () {
      expect(greetingForHour(2), 'Still up?');
    });

    test('greets very late hours', () {
      expect(greetingForHour(22), 'Winding down?');
    });
  });
}
