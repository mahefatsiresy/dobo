import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../console_providers.dart';
import 'console_page.dart';
import 'edit_dialog.dart';

/// The association's name (SPEC F16).
class AssociationPage extends ConsumerWidget {
  const AssociationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = ref.watch(consoleSessionProvider).value?.associationName ?? '';
    return ConsolePage(
      title: l10n.consoleNavAssociation,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.consoleFoundAssociation),
        subtitle: Text(name, style: Theme.of(context).textTheme.titleLarge),
        trailing: OutlinedButton.icon(
          key: const Key('renameAssociation'),
          icon: const Icon(Icons.edit),
          label: Text(l10n.consoleRename),
          onPressed: () => showEditDialog(
            context,
            title: l10n.consoleRename,
            fields: [
              EditField(
                'nameField',
                l10n.consoleFoundAssociation,
                initial: name,
                required: true,
              ),
            ],
            save: (v, _) async {
              await ref.read(consoleApiProvider).renameAssociation(v['nameField']!);
              await ref.read(consoleSessionProvider.notifier).reload();
            },
          ),
        ),
      ),
    );
  }
}
