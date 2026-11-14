import '../../db/ids.dart';
import '../../domain/types.dart';
import '../../sync/auth_gateway.dart';

/// The server, as the web console sees it (SPEC F16). Online only: reads
/// under row-level security, writes as one more device through `sync_push`
/// with the phones' record rules, accounts through the edge functions.
///
/// No network throws `SyncOffline`; a refused write throws
/// [ConsoleWriteFailed]; a refused account action throws [AuthFailed].
abstract interface class ConsoleApi {
  bool get hasSession;
  Future<void> signIn(String email, String password);
  Future<void> signOut();

  /// The signed-in account's member row and association. Throws
  /// [AuthFailed] (`no_member`) when there is none or it is deactivated.
  Future<ConsoleMe> me();

  /// Founds the association (M9 plan Decision 3: a retry after a lost
  /// answer finishes it). Signed in as the founder afterwards.
  Future<void> foundAssociation(Founding f);

  Future<void> renameAssociation(String name);

  Future<List<GroupRow>> groups();
  Future<void> saveGroup(GroupRow g, {bool isNew = false});

  Future<List<MemberRow>> members();
  Future<void> saveMember(MemberRow m);

  /// Pushes the account's person first, then creates the account with it
  /// (M9 plan Decision 8).
  Future<void> createAccount(NewAccount a);
  Future<void> resetSecret(String memberId, String secret);

  Future<List<PersonRow>> people();
  Future<void> savePerson(PersonRow p, {bool isNew = false});
}

/// The server refused a write: a SQLSTATE (`42501`) or a code the server
/// raised (`last_admin`).
class ConsoleWriteFailed implements Exception {
  const ConsoleWriteFailed(this.code);

  final String code;

  @override
  String toString() => 'ConsoleWriteFailed($code)';
}

/// Who is signed in to the console.
class ConsoleMe {
  const ConsoleMe({
    required this.memberId,
    required this.associationId,
    required this.associationName,
    required this.name,
    required this.role,
    required this.isAdmin,
    required this.active,
    required this.locale,
  });

  final String memberId;
  final String associationId;
  final String associationName;
  final String name;
  final MemberRole role;
  final bool isAdmin;
  final bool active;
  final String locale;

  /// Only active admins use the console in v1 (SPEC F16).
  bool get mayUseConsole => isAdmin && active && role == MemberRole.member;
}

/// What the founding page sends, with ids planned once (M9 plan Decision 2)
/// so a retry sends the same ones.
class Founding {
  const Founding({
    required this.code,
    required this.email,
    required this.password,
    required this.founderName,
    required this.associationName,
    required this.groupName,
    required this.siteName,
    required this.locationNote,
    required this.associationId,
    required this.groupId,
    required this.siteId,
    required this.memberId,
    required this.personId,
  });

  factory Founding.planned({
    required String code,
    required String email,
    required String password,
    required String founderName,
    required String associationName,
    required String groupName,
    required String siteName,
    required String? locationNote,
  }) {
    final memberId = newId();
    return Founding(
      code: code,
      email: email,
      password: password,
      founderName: founderName,
      associationName: associationName,
      groupName: groupName,
      siteName: siteName,
      locationNote: locationNote,
      associationId: newId(),
      groupId: newId(),
      siteId: newId(),
      memberId: memberId,
      personId: accountPersonId(memberId),
    );
  }

  final String code;
  final String email;
  final String password;
  final String founderName;
  final String associationName;
  final String groupName;
  final String siteName;
  final String? locationNote;
  final String associationId;
  final String groupId;
  final String siteId;
  final String memberId;
  final String personId;

  /// The same planned ids with what the form now says.
  Founding withForm({
    required String code,
    required String email,
    required String password,
    required String founderName,
    required String associationName,
    required String groupName,
    required String siteName,
    required String? locationNote,
  }) => Founding(
    code: code,
    email: email,
    password: password,
    founderName: founderName,
    associationName: associationName,
    groupName: groupName,
    siteName: siteName,
    locationNote: locationNote,
    associationId: associationId,
    groupId: groupId,
    siteId: siteId,
    memberId: memberId,
    personId: personId,
  );

  Map<String, Object?> toJson(String deviceId) => {
    'code': code,
    'email': email.trim().toLowerCase(),
    'password': password,
    'founderName': founderName.trim(),
    'associationName': associationName.trim(),
    'groupName': groupName.trim(),
    'siteName': siteName.trim(),
    'locationNote': locationNote?.trim(),
    'associationId': associationId,
    'groupId': groupId,
    'siteId': siteId,
    'memberId': memberId,
    'personId': personId,
    'deviceId': deviceId,
  };
}

/// A family branch (SPEC §3). [raw] is the server row it was read from.
class GroupRow {
  const GroupRow({required this.id, required this.name, this.raw = const {}});

  factory GroupRow.fromJson(Map<String, Object?> j) =>
      GroupRow(id: j['id']! as String, name: j['name']! as String, raw: j);

  final String id;
  final String name;
  final Map<String, Object?> raw;

  GroupRow copyWith({String? name}) =>
      GroupRow(id: id, name: name ?? this.name, raw: raw);

  Map<String, Object?> get fields => {'name': name};
}

/// A member's or worker's account row (SPEC §4).
class MemberRow {
  const MemberRow({
    required this.id,
    required this.name,
    required this.groupId,
    required this.personId,
    required this.role,
    required this.isAdmin,
    required this.isSales,
    required this.active,
    required this.locale,
    required this.login,
    this.raw = const {},
  });

  factory MemberRow.fromJson(Map<String, Object?> j) => MemberRow(
    id: j['id']! as String,
    name: j['name']! as String,
    groupId: j['group_id'] as String?,
    personId: j['person_id'] as String?,
    role: MemberRole.values.byName(j['role']! as String),
    isAdmin: j['is_admin']! as bool,
    isSales: j['is_sales']! as bool,
    active: j['active']! as bool,
    locale: j['locale']! as String,
    login: j['login'] as String?,
    raw: j,
  );

  final String id;
  final String name;
  final String? groupId;
  final String? personId;
  final MemberRole role;
  final bool isAdmin;
  final bool isSales;
  final bool active;
  final String locale;

  /// Email for a member, username for a worker; null without an account.
  final String? login;
  final Map<String, Object?> raw;

  static const _keep = Object();

  MemberRow copyWith({
    String? name,
    Object? groupId = _keep,
    MemberRole? role,
    bool? isAdmin,
    bool? isSales,
    bool? active,
    String? locale,
  }) => MemberRow(
    id: id,
    name: name ?? this.name,
    groupId: identical(groupId, _keep) ? this.groupId : groupId as String?,
    personId: personId,
    role: role ?? this.role,
    isAdmin: isAdmin ?? this.isAdmin,
    isSales: isSales ?? this.isSales,
    active: active ?? this.active,
    locale: locale ?? this.locale,
    login: login,
    raw: raw,
  );

  Map<String, Object?> get fields => {
    'name': name,
    'group_id': groupId,
    'role': role.name,
    'is_admin': isAdmin,
    'is_sales': isSales,
    'active': active,
    'locale': locale,
  };
}

/// Any human the farm records name (SPEC §4 `Person`).
class PersonRow {
  const PersonRow({
    required this.id,
    required this.name,
    this.phone,
    this.note,
    this.active = true,
    this.raw = const {},
  });

  factory PersonRow.fromJson(Map<String, Object?> j) => PersonRow(
    id: j['id']! as String,
    name: j['name']! as String,
    phone: j['phone'] as String?,
    note: j['note'] as String?,
    active: j['active']! as bool,
    raw: j,
  );

  final String id;
  final String name;
  final String? phone;
  final String? note;
  final bool active;
  final Map<String, Object?> raw;

  static const _keep = Object();

  PersonRow copyWith({
    String? name,
    Object? phone = _keep,
    Object? note = _keep,
    bool? active,
  }) => PersonRow(
    id: id,
    name: name ?? this.name,
    phone: identical(phone, _keep) ? this.phone : phone as String?,
    note: identical(note, _keep) ? this.note : note as String?,
    active: active ?? this.active,
    raw: raw,
  );

  Map<String, Object?> get fields => {
    'name': name,
    'phone': phone,
    'note': note,
    'active': active,
  };
}
