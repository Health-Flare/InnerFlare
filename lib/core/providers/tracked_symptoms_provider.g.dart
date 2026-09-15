// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_symptoms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's full symptom catalog — built-in defaults plus anything
/// they've added — and each one's enabled state
/// (docs/features/symptom_settings.feature). Backs both the log screen's
/// chip list and the symptom settings screen.

@ProviderFor(TrackedSymptomsNotifier)
final trackedSymptomsProvider = TrackedSymptomsNotifierProvider._();

/// The user's full symptom catalog — built-in defaults plus anything
/// they've added — and each one's enabled state
/// (docs/features/symptom_settings.feature). Backs both the log screen's
/// chip list and the symptom settings screen.
final class TrackedSymptomsNotifierProvider
    extends
        $AsyncNotifierProvider<TrackedSymptomsNotifier, List<TrackedSymptom>> {
  /// The user's full symptom catalog — built-in defaults plus anything
  /// they've added — and each one's enabled state
  /// (docs/features/symptom_settings.feature). Backs both the log screen's
  /// chip list and the symptom settings screen.
  TrackedSymptomsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trackedSymptomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trackedSymptomsNotifierHash();

  @$internal
  @override
  TrackedSymptomsNotifier create() => TrackedSymptomsNotifier();
}

String _$trackedSymptomsNotifierHash() =>
    r'912c6e527fd5b59e9f1fb909e45e2e16e6062ceb';

/// The user's full symptom catalog — built-in defaults plus anything
/// they've added — and each one's enabled state
/// (docs/features/symptom_settings.feature). Backs both the log screen's
/// chip list and the symptom settings screen.

abstract class _$TrackedSymptomsNotifier
    extends $AsyncNotifier<List<TrackedSymptom>> {
  FutureOr<List<TrackedSymptom>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TrackedSymptom>>, List<TrackedSymptom>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TrackedSymptom>>,
                List<TrackedSymptom>
              >,
              AsyncValue<List<TrackedSymptom>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
