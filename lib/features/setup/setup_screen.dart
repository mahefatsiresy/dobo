import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final location = _location.text.trim();
    await ref.read(setupRepositoryProvider).completeSetup(
          siteName: _name.text.trim(),
          locationNote: location.isEmpty ? null : location,
        );
    ref.invalidate(sessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.setupSiteName),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(labelText: l10n.setupLocationNote),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              onPressed: _saving ? null : _start,
              child: Text(l10n.setupStart),
            ),
          ],
        ),
      ),
    );
  }
}
