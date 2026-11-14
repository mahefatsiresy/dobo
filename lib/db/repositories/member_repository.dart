import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../../sync/auth_gateway.dart';
import '../../sync/sync_engine.dart';
import '../../sync/sync_tables.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';
import 'person_repository.dart';

/// Members and their accounts (SPEC F14). Editing works offline and syncs
/// like any reference row; only creating an account and resetting its
/// password or PIN need the network.
class MemberRepository {
  MemberRepository(this.db, this.session, this.auth);

  final AppDatabase db;
  final Session session;

  /// Null in a build with no server: accounts can't be created.
  final AuthGateway? auth;

  /// By group name (members without a group last), then by name.
  Stream<List<Member>> watchAll() {
    final q =
        db.select(db.members).join([
          leftOuterJoin(db.groups, db.groups.id.equalsExp(db.members.groupId)),
        ])..orderBy([
          OrderingTerm(expression: db.groups.name.isNull()),
          OrderingTerm.asc(db.groups.name.lower()),
          OrderingTerm.asc(db.members.name.lower()),
        ]);
    return q.watch().map(
      (rows) => [for (final r in rows) r.readTable(db.members)],
    );
  }

  Future<void> update(
    String id, {
    required String name,
    String? groupId,
    required MemberRole role,
    required bool isAdmin,
    required bool isSales,
    required bool active,
    required String locale,
  }) => db.transaction(() async {
    final row = await (db.update(db.members)..where((m) => m.id.equals(id)))
        .writeReturning(
          MembersCompanion(
            name: Value(name),
            groupId: Value(groupId),
            role: Value(role),
            isAdmin: Value(isAdmin),
            isSales: Value(isSales),
            active: Value(active),
            locale: Value(locale),
            deviceId: Value(session.deviceId),
            updatedAtDevice: Value(utcNow()),
            syncState: const Value(SyncState.pending),
          ),
        );
    // The account's name is the person's name: renamed here only.
    final personId = row.singleOrNull?.personId;
    if (personId == null) return;
    await (db.update(
      db.people,
    )..where((p) => p.id.equals(personId) & p.name.equals(name).not())).write(
      PeopleCompanion(
        name: Value(name),
        deviceId: Value(session.deviceId),
        updatedAtDevice: Value(utcNow()),
        syncState: const Value(SyncState.pending),
      ),
    );
  });

  /// The signed-in member's language (SPEC §9), kept on their account.
  Future<void> setOwnLocale(String locale) =>
      (db.update(db.members)..where((m) => m.id.equals(session.userId))).write(
        MembersCompanion(
          locale: Value(locale),
          deviceId: Value(session.deviceId),
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );

  /// Creates the account on the server (online) and keeps its member row.
  Future<String> create(NewAccount account) async {
    final gateway = auth ?? (throw const AuthFailed('no_server'));
    final row = await gateway.createAccount(account);
    await applyServerRow(
      db,
      syncTables(db).singleWhere((t) => t.name == 'members'),
      row,
    );
    // The new account gets its person now rather than at the next sync.
    if (session.isAdmin) {
      await PersonRepository(db, session).ensureAccountPeople();
    }
    return account.memberId;
  }

  /// An admin sets a new password or PIN for [memberId]'s account (online).
  /// Nothing is stored on the phone.
  Future<void> resetSecret(String memberId, String secret) async {
    final gateway = auth ?? (throw const AuthFailed('no_server'));
    await gateway.resetSecret(memberId: memberId, secret: secret);
  }
}

/// Family branches (SPEC §3).
class GroupRepository {
  GroupRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  Stream<List<Group>> watchAll() => (db.select(
    db.groups,
  )..orderBy([(g) => OrderingTerm.asc(g.name.lower())])).watch();

  Future<String> create(String name) async {
    final id = newId();
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: Value(id),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            name: name,
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) =>
      (db.update(db.groups)..where((g) => g.id.equals(id))).write(
        GroupsCompanion(
          name: Value(name),
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );
}
