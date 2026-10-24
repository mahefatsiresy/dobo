import 'dart:async';

import 'package:drift/drift.dart';

import '../database.dart';

/// Emits [load] now and again whenever one of [tables] changes. Table
/// changes are listened to before the first load starts, so a write that
/// lands during it still triggers a reload.
Stream<T> watchTables<T>(
  AppDatabase db,
  Set<TableInfo<Table, Object?>> tables,
  Future<T> Function() load,
) {
  final updates = db.tableUpdates(TableUpdateQuery.onAllTables(tables));
  StreamSubscription<T>? changes;
  late final StreamController<T> out;
  out = StreamController<T>(
    onListen: () {
      changes = updates
          .asyncMap((_) => load())
          .listen(out.add, onError: out.addError);
      load().then(out.add, onError: out.addError);
    },
    onCancel: () => changes?.cancel(),
  );
  return out.stream;
}
