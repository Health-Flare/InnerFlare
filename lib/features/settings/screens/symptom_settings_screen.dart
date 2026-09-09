import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_provider.dart';
import 'package:inner_flare/models/tracked_symptom.dart';

/// Lets the user change, add, enable, and disable the symptoms offered on
/// the log screen (docs/features/symptom_settings.feature). Disabling a
/// symptom here never deletes it or touches a day already logged with
/// it — it only stops offering that chip on future/other logging.
class SymptomSettingsScreen extends ConsumerWidget {
  const SymptomSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(trackedSymptomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptoms to track'),
        actions: [
          IconButton(
            tooltip: 'Add a symptom',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addSymptom(context, ref),
          ),
        ],
      ),
      body: symptomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Couldn't load: $error")),
        data: (symptoms) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final symptom in symptoms)
              SwitchListTile(
                key: ValueKey(symptom.id),
                title: Text(symptom.label),
                subtitle: symptom.isCustom ? const Text('Custom') : null,
                value: symptom.enabled,
                onChanged: (enabled) {
                  ref
                      .read(trackedSymptomsProvider.notifier)
                      .setEnabled(symptom.id, enabled);
                },
                secondary: IconButton(
                  tooltip: 'Rename',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _renameSymptom(context, ref, symptom),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSymptom(BuildContext context, WidgetRef ref) async {
    final label = await _promptForLabel(context, title: 'Add a symptom');
    if (label == null || label.isEmpty) return;
    await ref.read(trackedSymptomsProvider.notifier).add(label);
  }

  Future<void> _renameSymptom(
    BuildContext context,
    WidgetRef ref,
    TrackedSymptom symptom,
  ) async {
    final label = await _promptForLabel(
      context,
      title: 'Rename symptom',
      initialValue: symptom.label,
    );
    if (label == null || label.isEmpty || label == symptom.label) return;
    await ref
        .read(trackedSymptomsProvider.notifier)
        .rename(symptom.id, label);
  }

  Future<String?> _promptForLabel(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          _SymptomLabelDialog(title: title, initialValue: initialValue),
    );
  }
}

class _SymptomLabelDialog extends StatefulWidget {
  const _SymptomLabelDialog({required this.title, this.initialValue = ''});

  final String title;
  final String initialValue;

  @override
  State<_SymptomLabelDialog> createState() => _SymptomLabelDialogState();
}

class _SymptomLabelDialogState extends State<_SymptomLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Symptom name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
