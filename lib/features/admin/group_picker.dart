import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import 'members_screen.dart';

/// What the group picker returns for "no branch".
const noGroup = '';

/// Opens the branch picker: a group id, [noGroup], or null on back.
Future<String?> pickGroup(BuildContext context, {String? current}) =>
    context.push<String>(
      Uri(
        path: '/more/admin/groups/pick',
        queryParameters: {'current': ?current},
      ).toString(),
    );

/// The branches, "Aucune" first, one tap to pick.
class GroupPickerScreen extends ConsumerWidget {
  const GroupPickerScreen({super.key, this.current});

  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.dobo;
    final groups = ref.watch(groupsProvider).value;
    Widget row(String id, String name) => ListTile(
      minTileHeight: 56,
      title: Text(name),
      trailing: id == (current ?? noGroup)
          ? Icon(Icons.check, color: c.ink)
          : null,
      onTap: () => context.pop(id),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupPickTitle)),
      body: groups == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                row(noGroup, l10n.memberNone),
                for (final g in groups) ...[
                  Divider(height: 1, color: c.line),
                  row(g.id, g.name),
                ],
              ],
            ),
    );
  }
}
