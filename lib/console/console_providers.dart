import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signs the console out ("Se déconnecter", or 30 minutes idle).
final consoleSignOutProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);
