import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import '../db/repositories/providers.dart';
import 'providers.dart';
import 'sync_api.dart';
import 'sync_engine.dart';

enum SyncRunState {
  idle,
  running,

  /// No network: everything stays on the phone until next time.
  offline,

  /// The account's session ended; someone must sign in again.
  signedOut,

  /// A phone set up before accounts: create the association's account.
  unlinked,

  /// A build with no server.
  notConfigured,

  /// The server answered with something unexpected.
  failed,
}

class SyncView {
  const SyncView(this.state, {this.error});

  final SyncRunState state;
  final String? error;
}

/// Decides when to sync (plan Decision 11): the app calls [syncNow] at
/// start, on resume, after sign-in and on "Synchroniser", and [resume]
/// keeps a 5-minute timer while the app is in the foreground.
class SyncController extends Notifier<SyncView> {
  static const interval = Duration(minutes: 5);

  Future<void>? _running;
  Timer? _timer;

  @override
  SyncView build() {
    ref.onDispose(() => _timer?.cancel());
    return SyncView(_blocked() ?? SyncRunState.idle);
  }

  /// Why a sync can't run now, or null when it can.
  SyncRunState? _blocked() {
    final auth = ref.read(authGatewayProvider);
    if (ref.read(syncApiProvider) == null || auth == null) {
      return SyncRunState.notConfigured;
    }
    final session = ref.read(sessionProvider).value;
    if (session == null) return SyncRunState.signedOut;
    if (!session.isLinked) return SyncRunState.unlinked;
    if (!auth.hasSession) return SyncRunState.signedOut;
    return null;
  }

  /// Syncs now; while a sync runs, asking again returns that one.
  Future<void> syncNow() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<void> _run() async {
    final blocked = _blocked();
    if (blocked != null) {
      state = SyncView(blocked);
      return;
    }
    state = const SyncView(SyncRunState.running);
    try {
      await SyncEngine(
        ref.read(databaseProvider),
        ref.read(syncApiProvider)!,
      ).run();
      state = const SyncView(SyncRunState.idle);
    } on SyncOffline {
      state = const SyncView(SyncRunState.offline);
    } on SyncSignedOut {
      state = const SyncView(SyncRunState.signedOut);
    } catch (e) {
      state = SyncView(SyncRunState.failed, error: '$e');
    }
  }

  /// Puts refused rows back in the queue and syncs.
  Future<void> retryRejected() async {
    await retryRejectedRows(ref.read(databaseProvider));
    await syncNow();
  }

  /// Foreground: sync every [interval].
  void resume() {
    _timer?.cancel();
    _timer = _blocked() == SyncRunState.notConfigured
        ? null
        : Timer.periodic(interval, (_) => syncNow());
  }

  /// Background: no timer.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncView>(
  SyncController.new,
);
