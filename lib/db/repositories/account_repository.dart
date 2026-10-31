import 'package:drift/drift.dart';

import '../../sync/auth_gateway.dart';
import '../../sync/sync_engine.dart';
import '../../sync/sync_tables.dart';
import '../../domain/types.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';
import 'setup_repository.dart';

/// Signing in and out, and creating the association (SPEC §3, §7; plan
/// Decisions 2, 3, 12). Records on the phone are never deleted here.
class AccountRepository {
  AccountRepository(this.db, this.setup, this.auth);

  final AppDatabase db;
  final SetupRepository setup;
  final AuthGateway auth;

  /// Set once the phone's session belongs to a server account. A phone set
  /// up before accounts has a session without it.
  static const linkedKey = 'linked';
  static const _lastMemberKey = 'last_member_id';

  Future<String?> _meta(String key) async => (await (db.select(
    db.localMeta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setMeta(String key, String value) => db
      .into(db.localMeta)
      .insert(
        LocalMetaCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrReplace,
      );

  /// Signs in a member (email, password) or a worker (username, PIN). A
  /// phone that holds another association's records refuses before writing
  /// anything (`other_association`).
  Future<void> signIn({
    required String login,
    required String secret,
    required bool worker,
  }) async {
    final email = worker
        ? workerEmail(login.trim().toLowerCase())
        : login.trim().toLowerCase();
    await auth.signIn(email: email, password: secret);
    final RemoteMember me;
    try {
      me = await auth.myMember();
      final bound = await _meta('association_id');
      if (bound != null && bound != me.associationId) {
        throw const AuthFailed('other_association');
      }
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
    final siteId = me.siteId ?? await _meta('site_id');
    if (siteId == null) {
      await auth.signOut();
      throw const AuthFailed('no_site');
    }
    final previous = await _meta(_lastMemberKey) ?? await _meta('user_id');
    await db.transaction(() async {
      await setup.writeSignIn(
        associationId: me.associationId,
        memberId: me.id,
        siteId: siteId,
        role: me.role,
        isAdmin: me.isAdmin,
        isSales: me.isSales,
      );
      await _setMeta(linkedKey, '1');
      await _setMeta(_lastMemberKey, me.id);
      // Rows refused under someone else's role may be this member's to send.
      if (previous != null && previous != me.id) await retryRejectedRows(db);
    });
  }

  /// The founder's first step. On a phone that already records (M2/M3), the
  /// association, member and site keep the ids the phone made.
  Future<void> createAssociation({
    required String associationName,
    required String groupName,
    required String memberName,
    required String email,
    required String password,
    required String siteName,
    String? locationNote,
  }) async {
    final existing = await setup.currentSession();
    // Signed out, but holding an association's records: sign back in to it.
    if (existing == null && await _meta('association_id') != null) {
      throw const AuthFailed('other_association');
    }
    final login = email.trim().toLowerCase();
    try {
      await auth.signUp(email: login, password: password);
    } on AuthFailed catch (e) {
      // An earlier attempt made the account, then the network dropped.
      if (e.code != 'user_already_exists') rethrow;
      await auth.signIn(email: login, password: password);
    }
    final ids = Session(
      associationId: existing?.associationId ?? newId(),
      userId: existing?.userId ?? newId(),
      deviceId: await db.deviceId(),
      siteId: existing?.siteId ?? newId(),
    );
    await auth.createAssociation(
      associationId: ids.associationId,
      associationName: associationName.trim(),
      groupId: newId(),
      groupName: groupName.trim(),
      memberId: ids.userId,
      memberName: memberName.trim(),
      locale: 'fr',
      deviceId: ids.deviceId,
    );
    await db.transaction(() async {
      if (existing == null) {
        await setup.completeSetup(
          siteName: siteName.trim(),
          locationNote: locationNote,
          ids: ids,
        );
      } else {
        await setup.writeSignIn(
          associationId: ids.associationId,
          memberId: ids.userId,
          siteId: ids.siteId,
          role: MemberRole.member,
          isAdmin: true,
          isSales: false,
        );
      }
      await _setMeta(linkedKey, '1');
      await _setMeta(_lastMemberKey, ids.userId);
    });
  }

  /// Rows not yet sent, across every synced table.
  Future<int> pendingCount() async {
    var n = 0;
    for (final t in syncTables(db)) {
      final row = await db
          .customSelect(
            'SELECT count(*) AS n FROM "${t.name}" WHERE sync_state = ?',
            variables: [Variable(SyncState.pending.name)],
          )
          .getSingle();
      n += row.data['n']! as int;
    }
    return n;
  }

  /// Signs out of this phone. Every record, the association and the site
  /// stay; pending rows go out at the next sync.
  Future<void> signOut() async {
    final current = await _meta('user_id');
    if (current != null) await _setMeta(_lastMemberKey, current);
    await auth.signOut();
    await setup.clearUser();
  }
}
