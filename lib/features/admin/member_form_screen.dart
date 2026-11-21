import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/ids.dart';
import '../../db/repositories/providers.dart';
import '../../domain/accounts.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/auth_gateway.dart';
import '../account/account_errors.dart';
import '../common/attention_band.dart';
import '../common/choice_buttons.dart';
import '../common/form_body.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../common/save_once.dart';
import '../people/people_providers.dart';
import '../people/person_picker.dart';
import 'group_picker.dart';
import 'members_screen.dart';
import 'reset_secret_dialog.dart';

/// A member's account (SPEC F14). Editing works offline; a new account
/// needs the network and a login: email and password for a member,
/// username and 6-digit PIN for a worker. An account's password or PIN is
/// reset from here, online.
class MemberFormScreen extends ConsumerStatefulWidget {
  const MemberFormScreen({super.key, this.memberId});

  /// Null for a new account.
  final String? memberId;

  @override
  ConsumerState<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends ConsumerState<MemberFormScreen>
    with SaveOnce {
  final _name = TextEditingController();
  final _login = TextEditingController();
  final _secret = TextEditingController();
  MemberRole _role = MemberRole.member;
  String? _groupId;
  String? _personId;
  bool _admin = false;
  bool _sales = false;
  bool _active = true;
  String _locale = 'fr';
  bool _hasLogin = false;
  bool _loaded = false;
  String? _error;

  bool get _isNew => widget.memberId == null;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _login, _secret]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _load(Member m) {
    _loaded = true;
    _name.text = m.name;
    _role = m.role;
    _groupId = m.groupId;
    _personId = m.personId;
    _admin = m.isAdmin;
    _sales = m.isSales;
    _active = m.active;
    _locale = m.locale;
    _hasLogin = m.login != null;
  }

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (!_isNew) return true;
    return accountProblem(
          role: _role,
          login: _login.text,
          secret: _secret.text,
        ) ==
        null;
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    final done = await showResetSecretDialog(
      context,
      memberId: widget.memberId!,
      role: _role,
    );
    if (done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _role == MemberRole.worker
                ? l10n.resetPinDone
                : l10n.resetPasswordDone,
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(memberRepositoryProvider);
    setState(() => _error = null);
    try {
      if (_isNew) {
        await repo.create(
          NewAccount(
            memberId: newId(),
            name: _name.text.trim(),
            role: _role,
            login: _role == MemberRole.worker
                ? _login.text.trim().toLowerCase()
                : _login.text.trim(),
            secret: _secret.text,
            locale: _locale,
            deviceId: repo.session.deviceId,
            groupId: _groupId,
            personId: _role == MemberRole.worker ? _personId : null,
            isAdmin: _admin,
            isSales: _sales,
          ),
        );
      } else {
        await repo.update(
          widget.memberId!,
          name: _name.text.trim(),
          groupId: _groupId,
          role: _role,
          isAdmin: _admin,
          isSales: _sales,
          active: _active,
          locale: _locale,
        );
      }
      if (!mounted) return;
      showDone(context, AppLocalizations.of(context).doneSaved);
      context.canPop() ? context.pop() : context.go('/more/admin/members');
    } catch (e) {
      setState(() => _error = accountErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_isNew && !_loaded) {
      final member = ref
          .watch(membersProvider)
          .value
          ?.where((m) => m.id == widget.memberId)
          .firstOrNull;
      if (member == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _load(member);
    }
    final groups = ref.watch(groupsProvider).value ?? const <Group>[];
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final roles = ref.watch(personRolesProvider);
    final worker = _role == MemberRole.worker;
    // Nobody removes their own rights: one wrong tap could leave the
    // association without an admin.
    final own = widget.memberId == ref.watch(sessionProvider).value?.userId;
    // A build with no server has no accounts to reset.
    final canReset = ref.watch(memberRepositoryProvider).auth != null;
    final groupName = groups
        .where((g) => g.id == _groupId)
        .map((g) => g.name)
        .firstOrNull;
    final person = people.where((p) => p.id == _personId).firstOrNull;
    Widget pickerRow({
      required Key key,
      required String label,
      required String value,
      required VoidCallback onTap,
    }) => InkWell(
      key: key,
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        child: Text(value),
      ),
    );
    Widget switchRow(String title, bool value, ValueChanged<bool>? onChanged) =>
        SwitchListTile(
          minTileHeight: 56,
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          value: value,
          onChanged: onChanged,
        );
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.memberNew : _name.text),
        actions: [
          if (!_isNew && _hasLogin && canReset)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: worker ? l10n.resetPin : l10n.resetPassword,
                  icon: Icons.key,
                  onTap: _reset,
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: _isNew ? Icons.person_add : Icons.check,
        label: _isNew ? l10n.memberAddAction : l10n.save,
        onPressed: saving || !_valid ? null : () => saveOnce(_save),
      ),
      body: FormBody(
        children: [
          TextField(
            key: const Key('memberName'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.memberName),
          ),
          gap,
          // Nobody changes their own role: one wrong tap could leave the
          // association without an admin.
          ChoiceField<MemberRole>(
            label: l10n.accountRole,
            options: [
              (MemberRole.member, l10n.roleMember),
              (MemberRole.worker, l10n.roleWorker),
            ],
            value: _role,
            onChanged: own
                ? null
                : (r) => setState(() {
                    _role = r;
                    if (_isNew) _locale = r == MemberRole.worker ? 'mg' : 'fr';
                  }),
          ),
          gap,
          pickerRow(
            key: const Key('memberGroup'),
            label: l10n.memberGroup,
            value: groupName ?? l10n.memberNone,
            onTap: () async {
              final id = await pickGroup(context, current: _groupId);
              if (id != null && mounted) {
                setState(() => _groupId = id == noGroup ? null : id);
              }
            },
          ),
          const SizedBox(height: 8),
          switchRow(
            l10n.roleAdmin,
            _admin,
            own ? null : (v) => setState(() => _admin = v),
          ),
          switchRow(l10n.roleSales, _sales, (v) => setState(() => _sales = v)),
          if (!_isNew)
            switchRow(
              l10n.memberActive,
              _active,
              own ? null : (v) => setState(() => _active = v),
            ),
          gap,
          ChoiceField<String>(
            label: l10n.moreLanguage,
            options: [
              ('fr', l10n.languageFrench),
              ('mg', l10n.languageMalagasy),
            ],
            value: _locale,
            onChanged: (v) => setState(() => _locale = v),
          ),
          if (_isNew) ...[
            gap,
            TextField(
              key: const Key('login'),
              controller: _login,
              autocorrect: false,
              keyboardType: worker
                  ? TextInputType.text
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: worker ? l10n.loginUsername : l10n.loginEmail,
              ),
            ),
            gap,
            TextField(
              key: const Key('secret'),
              controller: _secret,
              obscureText: true,
              keyboardType: worker
                  ? TextInputType.number
                  : TextInputType.visiblePassword,
              inputFormatters: worker
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ]
                  : null,
              decoration: InputDecoration(
                labelText: worker ? l10n.loginPin : l10n.loginPassword,
                helperText: worker ? l10n.pinSixDigits : l10n.passwordTooShort,
              ),
            ),
            if (worker) ...[
              gap,
              pickerRow(
                key: const Key('memberPerson'),
                label: l10n.memberPerson,
                value: person == null
                    ? l10n.memberNone
                    : personLabel(l10n, person, roles[person.id]),
                onTap: () async {
                  final id = await pickPerson(context, current: _personId);
                  if (id != null && mounted) setState(() => _personId = id);
                },
              ),
            ],
          ],
          if (_error != null) ...[
            gap,
            AttentionBand(severity: BandSeverity.danger, text: _error!),
          ],
        ],
      ),
    );
  }
}
