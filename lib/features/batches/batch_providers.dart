import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/providers.dart';

final batchHistoryProvider = StreamProvider.family<List<BatchEvent>, String>(
  (ref, batchId) => ref.watch(batchRepositoryProvider).watchHistory(batchId),
);

/// Every pond of the site, archived ones included, by id: history keeps
/// naming the ponds fish went through.
final allPondsByIdProvider = StreamProvider<Map<String, Pond>>(
  (ref) => ref
      .watch(pondRepositoryProvider)
      .watchAll()
      .map((ponds) => {for (final p in ponds) p.id: p}),
);
