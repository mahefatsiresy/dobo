import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database_provider.dart';
import '../../db/repositories/providers.dart';

/// The signed-in member's language (SPEC §9): their member row's, or
/// before it arrives, Malagasy for a worker and French for a member. Null
/// when nobody is signed in.
final accountLocaleProvider = StreamProvider<Locale?>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return (db.select(db.members)..where((m) => m.id.equals(session.userId)))
      .watchSingleOrNull()
      .map((m) => Locale(m?.locale ?? (session.isWorker ? 'mg' : 'fr')))
      .distinct();
});
