/// A symptom the user can log (docs/features/log.feature), whether one of
/// the built-in defaults or one they've added themselves
/// (docs/features/symptom_settings.feature). Disabling one removes it from
/// the log screen's chip list without touching any day already logged
/// with it — see `TrackedSymptomsRepository.setEnabled`.
class TrackedSymptom {
  const TrackedSymptom({
    required this.id,
    required this.label,
    required this.isCustom,
    required this.enabled,
    required this.sortOrder,
  });

  /// Stable key stored in `cycle_day_logs.symptoms`. Never reused or
  /// reassigned, even if the symptom is later renamed or disabled — only
  /// its `label` and `enabled` state can change.
  final String id;
  final String label;
  final bool isCustom;
  final bool enabled;
  final int sortOrder;

  TrackedSymptom copyWith({String? label, bool? enabled}) {
    return TrackedSymptom(
      id: id,
      label: label ?? this.label,
      isCustom: isCustom,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrackedSymptom &&
        other.id == id &&
        other.label == label &&
        other.isCustom == isCustom &&
        other.enabled == enabled &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(id, label, isCustom, enabled, sortOrder);
}

/// The default symptom set every install starts with, seeded into the
/// `symptoms` table on create/upgrade (see lib/data/database/schema.dart).
/// IDs match the names of the fixed enum this table replaced, so
/// `cycle_day_logs.symptoms` entries written before symptom settings
/// existed still resolve correctly — an id here is fixed forever, since
/// changing one would orphan every log already saved with it.
const List<(String id, String label)> builtInSymptoms = [
  ('cramps', 'Cramps'),
  ('fatigue', 'Fatigue'),
  ('headache', 'Headache'),
  ('bloating', 'Bloating'),
  ('moodSwings', 'Mood swings'),
  ('acne', 'Acne'),
  ('tenderBreasts', 'Tender breasts'),
  ('nausea', 'Nausea'),
];
