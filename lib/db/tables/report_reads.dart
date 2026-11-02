import 'package:drift/drift.dart';

/// Reports opened on this phone. Never synced.
class ReportReads extends Table {
  TextColumn get reportId => text()();
  DateTimeColumn get readAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {reportId};
}
