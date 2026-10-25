import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dates.dart';

/// The clock; tests replace it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today in Madagascar, as a provider that moves on at the farm's midnight
/// and when the app comes back to the foreground: a worker phone left on
/// overnight must not show yesterday's ticks.
final farmTodayProvider = NotifierProvider<FarmToday, DateTime>(FarmToday.new);

class FarmToday extends Notifier<DateTime> {
  Timer? _midnight;

  @override
  DateTime build() {
    ref.onDispose(() => _midnight?.cancel());
    _scheduleMidnight();
    return _today();
  }

  /// Re-reads the clock (app resumed, or midnight passed).
  void refresh() {
    final today = _today();
    if (today != state) state = today;
    _scheduleMidnight();
  }

  DateTime _today() => farmDate(ref.read(clockProvider)().toUtc());

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = ref.read(clockProvider)().toUtc();
    final farmNow = now.add(farmUtcOffset);
    final nextMidnight = DateTime.utc(
      farmNow.year,
      farmNow.month,
      farmNow.day + 1,
    ).subtract(farmUtcOffset);
    _midnight = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      refresh,
    );
  }
}
