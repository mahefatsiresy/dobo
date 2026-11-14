import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../console_errors.dart';

/// One text field of an [EditDialog].
class EditField {
  const EditField(
    this.key,
    this.label, {
    this.initial = '',
    this.required = false,
  });

  final String key;
  final String label;
  final String initial;
  final bool required;
}

/// A small form in a dialog (SPEC F16 desktop layouts). It stays open with
/// what was typed when the save fails, and says why.
Future<void> showEditDialog(
  BuildContext context, {
  required String title,
  required List<EditField> fields,
  bool? active,
  String? activeLabel,
  required Future<void> Function(Map<String, String> values, bool active) save,
}) => showDialog<void>(
  context: context,
  builder: (_) => _EditDialog(
    title: title,
    fields: fields,
    active: active,
    activeLabel: activeLabel,
    save: save,
  ),
);

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.fields,
    required this.active,
    required this.activeLabel,
    required this.save,
  });

  final String title;
  final List<EditField> fields;
  final bool? active;
  final String? activeLabel;
  final Future<void> Function(Map<String, String>, bool) save;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _controllers = {
    for (final f in widget.fields) f.key: TextEditingController(text: f.initial),
  };
  late bool _active = widget.active ?? true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers.values) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => widget.fields.every(
    (f) => !f.required || _controllers[f.key]!.text.trim().isNotEmpty,
  );

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.save({
        for (final e in _controllers.entries) e.key: e.value.text.trim(),
      }, _active);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = consoleErrorText(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, f) in widget.fields.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  key: Key(f.key),
                  controller: _controllers[f.key],
                  autofocus: i == 0,
                  decoration: InputDecoration(labelText: f.label),
                ),
              ),
            if (widget.active != null)
              SwitchListTile(
                key: const Key('activeField'),
                contentPadding: EdgeInsets.zero,
                title: Text(widget.activeLabel ?? ''),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('dialogSave'),
          onPressed: _busy || !_valid ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
