import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/citations/medical_sources.dart';

void main() {
  test('every estimate explanation cites at least one source', () {
    expect(estimateExplanations, isNotEmpty);
    for (final explanation in estimateExplanations) {
      expect(
        explanation.sources,
        isNotEmpty,
        reason: '${explanation.title} has no source',
      );
    }
  });

  test('covers each built-in assumption the predictions rely on', () {
    final titles = estimateExplanations.map((e) => e.title).toList();
    expect(titles, contains('Predicted fertile window'));
    expect(titles, contains('Predicted next period'));
    expect(titles, contains('Irregular cycles'));
  });

  test('explains when a period starts, with a source (#101)', () {
    final average = estimateExplanations.singleWhere(
      (e) => e.title == 'Average cycle length and variability',
    );
    expect(average.method, contains('first day of light, medium or heavy'));
    expect(average.method, contains('Spotting'));
    expect(average.sources, containsAll([figo2023, bull2019]));
    expect(average.evidence, contains('first day of bleeding'));
  });

  test('the user\'s own "Period day" choice is said to win (#103)', () {
    final average = estimateExplanations.firstWhere(
      (e) => e.title == 'Average cycle length and variability',
    );
    expect(average.method, contains('"Period day"'));
  });

  test('every source links to the original over https', () {
    for (final source in medicalSources) {
      final uri = Uri.parse(source.url);
      expect(uri.scheme, 'https', reason: source.citation);
      expect(uri.host, isNotEmpty, reason: source.citation);
      expect(uri.host, isNot(contains('healthflare')), reason: source.citation);
    }
  });

  test(
    'every listed source is cited by an explanation, and ids are unique',
    () {
      final cited = {
        for (final e in estimateExplanations)
          for (final s in e.sources) s.id,
      };
      final ids = medicalSources.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(cited, ids.toSet());
    },
  );
}
