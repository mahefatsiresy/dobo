import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale_controller.dart';
import '../sync/auth_gateway.dart';
import 'console_config.dart';
import 'data/activity_store.dart';
import 'data/console_api.dart';

/// The console's server. `lib/main_web.dart` provides it; tests fake it.
final consoleApiProvider = Provider<ConsoleApi>(
  (ref) => throw StateError('consoleApiProvider is set in main_web.dart'),
);

/// When the admin last used the console; `main_web.dart` keeps it in the
/// browser.
final consoleActivityProvider = Provider<ActivityStore>(
  (ref) => MemoryActivityStore(),
);

/// Now, in UTC (tests set it).
final consoleClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

/// Who is signed in to the console: an active admin, or null (SPEC F16;
/// M9 plan Decision 13). Any other session is signed out at once.
final consoleSessionProvider =
    AsyncNotifierProvider<ConsoleSession, ConsoleMe?>(ConsoleSession.new);

/// Why the sign-in page is showing, when it isn't the admin's own choice:
/// `admins_only` or `idle`.
final consoleNoticeProvider = NotifierProvider<ConsoleNotice, String?>(
  ConsoleNotice.new,
);

class ConsoleNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? notice) => state = notice;
}

class ConsoleSession extends AsyncNotifier<ConsoleMe?> {
  ConsoleApi get _api => ref.read(consoleApiProvider);

  @override
  Future<ConsoleMe?> build() async {
    if (!_api.hasSession) return null;
    // A session left open in a closed tab or a reloaded page: the idle
    // limit still counts from the last use.
    final last = ref.read(consoleActivityProvider).last;
    final now = ref.read(consoleClockProvider)();
    if (last != null && now.difference(last) >= consoleIdleLimit) {
      await _api.signOut();
      _notice('idle');
      return null;
    }
    try {
      return await _accept(await _api.me());
    } on AuthFailed catch (e) {
      await _api.signOut();
      _notice(
        e.code == 'admins_only' || e.code == 'no_member' ? 'admins_only' : null,
      );
      return null;
    }
  }

  /// [me] if they may use the console; otherwise signs out and throws
  /// `AuthFailed('admins_only')`.
  Future<ConsoleMe> _accept(ConsoleMe me) async {
    if (!me.mayUseConsole) {
      await _api.signOut();
      throw const AuthFailed('admins_only');
    }
    ref.read(localeControllerProvider.notifier).set(Locale(me.locale));
    return me;
  }

  void _notice(String? notice) =>
      ref.read(consoleNoticeProvider.notifier).set(notice);

  /// Throws [AuthFailed] (`invalid_credentials`, `admins_only`) or
  /// `SyncOffline`; signed out in every failure.
  Future<void> signIn(String email, String password) async {
    await _api.signIn(email, password);
    ConsoleMe me;
    try {
      me = await _accept(await _api.me());
    } on AuthFailed catch (e) {
      await _api.signOut();
      throw e.code == 'no_member' ? const AuthFailed('admins_only') : e;
    } catch (_) {
      await _api.signOut();
      rethrow;
    }
    _notice(null);
    await touch();
    state = AsyncData(me);
  }

  /// Records a use of the console now.
  Future<void> touch() =>
      ref.read(consoleActivityProvider).touch(ref.read(consoleClockProvider)());

  /// After founding, the founder is already signed in.
  Future<void> reload() async {
    state = AsyncData(await build());
  }

  Future<void> signOut({String? notice}) async {
    await _api.signOut();
    _notice(notice);
    state = const AsyncData(null);
  }
}

/// Signs the console out ("Se déconnecter").
final consoleSignOutProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(consoleSessionProvider.notifier).signOut(),
);

/// The association's lists, read when a page opens and after each write.
final groupsProvider = FutureProvider.autoDispose<List<GroupRow>>(
  (ref) => ref.read(consoleApiProvider).groups(),
);
final membersProvider = FutureProvider.autoDispose<List<MemberRow>>(
  (ref) => ref.read(consoleApiProvider).members(),
);
final peopleProvider = FutureProvider.autoDispose<List<PersonRow>>(
  (ref) => ref.read(consoleApiProvider).people(),
);
