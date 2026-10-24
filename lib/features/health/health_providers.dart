import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';

final healthEventsProvider = StreamProvider.family<List<HealthEvent>, String>(
  (ref, pondId) => ref.watch(healthRepositoryProvider).watchForPond(pondId),
);

final treatmentsProvider = StreamProvider.family<List<Treatment>, String>(
  (ref, pondId) => ref.watch(healthRepositoryProvider).watchTreatments(pondId),
);
