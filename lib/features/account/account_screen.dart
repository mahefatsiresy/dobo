import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../admin/members_screen.dart';
import '../more/more_screen.dart';

/// Who is signed in on this phone, and signing out (plan Decision 12).
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final account = ref.read(accountRepositoryProvider)!;
    final pending = await account.pendingCount();
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOutQuestion),
        content: pending > 0 ? Text(l10n.accountSignOutPending(pending)) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmSignOut'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (ok ?? false) await account.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final session = ref.watch(sessionProvider).value;
    final canSignOut = ref.watch(accountRepositoryProvider) != null;
    final me = session == null
        ? null
        : ref
              .watch(membersProvider)
              .value
              ?.where((m) => m.id == session.userId)
              .firstOrNull;
    final group = ref
        .watch(groupsProvider)
        .value
        ?.where((g) => g.id == me?.groupId)
        .firstOrNull;
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (me != null) Text(me.name, style: text.titleLarge),
          if (session != null)
            Text(
              l10n.labelValue(
                l10n.accountRole,
                [
                  session.isWorker ? l10n.roleWorker : l10n.roleMember,
                  if (session.isAdmin) l10n.roleAdmin,
                  if (session.isSales) l10n.roleSales,
                ].join(', '),
              ),
            ),
          if (group != null) Text(group.name, style: text.bodySmall),
          const SizedBox(height: 16),
          Divider(height: 1, color: c.line),
          ListTile(
            minTileHeight: 56,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.translate),
            title: Text(l10n.moreLanguage),
            subtitle: Text(
              locale.languageCode == 'mg'
                  ? l10n.languageMalagasy
                  : l10n.languageFrench,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => chooseLanguage(context, ref),
          ),
          Divider(height: 1, color: c.line),
          if (canSignOut) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const Key('signOut'),
              icon: const Icon(Icons.logout),
              label: Text(l10n.accountSignOut),
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
