import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/files/scratch_files.dart';
import 'package:inner_flare/core/providers/backup_exporter_provider.dart';
import 'package:inner_flare/data/export/backup_file_io.dart';
import 'package:inner_flare/features/export/backup_error_messages.dart';
import 'package:share_plus/share_plus.dart';

/// Lets the user create a backup file of their data (docs/features/
/// export.feature). Never runs on its own: the only way this screen's
/// export logic executes is the user tapping the button below, matching
/// "export never happens automatically."
///
/// Encryption is on by default (issue #100): a plain file is the user's
/// explicit choice, made after a warning that names what's in it.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

/// Shown under the switch while "Encrypt export" is off.
const unencryptedWarning =
    'Without encryption, anyone who gets this file can read everything '
    'in it: your periods, symptoms, notes, ovulation tests and '
    'temperatures.';

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _encrypt = true;
  bool _exporting = false;
  String? _error;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Creates a single file with everything you\'ve logged and your '
            'symptom list, for moving to your own other device. Nothing is '
            'sent anywhere automatically: the next screen is the OS share '
            'sheet, and you choose where the file goes from there.',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Encrypt export'),
            subtitle: const Text(
              'Protects the file with a passphrase you set below.',
            ),
            value: _encrypt,
            onChanged: _exporting
                ? null
                : (value) => setState(() => _encrypt = value),
          ),
          if (_encrypt) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _passphraseController,
              obscureText: true,
              enabled: !_exporting,
              decoration: const InputDecoration(labelText: 'Passphrase'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              obscureText: true,
              enabled: !_exporting,
              decoration: const InputDecoration(
                labelText: 'Confirm passphrase',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inner Flare never stores this passphrase: if you forget it, '
              'this file can\'t be recovered.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          if (!_encrypt) ...[
            const SizedBox(height: 8),
            Text(
              key: const Key('export_plaintext_warning'),
              unencryptedWarning,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _exporting ? null : _export,
            child: _exporting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _error = null);

    String? passphrase;
    if (_encrypt) {
      final entered = _passphraseController.text;
      if (entered.isEmpty) {
        setState(
          () => _error = 'Enter a passphrase, or turn off "Encrypt export".',
        );
        return;
      }
      if (entered != _confirmController.text) {
        setState(() => _error = "Passphrases don't match.");
        return;
      }
      passphrase = entered;
    }

    setState(() => _exporting = true);
    try {
      final exporter = await ref.read(backupExporterProvider.future);
      final contents = await exporter.buildFileContents(passphrase: passphrase);
      final path = await BackupFileIO().writeTemporaryFile(contents);

      // No subject line: on email or messaging targets it would label the
      // file. The file is deleted once the share sheet is done with it
      // (phones), or at the next launch (desktop).
      await ScratchFiles.shareThenDelete(
        path,
        () => SharePlus.instance.share(
          ShareParams(files: [XFile(path, mimeType: 'application/json')]),
        ),
      );
    } catch (error) {
      debugPrint('Export failed: $error');
      if (!mounted) return;
      setState(() => _error = exportErrorMessage(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
