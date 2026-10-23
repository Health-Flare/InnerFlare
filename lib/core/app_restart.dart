import 'package:flutter/widgets.dart';

/// Lets the app start over from scratch without the process restarting:
/// [restart] rebuilds [child] under a new key, so everything below it,
/// including the `ProviderScope` (every provider, the open database
/// connection's provider, the navigator and its history), is thrown away
/// and created fresh, exactly as on a cold launch.
///
/// Used by Erase all data (docs/features/erase_data.feature) to land on
/// the same unlock and welcome screens as a fresh install. Resetting a
/// hand-picked list of providers instead would silently miss any provider
/// added later.
class AppRestartScope extends StatefulWidget {
  const AppRestartScope({super.key, required this.child});

  final Widget child;

  /// Returns a callback that starts the app over. Look it up before any
  /// `await`, so it still works once [context]'s widget is gone. Throws a
  /// [StateError] if there's no [AppRestartScope] above [context].
  static VoidCallback restarterOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRestartScopeState>();
    if (state == null) {
      throw StateError('No AppRestartScope above this context.');
    }
    return state._restart;
  }

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
