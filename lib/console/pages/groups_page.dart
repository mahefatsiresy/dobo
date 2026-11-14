import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/ids.dart';
import '../../l10n/app_localizations.dart';
import '../console_providers.dart';
import '../data/console_api.dart';
import 'console_page.dart';
import 'edit_dialog.dart';

/// The family branches (SPEC §3, F16): create and rename, never delete.
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final api = ref.read(consoleApiProvider);

    // A new group's id is planned once, so a retry can't make a second.
    Future<void> edit(GroupRow? g, {String? newGroupId}) => showEditDialog(
      context,
      title: g == null ? l10n.consoleNewGroup : l10n.consoleRename,
      fields: [
        EditField(
          'nameField',
          l10n.personName,
          initial: g?.name ?? '',
          required: true,
        ),
      ],
      save: (v, _) async {
        final name = v['nameField']!;
        await (g == null
            ? api.saveGroup(GroupRow(id: newGroupId!, name: name), isNew: true)
            : api.saveGroup(g.copyWith(name: name)));
        ref.invalidate(groupsProvider);
      },
    );

    return ConsolePage(
      title: l10n.consoleNavGroups,
      action: FilledButton.icon(
        key: const Key('newGroup'),
        icon: const Icon(Icons.add),
        label: Text(l10n.consoleNewGroup),
        onPressed: () => edit(null, newGroupId: newId()),
      ),
      child: AsyncRows(
        value: ref.watch(groupsProvider),
        builder: (groups) => ConsoleTable(
          columns: [l10n.personName, ''],
          rows: [
            for (final g in groups)
              DataRow(
                cells: [
                  DataCell(Text(g.name)),
                  DataCell(
                    IconButton(
                      key: Key('edit-${g.id}'),
                      tooltip: l10n.consoleRename,
                      icon: const Icon(Icons.edit),
                      onPressed: () => edit(g),
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
