import 'package:shared_preferences/shared_preferences.dart';

import '../../db/ids.dart';

const _key = 'dobo_device_id';

/// This browser's device id (M9 plan Decision 16): made once, kept in the
/// browser's storage, stamped on every row the console writes.
Future<String> browserDeviceId(SharedPreferences prefs) async {
  final kept = prefs.getString(_key);
  if (kept != null) return kept;
  final id = newId();
  await prefs.setString(_key, id);
  return id;
}
