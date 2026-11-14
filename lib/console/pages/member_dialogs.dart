import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/ids.dart';
import '../../domain/accounts.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/auth_gateway.dart';
import '../console_errors.dart';
import '../console_providers.dart';
import '../data/console_api.dart';

/// Creates an account ([member] null) or edits one (SPEC F14, F16). A new
/// account's id is planned when the dialog opens, so a retry sends it again.
/// An admin can't change their own role, admin flag or activity (as on the
/// phone: one wrong click could leave the association without an admin).
class AccountDialog extends ConsumerStatefulWidget {
  const AccountDialog({super.key, this.member, required this.groups});

  final MemberRow? member;
  final List<GroupRow> groups;

  @override
  ConsumerState<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<AccountDialog> {
  late final _name = TextEditingController(text: widget.member?.name ?? '');
  final _login = TextEditingController();
  final _secret = TextEditingController();
  final _again = TextEditingController();
  final _memberId = newId();
  late MemberRole _role = widget.member?.role ?? MemberRole.member;
  late String? _groupId = widget.member?.groupId;
  late bool _admin = widget.member?.isAdmin ?? false;
  late bool _sales = widget.member?.isSales ?? false;
  late String _locale = widget.member?.locale ?? 'fr';
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.member == null;
  bool get _worker => _role == MemberRole.worker;

  bool get _own =>
      widget.member?.id == ref.read(consoleSessionProvider).value?.memberId;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _login, _secret, _again]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _login, _secret, _again]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (!_isNew) return true;
    return accountProblem(
              role: _role,
              login: _login.text,
              secret: _secret.text,
            ) ==
            null &&
        _again.text == _secret.text;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final api = ref.read(consoleApiProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final m = widget.member;
      if (m == null) {
        await api.createAccount(
          NewAccount(
            memberId: _memberId,
            name: _name.text.trim(),
            role: _role,
            login: _login.text.trim().toLowerCase(),
            secret: _secret.text,
            locale: _locale,
            // The console's API stamps its own device id.
            deviceId: '',
            groupId: _groupId,
            isAdmin: !_worker && _admin,
            isSales: !_worker && _sales,
          ),
        );
      } else {
        await api.saveMember(
          m.copyWith(
            name: _name.text.trim(),
            groupId: _groupId,
            role: _role,
            isAdmin: !_worker && _admin,
            isSales: !_worker && _sales,
            locale: _locale,
          ),
        );
      }
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
    final own = _own;
    return AlertDialog(
      title: Text(_isNew ? l10n.memberNew : widget.member!.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('accountName'),
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.memberName),
              ),
              const SizedBox(height: 16),
              SegmentedButton<MemberRole>(
                segments: [
                  ButtonSegment(
                    value: MemberRole.member,
                    label: Text(l10n.roleMember, key: const Key('role-member')),
                  ),
                  ButtonSegment(
                    value: MemberRole.worker,
                    label: Text(l10n.roleWorker, key: const Key('role-worker')),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: own
                    ? null
                    : (s) => setState(() {
                        _role = s.single;
                        // SPEC §9: Malagasy for workers, French for members.
                        if (_isNew) _locale = _worker ? 'mg' : 'fr';
                      }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('accountGroup'),
                initialValue: _groupId,
                decoration: InputDecoration(labelText: l10n.memberGroup),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.memberNone)),
                  for (final g in widget.groups)
                    DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setState(() => _groupId = v),
              ),
              if (!_worker) ...[
                SwitchListTile(
                  key: const Key('accountAdmin'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.roleAdmin),
                  value: _admin,
                  onChanged: own ? null : (v) => setState(() => _admin = v),
                ),
                SwitchListTile(
                  key: const Key('accountSales'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.roleSales),
                  value: _sales,
                  onChanged: (v) => setState(() => _sales = v),
                ),
              ],
              const SizedBox(height: 8),
              Text(l10n.moreLanguage),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'fr', label: Text(l10n.languageFrench)),
                  ButtonSegment(value: 'mg', label: Text(l10n.languageMalagasy)),
                ],
                selected: {_locale},
                onSelectionChanged: (s) => setState(() => _locale = s.single),
              ),
              if (_isNew) ...[
                const SizedBox(height: 16),
                TextField(
                  key: const Key('accountLogin'),
                  controller: _login,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: _worker ? l10n.loginUsername : l10n.loginEmail,
                  ),
                ),
                const SizedBox(height: 16),
                ..._secretFields(l10n),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('accountSave'),
          onPressed: _busy || !_valid ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  List<Widget> _secretFields(AppLocalizations l10n) => secretFields(
    l10n,
    worker: _worker,
    secret: _secret,
    again: _again,
    keys: const ('accountSecret', 'accountSecretAgain'),
  );
}

/// The new password or PIN, typed twice.
List<Widget> secretFields(
  AppLocalizations l10n, {
  required bool worker,
  required TextEditingController secret,
  required TextEditingController again,
  required (String, String) keys,
}) {
  final formatters = worker
      ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(pinLength),
        ]
      : null;
  return [
    TextField(
      key: Key(keys.$1),
      controller: secret,
      obscureText: true,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: worker ? l10n.loginPin : l10n.loginPassword,
        helperText: worker ? l10n.pinSixDigits : l10n.passwordTooShort,
      ),
    ),
    const SizedBox(height: 16),
    TextField(
      key: Key(keys.$2),
      controller: again,
      obscureText: true,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: l10n.consoleAgain,
        errorText: again.text.isNotEmpty && again.text != secret.text
            ? l10n.consoleSecretsDiffer
            : null,
      ),
    ),
  ];
}

/// A new password or PIN for [member]'s account (SPEC F14, F16). Returns
/// true once the server took it.
class ResetSecretDialog extends ConsumerStatefulWidget {
  const ResetSecretDialog({super.key, required this.member});

  final MemberRow member;

  @override
  ConsumerState<ResetSecretDialog> createState() => _ResetSecretDialogState();
}

class _ResetSecretDialogState extends ConsumerState<ResetSecretDialog> {
  final _secret = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _worker => widget.member.role == MemberRole.worker;

  @override
  void initState() {
    super.initState();
    for (final c in [_secret, _again]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _secret.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(consoleApiProvider)
          .resetSecret(widget.member.id, _secret.text);
      if (mounted) Navigator.of(context).pop(true);
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
    final ok =
        secretProblem(role: widget.member.role, secret: _secret.text) == null &&
        _again.text == _secret.text &&
        !_busy;
    return AlertDialog(
      title: Text(
        '${_worker ? l10n.resetPin : l10n.resetPassword} — ${widget.member.name}',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...secretFields(
              l10n,
              worker: _worker,
              secret: _secret,
              again: _again,
              keys: const ('consoleNewSecret', 'consoleNewSecretAgain'),
            ),
            const SizedBox(height: 12),
            Text(l10n.resetHint),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('consoleConfirmReset'),
          onPressed: ok ? _send : null,
          child: Text(l10n.resetConfirm),
        ),
      ],
    );
  }
}
