import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';

/// The phone's session, kept in `local_meta`: which association, member and
/// site it records for, and that member's role. Signing out removes only the
/// member; the association, the site, the device id and every record stay.
class SetupRepository {
  SetupRepository(this.db);

  final AppDatabase db;

  static const _associationKey = 'association_id';
  static const _userKey = 'user_id';
  static const _siteKey = 'site_id';
  static const _roleKey = 'role';
  static const _adminKey = 'is_admin';
  static const _salesKey = 'is_sales';

  /// The session now, or null when nobody is signed in on this phone.
  Future<Session?> currentSession() async {
    final meta = {
      for (final row in await db.select(db.localMeta).get()) row.key: row.value,
    };
    final associationId = meta[_associationKey];
    final userId = meta[_userKey];
    final siteId = meta[_siteKey];
    if (associationId == null || userId == null || siteId == null) {
      return null;
    }
    final row = await (db.select(
      db.members,
    )..where((m) => m.id.equals(userId))).getSingleOrNull();
    // The member row as the server holds it is the truth; a local edit not
    // yet accepted (or refused) never changes what this phone may do.
    // Before the row arrives, what sign-in recorded; a phone from before
    // accounts is its founder's.
    final member = row?.syncState == SyncState.synced ? row : null;
    final role = member?.role ?? _role(meta[_roleKey]) ?? MemberRole.member;
    final admin = member?.isAdmin ?? _flag(meta[_adminKey]) ?? true;
    return Session(
      associationId: associationId,
      userId: userId,
      deviceId: await db.deviceId(),
      siteId: siteId,
      role: role,
      isAdmin: admin,
      // Off the server, the phone's admin also sells (plan M7 Task 8): no
      // one else could record a harvest. Signing in writes the server's
      // flag.
      isSales: member?.isSales ?? _flag(meta[_salesKey]) ?? admin,
      isLinked: meta['linked'] == '1',
    );
  }

  /// The session, again whenever it changes. `local_meta` also holds sync
  /// cursors: writing those must not rebuild everything that reads the
  /// session.
  Stream<Session?> watchSession() => db
      .customSelect('SELECT 1', readsFrom: {db.localMeta, db.members})
      .watch()
      .asyncMap((_) => currentSession())
      .distinct();

  static MemberRole? _role(String? name) =>
      MemberRole.values.where((r) => r.name == name).firstOrNull;

  static bool? _flag(String? value) => value == null ? null : value == '1';

  /// Creates the site and the session. [ids] keeps given association, user
  /// and site ids (an account created from a phone that already records);
  /// otherwise new ones are made.
  Future<Session> completeSetup({
    required String siteName,
    String? locationNote,
    Session? ids,
    MemberRole role = MemberRole.member,
    bool isAdmin = true,

    /// Defaults to [isAdmin]: off the server, the admin also sells.
    bool? isSales,
  }) => db.transaction(() async {
    if (await currentSession() != null) {
      throw StateError('Setup already done');
    }
    final deviceId = await db.deviceId();
    final associationId = ids?.associationId ?? newId();
    final userId = ids?.userId ?? newId();
    final siteId = ids?.siteId ?? newId();
    await db
        .into(db.sites)
        .insert(
          SitesCompanion.insert(
            id: Value(siteId),
            associationId: associationId,
            enteredBy: userId,
            deviceId: deviceId,
            name: siteName,
            locationNote: Value(locationNote),
          ),
        );
    await _write({
      _associationKey: associationId,
      _userKey: userId,
      _siteKey: siteId,
      _roleKey: role.name,
      _adminKey: isAdmin ? '1' : '0',
      _salesKey: (isSales ?? isAdmin) ? '1' : '0',
    });
    return (await currentSession())!;
  });

  /// Records who signed in, with the role the server gave.
  Future<void> writeSignIn({
    required String associationId,
    required String memberId,
    required String siteId,
    required MemberRole role,
    required bool isAdmin,
    required bool isSales,
  }) => _write({
    _associationKey: associationId,
    _userKey: memberId,
    _siteKey: siteId,
    _roleKey: role.name,
    _adminKey: isAdmin ? '1' : '0',
    _salesKey: isSales ? '1' : '0',
  });

  /// Signs the member out of this phone; everything else stays.
  Future<void> clearUser() => (db.delete(
    db.localMeta,
  )..where((m) => m.key.isIn([_userKey, _roleKey, _adminKey, _salesKey]))).go();

  Future<void> _write(Map<String, String> values) => db.batch((b) {
    for (final e in values.entries) {
      b.insert(
        db.localMeta,
        LocalMetaCompanion.insert(key: e.key, value: e.value),
        mode: InsertMode.insertOrReplace,
      );
    }
  });
}
