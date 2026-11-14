import 'package:shared_preferences/shared_preferences.dart';

/// When the admin last used the console (SPEC F16: 30 minutes without use
/// signs out). Kept in the browser, so a reload or a closed tab doesn't
/// reset the count: the session it would reopen is signed out instead.
abstract interface class ActivityStore {
  DateTime? get last;
  Future<void> touch(DateTime at);
}

/// In memory only: tests, and the default before `main_web.dart` sets the
/// browser's own.
class MemoryActivityStore implements ActivityStore {
  @override
  DateTime? last;

  @override
  Future<void> touch(DateTime at) async => last = at;
}

/// In the browser's storage (local storage on the web).
class PrefsActivityStore implements ActivityStore {
  PrefsActivityStore(this.prefs);

  final SharedPreferences prefs;
  static const _key = 'dobo_last_activity';

  @override
  DateTime? get last {
    final ms = prefs.getInt(_key);
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  @override
  Future<void> touch(DateTime at) =>
      prefs.setInt(_key, at.toUtc().millisecondsSinceEpoch);
}
