import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../sync_columns.dart';

/// A photo on an observation, a health event or a visit (SPEC §8). The file
/// stays on the phone that took it; only the row syncs, and the file goes
/// to Storage only when [upload] is set.
@DataClassName('Photo')
class Photos extends Table with SyncedRow, EventRow {
  TextColumn get ownerKind => textEnum<PhotoOwner>()();
  TextColumn get ownerId => text()();

  /// The first row's id; stays the same across corrections. The file is
  /// `<photoKey>.jpg`.
  TextColumn get photoKey => text()();
  BoolColumn get upload => boolean().withDefault(const Constant(false))();
  IntColumn get bytes => integer()();
}
