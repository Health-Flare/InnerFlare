import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/app_restart.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/data_eraser_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/reauthenticating_provider.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';

enum _EraseChoice { cancel, exportFirst, erase }

/// Settings > Erase all data (docs/features/erase_data.feature): the
/// device unlock first, then one confirm dialog, then [DataEraser.erase]
/// and a restart into the fresh-install flow.
///
/// Only ever shown in Settings, which sits behind the unlock gate; never
/// on the lock or unlock screen.
class EraseAllDataTile extends ConsumerStatefulWidget {
  const EraseAllDataTile({super.key});

  @override
  ConsumerState<EraseAllDataTile> createState() => _EraseAllDataTileState();
}

class _EraseAllDataTileState extends ConsumerState<EraseAllDataTile> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    // Looked up before any await: by the time the erase finishes, this
    // widget is about to be thrown away with the rest of the app.
    final restart = AppRestartScope.restarterOf(context);
    setState(() => _busy = true);
    try {
      if (!await _confirmIdentity() || !mounted) return;

      final choice = await _askToConfirm();
      if (!mounted) return;
      switch (choice) {
        case null:
        case _EraseChoice.cancel:
          return;
        case _EraseChoice.exportFirst:
          await Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ExportScreen()));
          return;
        case _EraseChoice.erase:
          if (await _erase()) restart();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The device's own unlock (Face ID, fingerprint or passcode). Sets the
  /// same flag AppLockScreen does while the prompt is up, so the prompt's
  /// own pause/resume isn't mistaken for leaving the app and doesn't lock
  /// it again (see reauthenticating_provider.dart).
  Future<bool> _confirmIdentity() async {
    final flag = ref.read(reauthenticationFlagProvider);
    flag.inProgress = true;
    try {
      return await ref.read(biometricGateProvider).authenticate();
    } finally {
      flag.inProgress = false;
    }
  }

  Future<_EraseChoice?> _askToConfirm() {
    return showDialog<_EraseChoice>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Erase all data?'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This deletes every day you've logged, your symptoms, notes "
                "and settings from this phone. It can't be undone.",
              ),
              SizedBox(height: 12),
              Text("Backups you've already exported aren't affected."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_EraseChoice.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EraseChoice.exportFirst),
              child: const Text('Export a backup first'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(_EraseChoice.erase),
              child: const Text('Erase'),
            ),
          ],
        );
      },
    );
  }

  /// Returns true once the data is gone. On failure nothing was erased
  /// ([DataEraser.erase] only throws before it touches anything), so the
  /// user is told and stays here.
  Future<bool> _erase() async {
    try {
      await ref
          .read(dataEraserProvider)
          .erase(
            closeDatabase: () async {
              final db = await ref.read(appDatabaseProvider.future);
              await db.close();
            },
          );
      return true;
    } catch (error) {
      debugPrint('Erase all data failed before erasing anything: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text("Couldn't erase. Your data is still here."),
            ),
          );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Start over',
            style: TextStyle(fontWeight: FontWeight.w600, color: error),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.delete_forever_outlined, color: error),
          title: Text('Erase all data', style: TextStyle(color: error)),
          subtitle: const Text(
            'Delete everything Inner Flare has stored on this phone.',
          ),
          enabled: !_busy,
          onTap: _start,
        ),
      ],
    );
  }
}
