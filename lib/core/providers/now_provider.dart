import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'now_provider.g.dart';

/// The current time, as a provider — so anything that needs "now" can be
/// given a fixed value in tests instead of depending on [DateTime.now]
/// directly (same rule CLAUDE.md sets for the pure cycle-math functions).
@Riverpod(keepAlive: true)
DateTime Function() now(Ref ref) => DateTime.now;
