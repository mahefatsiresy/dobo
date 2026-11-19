import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../common/farm_today.dart';

/// The current log of a pond on a farm date, if any.
final dailyLogForDayProvider = FutureProvider.autoDispose
    .family<DailyLog?, (String, DateTime)>(
      (ref, key) =>
          ref.watch(dailyLogRepositoryProvider).forDay(key.$1, key.$2),
    );

/// Ponds already logged today.
final loggedTodayProvider = StreamProvider<Set<String>>(
  (ref) => ref
      .watch(dailyLogRepositoryProvider)
      .watchLoggedPondsOn(ref.watch(farmTodayProvider)),
);

/// Today's current log of a pond, the newest when two phones logged it;
/// follows corrections, transcriptions and sync as they land.
final todayLogProvider = StreamProvider.family<DailyLog?, String>(
  (ref, pondId) => ref
      .watch(dailyLogRepositoryProvider)
      .watchCurrentForDay(pondId, ref.watch(farmTodayProvider))
      .map((logs) => logs.firstOrNull),
);
