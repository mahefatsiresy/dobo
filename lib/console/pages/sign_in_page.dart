import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../console_errors.dart';
import '../console_providers.dart';

/// Admins sign in to the console (SPEC F16) with their email and password.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(consoleSessionProvider.notifier)
          .signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = consoleErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notice = switch (ref.watch(consoleNoticeProvider)) {
      'admins_only' => l10n.consoleAdminsOnly,
      'idle' => l10n.consoleIdleNotice,
      _ => null,
    };
    final message = _error ?? notice;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.consoleSignInTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('consoleEmail'),
                    controller: _email,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.loginEmail),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('consolePassword'),
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _busy ? null : _signIn(),
                    decoration: InputDecoration(labelText: l10n.loginPassword),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('consoleSignIn'),
                    onPressed: _busy ? null : _signIn,
                    child: Text(l10n.loginSubmit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
