import 'package:drift/drift.dart';

/// Device-local key/value settings. Never synced.
class LocalMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
