import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import 'members_screen.dart';

/// Family branches (SPEC §3): add and rename, offline.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Group? g]) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: g?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final repo = ref.read(groupRepositoryProvider);
    g == null ? await repo.create(name) : await repo.rename(g.id, name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(groupsProvider).value ?? const <Group>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminGroups)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
      ),
      body: groups.isEmpty
          ? Center(child: Text(l10n.groupsEmpty))
          : ListView(
              children: [
                for (final g in groups)
                  ListTile(
                    minTileHeight: 56,
                    title: Text(g.name),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _edit(context, ref, g),
                  ),
              ],
            ),
    );
  }
}
