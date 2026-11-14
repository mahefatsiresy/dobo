import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_errors_stub.dart'
    if (dart.library.io) 'network_errors_io.dart';
import 'auth_gateway.dart';
import 'sync_api.dart';

/// Runs [call] against Supabase, turning a missing network into
/// [SyncOffline] and an ended session into [SyncSignedOut].
Future<T> guardServer<T>(Future<T> Function() call) async {
  try {
    return await call().timeout(const Duration(seconds: 30));
  } on TimeoutException {
    throw SyncOffline();
  } on ClientException {
    throw SyncOffline();
  } on AuthRetryableFetchException {
    throw SyncOffline();
  } on PostgrestException catch (e) {
    // PGRST301: the JWT expired or is invalid.
    if (e.code == 'PGRST301' || e.code == '401') throw SyncSignedOut();
    rethrow;
  } on AuthException catch (e) {
    if (e.statusCode == null) throw SyncOffline();
    throw SyncSignedOut();
  } catch (e) {
    // dart:io's SocketException and HttpException, on the phone only.
    if (isIoNetworkError(e)) throw SyncOffline();
    rethrow;
  }
}

/// Signing in through [guardServer]: a refused login is [AuthFailed] with
/// the server's code (`invalid_credentials`), never an ended session; no
/// network is still `SyncOffline`. [guardServer] alone would turn the
/// refusal into `SyncSignedOut`, and the screen would say "no connection".
Future<void> guardSignIn(Future<Object?> Function() call) async {
  AuthApiException? refused;
  await guardServer(() async {
    try {
      await call();
    } on AuthApiException catch (e) {
      refused = e;
    }
  });
  final r = refused;
  if (r != null) throw AuthFailed(r.code ?? 'auth_failed');
}
