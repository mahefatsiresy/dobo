import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';

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
    final session = ref.watch(sessionProvider).value;
    final canSignOut = ref.watch(accountRepositoryProvider) != null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (session != null)
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text(l10n.accountRole),
              subtitle: Text(
                [
                  session.isWorker ? l10n.roleWorker : l10n.roleMember,
                  if (session.isAdmin) l10n.roleAdmin,
                  if (session.isSales) l10n.roleSales,
                ].join(' · '),
              ),
            ),
          if (canSignOut) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('signOut'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
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
