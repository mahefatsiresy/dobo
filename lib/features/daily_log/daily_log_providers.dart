import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../ponds/pond_overview.dart';

/// The current log of a pond on a farm date, if any.
final dailyLogForDayProvider = FutureProvider.autoDispose
    .family<DailyLog?, (String, DateTime)>(
      (ref, key) =>
          ref.watch(dailyLogRepositoryProvider).forDay(key.$1, key.$2),
    );

/// Ponds already logged today.
final loggedTodayProvider = StreamProvider<Set<String>>(
  (ref) =>
      ref.watch(dailyLogRepositoryProvider).watchLoggedPondsOn(farmToday()),
);
