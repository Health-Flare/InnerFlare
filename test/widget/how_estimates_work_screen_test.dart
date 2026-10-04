import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/citations/medical_sources.dart';
import 'package:inner_flare/core/citations/open_source_link.dart';
import 'package:inner_flare/features/insights/screens/how_estimates_work_screen.dart';

import '../helpers/test_app_builder.dart';

void main() {
  testWidgets('shows every estimate and every citation', (tester) async {
    // Tall enough that the lazy list builds every card at once.
    tester.view.physicalSize = const Size(800, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTestApp(tester, const HowEstimatesWorkScreen());

    for (final explanation in estimateExplanations) {
      expect(find.text(explanation.title), findsOneWidget);
      expect(find.text(explanation.method), findsOneWidget);
    }
    for (final source in medicalSources) {
      expect(find.text(source.citation), findsWidgets, reason: source.id);
    }
  });

  testWidgets('says plainly that these are estimates, not medical advice', (
    tester,
  ) async {
    await pumpTestApp(tester, const HowEstimatesWorkScreen());
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });

  testWidgets('tapping a source opens its original link', (tester) async {
    final opened = <Uri>[];
    await pumpTestApp(
      tester,
      const HowEstimatesWorkScreen(),
      overrides: [
        sourceLinkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
        }),
      ],
    );

    final first = estimateExplanations.first.sources.first;
    await tester.ensureVisible(find.text(first.citation).first);
    await tester.pump();
    await tester.tap(find.text(first.citation).first);
    await tester.pump();

    expect(opened, [Uri.parse(first.url)]);
  });

  testWidgets('a link that will not open shows a message instead of failing', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const HowEstimatesWorkScreen(),
      overrides: [
        sourceLinkOpenerProvider.overrideWithValue(
          (uri) async => throw StateError('no browser'),
        ),
      ],
    );

    final first = estimateExplanations.first.sources.first;
    await tester.ensureVisible(find.text(first.citation).first);
    await tester.pump();
    await tester.tap(find.text(first.citation).first);
    await tester.pump();

    expect(find.text('Could not open that link.'), findsOneWidget);
  });
}
