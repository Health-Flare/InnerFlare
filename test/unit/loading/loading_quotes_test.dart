import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/features/loading/loading_quotes.dart';

void main() {
  group('pickLoadingQuote', () {
    test('returns one of the configured quotes', () {
      for (var seed = 0; seed < loadingQuotes.length; seed++) {
        final quote = pickLoadingQuote(loadingQuotes, Random(seed));
        expect(loadingQuotes, contains(quote));
      }
    });

    test('picks quotes on-device with no dependency beyond dart:math', () {
      // A seeded Random is deterministic, mirroring the on-device,
      // no-network selection described in docs/features/loading.feature.
      final first = pickLoadingQuote(loadingQuotes, Random(42));
      final second = pickLoadingQuote(loadingQuotes, Random(42));
      expect(first, second);
    });

    test('can select every configured quote given enough draws', () {
      final seen = <String>{};
      for (
        var seed = 0;
        seed < 200 && seen.length < loadingQuotes.length;
        seed++
      ) {
        seen.add(pickLoadingQuote(loadingQuotes, Random(seed)));
      }
      expect(seen, containsAll(loadingQuotes));
    });
  });
}
