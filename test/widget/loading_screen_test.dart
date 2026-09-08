import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/features/loading/loading_quotes.dart';
import 'package:inner_flare/features/loading/screens/loading_screen.dart';

void main() {
  testWidgets('shows the logo and one of the configured quotes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingScreen(
          random: Random(0),
          readyFuture: Completer<void>().future, // never resolves
          minDisplayDuration: Duration.zero,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final textWidget = tester.widget<Text>(find.byType(Text));
    expect(loadingQuotes, contains(textWidget.data));
  });

  testWidgets('is dismissed once loading completes', (tester) async {
    final ready = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: LoadingScreen(
          random: Random(0),
          readyFuture: ready.future,
          minDisplayDuration: Duration.zero,
          nextScreenBuilder: (context) =>
              const Scaffold(body: Text('Next screen')),
        ),
      ),
    );

    expect(find.text('Next screen'), findsNothing);

    ready.complete();
    await tester.pump(); // flush the readyFuture's .then callback
    await tester.pump(const Duration(milliseconds: 500)); // page transition

    expect(find.text('Next screen'), findsOneWidget);
  });
}
