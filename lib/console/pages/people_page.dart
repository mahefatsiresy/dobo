import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/ids.dart';
import '../../l10n/app_localizations.dart';
import '../console_providers.dart';
import '../data/console_api.dart';
import 'console_page.dart';
import 'edit_dialog.dart';

/// Everyone the farm's records name (SPEC §4 `Person`, F16): workers
/// without an account and the like. Created and edited, never deleted.
class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final api = ref.read(consoleApiProvider);

    String? orNull(String v) => v.isEmpty ? null : v;

    // A new person's id is planned once, so a retry can't make a second.
    Future<void> edit(PersonRow? p, {String? newPersonId}) => showEditDialog(
      context,
      title: p == null ? l10n.consoleNewPerson : l10n.consoleEdit,
      fields: [
        EditField(
          'nameField',
          l10n.personName,
          initial: p?.name ?? '',
          required: true,
        ),
        EditField('phoneField', l10n.personPhone, initial: p?.phone ?? ''),
        EditField('noteField', l10n.personNote, initial: p?.note ?? ''),
      ],
      active: p?.active ?? true,
      activeLabel: l10n.personActive,
      save: (v, active) async {
        final name = v['nameField']!;
        final phone = orNull(v['phoneField']!);
        final note = orNull(v['noteField']!);
        await (p == null
            ? api.savePerson(
                PersonRow(
                  id: newPersonId!,
                  name: name,
                  phone: phone,
                  note: note,
                  active: active,
                ),
                isNew: true,
              )
            : api.savePerson(
                p.copyWith(name: name, phone: phone, note: note, active: active),
              ));
        ref.invalidate(peopleProvider);
      },
    );

    return ConsolePage(
      title: l10n.consoleNavPeople,
      action: FilledButton.icon(
        key: const Key('newPerson'),
        icon: const Icon(Icons.add),
        label: Text(l10n.consoleNewPerson),
        onPressed: () => edit(null, newPersonId: newId()),
      ),
      child: AsyncRows(
        value: ref.watch(peopleProvider),
        builder: (people) => ConsoleTable(
          columns: [
            l10n.personName,
            l10n.personPhone,
            l10n.personNote,
            l10n.personActive,
            '',
          ],
          rows: [
            for (final p in people)
              DataRow(
                cells: [
                  DataCell(Text(p.name)),
                  DataCell(Text(p.phone ?? '')),
                  DataCell(Text(p.note ?? '')),
                  DataCell(Icon(p.active ? Icons.check : Icons.remove)),
                  DataCell(
                    IconButton(
                      key: Key('edit-${p.id}'),
                      tooltip: l10n.consoleEdit,
                      icon: const Icon(Icons.edit),
                      onPressed: () => edit(p),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
