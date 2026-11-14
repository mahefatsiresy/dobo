import 'package:dobo/console/data/console_api.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/sync/auth_gateway.dart';
import 'package:dobo/sync/sync_api.dart';

/// The console's server, in memory: one association, its groups, members
/// and people, a password to check and a switch for having no network.
class FakeConsoleApi implements ConsoleApi {
  FakeConsoleApi({ConsoleMe? me, this.password}) : account = me;

  /// Who signs in; null means the account has no member row.
  ConsoleMe? account;

  /// The only accepted password; null accepts any.
  final String? password;

  /// Every call fails as if there were no network.
  bool offline = false;

  /// The next write fails with this code, as the server would refuse it.
  String? failNextWrite;

  /// The next founding is done, then its answer is lost (no network).
  bool loseNextFoundingAnswer = false;

  bool signedIn = false;
  bool signedOut = false;
  String associationName = 'Famille Rabe';
  final groupRows = <GroupRow>[];
  final memberRows = <MemberRow>[];
  final peopleRows = <PersonRow>[];
  final foundings = <Founding>[];

  /// Every founding sent, refused or not.
  final plannedSeen = <Founding>[];
  final createdAccounts = <NewAccount>[];
  final resets = <(String, String)>[];

  void _net() {
    if (offline) throw SyncOffline();
  }

  void _write() {
    _net();
    final code = failNextWrite;
    if (code != null) {
      failNextWrite = null;
      throw ConsoleWriteFailed(code);
    }
  }

  @override
  bool get hasSession => signedIn;

  @override
  Future<void> signIn(String email, String password) async {
    _net();
    if (this.password != null && password != this.password) {
      throw const AuthFailed('invalid_credentials');
    }
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
    signedOut = true;
  }

  @override
  Future<ConsoleMe> me() async {
    _net();
    if (!signedIn) throw const AuthFailed('no_member');
    return account ?? (throw const AuthFailed('no_member'));
  }

  @override
  Future<void> foundAssociation(Founding f) async {
    plannedSeen.add(f);
    _net();
    foundings.add(f);
    account = ConsoleMe(
      memberId: f.memberId,
      associationId: f.associationId,
      associationName: f.associationName,
      name: f.founderName,
      role: MemberRole.member,
      isAdmin: true,
      active: true,
      locale: 'fr',
    );
    associationName = f.associationName;
    if (loseNextFoundingAnswer) {
      loseNextFoundingAnswer = false;
      throw SyncOffline();
    }
    signedIn = true;
  }

  @override
  Future<void> renameAssociation(String name) async {
    _write();
    associationName = name;
    final me = account;
    if (me != null) {
      account = ConsoleMe(
        memberId: me.memberId,
        associationId: me.associationId,
        associationName: name,
        name: me.name,
        role: me.role,
        isAdmin: me.isAdmin,
        active: me.active,
        locale: me.locale,
      );
    }
  }

  @override
  Future<List<GroupRow>> groups() async {
    _net();
    return [...groupRows]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> saveGroup(GroupRow g, {bool isNew = false}) async {
    _write();
    groupRows
      ..removeWhere((r) => r.id == g.id)
      ..add(g);
  }

  @override
  Future<List<MemberRow>> members() async {
    _net();
    return [...memberRows]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> saveMember(MemberRow m) async {
    _write();
    final i = memberRows.indexWhere((r) => r.id == m.id);
    memberRows[i] = m;
    // The signed-in account reads its own row, as on the server.
    final me = account;
    if (me != null && me.memberId == m.id) {
      account = ConsoleMe(
        memberId: me.memberId,
        associationId: me.associationId,
        associationName: me.associationName,
        name: m.name,
        role: m.role,
        isAdmin: m.isAdmin,
        active: m.active,
        locale: m.locale,
      );
    }
  }

  @override
  Future<void> createAccount(NewAccount a) async {
    _write();
    createdAccounts.add(a);
    memberRows.add(
      MemberRow(
        id: a.memberId,
        name: a.name,
        groupId: a.groupId,
        personId: a.personId,
        role: a.role,
        isAdmin: a.isAdmin,
        isSales: a.isSales,
        active: true,
        locale: a.locale,
        login: a.login,
      ),
    );
  }

  @override
  Future<void> resetSecret(String memberId, String secret) async {
    _write();
    resets.add((memberId, secret));
  }

  @override
  Future<List<PersonRow>> people() async {
    _net();
    return [...peopleRows]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> savePerson(PersonRow p, {bool isNew = false}) async {
    _write();
    peopleRows
      ..removeWhere((r) => r.id == p.id)
      ..add(p);
  }
}

/// An active admin of association a1, for [FakeConsoleApi].
ConsoleMe consoleAdmin({
  MemberRole role = MemberRole.member,
  bool isAdmin = true,
  String locale = 'fr',
}) => ConsoleMe(
  memberId: 'm1',
  associationId: 'a1',
  associationName: 'Famille Rabe',
  name: 'Soa',
  role: role,
  isAdmin: isAdmin,
  active: true,
  locale: locale,
);
