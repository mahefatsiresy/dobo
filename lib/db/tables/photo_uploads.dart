import 'package:drift/drift.dart';

/// This phone's photo uploads: done when [uploadedAt] is set, otherwise
/// waiting, with the last [error] (`cap`, …). Never synced.
class PhotoUploads extends Table {
  TextColumn get photoKey => text()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {photoKey};
}
