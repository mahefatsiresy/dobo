import 'types.dart';

/// Sign-in rules, the same as the server's edge functions (SPEC F14, F16):
/// a member has an email and a password, a worker a username and a PIN.
/// The problems are the server's error codes.
const minPasswordLength = 8;
const pinLength = 6;

final _username = RegExp(r'^[a-z0-9._-]{3,30}$');
final _email = RegExp(r'^[^@\s]+@[^@\s]+$');
final _pin = RegExp('^\\d{$pinLength}\$');

/// `bad_login`, `bad_secret`, or null when both are fine. The login is
/// checked trimmed and lowercased, as it is sent.
String? accountProblem({
  required MemberRole role,
  required String login,
  required String secret,
}) {
  final l = login.trim().toLowerCase();
  final loginOk = role == MemberRole.worker
      ? _username.hasMatch(l)
      : _email.hasMatch(l);
  if (!loginOk) return 'bad_login';
  return secretProblem(role: role, secret: secret);
}

/// `bad_secret`, or null: a 6-digit PIN for a worker, a password of at
/// least [minPasswordLength] characters for a member.
String? secretProblem({required MemberRole role, required String secret}) {
  final ok = role == MemberRole.worker
      ? _pin.hasMatch(secret)
      : secret.length >= minPasswordLength;
  return ok ? null : 'bad_secret';
}
