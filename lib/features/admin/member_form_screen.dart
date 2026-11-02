import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/ids.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/auth_gateway.dart';
import '../account/account_errors.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import '../people/people_providers.dart';
import 'members_screen.dart';

/// A member's account (SPEC F14). Editing works offline; a new account
/// needs the network and a login: email and password for a member,
/// username and 6-digit PIN for a worker.
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
  }

  bool get _valid {
    if (_name.text.trim().isEmpty) return false;
    if (!_isNew) return true;
    final login = _login.text.trim();
    final secret = _secret.text;
    return _role == MemberRole.worker
        ? RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(login.toLowerCase()) &&
              RegExp(r'^\d{6}$').hasMatch(secret)
        : login.contains('@') && secret.length >= 8;
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
      if (mounted) context.pop();
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
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? l10n.memberNew : _name.text)),
      body: FormBody(
        children: [
          TextField(
            key: const Key('memberName'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.memberName),
          ),
          const SizedBox(height: 16),
          SegmentedButton<MemberRole>(
            segments: [
              ButtonSegment(
                value: MemberRole.member,
                label: Text(l10n.roleMember),
              ),
              ButtonSegment(
                value: MemberRole.worker,
                label: Text(l10n.roleWorker),
              ),
            ],
            selected: {_role},
            onSelectionChanged: own
                ? null
                : (s) => setState(() {
                    _role = s.single;
                    if (_isNew) {
                      _locale = _role == MemberRole.worker ? 'mg' : 'fr';
                    }
                  }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            key: const Key('memberGroup'),
            initialValue: _groupId,
            decoration: InputDecoration(labelText: l10n.memberGroup),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.memberNone)),
              for (final g in groups)
                DropdownMenuItem(value: g.id, child: Text(g.name)),
            ],
            onChanged: (v) => setState(() => _groupId = v),
          ),
          SwitchListTile(
            title: Text(l10n.roleAdmin),
            value: _admin,
            onChanged: own ? null : (v) => setState(() => _admin = v),
          ),
          SwitchListTile(
            title: Text(l10n.roleSales),
            value: _sales,
            onChanged: (v) => setState(() => _sales = v),
          ),
          if (!_isNew)
            SwitchListTile(
              title: Text(l10n.memberActive),
              value: _active,
              onChanged: own ? null : (v) => setState(() => _active = v),
            ),
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
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _personId,
                decoration: InputDecoration(labelText: l10n.memberPerson),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.memberNone)),
                  for (final p in people.where((p) => p.active))
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(personLabel(l10n, p, roles[p.id])),
                    ),
                ],
                onChanged: (v) => setState(() => _personId = v),
              ),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('saveMember'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving || !_valid ? null : () => saveOnce(_save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
