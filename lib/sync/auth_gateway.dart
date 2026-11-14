import '../domain/types.dart';

/// Accounts on the server (SPEC §3, F14). Only signing in, creating an
/// account and resetting a secret need the network; everything after works
/// offline. Associations are founded in the web console (F16), never here.
abstract interface class AuthGateway {
  bool get hasSession;

  /// Throws [AuthFailed] for a wrong login, `SyncOffline` with no network.
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();

  /// The signed-in account's member row. Throws [AuthFailed] (`no_member`)
  /// when the account has none or it is deactivated.
  Future<RemoteMember> myMember();

  /// An admin creates someone's account; returns the new member row.
  Future<Map<String, Object?>> createAccount(NewAccount account);

  /// An admin sets a new password or PIN for [memberId]'s account. Throws
  /// [AuthFailed] (`not_admin`, `no_member`, `bad_secret`).
  Future<void> resetSecret({required String memberId, required String secret});
}

/// The signed-in member, as the server knows them.
class RemoteMember {
  const RemoteMember({
    required this.id,
    required this.associationId,
    required this.associationName,
    required this.siteId,
    required this.name,
    required this.role,
    required this.isAdmin,
    required this.isSales,
    required this.locale,
  });

  final String id;
  final String associationId;
  final String associationName;

  /// The association's site (v1 runs one), or null before the founder's
  /// phone has sent it.
  final String? siteId;
  final String name;
  final MemberRole role;
  final bool isAdmin;
  final bool isSales;
  final String locale;
}

/// What an admin fills in to create an account.
class NewAccount {
  const NewAccount({
    required this.memberId,
    required this.name,
    required this.role,
    required this.login,
    required this.secret,
    required this.locale,
    required this.deviceId,
    this.groupId,
    this.personId,
    this.isAdmin = false,
    this.isSales = false,
  });

  final String memberId;
  final String name;
  final MemberRole role;

  /// Email for a member, username for a worker.
  final String login;

  /// Password for a member, 6-digit PIN for a worker.
  final String secret;
  final String locale;
  final String deviceId;
  final String? groupId;
  final String? personId;
  final bool isAdmin;
  final bool isSales;

  Map<String, Object?> toJson() => {
    'memberId': memberId,
    'name': name,
    'role': role.name,
    'login': login,
    'secret': secret,
    'groupId': groupId,
    'personId': personId,
    'isAdmin': isAdmin,
    'isSales': isSales,
    'locale': locale,
    'deviceId': deviceId,
  };
}

/// The server said no: `invalid_credentials`, `user_already_exists`,
/// `no_member`, `login_taken`, `bad_secret`, `not_admin`, `already_member`…
class AuthFailed implements Exception {
  const AuthFailed(this.code);

  final String code;

  @override
  String toString() => 'AuthFailed($code)';
}

/// Workers sign in with a username; the account behind it uses this
/// address, which never receives mail.
String workerEmail(String username) => '$username@ouvriers.dobo.invalid';
