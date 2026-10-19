# M0 + M1: Scaffold and Domain Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter Android app that boots in French or Malagasy on a Drift database carrying the sync columns, plus every DOMAIN.md formula and alert rule as tested pure Dart.

**Architecture:** `lib/domain/` is pure Dart: functions take plain values (ints in grams, local `DateTime`s, a `DomainConfig`) and return values or `Alert`s; it knows nothing about Flutter or the database. `lib/db/` defines Drift tables through two mixins that give every synced row the SPEC §4 columns. The app shell is Riverpod + go_router with ARB localisation and French fallbacks for Malagasy.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2 (installed), flutter_riverpod, go_router, flutter_localizations + intl, drift + drift_flutter + drift_dev + build_runner, uuid.

**Spec:** `CLAUDE.md`, `docs/SPEC.md` (§4 data model, §11 milestones M0–M1), `docs/DOMAIN.md` (all values and rules). Read all three before starting.

## Global Constraints

- Android only: `flutter create --platforms android`; `minSdk = 26`.
- Dart null safety; `analysis_options.yaml` = `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types`. `flutter analyze` reports no issues at the end of every task.
- Nothing under `lib/domain/` imports `package:flutter`, `package:drift` or anything under `lib/db/`.
- Fish and feed weights are `int` grams. Averages are `double` grams. Areas `double` m².
- Domain dates are local (Indian/Antananarivo) `DateTime`s supplied by the caller; day counts use `daysBetween` (Task 4) and nothing else.
- Every farming number comes from `DomainConfig.defaults` (Task 4); no numeric literal for a DOMAIN value appears anywhere else in `lib/`.
- Domain code returns enums and facts, never user-facing text. Text comes from ARB files (Task 2).
- Commits: conventional prefix (`feat:`, `chore:`, `test:`), message body ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Run tests with `flutter test <path>`; the whole suite with `flutter test`.

## Review Focus

1. **Records that contradict each other** (a transcription typo logs 150 deaths in a pond of 100 fish): live count clamps to 0 and reports `inconsistent: true`; biomass is never negative. Test in Task 6.
2. **An empty or zero sample** (form saved with 0 fish or 0 g): `sampleResult` returns `null`, never `NaN` or a division error. Test in Task 6.
3. **A pond with no surface recorded**: density, density alert and prep doses return `null`, no exception. Tests in Tasks 6 and 8.
4. **Malagasy selected**: Material widgets and number formatting fall back to French without throwing. Test in Task 2.
5. **Times near midnight**: 23:59 on day 1 to 00:01 on day 2 counts as 1 day, so "due" alerts don't fire a day late or early. Test in Task 4.

---

## M0 — Scaffold

### Task 1: Flutter project, lints, git

**Files:**
- Create (generated): `pubspec.yaml`, `android/`, `lib/main.dart`, `test/widget_test.dart`
- Modify: `android/app/build.gradle.kts` (`minSdk`), `analysis_options.yaml`

**Interfaces:**
- Produces: package name `dobo`, Android application id `mg.dobo.dobo`.

- [ ] **Step 1: Generate the project in the existing folder** (keeps `CLAUDE.md`, `docs/`, the `.docx`)

Run: `flutter create --project-name dobo --org mg.dobo --platforms android .`
Expected: "All done!" and `lib/main.dart` exists.

- [ ] **Step 2: Set `minSdk = 26`** in `android/app/build.gradle.kts` (replace `flutter.minSdkVersion`).

- [ ] **Step 3: Strict analysis.** `analysis_options.yaml`: include `package:flutter_lints/flutter.yaml`; `analyzer.language` strict-casts/strict-inference/strict-raw-types `true`; `analyzer.exclude`: `**/*.g.dart`, `lib/l10n/app_localizations*.dart`.

- [ ] **Step 4: Verify**

Run: `flutter analyze && flutter test`
Expected: "No issues found!" and the generated counter test passes.

- [ ] **Step 5: Init git and commit**

```bash
git init -b main
git add -A
git commit -m "chore: scaffold Flutter Android app"
```

### Task 2: App shell, localisation and Malagasy fallback

**Files:**
- Create: `l10n.yaml`, `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `lib/l10n/mg_fallback.dart`, `lib/l10n/formatting.dart`, `lib/app.dart`, `lib/router.dart`, `lib/locale_controller.dart`, `lib/features/home/home_screen.dart`
- Modify: `lib/main.dart`, `pubspec.yaml`
- Delete: `test/widget_test.dart`
- Test: `test/app_test.dart`, `test/l10n/formatting_test.dart`

**Interfaces:**
- Produces:
  - `class DoboApp extends ConsumerWidget`, the root widget, wrapped by `ProviderScope` in `main()`.
  - `final localeControllerProvider = NotifierProvider<LocaleController, Locale>`, where `LocaleController.build()` returns `Locale('fr')` and `void set(Locale locale)` switches the language.
  - `final routerProvider = Provider<GoRouter>` with route `/` → `HomeScreen`.
  - `const List<LocalizationsDelegate<dynamic>> mgFallbackDelegates` covering Material, Cupertino and Widgets.
  - `String intlLocaleFor(Locale locale)` returns `'fr'` for `mg`, else the language code.
  - `String formatKg(int grams, Locale locale)`.
  - ARB keys: `appTitle` (fr "Dobo", mg "Dobo"), `homeWelcome` (fr "Bienvenue", mg "Tongasoa").

- [ ] **Step 1: Add dependencies**

Run: `flutter pub add flutter_riverpod go_router intl && flutter pub add flutter_localizations --sdk=flutter`
Then set `flutter: generate: true` in `pubspec.yaml`. `l10n.yaml` sets `arb-dir: lib/l10n`, `template-arb-file: app_fr.arb`, `output-localization-file: app_localizations.dart`.

- [ ] **Step 2: Write the failing tests**

`test/app_test.dart`:
```dart
testWidgets('boots in French', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: DoboApp()));
  await tester.pumpAndSettle();
  expect(find.text('Bienvenue'), findsOneWidget);
});

testWidgets('Malagasy shows mg strings and French Material labels', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: DoboApp()));
  final container = ProviderScope.containerOf(tester.element(find.byType(DoboApp)));
  container.read(localeControllerProvider.notifier).set(const Locale('mg'));
  await tester.pumpAndSettle();
  expect(find.text('Tongasoa'), findsOneWidget);
  expect(tester.takeException(), isNull);
  final ctx = tester.element(find.byType(HomeScreen));
  final fr = await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  expect(MaterialLocalizations.of(ctx).cancelButtonLabel, fr.cancelButtonLabel);
});
```

`test/l10n/formatting_test.dart`:
```dart
expect(intlLocaleFor(const Locale('mg')), 'fr');
expect(intlLocaleFor(const Locale('fr')), 'fr');
expect(formatKg(12500, const Locale('fr')), '12,5 kg');
expect(formatKg(12500, const Locale('mg')), '12,5 kg');
expect(formatKg(3000, const Locale('fr')), '3 kg');
expect(formatKg(500, const Locale('mg')), '0,5 kg');
```

- [ ] **Step 3: Run to verify they fail**

Run: `flutter test test/app_test.dart test/l10n/formatting_test.dart`
Expected: FAIL (compile errors: `DoboApp`, `formatKg` not defined).

- [ ] **Step 4: Implement**

- `mg_fallback.dart`: three delegates whose `isSupported` is true only for `languageCode == 'mg'` and whose `load` returns the corresponding `Global*Localizations.delegate.load(const Locale('fr'))`. `shouldReload` returns false.
- `DoboApp`: `MaterialApp.router` with `locale` from `localeControllerProvider`, `supportedLocales: [Locale('fr'), Locale('mg')]`, and `localizationsDelegates`: `AppLocalizations.delegate`, `...mgFallbackDelegates`, then the three `Global*` delegates. The fallback delegates must come before the Global ones.
- `formatKg`: `NumberFormat('#,##0.#', intlLocaleFor(locale))` on `grams / 1000`, plus `' kg'`.
- `HomeScreen`: shows `appTitle` in the app bar and `homeWelcome` in the body.

- [ ] **Step 5: Run to verify they pass**

Run: `flutter test && flutter analyze`
Expected: all pass, "No issues found!"

- [ ] **Step 6: Commit** `feat: app shell with fr/mg localisation and French fallback for Malagasy`

### Task 3: Drift database with sync columns

**Files:**
- Create: `build.yaml`, `lib/db/ids.dart`, `lib/db/sync_state.dart`, `lib/db/sync_columns.dart`, `lib/db/tables/sites.dart`, `lib/db/tables/local_meta.dart`, `lib/db/database.dart`, `lib/db/database_provider.dart`
- Test: `test/db/database_test.dart`, plus migration tests generated by drift_dev in `test/db/`

**Interfaces:**
- Produces:
  - `String newId()`: a UUIDv7 string.
  - `enum SyncState { pending, synced, rejected }`.
  - `mixin SyncedRow on Table`: `id` (text, `clientDefault(newId)`, primary key), `associationId` text, `enteredBy` text, `observedBy` text nullable, `createdAtDevice` dateTime (`clientDefault` = UTC now), `deviceId` text, `serverReceivedAt` dateTime nullable, `serverSeq` int nullable, `syncState` `textEnum<SyncState>()` default `pending`, `syncError` text nullable.
  - `mixin ReferenceRow on Table` (applied after `SyncedRow`): adds `updatedAtDevice` dateTime (`clientDefault` = UTC now).
  - `mixin EventRow on Table` (applied after `SyncedRow`): adds `recordedAt` dateTime, `supersedesId` text nullable, `isTombstone` bool default false. (First used in M3.)
  - `class Sites extends Table with SyncedRow, ReferenceRow`: `name` text, `locationNote` text nullable.
  - `class LocalMeta extends Table`: `key` text primary key, `value` text. Device-local, never synced.
  - `class AppDatabase extends _$AppDatabase`: `AppDatabase(QueryExecutor e)`, `factory AppDatabase.open()` (uses `driftDatabase(name: 'dobo')`), `schemaVersion => 1`, `Future<String> deviceId()` (reads `LocalMeta['device_id']`, or creates and stores `newId()` on first call).
  - `final databaseProvider = Provider<AppDatabase>` (opens once, closes on dispose).

- [ ] **Step 1: Add dependencies**

Run: `flutter pub add drift drift_flutter uuid && flutter pub add -d drift_dev build_runner`

`build.yaml`: drift options `store_date_time_values_as_text: true`; `databases: { default: lib/db/database.dart }`; `schema_dir: drift_schemas/`; `test_dir: test/db/`.

- [ ] **Step 2: Write the failing test** `test/db/database_test.dart` (uses `AppDatabase(NativeDatabase.memory())`):

```dart
test('site gets a UUIDv7 id, pending state and UTC timestamps', () async {
  final id = await db.into(db.sites).insert(SitesCompanion.insert(
      name: 'Ambohidratrimo', associationId: 'a1', enteredBy: 'u1', deviceId: 'd1'));
  final site = await (db.select(db.sites)..where((s) => s.rowId.equals(id))).getSingle();
  expect(site.id[14], '7');
  expect(site.syncState, SyncState.pending);
  expect(site.createdAtDevice.isUtc, isTrue);
  expect(site.serverSeq, isNull);
});

test('deviceId is created once and then stable', () async {
  final first = await db.deviceId();
  expect(await db.deviceId(), first);
});
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/db/database_test.dart`
Expected: FAIL (compile errors: `AppDatabase` not defined).

- [ ] **Step 4: Implement the files listed above, then generate**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/db/database.g.dart` created, no errors.

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/db/database_test.dart`
Expected: PASS.

- [ ] **Step 6: Snapshot schema v1 and its migration test**

Run: `dart run drift_dev make-migrations && flutter test test/db/`
Expected: `drift_schemas/default/drift_schema_v1.json` exists; generated tests pass.

- [ ] **Step 7: Commit** `feat: Drift database with sync columns, sites table and device id`

---

## M1 — Domain core

All files in `lib/domain/`; tests mirror them in `test/domain/`. Each test file builds `const cfg = DomainConfig.defaults;`.

### Task 4: Domain types, config and dates

**Files:**
- Create: `lib/domain/types.dart`, `lib/domain/config.dart`, `lib/domain/dates.dart`
- Test: `test/domain/config_test.dart`, `test/domain/dates_test.dart`, `test/domain/purity_test.dart`

**Interfaces:**
- Produces (`types.dart`):
  - `class Range<T extends num> { const Range(this.min, this.max); final T min; final T max; bool contains(num v) => v >= min && v <= max; }`
  - `enum Phase { fry, pregrow, growout, finishing }`
  - `enum StructureType { earth, tank, cage }`
  - `enum PondRole { breeding, nursery, pregrow, growout, holding, quarantine }`
  - `enum WaterSupply { barrage, derivation, marsh }`
  - `enum WaterColour { clear, lightGreen, mediumGreen, darkGreen, brownTurbid }`
  - `enum WarningSign { noAppetite, surfaceSwimming, nearBanks, erraticOrCircling, abnormalColour, skinLesions, paleOrSwollenGills, groupedDeaths, rubbing, excessMucus, whiteSpots, bulgingEyes, finBleeding }`
  - `enum Leftover { none, some, lots }`
  - `enum ProductForm { live, fresh, frozen, smoked, dried }`
  - `enum PrepStep { drain, dry, treat, fertilise, fill, rest }`
  - `enum Severity { warning, danger }`
  - `class FeedingGuide { const FeedingGuide({this.proteinPct, required this.pelletMinMm, this.pelletMaxMm, required this.feedingsPerDay}); final Range<double>? proteinPct; final double pelletMinMm; final double? pelletMaxMm; final Range<int> feedingsPerDay; }`
- Produces (`config.dart`): `class DomainConfig` with a `const` constructor and `static const defaults`. Each field carries a `///` comment citing its DOMAIN.md section. Fields and default values:

| Field | Type | Default |
|---|---|---|
| `fryMaxG`, `pregrowMaxG`, `growoutMaxG` | `double` | 5, 20, 250 (exclusive upper bounds) |
| `rationRate` | `Map<Phase, double>` | fry .05, pregrow .05, growout .04, finishing .03 |
| `maxRationRate` | `double` | .05 |
| `leftoverReduction`, `ateFastIncrease` | `double` | .15, .05 |
| `feedingGuides` | `Map<Phase, FeedingGuide>` | fry (30–35, 0.5–1.0, 4–6), pregrow (25–30, 2–2, 4–6), growout (20–25, 3–3, 3–4), finishing (null, 3–null, 2–3) |
| `densityPerM2` | `Map<StructureType, Range<double>>` | earth 2–6, tank 50–100, cage 150–200 |
| `temperatureC`, `ph` | `Range<double>` | 27–32, 6.5–8.5 |
| `minOxygenMgL` | `double` | 3.0 |
| `waterRenewalPctPerWeek` | `Range<int>` | 10–20 |
| `sampleIntervalDays`, `sampleMinFish`, `sampleMaxFish` | `int` | 14, 30, 50 |
| `waterCheckIntervalDays` | `int` | 7 |
| `fcrTarget` | `Range<double>` | 1.5–1.8 |
| `feedAgeWarnDays`, `feedAgeDangerDays`, `lowStockDays` | `int` | 60, 90, 7 |
| `mortalitySpikeShare`, `mortalitySpikeMultiplier` | `double` | .005, 3.0 |
| `mortalityTrailingDays`, `warningSignLookbackDays` | `int` | 7, 3 |
| `quarantineDays`, `dryingDays`, `restDays` | `Range<int>` | 7–10, 5–7, 2–3 |
| `preHarvestFastHours` | `int` | 48 |
| `limeKgPerM2`, `manureKgPerM2` | `Range<double>` | 0.1–0.2, 0.02–0.03 |
| `pondSurfaceM2`, `pondLengthWidthRatio` | `Range<double>` | 200–1000, 2–3 |
| `minDepthM` | `double` | 1.0 |
| `stockingWeightG`, `acclimatisationMinutes` | `Range<int>` | 10–20, 15–20 |

- Produces (`dates.dart`): `int daysBetween(DateTime from, DateTime to)`: whole calendar days from `from`'s date to `to`'s date, ignoring time of day. Compare `DateTime.utc(y, m, d)` of each.

- [ ] **Step 1: Write the failing tests**

`config_test.dart` pins the values most likely to be edited by mistake:
```dart
expect(cfg.minOxygenMgL, 3.0);
expect(cfg.rationRate[Phase.growout], 0.04);
expect(cfg.densityPerM2[StructureType.earth]!.min, 2);
expect(cfg.densityPerM2[StructureType.earth]!.max, 6);
expect(cfg.sampleIntervalDays, 14);
expect(cfg.feedingGuides[Phase.finishing]!.proteinPct, isNull);
expect(Phase.values.every(cfg.rationRate.containsKey), isTrue);
expect(Phase.values.every(cfg.feedingGuides.containsKey), isTrue);
expect(StructureType.values.every(cfg.densityPerM2.containsKey), isTrue);
```
`dates_test.dart`:
```dart
expect(daysBetween(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2, 0, 1)), 1);
expect(daysBetween(DateTime(2026, 3, 1, 0, 1), DateTime(2026, 3, 1, 23, 59)), 0);
expect(daysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
expect(daysBetween(DateTime(2026, 3, 10), DateTime(2026, 3, 1)), -9);
```
`purity_test.dart`: list every `.dart` file under `lib/domain/` with `dart:io`; expect none to contain `package:flutter`, `package:drift` or `package:dobo/db/`.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/domain/`
Expected: FAIL (`DomainConfig`, `daysBetween` not defined).

- [ ] **Step 3: Implement the three files** with the interfaces above.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/domain/ && flutter analyze`
Expected: PASS, no issues.

- [ ] **Step 5: Commit** `feat(domain): types, DomainConfig defaults from DOMAIN.md, daysBetween`

### Task 5: Phase and feed ration

**Files:**
- Create: `lib/domain/phase.dart`, `lib/domain/ration.dart`
- Test: `test/domain/phase_test.dart`, `test/domain/ration_test.dart`

**Interfaces:**
- Consumes: `Phase`, `Leftover`, `FeedingGuide`, `DomainConfig` (Task 4).
- Produces:
  - `Phase phaseFor(double avgWeightG, DomainConfig config)`: a weight exactly on a boundary belongs to the heavier phase.
  - `FeedingGuide feedingGuideFor(Phase phase, DomainConfig config)`
  - `int suggestedRationG({required int biomassG, required Phase phase, Leftover? lastLeftover, bool lastAteFast = false, required DomainConfig config})`: rate = `rationRate[phase]`. Leftover `some` or `lots` multiplies it by `1 − leftoverReduction`; otherwise `lastAteFast` multiplies it by `1 + ateFastIncrease`. The rate is then capped at `maxRationRate` and the result is `(biomassG × rate).round()`.

- [ ] **Step 1: Write the failing tests**

```dart
// phase
expect(phaseFor(4.99, cfg), Phase.fry);
expect(phaseFor(5.0, cfg), Phase.pregrow);
expect(phaseFor(19.9, cfg), Phase.pregrow);
expect(phaseFor(20.0, cfg), Phase.growout);
expect(phaseFor(249.9, cfg), Phase.growout);
expect(phaseFor(250.0, cfg), Phase.finishing);
expect(feedingGuideFor(Phase.growout, cfg).feedingsPerDay.max, 4);
// ration (biomass 100 kg)
expect(suggestedRationG(biomassG: 100000, phase: Phase.growout, config: cfg), 4000);
expect(suggestedRationG(biomassG: 100000, phase: Phase.fry, config: cfg), 5000);
expect(suggestedRationG(biomassG: 100000, phase: Phase.finishing, config: cfg), 3000);
expect(suggestedRationG(biomassG: 100000, phase: Phase.growout, lastLeftover: Leftover.some, config: cfg), 3400);
expect(suggestedRationG(biomassG: 100000, phase: Phase.growout, lastLeftover: Leftover.lots, config: cfg), 3400);
expect(suggestedRationG(biomassG: 100000, phase: Phase.growout, lastAteFast: true, config: cfg), 4200);
expect(suggestedRationG(biomassG: 100000, phase: Phase.fry, lastAteFast: true, config: cfg), 5000); // capped
expect(suggestedRationG(biomassG: 100000, phase: Phase.growout, lastLeftover: Leftover.some, lastAteFast: true, config: cfg), 3400);
expect(suggestedRationG(biomassG: 0, phase: Phase.growout, config: cfg), 0);
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/domain/phase_test.dart test/domain/ration_test.dart` → FAIL (not defined).
- [ ] **Step 3: Implement** both files per the interfaces.
- [ ] **Step 4: Run to verify they pass.** Same command → PASS; `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(domain): phase from average weight and suggested daily ration`

### Task 6: Stock, sample, biomass, survival, density

**Files:**
- Create: `lib/domain/stock.dart`
- Test: `test/domain/stock_test.dart`

**Interfaces:**
- Consumes: `StructureType`, `DomainConfig`.
- Produces:
  - `class LiveCount { const LiveCount(this.count, {required this.inconsistent}); final int count; final bool inconsistent; }`
  - `LiveCount liveCount({required int stocked, int transferredIn = 0, int transferredOut = 0, int deaths = 0, int harvested = 0})`: a negative result clamps to 0 with `inconsistent: true`.
  - `class SampleResult { const SampleResult(this.avgWeightG, {required this.smallSample}); final double avgWeightG; final bool smallSample; }`
  - `SampleResult? sampleResult({required int fishCount, required int totalWeightG, required DomainConfig config})`: returns `null` when either value ≤ 0; `smallSample` is true when `fishCount < sampleMinFish`.
  - `int biomassG({required int liveCount, required double avgWeightG})`: rounded.
  - `double? survivalRate({required int live, required int entered})`: `null` when `entered` ≤ 0.
  - `double? densityPerM2({required int live, required double? surfaceM2})`: `null` when the surface is null or ≤ 0.
  - `enum DensityStatus { below, within, above }`
  - `DensityStatus? densityStatus({required double? density, required StructureType structure, required DomainConfig config})`: `null` when `density` is null.

- [ ] **Step 1: Write the failing tests**

```dart
expect(liveCount(stocked: 1000, deaths: 50).count, 950);
expect(liveCount(stocked: 1000, deaths: 50).inconsistent, isFalse);
expect(liveCount(stocked: 1000, transferredIn: 200, transferredOut: 300, deaths: 50, harvested: 100).count, 750);
final bad = liveCount(stocked: 100, deaths: 150);           // Review Focus 1
expect(bad.count, 0);
expect(bad.inconsistent, isTrue);
expect(biomassG(liveCount: bad.count, avgWeightG: 120), 0);

expect(sampleResult(fishCount: 40, totalWeightG: 4000, config: cfg)!.avgWeightG, 100.0);
expect(sampleResult(fishCount: 40, totalWeightG: 4000, config: cfg)!.smallSample, isFalse);
expect(sampleResult(fishCount: 20, totalWeightG: 2000, config: cfg)!.smallSample, isTrue);
expect(sampleResult(fishCount: 0, totalWeightG: 0, config: cfg), isNull);    // Review Focus 2
expect(sampleResult(fishCount: 30, totalWeightG: 0, config: cfg), isNull);

expect(biomassG(liveCount: 950, avgWeightG: 100.0), 95000);
expect(survivalRate(live: 950, entered: 1000), 0.95);
expect(survivalRate(live: 0, entered: 0), isNull);

expect(densityPerM2(live: 1500, surfaceM2: 500), 3.0);
expect(densityPerM2(live: 1500, surfaceM2: null), isNull);  // Review Focus 3
expect(densityPerM2(live: 1500, surfaceM2: 0), isNull);
expect(densityStatus(density: 1.5, structure: StructureType.earth, config: cfg), DensityStatus.below);
expect(densityStatus(density: 6.0, structure: StructureType.earth, config: cfg), DensityStatus.within);
expect(densityStatus(density: 6.5, structure: StructureType.earth, config: cfg), DensityStatus.above);
expect(densityStatus(density: 60, structure: StructureType.tank, config: cfg), DensityStatus.within);
expect(densityStatus(density: null, structure: StructureType.earth, config: cfg), isNull);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/stock_test.dart` → FAIL.
- [ ] **Step 3: Implement** `stock.dart`.
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): live count, sample average, biomass, survival and density`

### Task 7: Feed conversion ratio

**Files:**
- Create: `lib/domain/fcr.dart`
- Test: `test/domain/fcr_test.dart`

**Interfaces:**
- Produces:
  - `sealed class FcrResult`, with `final class FcrValue extends FcrResult { const FcrValue(this.value); final double value; }` and `final class FcrStalled extends FcrResult { const FcrStalled(); }`
  - `FcrResult periodFcr({required int feedG, required int biomassPrevG, required int biomassNowG, int outWeightG = 0, int inWeightG = 0})`: gain = `(biomassNowG + outWeightG) − (biomassPrevG + inWeightG)`. Gain ≤ 0 gives `FcrStalled`; otherwise `feedG / gain`.
  - `FcrResult cycleFcr({required int totalFeedG, required int harvestedG, required int stockedG})`: gain = `harvestedG − stockedG`, with the same stalled rule.
  - `bool isFcrWorsening(List<FcrResult> chronological)`: true only when the last three are all `FcrValue` and strictly increasing.

- [ ] **Step 1: Write the failing tests**

```dart
double v(FcrResult r) => (r as FcrValue).value;
expect(v(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 70000)), 1.5);
expect(v(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 50000, outWeightG: 20000)), 1.5);
expect(v(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 80000, inWeightG: 10000)), 1.5);
expect(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 50000), isA<FcrStalled>());
expect(periodFcr(feedG: 30000, biomassPrevG: 50000, biomassNowG: 45000), isA<FcrStalled>());
expect(v(periodFcr(feedG: 0, biomassPrevG: 50000, biomassNowG: 60000)), 0.0);
expect(v(cycleFcr(totalFeedG: 450000, harvestedG: 320000, stockedG: 20000)), 1.5);
expect(cycleFcr(totalFeedG: 1000, harvestedG: 0, stockedG: 20000), isA<FcrStalled>());

List<FcrResult> f(List<double> xs) => [for (final x in xs) FcrValue(x)];
expect(isFcrWorsening(f([1.5, 1.6, 1.7])), isTrue);
expect(isFcrWorsening(f([2.0, 1.5, 1.6, 1.7])), isTrue);
expect(isFcrWorsening(f([1.5, 1.7, 1.6])), isFalse);
expect(isFcrWorsening(f([1.4, 1.5, 1.6, 1.5])), isFalse);
expect(isFcrWorsening(f([1.6, 1.7])), isFalse);
expect(isFcrWorsening(f([1.5, 1.5, 1.6])), isFalse);
expect(isFcrWorsening([const FcrValue(1.5), const FcrStalled(), const FcrValue(1.8)]), isFalse);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/fcr_test.dart` → FAIL.
- [ ] **Step 3: Implement** `fcr.dart`.
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): period and cycle FCR with worsening trend`

### Task 8: Water, pond design and prep doses, feed stock

**Files:**
- Create: `lib/domain/water.dart`, `lib/domain/pond.dart`, `lib/domain/feed_stock.dart`
- Test: `test/domain/water_test.dart`, `test/domain/pond_test.dart`, `test/domain/feed_stock_test.dart`

**Interfaces:**
- Produces (`water.dart`):
  - `enum WaterParam { temperature, ph, oxygen, colour }`, `enum Direction { low, high }`
  - `class WaterIssue { const WaterIssue(this.param, this.severity, {this.value, this.direction}); final WaterParam param; final Severity severity; final double? value; final Direction? direction; }`
  - `List<WaterIssue> waterIssues({double? temperatureC, double? ph, double? oxygenMgL, WaterColour? colour, required DomainConfig config})`. A null parameter is skipped. Oxygen below `minOxygenMgL` is `danger`/low. Temperature or pH outside its range is a `warning` with a direction. `darkGreen` or `brownTurbid` is a colour `warning` (renew water).
- Produces (`pond.dart`):
  - `class PrepDoses { const PrepDoses(this.limeKg, this.manureKg); final Range<double> limeKg; final Range<double> manureKg; }`
  - `PrepDoses? prepDoses(double? surfaceM2, DomainConfig config)`: `null` when the surface is null or ≤ 0.
  - `enum PondDesignWarning { surfaceTooSmall, surfaceTooLarge, notElongated, tooElongated, tooShallow }`
  - `Set<PondDesignWarning> pondDesignWarnings({double? lengthM, double? widthM, double? depthInletM, double? depthOutletM, required DomainConfig config})`. Surface and ratio checks run only when both dimensions are > 0; ratio = longer side ÷ shorter side. Depth check: the mean of the depths given < `minDepthM` → `tooShallow`.
- Produces (`feed_stock.dart`):
  - `enum FeedAge { ok, old, expired }`
  - `FeedAge feedLotAge({required DateTime manufacturedOn, required DateTime today, required DomainConfig config})`: ≥ `feedAgeDangerDays` → expired; ≥ `feedAgeWarnDays` → old.
  - `double? daysOfStockLeft({required int stockG, required int dailyUsageG})`: `null` when usage ≤ 0.

- [ ] **Step 1: Write the failing tests**

```dart
// water
expect(waterIssues(config: cfg), isEmpty);
expect(waterIssues(temperatureC: 27, ph: 6.5, oxygenMgL: 3.0, colour: WaterColour.lightGreen, config: cfg), isEmpty);
expect(waterIssues(temperatureC: 32, ph: 8.5, config: cfg), isEmpty);
final t = waterIssues(temperatureC: 26, config: cfg).single;
expect((t.param, t.severity, t.direction), (WaterParam.temperature, Severity.warning, Direction.low));
expect(waterIssues(temperatureC: 33, config: cfg).single.direction, Direction.high);
expect(waterIssues(ph: 8.6, config: cfg).single.param, WaterParam.ph);
final o = waterIssues(oxygenMgL: 2.9, config: cfg).single;
expect((o.param, o.severity), (WaterParam.oxygen, Severity.danger));
expect(waterIssues(colour: WaterColour.brownTurbid, config: cfg).single.param, WaterParam.colour);
expect(waterIssues(temperatureC: 26, oxygenMgL: 1, config: cfg).length, 2);
// pond
final d = prepDoses(500, cfg)!;
expect((d.limeKg.min, d.limeKg.max, d.manureKg.min, d.manureKg.max), (50.0, 100.0, 10.0, 15.0));
expect(prepDoses(null, cfg), isNull);                       // Review Focus 3
expect(prepDoses(0, cfg), isNull);
expect(pondDesignWarnings(lengthM: 30, widthM: 15, depthInletM: 0.8, depthOutletM: 1.2, config: cfg), isEmpty);
expect(pondDesignWarnings(lengthM: 40, widthM: 12.5, config: cfg), {PondDesignWarning.tooElongated});
expect(pondDesignWarnings(lengthM: 10, widthM: 10, config: cfg), {PondDesignWarning.surfaceTooSmall, PondDesignWarning.notElongated});
expect(pondDesignWarnings(lengthM: 50, widthM: 30, config: cfg), {PondDesignWarning.surfaceTooLarge, PondDesignWarning.notElongated});
expect(pondDesignWarnings(depthInletM: 0.6, depthOutletM: 0.9, config: cfg), {PondDesignWarning.tooShallow});
expect(pondDesignWarnings(config: cfg), isEmpty);
// feed stock
final made = DateTime(2026, 1, 1);
expect(feedLotAge(manufacturedOn: made, today: made.add(const Duration(days: 59)), config: cfg), FeedAge.ok);
expect(feedLotAge(manufacturedOn: made, today: made.add(const Duration(days: 60)), config: cfg), FeedAge.old);
expect(feedLotAge(manufacturedOn: made, today: made.add(const Duration(days: 90)), config: cfg), FeedAge.expired);
expect(daysOfStockLeft(stockG: 70000, dailyUsageG: 10000), 7.0);
expect(daysOfStockLeft(stockG: 70000, dailyUsageG: 0), isNull);
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/domain/water_test.dart test/domain/pond_test.dart test/domain/feed_stock_test.dart` → FAIL.
- [ ] **Step 3: Implement** the three files.
- [ ] **Step 4: Run to verify they pass.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): water issues, pond design warnings, prep doses, feed stock age`

### Task 9: Alert model and health/growth alert rules

**Files:**
- Create: `lib/domain/alerts/alert.dart`, `lib/domain/alerts/health_alerts.dart`
- Test: `test/domain/alerts/health_alerts_test.dart`

**Interfaces:**
- Consumes: `WaterIssue` (Task 8), `FcrResult`, `isFcrWorsening` (Task 7), `DensityStatus` (Task 6), `phaseFor` (Task 5), `daysBetween`, `WarningSign`, `Severity`, `DomainConfig` (Task 4).
- Produces (`alert.dart`):
  - `enum AlertKind { waterOutOfRange, fcrWorsening, growthStalled, mortalitySpike, warningSignSeen, densityOutOfRange, phaseChange, sampleDue, waterCheckDue, quarantineEnding, preHarvestFast, feedStockLow, feedTooOld, prepStepDue }`
  - `class Alert { const Alert(this.kind, this.severity, {this.pondId, this.batchId, this.facts = const {}}); final AlertKind kind; final Severity severity; final String? pondId; final String? batchId; final Map<String, Object?> facts; }`
  - `class DatedSigns { const DatedSigns(this.date, this.signs); final DateTime date; final Set<WarningSign> signs; }`
- Produces (`health_alerts.dart`; each returns `null` when the rule doesn't fire):
  - `List<Alert> waterAlerts({required String pondId, required List<WaterIssue> issues})`: one `waterOutOfRange` alert per issue with the issue's severity; facts `param`, `value`, `direction`.
  - `Alert? fcrWorseningAlert({required String pondId, required String batchId, required List<FcrResult> periodFcrs})`: danger.
  - `Alert? growthStalledAlert({required String pondId, required String batchId, required FcrResult latest})`: danger when `latest` is `FcrStalled`.
  - `Alert? mortalitySpikeAlert({required String pondId, required int deathsToday, required List<int> previousDailyDeaths, required int liveCountAtDayStart, required DomainConfig config})`: danger when `deathsToday > liveCountAtDayStart × mortalitySpikeShare`, or when the trailing average is > 0 and `deathsToday ≥ multiplier × average`. The average is taken over the last `mortalityTrailingDays` entries of `previousDailyDeaths`, which the caller supplies chronologically with 0 for days without deaths. An empty list means average 0. Facts: `deathsToday`, `trailingAverage`.
  - `Alert? warningSignAlert({required String pondId, required List<DatedSigns> recent, required DateTime today, required DomainConfig config})`: danger if any entry with `0 ≤ daysBetween(date, today) < warningSignLookbackDays` has signs. Facts: `signs` (union `Set<WarningSign>`).
  - `Alert? densityAlert({required String pondId, required DensityStatus? status, double? density})`: warning when `below` or `above`. Facts: `status`, `density`.
  - `Alert? phaseChangeAlert({required String pondId, required String batchId, double? previousAvgG, required double latestAvgG, required DomainConfig config})`: warning when both phases differ. Facts: `from`, `to` (`Phase`).

- [ ] **Step 1: Write the failing tests**

```dart
final today = DateTime(2026, 3, 10);
expect(waterAlerts(pondId: 'E1', issues: const [
  WaterIssue(WaterParam.oxygen, Severity.danger, value: 2, direction: Direction.low)]).single.severity, Severity.danger);
expect(waterAlerts(pondId: 'E1', issues: const []), isEmpty);

List<FcrResult> f(List<double> xs) => [for (final x in xs) FcrValue(x)];
expect(fcrWorseningAlert(pondId: 'E1', batchId: 'L1', periodFcrs: f([1.5, 1.6, 1.7]))!.severity, Severity.danger);
expect(fcrWorseningAlert(pondId: 'E1', batchId: 'L1', periodFcrs: f([1.7, 1.6])), isNull);
expect(growthStalledAlert(pondId: 'E1', batchId: 'L1', latest: const FcrStalled())!.kind, AlertKind.growthStalled);
expect(growthStalledAlert(pondId: 'E1', batchId: 'L1', latest: const FcrValue(1.6)), isNull);

Alert? m(int today, List<int> prev, int live) => mortalitySpikeAlert(
    pondId: 'E1', deathsToday: today, previousDailyDeaths: prev, liveCountAtDayStart: live, config: cfg);
expect(m(51, List.filled(7, 5), 10000), isNotNull);   // > 0.5 % of 10 000
expect(m(15, List.filled(7, 5), 10000), isNotNull);   // 3 × average 5
expect(m(14, List.filled(7, 5), 10000), isNull);
expect(m(3, List.filled(7, 0), 10000), isNull);       // zero average never multiplies
expect(m(3, const [], 100), isNotNull);               // 3 > 0.5
expect(m(15, [100, ...List.filled(7, 5)], 10000), isNotNull); // only last 7 days count

expect(warningSignAlert(pondId: 'E1', today: today, config: cfg, recent: [
  DatedSigns(DateTime(2026, 3, 8), {WarningSign.rubbing})])!.facts['signs'], {WarningSign.rubbing});
expect(warningSignAlert(pondId: 'E1', today: today, config: cfg, recent: [
  DatedSigns(DateTime(2026, 3, 7), {WarningSign.rubbing})]), isNull);
expect(warningSignAlert(pondId: 'E1', today: today, config: cfg, recent: [
  DatedSigns(DateTime(2026, 3, 9), const {})]), isNull);

expect(densityAlert(pondId: 'E1', status: DensityStatus.above, density: 7)!.severity, Severity.warning);
expect(densityAlert(pondId: 'E1', status: DensityStatus.within, density: 4), isNull);
expect(densityAlert(pondId: 'E1', status: null), isNull);

final p = phaseChangeAlert(pondId: 'E1', batchId: 'L1', previousAvgG: 18, latestAvgG: 22, config: cfg)!;
expect((p.facts['from'], p.facts['to']), (Phase.pregrow, Phase.growout));
expect(phaseChangeAlert(pondId: 'E1', batchId: 'L1', latestAvgG: 22, config: cfg), isNull);
expect(phaseChangeAlert(pondId: 'E1', batchId: 'L1', previousAvgG: 22, latestAvgG: 30, config: cfg), isNull);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/alerts/health_alerts_test.dart` → FAIL.
- [ ] **Step 3: Implement** `alert.dart` and `health_alerts.dart`.
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): alert model and health/growth alert rules`

### Task 10: Schedule alert rules

**Files:**
- Create: `lib/domain/alerts/schedule_alerts.dart`
- Test: `test/domain/alerts/schedule_alerts_test.dart`

**Interfaces:**
- Consumes: `Alert`, `AlertKind` (Task 9), `feedLotAge`, `FeedAge`, `daysOfStockLeft` (Task 8), `daysBetween`, `PrepStep`, `DomainConfig` (Task 4).
- Produces (each returns `null` when the rule doesn't fire; severity is `warning` unless stated):
  - `Alert? sampleDueAlert({required String pondId, required String batchId, required DateTime lastSampleOrStocking, required DateTime today, required DomainConfig config})`: fires at ≥ `sampleIntervalDays`. Facts: `daysSince`.
  - `Alert? waterCheckDueAlert({required String pondId, DateTime? lastReading, required DateTime today, required DomainConfig config})`: fires when `lastReading` is null or ≥ `waterCheckIntervalDays` old.
  - `Alert? quarantineEndingAlert({required String pondId, required String batchId, required DateTime quarantineStart, required DateTime today, required DomainConfig config})`: fires at ≥ `quarantineDays.min`. Facts: `days`, `recommendedDays` (= `quarantineDays.max`).
  - `Alert? preHarvestFastAlert({required String pondId, required String batchId, required DateTime plannedHarvestAt, required DateTime now, DateTime? lastFeedingAt, required DomainConfig config})`: fires when `plannedHarvestAt − preHarvestFastHours ≤ now < plannedHarvestAt`. Facts: `fedDuringFast` (true when `lastFeedingAt` is at or after the window start).
  - `Alert? feedStockLowAlert({required int stockG, required int dailyUsageG, required DomainConfig config})`: fires when the days left is non-null and < `lowStockDays`. Facts: `daysLeft`.
  - `Alert? feedTooOldAlert({required String feedLotId, required DateTime manufacturedOn, required int remainingG, required DateTime today, required DomainConfig config})`: `old` gives warning, `expired` gives danger; no alert when `remainingG` ≤ 0. Facts: `feedLotId`, `age`.
  - `Alert? prepStepDueAlert({required String pondId, required PrepStep lastDone, required DateTime lastDoneOn, required DateTime today, required DomainConfig config})`: `drain` done and ≥ `dryingDays.min` days ago → facts `waitingStep: PrepStep.dry`. `fill` done and ≥ `restDays.min` days ago → `waitingStep: PrepStep.rest`. Any other step → `null`.

- [ ] **Step 1: Write the failing tests**

```dart
final d0 = DateTime(2026, 3, 1);
DateTime d(int days) => d0.add(Duration(days: days));
expect(sampleDueAlert(pondId: 'E1', batchId: 'L1', lastSampleOrStocking: d0, today: d(13), config: cfg), isNull);
expect(sampleDueAlert(pondId: 'E1', batchId: 'L1', lastSampleOrStocking: d0, today: d(14), config: cfg)!.facts['daysSince'], 14);
expect(waterCheckDueAlert(pondId: 'E1', today: d0, config: cfg), isNotNull);
expect(waterCheckDueAlert(pondId: 'E1', lastReading: d0, today: d(6), config: cfg), isNull);
expect(waterCheckDueAlert(pondId: 'E1', lastReading: d0, today: d(7), config: cfg), isNotNull);
expect(quarantineEndingAlert(pondId: 'Q1', batchId: 'L1', quarantineStart: d0, today: d(6), config: cfg), isNull);
final q = quarantineEndingAlert(pondId: 'Q1', batchId: 'L1', quarantineStart: d0, today: d(7), config: cfg)!;
expect((q.facts['days'], q.facts['recommendedDays']), (7, 10));

final harvest = DateTime(2026, 3, 10, 6);
Alert? h(DateTime now, [DateTime? fed]) => preHarvestFastAlert(
    pondId: 'E1', batchId: 'L1', plannedHarvestAt: harvest, now: now, lastFeedingAt: fed, config: cfg);
expect(h(DateTime(2026, 3, 8, 5, 59)), isNull);
expect(h(DateTime(2026, 3, 8, 6))!.facts['fedDuringFast'], isFalse);
expect(h(DateTime(2026, 3, 9, 8), DateTime(2026, 3, 8, 15))!.facts['fedDuringFast'], isTrue);
expect(h(DateTime(2026, 3, 9, 8), DateTime(2026, 3, 7, 15))!.facts['fedDuringFast'], isFalse);
expect(h(harvest), isNull);

expect(feedStockLowAlert(stockG: 60000, dailyUsageG: 10000, config: cfg), isNotNull);
expect(feedStockLowAlert(stockG: 70000, dailyUsageG: 10000, config: cfg), isNull);
expect(feedStockLowAlert(stockG: 0, dailyUsageG: 0, config: cfg), isNull);

expect(feedTooOldAlert(feedLotId: 'F1', manufacturedOn: d0, remainingG: 5000, today: d(60), config: cfg)!.severity, Severity.warning);
expect(feedTooOldAlert(feedLotId: 'F1', manufacturedOn: d0, remainingG: 5000, today: d(90), config: cfg)!.severity, Severity.danger);
expect(feedTooOldAlert(feedLotId: 'F1', manufacturedOn: d0, remainingG: 0, today: d(90), config: cfg), isNull);
expect(feedTooOldAlert(feedLotId: 'F1', manufacturedOn: d0, remainingG: 5000, today: d(59), config: cfg), isNull);

expect(prepStepDueAlert(pondId: 'E1', lastDone: PrepStep.drain, lastDoneOn: d0, today: d(4), config: cfg), isNull);
expect(prepStepDueAlert(pondId: 'E1', lastDone: PrepStep.drain, lastDoneOn: d0, today: d(5), config: cfg)!.facts['waitingStep'], PrepStep.dry);
expect(prepStepDueAlert(pondId: 'E1', lastDone: PrepStep.fill, lastDoneOn: d0, today: d(2), config: cfg)!.facts['waitingStep'], PrepStep.rest);
expect(prepStepDueAlert(pondId: 'E1', lastDone: PrepStep.treat, lastDoneOn: d0, today: d(30), config: cfg), isNull);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/alerts/schedule_alerts_test.dart` → FAIL.
- [ ] **Step 3: Implement** `schedule_alerts.dart`.
- [ ] **Step 4: Run the whole suite**

Run: `flutter test && flutter analyze`
Expected: every test passes, "No issues found!"

- [ ] **Step 5: Smoke-check on Android**

Run: `flutter build apk --debug`, then install on an emulator in airplane mode, launch, and switch the device language to check that the French home screen shows.
Expected: the build succeeds and the app opens offline.

- [ ] **Step 6: Commit** `feat(domain): schedule alert rules (sampling, water, quarantine, fast, feed, prep)`

---

## Out of scope for this plan

M2 onwards (SPEC §11): pond, batch and event tables beyond `sites`; repositories; screens beyond the home placeholder; Supabase; sync; turning database rows into domain inputs; alert text in ARB files.
