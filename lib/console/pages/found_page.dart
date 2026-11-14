import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/accounts.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../console_errors.dart';
import '../console_providers.dart';
import '../data/console_api.dart';

/// Founding the association (SPEC F16), once, with the founding code. The
/// page plans its ids once, so a retry after a lost answer sends the same
/// ones and the server finishes the first founding instead of a second.
class FoundPage extends ConsumerStatefulWidget {
  const FoundPage({super.key});

  @override
  ConsumerState<FoundPage> createState() => _FoundPageState();
}

class _FoundPageState extends ConsumerState<FoundPage> {
  final _code = TextEditingController();
  final _association = TextEditingController();
  final _group = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  final _site = TextEditingController();
  final _note = TextEditingController();
  late final _planned = Founding.planned(
    code: '',
    email: '',
    password: '',
    founderName: '',
    associationName: '',
    groupName: '',
    siteName: '',
    locationNote: null,
  );
  bool _busy = false;
  String? _error;

  List<TextEditingController> get _all => [
    _code,
    _association,
    _group,
    _name,
    _email,
    _password,
    _again,
    _site,
    _note,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _differ => _again.text.isNotEmpty && _again.text != _password.text;

  bool get _valid =>
      [
        _code,
        _association,
        _group,
        _name,
        _site,
      ].every((c) => c.text.trim().isNotEmpty) &&
      accountProblem(
            role: MemberRole.member,
            login: _email.text,
            secret: _password.text,
          ) ==
          null &&
      _again.text == _password.text;

  Future<void> _found() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final note = _note.text.trim();
    try {
      await ref
          .read(consoleApiProvider)
          .foundAssociation(
            _planned.withForm(
              code: _code.text.trim(),
              email: _email.text,
              password: _password.text,
              founderName: _name.text,
              associationName: _association.text,
              groupName: _group.text,
              siteName: _site.text,
              locationNote: note.isEmpty ? null : note,
            ),
          );
      await ref.read(consoleSessionProvider.notifier).reload();
    } catch (e) {
      if (mounted) setState(() => _error = consoleErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      bool secret = false,
      String? helper,
      String? error,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: Key(key),
        controller: c,
        obscureText: secret,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consoleFoundTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.consoleFoundIntro),
                const SizedBox(height: 24),
                field('foundCode', _code, l10n.consoleFoundCode),
                field(
                  'foundAssociation',
                  _association,
                  l10n.consoleFoundAssociation,
                ),
                field('foundGroup', _group, l10n.consoleFoundGroup),
                field('foundName', _name, l10n.consoleFoundName),
                field(
                  'foundEmail',
                  _email,
                  l10n.loginEmail,
                  keyboard: TextInputType.emailAddress,
                ),
                field(
                  'foundPassword',
                  _password,
                  l10n.loginPassword,
                  secret: true,
                  helper: l10n.passwordTooShort,
                ),
                field(
                  'foundPasswordAgain',
                  _again,
                  l10n.consoleFoundPasswordAgain,
                  secret: true,
                  error: _differ ? l10n.consolePasswordsDiffer : null,
                ),
                field('foundSite', _site, l10n.setupSiteName),
                field('foundNote', _note, l10n.setupLocationNote),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  key: const Key('foundSubmit'),
                  onPressed: _busy || !_valid ? null : _found,
                  child: Text(l10n.consoleFoundSubmit),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/connexion'),
                  child: Text(l10n.consoleSignInTitle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
