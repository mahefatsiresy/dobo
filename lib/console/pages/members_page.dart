import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../console_errors.dart';
import '../console_providers.dart';
import '../data/console_api.dart';
import 'console_page.dart';
import 'member_dialogs.dart';

/// Members and workers with their accounts (SPEC F14, F16): create, edit,
/// deactivate and reactivate, reset a password or PIN. Nothing is deleted.
class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    final ownId = ref.watch(consoleSessionProvider).value?.memberId;
    String groupName(String? id) =>
        groups.where((g) => g.id == id).firstOrNull?.name ?? '';

    Future<void> account(MemberRow? m) => showDialog<void>(
      context: context,
      builder: (_) => AccountDialog(member: m, groups: groups),
    );

    Future<void> reset(MemberRow m) async {
      final done = await showDialog<bool>(
        context: context,
        builder: (_) => ResetSecretDialog(member: m),
      );
      if (done == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              m.role == MemberRole.worker
                  ? l10n.resetPinDone
                  : l10n.resetPasswordDone,
            ),
          ),
        );
      }
    }

    Future<void> toggle(MemberRow m) => showDialog<void>(
      context: context,
      builder: (_) => _ToggleDialog(member: m),
    );

    Widget yes(bool v) => Icon(v ? Icons.check : Icons.remove, size: 20);

    return ConsolePage(
      title: l10n.consoleNavMembers,
      action: FilledButton.icon(
        key: const Key('newAccount'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.memberNew),
        onPressed: () => account(null),
      ),
      child: AsyncRows(
        value: ref.watch(membersProvider),
        builder: (members) => ConsoleTable(
          columns: [
            l10n.memberName,
            l10n.memberGroup,
            l10n.consoleLogin,
            l10n.roleAdmin,
            l10n.roleSales,
            l10n.memberActive,
            l10n.moreLanguage,
            '',
          ],
          rows: [
            for (final m in members)
              DataRow(
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name),
                        Text(
                          m.role == MemberRole.worker
                              ? l10n.roleWorker
                              : l10n.roleMember,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(groupName(m.groupId))),
                  DataCell(Text(m.login ?? '')),
                  DataCell(yes(m.isAdmin)),
                  DataCell(yes(m.isSales)),
                  DataCell(
                    m.active
                        ? yes(true)
                        : Icon(
                            Icons.block,
                            key: Key('inactive-${m.id}'),
                            size: 20,
                          ),
                  ),
                  DataCell(Text(m.locale.toUpperCase())),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('edit-${m.id}'),
                          tooltip: l10n.consoleEdit,
                          icon: const Icon(Icons.edit),
                          onPressed: () => account(m),
                        ),
                        if (m.login != null)
                          IconButton(
                            key: Key('reset-${m.id}'),
                            tooltip: m.role == MemberRole.worker
                                ? l10n.resetPin
                                : l10n.resetPassword,
                            icon: const Icon(Icons.key),
                            onPressed: () => reset(m),
                          ),
                        if (m.id != ownId)
                          IconButton(
                            key: Key('toggle-${m.id}'),
                            tooltip: m.active
                                ? l10n.consoleDeactivate
                                : l10n.consoleReactivate,
                            icon: Icon(
                              m.active ? Icons.person_off : Icons.person,
                            ),
                            onPressed: () => toggle(m),
                          ),
                      ],
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

/// Asks before deactivating or reactivating an account.
class _ToggleDialog extends ConsumerStatefulWidget {
  const _ToggleDialog({required this.member});

  final MemberRow member;

  @override
  ConsumerState<_ToggleDialog> createState() => _ToggleDialogState();
}

class _ToggleDialogState extends ConsumerState<_ToggleDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    final m = widget.member;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(consoleApiProvider).saveMember(m.copyWith(active: !m.active));
      ref.invalidate(membersProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = consoleErrorText(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.member;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.active
                ? l10n.consoleDeactivateAsk(m.name)
                : l10n.consoleReactivateAsk(m.name),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirmToggle'),
          onPressed: _busy ? null : _confirm,
          child: Text(
            m.active ? l10n.consoleDeactivate : l10n.consoleReactivate,
          ),
        ),
      ],
    );
  }
}
