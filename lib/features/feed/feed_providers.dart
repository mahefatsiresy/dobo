import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/feed_lots.dart';
import '../common/farm_today.dart';

/// Feed on hand today, lot by lot (SPEC F11).
final feedStockProvider = StreamProvider<FeedStock>(
  (ref) => ref
      .watch(feedRepositoryProvider)
      .watchStock(ref.watch(farmTodayProvider)),
);
