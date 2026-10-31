import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// A person with an account (SPEC §3). Its id is what `entered_by` stores;
/// the link to the Supabase account stays on the server.
@DataClassName('Member')
class Members extends Table with SyncedRow, ReferenceRow {
  TextColumn get name => text()();
  TextColumn get groupId => text().nullable()();

  /// The `Person` this account belongs to, for a worker.
  TextColumn get personId => text().nullable()();
  TextColumn get role => textEnum<MemberRole>()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isSales => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// `fr` or `mg` (SPEC §9).
  TextColumn get locale => text()();

  /// Email for a member, username for a worker.
  TextColumn get login => text().nullable()();
}
