import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/features/log/widgets/flow_selector.dart';
import 'package:inner_flare/features/log/widgets/symptom_selector.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/symptom.dart';

/// The single-screen log UI for [date] — today or any prior day
/// (docs/features/log.feature). No field is required to save — flow,
/// symptoms, and the note all persist as they're changed, so tapping
/// "Done" with nothing touched still confirms an empty entry.
///
/// If [date] already has an entry, pass it as [initialLog] to pre-fill
/// every field — the caller fetches it (rather than this screen reading
/// provider state itself) so there's no dependency on some other widget
/// having already resolved that date's provider first. Further changes
/// update that same row rather than creating a new one — the repository
/// upserts by date (docs/features/log.feature, "Editing an existing
/// day's log" and "Back-logging a missed day is exactly as fast as
/// logging today").
class LogEntryScreen extends ConsumerStatefulWidget {
  const LogEntryScreen({super.key, required this.date, this.initialLog});

  /// Date-only (no time-of-day component) — the day being logged.
  final DateTime date;

  /// The existing entry for [date], if any, already fetched by the
  /// caller.
  final CycleDayLog? initialLog;

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  late PeriodFlow? _flow;
  late Set<Symptom> _symptoms;
  late final TextEditingController _noteController;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialLog;
    _flow = existing?.periodFlow;
    _symptoms = Set.of(existing?.symptoms ?? const {});
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  CycleDayLog _currentLog() {
    final note = _noteController.text.trim();
    return CycleDayLog(
      date: widget.date,
      periodFlow: _flow,
      symptoms: _symptoms,
      note: note.isEmpty ? null : note,
    );
  }

  Future<bool> _persist() async {
    try {
      await ref
          .read(cycleDayLogEntryProvider(widget.date).notifier)
          .save(_currentLog());
      if (mounted) setState(() => _saveFailed = false);
      return true;
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
      return false;
    }
  }

  Future<void> _onFlowChanged(PeriodFlow? flow) async {
    setState(() => _flow = flow);
    await _persist();
  }

  Future<void> _onSymptomsChanged(Set<Symptom> symptoms) async {
    setState(() => _symptoms = symptoms);
    await _persist();
  }

  Future<void> _confirmAndClose() async {
    final saved = await _persist();
    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  bool _isToday(DateTime now) {
    return widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider)();
    final isToday = _isToday(now);
    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Log today' : 'Edit a previous day'),
        actions: [
          IconButton(
            tooltip: 'Done',
            icon: const Icon(Icons.check_rounded),
            onPressed: _confirmAndClose,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              _formatDate(widget.date),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Nothing here is required — tap what applies and leave the '
              'rest.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Flow', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FlowSelector(selected: _flow, onChanged: _onFlowChanged),
            const SizedBox(height: 24),
            Text('Symptoms', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SymptomSelector(selected: _symptoms, onChanged: _onSymptomsChanged),
            const SizedBox(height: 24),
            Text('Note', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Anything else worth remembering about this day?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _persist(),
            ),
            if (_saveFailed) ...[
              const SizedBox(height: 16),
              Text(
                "Couldn't save. Try again.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatDate(DateTime date) {
    return '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} '
        '${date.day}';
  }
}
