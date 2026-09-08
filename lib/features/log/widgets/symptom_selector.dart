import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/symptom.dart';

/// Multi-select toggle chips for the day's symptoms. Tapping a selected
/// chip again removes it from the set (see docs/features/log.feature).
class SymptomSelector extends StatelessWidget {
  const SymptomSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<Symptom> selected;
  final ValueChanged<Set<Symptom>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final symptom in Symptom.values)
          FilterChip(
            label: Text(_label(symptom)),
            selected: selected.contains(symptom),
            onSelected: (isSelected) {
              final next = Set<Symptom>.of(selected);
              if (isSelected) {
                next.add(symptom);
              } else {
                next.remove(symptom);
              }
              onChanged(next);
            },
            selectedColor: AppColors.deepTeal,
            labelStyle: TextStyle(
              color: selected.contains(symptom) ? Colors.white : null,
              fontWeight: selected.contains(symptom) ? FontWeight.w600 : null,
            ),
          ),
      ],
    );
  }

  String _label(Symptom symptom) {
    switch (symptom) {
      case Symptom.cramps:
        return 'Cramps';
      case Symptom.fatigue:
        return 'Fatigue';
      case Symptom.headache:
        return 'Headache';
      case Symptom.bloating:
        return 'Bloating';
      case Symptom.moodSwings:
        return 'Mood swings';
      case Symptom.acne:
        return 'Acne';
      case Symptom.tenderBreasts:
        return 'Tender breasts';
      case Symptom.nausea:
        return 'Nausea';
    }
  }
}
