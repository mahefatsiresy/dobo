import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import 'account_errors.dart';

/// Sign in (needs the network once): a member with email and password, a
/// worker with username and a 6-digit PIN on the number pad.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.worker});

  final bool worker;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _secret = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await ref
          .read(accountRepositoryProvider)!
          .signIn(
            login: _login.text,
            secret: _secret.text,
            worker: widget.worker,
          );
      if (mounted) context.go(widget.worker ? '/worker' : '/ponds');
    } catch (e) {
      setState(() => _error = accountErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final worker = widget.worker;
    return Scaffold(
      appBar: AppBar(
        title: Text(worker ? l10n.welcomeWorker : l10n.loginTitle),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            TextFormField(
              key: const Key('login'),
              controller: _login,
              autocorrect: false,
              keyboardType: worker
                  ? TextInputType.text
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: worker ? l10n.loginUsername : l10n.loginEmail,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
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
              ),
              validator: (v) => worker && (v ?? '').length != 6
                  ? l10n.pinSixDigits
                  : (v ?? '').isEmpty
                  ? l10n.fieldRequired
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('signIn'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: saving ? null : () => saveOnce(_signIn),
              child: Text(l10n.loginSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
