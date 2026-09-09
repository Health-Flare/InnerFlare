import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/tracked_symptom.dart';

/// Multi-select toggle chips for the day's symptoms. Tapping a selected
/// chip again removes it from the set (see docs/features/log.feature).
class SymptomSelector extends StatelessWidget {
  const SymptomSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// The symptoms offered as chips, in display order — the caller decides
  /// which ones that is (normally the enabled ones, see LogEntryScreen).
  final List<TrackedSymptom> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final symptom in options)
          FilterChip(
            label: Text(symptom.label),
            selected: selected.contains(symptom.id),
            onSelected: (isSelected) {
              final next = Set<String>.of(selected);
              if (isSelected) {
                next.add(symptom.id);
              } else {
                next.remove(symptom.id);
              }
              onChanged(next);
            },
            selectedColor: AppColors.deepTeal,
            labelStyle: TextStyle(
              color: selected.contains(symptom.id) ? Colors.white : null,
              fontWeight: selected.contains(symptom.id)
                  ? FontWeight.w600
                  : null,
            ),
          ),
      ],
    );
  }
}
