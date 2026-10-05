// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nudge_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's stored dismiss/snooze choice for each dashboard nudge, and
/// the actions that change them (docs/features/dashboard_nudges.feature).
/// Choices for nudge ids this app version doesn't know are ignored.

@ProviderFor(NudgeStates)
final nudgeStatesProvider = NudgeStatesProvider._();

/// The user's stored dismiss/snooze choice for each dashboard nudge, and
/// the actions that change them (docs/features/dashboard_nudges.feature).
/// Choices for nudge ids this app version doesn't know are ignored.
final class NudgeStatesProvider
    extends
        $AsyncNotifierProvider<NudgeStates, Map<DashboardNudge, NudgeState>> {
  /// The user's stored dismiss/snooze choice for each dashboard nudge, and
  /// the actions that change them (docs/features/dashboard_nudges.feature).
  /// Choices for nudge ids this app version doesn't know are ignored.
  NudgeStatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nudgeStatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nudgeStatesHash();

  @$internal
  @override
  NudgeStates create() => NudgeStates();
}

String _$nudgeStatesHash() => r'019232efab77dd1521f746f5750046726fad84f6';

/// The user's stored dismiss/snooze choice for each dashboard nudge, and
/// the actions that change them (docs/features/dashboard_nudges.feature).
/// Choices for nudge ids this app version doesn't know are ignored.

abstract class _$NudgeStates
    extends $AsyncNotifier<Map<DashboardNudge, NudgeState>> {
  FutureOr<Map<DashboardNudge, NudgeState>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<DashboardNudge, NudgeState>>,
              Map<DashboardNudge, NudgeState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<DashboardNudge, NudgeState>>,
                Map<DashboardNudge, NudgeState>
              >,
              AsyncValue<Map<DashboardNudge, NudgeState>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The one dashboard nudge to show now, or null. Recomputes when the card
/// layout, the log, or a stored choice changes.

@ProviderFor(currentDashboardNudge)
final currentDashboardNudgeProvider = CurrentDashboardNudgeProvider._();

/// The one dashboard nudge to show now, or null. Recomputes when the card
/// layout, the log, or a stored choice changes.

final class CurrentDashboardNudgeProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardNudge?>,
          DashboardNudge?,
          FutureOr<DashboardNudge?>
        >
    with $FutureModifier<DashboardNudge?>, $FutureProvider<DashboardNudge?> {
  /// The one dashboard nudge to show now, or null. Recomputes when the card
  /// layout, the log, or a stored choice changes.
  CurrentDashboardNudgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDashboardNudgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDashboardNudgeHash();

  @$internal
  @override
  $FutureProviderElement<DashboardNudge?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardNudge?> create(Ref ref) {
    return currentDashboardNudge(ref);
  }
}

String _$currentDashboardNudgeHash() =>
    r'4e4a64baba2912cd9536ffd237977df5c2cf9a1e';
