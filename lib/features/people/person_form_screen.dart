import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import 'people_providers.dart';
import '../common/save_once.dart';
import '../common/details_fold.dart';
import '../common/form_body.dart';
import '../common/pinned_action.dart';

/// Adds a person, or edits the one with [personId].
class PersonFormScreen extends ConsumerStatefulWidget {
  const PersonFormScreen({super.key, this.personId});

  final String? personId;

  @override
  ConsumerState<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends ConsumerState<PersonFormScreen>
    with SaveOnce {
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
    // An account's person is renamed with the account (Admin › Membres).
    final linked = id != null && ref.watch(personRolesProvider)[id] != null;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.add : _name.text)),
      bottomNavigationBar: PinnedAction(
        icon: id == null ? Icons.person_add : Icons.check,
        label: id == null ? l10n.actionAddPerson : l10n.save,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            TextFormField(
              controller: _name,
              readOnly: linked,
              decoration: InputDecoration(
                labelText: l10n.personName,
                helperText: linked ? l10n.personRenameFromAdmin : null,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            if (id != null)
              SwitchListTile(
                minTileHeight: 56,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.personActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            DetailsFold(
              initiallyOpen: _phone.text.isNotEmpty || _note.text.isNotEmpty,
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
