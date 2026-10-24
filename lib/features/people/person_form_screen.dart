import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import 'people_providers.dart';

/// Adds a person, or edits the one with [personId].
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  var _active = true;
  var _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _load(Person p) {
    _name.text = p.name;
    _phone.text = p.phone ?? '';
    _note.text = p.note ?? '';
    _active = p.active;
    _loaded = true;
  }

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(personRepositoryProvider);
    final id = widget.personId;
    if (id == null) {
      await repo.create(
        name: _name.text.trim(),
        phone: _optional(_phone),
        note: _optional(_note),
      );
    } else {
      await repo.update(
        id,
        name: _name.text.trim(),
        phone: _optional(_phone),
        note: _optional(_note),
        active: _active,
      );
    }
    if (mounted) context.go('/more/people');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.personId;
    if (id != null && !_loaded) {
      final person = ref
          .watch(peopleProvider)
          .value
          ?.where((p) => p.id == id)
          .firstOrNull;
      if (person == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _load(person);
    }
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.add : _name.text)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.personName),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: l10n.personPhone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.personNote),
            ),
            if (id != null)
              SwitchListTile(
                minTileHeight: 56,
                title: Text(l10n.personActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
