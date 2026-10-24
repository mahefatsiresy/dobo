import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';

/// A pond's latest water reading.
final latestReadingProvider = StreamProvider.family<WaterReading?, String>(
  (ref, pondId) =>
      ref.watch(readingRepositoryProvider).watchLatestWaterReading(pondId),
);
