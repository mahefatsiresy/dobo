import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/accounts.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_errors.dart';

/// An admin sets a new password (member) or PIN (worker) for an account
/// (SPEC F14). Online; the admin hands it over in person. Returns true once
/// the server took it.
Future<bool> showResetSecretDialog(
  BuildContext context, {
  required String memberId,
  required MemberRole role,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _ResetSecretDialog(memberId: memberId, role: role),
    ) ??
    false;

class _ResetSecretDialog extends ConsumerStatefulWidget {
  const _ResetSecretDialog({required this.memberId, required this.role});

  final String memberId;
  final MemberRole role;

  @override
  ConsumerState<_ResetSecretDialog> createState() => _ResetSecretDialogState();
}

class _ResetSecretDialogState extends ConsumerState<_ResetSecretDialog> {
  final _secret = TextEditingController();
  bool _sending = false;
  String? _error;

  bool get _worker => widget.role == MemberRole.worker;

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(memberRepositoryProvider)
          .resetSecret(widget.memberId, _secret.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = accountErrorText(l10n, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ok =
        secretProblem(role: widget.role, secret: _secret.text) == null &&
        !_sending;
    return AlertDialog(
      title: Text(_worker ? l10n.resetPin : l10n.resetPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('newSecret'),
            controller: _secret,
            autofocus: true,
            obscureText: true,
            keyboardType: _worker
                ? TextInputType.number
                : TextInputType.visiblePassword,
            inputFormatters: _worker
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(pinLength),
                  ]
                : null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _worker ? l10n.loginPin : l10n.loginPassword,
              helperText: _worker ? l10n.pinSixDigits : l10n.passwordTooShort,
            ),
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
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirmReset'),
          style: FilledButton.styleFrom(minimumSize: const Size(56, 56)),
          onPressed: ok ? _send : null,
          child: Text(l10n.resetConfirm),
        ),
      ],
    );
  }
}
