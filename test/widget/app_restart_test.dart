import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/app_restart.dart';
import 'package:inner_flare/main.dart';

class _Counter extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state += 1;
}

final _counter = NotifierProvider<_Counter, int>(_Counter.new);

void main() {
  test('the app root has AppRestartScope above ProviderScope, which Erase '
      'all data needs to start over', () {
    final root = rootApp();
    expect(root, isA<AppRestartScope>());
    expect((root as AppRestartScope).child, isA<ProviderScope>());
  });

  testWidgets('restarting throws away every provider and the navigator', (
    tester,
  ) async {
    late VoidCallback restart;
    await tester.pumpWidget(
      AppRestartScope(
        child: ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                restart = AppRestartScope.restarterOf(context);
                return TextButton(
                  onPressed: () => ref.read(_counter.notifier).bump(),
                  child: Text('count ${ref.watch(_counter)}'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('count 0'));
    await tester.pump();
    final navigator = tester.state(find.byType(Navigator));
    Navigator.of(
      navigator.context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Text('pushed')));
    await tester.pumpAndSettle();
    expect(find.text('pushed'), findsOneWidget);

    restart();
    await tester.pumpAndSettle();

    expect(find.text('pushed'), findsNothing);
    expect(find.text('count 0'), findsOneWidget);
  });

  testWidgets('restarterOf without an AppRestartScope is an error', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(() => AppRestartScope.restarterOf(context), throwsStateError);
  });
}
