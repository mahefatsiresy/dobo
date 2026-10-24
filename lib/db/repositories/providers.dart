import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_provider.dart';
import '../session.dart';
import 'setup_repository.dart';

final setupRepositoryProvider =
    Provider<SetupRepository>((ref) => SetupRepository(ref.watch(databaseProvider)));

/// Null until first-launch setup is done.
final sessionProvider = FutureProvider<Session?>(
    (ref) => ref.watch(setupRepositoryProvider).currentSession());
