import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_api.dart';

/// Runs [call] against Supabase, turning a missing network into
/// [SyncOffline] and an ended session into [SyncSignedOut].
Future<T> guardServer<T>(Future<T> Function() call) async {
  try {
    return await call().timeout(const Duration(seconds: 30));
  } on SocketException {
    throw SyncOffline();
  } on TimeoutException {
    throw SyncOffline();
  } on HttpException {
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
  }
}
