import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../database.dart';
import '../database_provider.dart';
import '../photo_files.dart';
import '../session.dart';
import '../../domain/config.dart';
import '../../domain/config_overrides.dart';
import '../../domain/farm_facts.dart';
import '../../sync/providers.dart';
import 'account_repository.dart';
import 'batch_repository.dart';
import 'daily_log_repository.dart';
import 'facts_repository.dart';
import 'health_repository.dart';
import 'member_repository.dart';
import 'person_repository.dart';
import 'photo_repository.dart';
import 'pond_repository.dart';
import 'reading_repository.dart';
import 'report_repository.dart';
import 'settings_repository.dart';
import 'setup_repository.dart';
import 'visit_repository.dart';

final setupRepositoryProvider = Provider<SetupRepository>(
  (ref) => SetupRepository(ref.watch(databaseProvider)),
);

/// Accounts; null in a build with no server, which sets up offline.
final accountRepositoryProvider = Provider<AccountRepository?>((ref) {
  final auth = ref.watch(authGatewayProvider);
  if (auth == null) return null;
  return AccountRepository(
    ref.watch(databaseProvider),
    ref.watch(setupRepositoryProvider),
    auth,
  );
});

/// Null while nobody is signed in on this phone. Follows sign-in, sign-out
/// and role changes arriving with the member row.
final sessionProvider = StreamProvider<Session?>(
  (ref) => ref.watch(setupRepositoryProvider).watchSession(),
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

/// Photo files: the phone's own in documents, downloaded ones in the cache.
final photoFilesProvider = Provider<PhotoFiles>(
  (ref) => PhotoFiles(
    docs: getApplicationDocumentsDirectory,
    cache: getApplicationCacheDirectory,
  ),
);

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    ref.watch(photoFilesProvider),
  ),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => MemberRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
    ref.watch(authGatewayProvider),
  ),
);

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(
    ref.watch(databaseProvider),
    ref.watch(_readySessionProvider),
  ),
);

final settingOverridesProvider = StreamProvider<Map<String, num>>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// The farming numbers for this site: DOMAIN's, with the admins'
/// overrides (SPEC F14). Every screen and calculation reads this.
final domainConfigProvider = Provider<DomainConfig>(
  (ref) => applyOverrides(
    DomainConfig.defaults,
    ref.watch(settingOverridesProvider).value ?? const {},
  ),
);

/// Every current stocking, move, sample and daily log; placements, growth
/// and alerts are all computed from it.
final farmFactsProvider = StreamProvider<FarmFacts>(
  (ref) => watchFarmFacts(ref.watch(databaseProvider)),
);
