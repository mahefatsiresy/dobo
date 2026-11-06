import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/prep.dart';

/// Every pond's current preparation, by pond id (SPEC F10).
final prepProgressAllProvider = StreamProvider<Map<String, PrepProgress>>(
  (ref) => ref.watch(prepRepositoryProvider).watchAll(),
);

/// One pond's current preparation.
final prepProgressProvider = StreamProvider.family<PrepProgress, String>(
  (ref, pondId) => ref.watch(prepRepositoryProvider).watchProgress(pondId),
);
