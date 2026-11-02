import 'package:drift/drift.dart';

import '../sync_columns.dart';

/// A published visit report (SPEC F8): a frozen snapshot of what the
/// member saw, as JSON (`ReportContent`). One per visit.
@DataClassName('VisitReport')
class VisitReports extends Table with SyncedRow, EventRow {
  TextColumn get visitId => text()();
  TextColumn get siteId => text()();

  /// Farm days covered, both included (`farmDateToUtc`).
  DateTimeColumn get periodFrom => dateTime()();
  DateTimeColumn get periodTo => dateTime()();
  TextColumn get content => text()();
}
