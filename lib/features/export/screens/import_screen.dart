import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/backup_importer_provider.dart';
import 'package:inner_flare/core/providers/log_data_invalidation.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_provider.dart';
import 'package:inner_flare/core/security/backup_encryption.dart';
import 'package:inner_flare/data/export/backup_file_codec.dart';
import 'package:inner_flare/data/export/backup_file_io.dart';
import 'package:inner_flare/data/export/backup_importer.dart';

/// Lets the user restore a previously exported backup file (docs/features/
/// export.feature). Every step below happens only in response to the
/// user's own taps — picking a file, entering a passphrase if needed,
/// choosing replace or merge — and nothing is written to the database
/// until all of that has happened and the file has validated successfully.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _importing = false;
  String? _error;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Restores a backup file created by Inner Flare\'s export '
            'feature. You\'ll choose whether it replaces everything on '
            'this device or merges with what\'s already here before '
            'anything is written.',
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          if (_successMessage != null) ...[
            Text(_successMessage!),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: _importing ? null : _pickAndImport,
            child: _importing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Choose backup file…'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport() async {
    setState(() {
      _error = null;
      _successMessage = null;
    });

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [BackupFileIO.extension],
    );
    if (picked == null) return;

    setState(() => _importing = true);
    try {
      final contents = await picked.xFile.readAsString();
      final importer = await ref.read(backupImporterProvider.future);

      final passphrase = importer.isEncrypted(contents)
          ? await _promptForPassphrase()
          : null;
      if (!mounted) return;
      if (importer.isEncrypted(contents) && passphrase == null) {
        // User cancelled the passphrase prompt.
        setState(() => _importing = false);
        return;
      }

      final strategy = await _promptForStrategy();
      if (!mounted) return;
      if (strategy == null) {
        setState(() => _importing = false);
        return;
      }

      await importer.import(
        contents,
        strategy: strategy,
        passphrase: passphrase,
      );

      _invalidateDataProviders();
      if (!mounted) return;
      setState(() => _successMessage = 'Import complete.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _messageFor(Object error) {
    if (error is InvalidBackupFile) return error.toString();
    if (error is BackupPassphraseRequired) return error.toString();
    if (error is IncorrectBackupPassphrase) return error.toString();
    if (error is UnsupportedBackupSchemaVersion) return error.toString();
    return "Couldn't import: $error";
  }

  Future<String?> _promptForPassphrase() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PassphraseDialog(),
    );
  }

  Future<ImportStrategy?> _promptForStrategy() {
    return showDialog<ImportStrategy>(
      context: context,
      builder: (_) => const _StrategyDialog(),
    );
  }

  void _invalidateDataProviders() {
    invalidateLogDependentProviders(ref);
    ref.invalidate(trackedSymptomsProvider);
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog();

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter passphrase'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Passphrase',
          hintText: 'This backup file is encrypted',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}

class _StrategyDialog extends StatefulWidget {
  const _StrategyDialog();

  @override
  State<_StrategyDialog> createState() => _StrategyDialogState();
}

class _StrategyDialogState extends State<_StrategyDialog> {
  ImportStrategy _selected = ImportStrategy.merge;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Replace or merge?'),
      content: RadioGroup<ImportStrategy>(
        groupValue: _selected,
        onChanged: (value) {
          if (value != null) setState(() => _selected = value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            RadioListTile<ImportStrategy>(
              contentPadding: EdgeInsets.zero,
              value: ImportStrategy.merge,
              title: Text('Merge'),
              subtitle: Text(
                'Combine the backup with what\'s already on this device. '
                'Nothing already here is overwritten.',
              ),
            ),
            RadioListTile<ImportStrategy>(
              contentPadding: EdgeInsets.zero,
              value: ImportStrategy.replace,
              title: Text('Replace'),
              subtitle: Text(
                'Replace everything on this device with the backup. '
                'Anything logged here that isn\'t in the backup is '
                'deleted. This can\'t be undone.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
