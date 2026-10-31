import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import 'account_errors.dart';

/// The founder creates the association and their admin account (needs the
/// network once). On a phone that already records, its site is kept and
/// the site fields are hidden.
class CreateAssociationScreen extends ConsumerStatefulWidget {
  const CreateAssociationScreen({super.key});

  @override
  ConsumerState<CreateAssociationScreen> createState() =>
      _CreateAssociationScreenState();
}

class _CreateAssociationScreenState
    extends ConsumerState<CreateAssociationScreen>
    with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _association = TextEditingController();
  final _group = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _site = TextEditingController();
  final _location = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _association,
      _group,
      _name,
      _email,
      _password,
      _site,
      _location,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    final location = _location.text.trim();
    try {
      await ref
          .read(accountRepositoryProvider)!
          .createAssociation(
            associationName: _association.text,
            groupName: _group.text,
            memberName: _name.text,
            email: _email.text,
            password: _password.text,
            siteName: _site.text,
            locationNote: location.isEmpty ? null : location,
          );
      if (mounted) context.go('/ponds');
    } catch (e) {
      setState(() => _error = accountErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSite = ref.watch(sessionProvider).value != null;
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.fieldRequired : null;
    Widget field(
      TextEditingController c,
      String label, {
      String? Function(String?)? validator,
      bool obscure = false,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createTitle)),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            field(
              _association,
              l10n.createAssociationName,
              validator: required,
            ),
            field(_group, l10n.createGroupName, validator: required),
            field(_name, l10n.createYourName, validator: required),
            field(
              _email,
              l10n.loginEmail,
              validator: required,
              keyboard: TextInputType.emailAddress,
            ),
            field(
              _password,
              l10n.loginPassword,
              obscure: true,
              validator: (v) =>
                  (v ?? '').length < 8 ? l10n.passwordTooShort : null,
            ),
            if (!hasSite) ...[
              field(_site, l10n.setupSiteName, validator: required),
              field(_location, l10n.setupLocationNote),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: saving ? null : () => saveOnce(_create),
              child: Text(l10n.createSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
