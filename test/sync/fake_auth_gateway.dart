import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/sync_api.dart';

/// Accounts without a server: one member to sign in as, a password to
/// check, and a switch for having no network.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.member, this.password, this.existingEmails = const {}});

  /// Who [myMember] says is signed in.
  RemoteMember? member;

  /// The only accepted password or PIN; null accepts any.
  String? password;

  /// Emails [signUp] refuses as taken.
  final Set<String> existingEmails;

  /// Every call fails as if the phone had no network.
  bool offline = false;

  /// The next createAssociation is applied, then its answer is lost.
  bool loseNextAssociationAnswer = false;

  bool signedIn = false;
  final _signedUp = <String>{};
  String? lastEmail;
  final createdAssociations = <Map<String, String>>[];
  final createdAccounts = <NewAccount>[];

  void _net() {
    if (offline) throw SyncOffline();
  }

  @override
  bool get hasSession => signedIn;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _net();
    if (this.password != null && password != this.password) {
      throw const AuthFailed('invalid_credentials');
    }
    lastEmail = email;
    signedIn = true;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    _net();
    if (existingEmails.contains(email) || _signedUp.contains(email)) {
      throw const AuthFailed('user_already_exists');
    }
    _signedUp.add(email);
    lastEmail = email;
    signedIn = true;
  }

  @override
  Future<void> signOut() async => signedIn = false;

  @override
  Future<RemoteMember> myMember() async {
    _net();
    return member ?? (throw const AuthFailed('no_member'));
  }

  @override
  Future<void> createAssociation({
    required String associationId,
    required String associationName,
    required String groupId,
    required String groupName,
    required String memberId,
    required String memberName,
    required String locale,
    required String deviceId,
  }) async {
    _net();
    createdAssociations.add({
      'associationId': associationId,
      'associationName': associationName,
      'groupId': groupId,
      'groupName': groupName,
      'memberId': memberId,
      'memberName': memberName,
      'locale': locale,
      'deviceId': deviceId,
    });
    member = RemoteMember(
      id: memberId,
      associationId: associationId,
      associationName: associationName,
      siteId: null,
      name: memberName,
      role: MemberRole.member,
      isAdmin: true,
      isSales: false,
      locale: locale,
    );
    if (loseNextAssociationAnswer) {
      loseNextAssociationAnswer = false;
      throw SyncOffline();
    }
  }

  @override
  Future<Map<String, Object?>> createAccount(NewAccount account) async {
    _net();
    createdAccounts.add(account);
    final now = DateTime.utc(2026, 3, 1, 12).toIso8601String();
    return {
      'id': account.memberId,
      'association_id': member?.associationId,
      'entered_by': member?.id,
      'observed_by': null,
      'created_at_device': now,
      'device_id': account.deviceId,
      'server_received_at': now,
      'server_seq': 100 + createdAccounts.length,
      'updated_at_device': now,
      'name': account.name,
      'group_id': account.groupId,
      'person_id': account.personId,
      'role': account.role.name,
      'is_admin': account.isAdmin,
      'is_sales': account.isSales,
      'active': true,
      'locale': account.locale,
      'login': account.login,
      'user_id': 'u-${account.memberId}',
    };
  }
}

/// A member of association [associationId] for [FakeAuthGateway.member].
RemoteMember remoteMember({
  String id = 'm1',
  String associationId = 'a1',
  String? siteId = 's1',
  MemberRole role = MemberRole.member,
  bool isAdmin = false,
  String locale = 'fr',
}) => RemoteMember(
  id: id,
  associationId: associationId,
  associationName: 'Famille',
  siteId: siteId,
  name: role == MemberRole.worker ? 'Rakoto' : 'Soa',
  role: role,
  isAdmin: isAdmin,
  isSales: false,
  locale: locale,
);
