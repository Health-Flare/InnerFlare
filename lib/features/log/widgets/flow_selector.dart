import 'package:flutter/material.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/models/period_flow.dart';

/// Single-tap chips for choosing the day's period flow. Tapping the
/// already-selected chip clears it — flow is optional, never required
/// (see docs/features/log.feature).
class FlowSelector extends StatelessWidget {
  const FlowSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PeriodFlow? selected;
  final ValueChanged<PeriodFlow?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final flow in PeriodFlow.values)
          ChoiceChip(
            label: Text(_label(flow)),
            selected: selected == flow,
            onSelected: (isSelected) => onChanged(isSelected ? flow : null),
            selectedColor: AppColors.emberOrange,
            labelStyle: TextStyle(
              color: selected == flow ? Colors.white : null,
              fontWeight: selected == flow ? FontWeight.w600 : null,
            ),
          ),
      ],
    );
  }

  String _label(PeriodFlow flow) {
    switch (flow) {
      case PeriodFlow.spotting:
        return 'Spotting';
      case PeriodFlow.light:
        return 'Light';
      case PeriodFlow.medium:
        return 'Medium';
      case PeriodFlow.heavy:
        return 'Heavy';
    }
  }
}
