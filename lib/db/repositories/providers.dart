import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database.dart';
import '../database_provider.dart';
import '../session.dart';
import 'batch_repository.dart';
import 'daily_log_repository.dart';
import 'health_repository.dart';
import 'person_repository.dart';
import 'pond_repository.dart';
import 'reading_repository.dart';
import 'setup_repository.dart';
import 'visit_repository.dart';

final setupRepositoryProvider = Provider<SetupRepository>(
  (ref) => SetupRepository(ref.watch(databaseProvider)),
);

/// Null until first-launch setup is done.
final sessionProvider = FutureProvider<Session?>(
  (ref) => ref.watch(setupRepositoryProvider).currentSession(),
);

/// The session of a phone that is set up. Only read below the member shell,
/// which the router shows once [sessionProvider] has a value.
final _readySessionProvider = Provider<Session>(
  (ref) => ref.watch(sessionProvider).requireValue!,
);

final personRepositoryProvider = Provider<PersonRepository>(
  (ref) => PersonRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final pondRepositoryProvider = Provider<PondRepository>(
  (ref) => PondRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final batchRepositoryProvider = Provider<BatchRepository>(
  (ref) => BatchRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

/// This phone's open visit, if any (SPEC F5).
final openVisitProvider = StreamProvider<Visit?>(
  (ref) => ref.watch(visitRepositoryProvider).watchOpen(),
);

/// The open visit's id, stamped on every record entered while it is open.
final _visitIdProvider = Provider<String?>(
  (ref) => ref.watch(openVisitProvider).value?.id,
);

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => DailyLogRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    visitId: ref.watch(_visitIdProvider),
  ),
);

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => ReadingRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    visitId: ref.watch(_visitIdProvider),
  ),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    visitId: ref.watch(_visitIdProvider),
  ),
);

final observationRepositoryProvider = Provider<ObservationRepository>(
  (ref) => ObservationRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    visitId: ref.watch(_visitIdProvider),
  ),
);
