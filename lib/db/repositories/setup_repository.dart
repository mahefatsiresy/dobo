import 'package:drift/drift.dart';

import '../database.dart';
import '../ids.dart';
import '../session.dart';

/// First-launch setup: creates the association, the local user and the site
/// (SPEC F1; v1 runs one site). M4 replaces the placeholder ids with the
/// Supabase ones before anything syncs.
class SetupRepository {
  SetupRepository(this.db);

  final AppDatabase db;

  static const _associationKey = 'association_id';
  static const _userKey = 'user_id';
  static const _siteKey = 'site_id';

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
    return Session(
      associationId: associationId,
      userId: userId,
      deviceId: await db.deviceId(),
      siteId: siteId,
    );
  }

  Future<Session> completeSetup({
    required String siteName,
    String? locationNote,
  }) => db.transaction(() async {
    if (await currentSession() != null) {
      throw StateError('Setup already done');
    }
    final session = Session(
      associationId: newId(),
      userId: newId(),
      deviceId: await db.deviceId(),
      siteId: newId(),
    );
    await db
        .into(db.sites)
        .insert(
          SitesCompanion.insert(
            id: Value(session.siteId),
            associationId: session.associationId,
            enteredBy: session.userId,
            deviceId: session.deviceId,
            name: siteName,
            locationNote: Value(locationNote),
          ),
        );
    for (final (key, value) in [
      (_associationKey, session.associationId),
      (_userKey, session.userId),
      (_siteKey, session.siteId),
    ]) {
      await db
          .into(db.localMeta)
          .insert(LocalMetaCompanion.insert(key: key, value: value));
    }
    return session;
  });
}
