# M3: Recording Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything that happens at a pond can be recorded offline: the worker's daily log (feed, leftovers, deaths, signs, water colour), a member's transcription of paper sheets, water readings, samples, health events with isolation and treatments, and visits that group a member's checks. Recorded deaths and samples feed back into each pond's estimated fish, average weight and suggested ration.

**Architecture:** Schema v3 adds seven tables: six append-only events (`daily_logs`, `water_readings`, `samples`, `observations`, `health_events`, `treatments`) and one reference row (`visits`). Every event a member enters during an open visit carries its `visit_id`. `placements()` in `lib/domain/occupancy.dart` learns sample and death facts, and a new `pondRationG()` gives the day's ration. Repositories reuse `EventWrites` (supersede and tombstone with the stale-version guard). Worker screens are built now and reached through a "worker mode" entry in More, so they can be tested and used before M4 brings accounts and roles.

**Tech Stack:** Flutter 3.47.8, Drift 2.35, flutter_riverpod 3, go_router 18, ARB l10n (fr, and mg for worker screens). No new dependencies.

**Spec:** `CLAUDE.md`, `docs/SPEC.md` (§3 roles, §4 data model, F3, F4, F5, F9, §6 navigation, §8 photos, §9 language, §11 M3), `docs/DOMAIN.md` (§Feeding, §Sampling, §Formulas, §Water quality, §Health, §Biosecurity). Decisions below are Claude's calls, made without the user, and can be revisited.

## Decisions (Claude's calls)

1. **Worker screens before roles.** More gets a "Mode ouvrier" entry that opens the worker home (`/worker`): pond tiles, each opening that pond's daily log for today. The worker home has no other navigation, and an exit button returns to the member shell. In M4 a worker account will land there with no exit. Entering worker mode switches the app to Malagasy; leaving it switches back.
2. **Members log days too,** from a "Journal du jour" button on the pond page. It opens the same screen as the worker's.
3. **One daily log per pond-day per phone.** Opening a pond-day that already has a current log edits it, and saving supersedes it. Two logs for the same pond-day from two phones arrive by sync and are flagged in M5.
4. **Deaths are recorded per pond, not per batch.** In a pond with several batches, the day's deaths are shared out in proportion to each batch's fish at that moment: each batch takes the whole part of its share, and the deaths left over go one each to the largest remainders (ties by batch id). Deaths in a pond whose fish have all gone go to the batch that was there most recently, which makes it "inconsistent" rather than vanishing. Deaths in a pond that has never held fish are dropped from the counts: there's no batch to count them against, and the daily log still shows them.
5. **Average weight** of a batch in a pond is the most recent of: a sample of that batch in that pond, a stocking into it, a move into it.
6. **Leftovers:** three pictograms (none, some, lots). Choosing "none" shows a fourth, optional toggle, "ate fast" (`ateFast`). The next day's suggested ration applies DOMAIN's adjustment from the pond's most recent log (`suggestedRationG`), summed over the pond's batches.
7. **Worker screen fields:** feed in kg with the suggested ration shown large, leftovers, deaths (defaults to 0), warning signs, water colour. Only the feed amount is required. Number of feedings is a row of 1–6 chips. The note field is kept but hidden behind a "+" button. Signs on dead fish use the six body signs from DOMAIN's list (skin lesions, pale or swollen gills, white spots, bulging eyes, fin bleeding, abnormal colour), shown once deaths > 0.
8. **Pictograms** are Material icons with a short label for now (one per warning sign, water colour as a colour swatch, leftovers as bowl icons). Custom artwork belongs with the M8 field test with the worker.
9. **Malagasy:** worker screens get Malagasy strings now, Claude's best effort, marked for review in M8. Member screens stay French (M2 Decision 10).
10. **Visits:**
    - A `Visit` is a reference row: site, member, started, ended, summary.
    - One open visit per phone. While it's open, every event entered on this phone carries its `visit_id`.
    - The Visit tab joins the shell between Ponds and More. It shows a "Démarrer une visite" button and the list of past visits, or, while a visit is open, its checklist.
    - Checklist items: water reading for each stocked pond; sample for each batch due (DOMAIN rule via `sampleDueAlert`); a condition check per pond (dike, inlet screen, predator nets, fence, grass), each OK or problem with an optional note; the biosecurity reminders; free observations; the summary.
    - Condition checks and observations are stored as `observations`. Biosecurity reminders are tick boxes on screen and are not stored.
    - Ending a visit sets `ended_at`. The report itself is M6.
11. **Photos are deferred to M6,** where reports show them. M3 stores no photos and adds no photo columns. The column comes with M6's schema change.
12. **Health (F9):**
    - A health event records the signs, a suspected issue (optional text), and its actions: `isolated`, `technician_called`, `released`.
    - Isolating sets the pond's stored status to `isolated`. Releasing writes a `released` event and sets the stored status back to `empty`, so the fish then decide what the pond shows.
    - An isolated pond shows a red banner on its card, its page, its worker tile and its daily log.
    - Treatments record pond, batch, product, dose (text), date, and who advised (text). The app never suggests a product or dose.
    - The disease info cards repeat DOMAIN §Health and are labelled as information, not a diagnosis.
13. **Transcription grid (F4):**
    - One week (Monday to Sunday) for the site. Rows are days; columns are active ponds.
    - Each cell takes feed in kg and deaths; signs are optional, through a tap-through.
    - The member picks whose sheet it is (an active person), which sets `observed_by`.
    - A cell that already has a current log shows its values greyed out. Tapping it opens that daily log to correct.
    - Saving writes one daily log per cell that has a value, all in one transaction.
14. **Water readings and samples** are member screens, reached from the pond page and from the visit checklist.
    - A water reading's time defaults to now, and out-of-range values show in red as you type (`waterIssues`).
    - A sample is batch, fish count and total weight (kg, decimal). It shows the average weight and the "small sample" warning live.

## Global Constraints

- Offline only. All writes are local Drift transactions, and every event write goes through `EventWrites` for corrections and deletions.
- Weights are stored as integer grams, except average weights, which are integer milligrams (M2 Decision 3). Sample total weight is `total_weight_g`.
- Dates entered by hand are date-only, stored with `farmDateToUtc`. Water reading times are full instants (UTC).
- Every synced row is stamped from the `Session`. `observed_by` is set only by transcription.
- Schema change: `schemaVersion` 2 → 3. Write `from2To3` with `stepByStep`, run `make-migrations`, and fill the generated v2→v3 data-integrity test with a pond and a stocking that survive. Commit the snapshot, the steps file and the generated tests.
- Nothing in `lib/domain/` imports Flutter or Drift. Every farming number comes from `DomainConfig.defaults`, and every string from the ARB files. Worker screens need `app_mg.arb` entries.
- Worker screens: one task per screen, touch targets ≥ 56 dp, numeric keypad, icons with numbers, nothing typed except an optional note.
- Every Save goes through `SaveOnce`. Every pushed screen has a working Back.
- `flutter analyze` reports no issues, and `flutter test` passes under the machine zone and `TZ=UTC` at the end of each task.
- Commits: conventional prefix, body ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Branch `feat/m3-recording`, which already holds the derived-status commit.

## Review Focus

1. **More deaths than fish** (a typo of 500 for 50): the pond shows 0 fish flagged "inconsistent", never a negative count, and the ration is 0. Deaths dated before the pond's first stocking don't change its count. Tests in Task 2 and Task 6.
2. **The same pond-day opened twice on one phone:** the second save supersedes the first. There is never a second current log, and a double tap writes once. Tests in Task 3 and Task 6.
3. **A visit left open when the app is killed:** reopening the app shows the open visit, and records entered after the restart still carry its id. Test in Task 9.
4. **A sample with 0 fish or 0 g, or a water reading with every field empty:** refused before writing, with "Obligatoire" on the field. A pH of `7,5` typed with a comma is read as 7.5. Tests in Task 7.
5. **The transcription grid on a week that crosses a month end, opened under `TZ=UTC`:** each cell's date is the Madagascar date (Monday to Sunday), and values saved for 31/03 don't land on 01/04. Test in Task 8.

---

### Task 1: Schema v3

**Files:**
- Modify: `lib/domain/types.dart`, `lib/db/database.dart`
- Create: `lib/db/tables/daily_logs.dart`, `water_readings.dart`, `samples.dart`, `observations.dart`, `health_events.dart`, `treatments.dart`, `visits.dart`, `lib/db/converters.dart`
- Test: `test/db/schema_v3_test.dart`, generated v2→v3 tests in `test/db/default/`

**Interfaces:**
- Produces (`types.dart`): `enum ObservationCategory { dike, inletScreen, predatorNets, fence, grass, predators, theft, other }`, `enum HealthAction { isolated, technicianCalled, released }`, `const deathSigns = {WarningSign.skinLesions, WarningSign.paleOrSwollenGills, WarningSign.whiteSpots, WarningSign.bulgingEyes, WarningSign.finBleeding, WarningSign.abnormalColour}`.
- Produces (`converters.dart`): `class EnumSetConverter<E extends Enum> extends TypeConverter<Set<E>, String>`. It stores enum names comma-separated in declaration order; `''` reads back as `{}`. Unknown names are skipped, so a newer phone's value never crashes an older one. Instances `warningSignsConverter`, `healthActionsConverter`.
- Produces (tables, all `SyncedRow`, events also `EventRow`, nullable `visitId` on every event table; Drift class names singular):
  - `DailyLogs`: `pondId`, `feedGivenG` int, `feedLotId` text nullable (M7), `feedings` int nullable, `leftover` `textEnum<Leftover>` nullable, `ateFast` bool default false, `deaths` int default 0, `deathSigns` text (`warningSignsConverter`) default `''`, `warningSigns` (same), `waterColour` `textEnum<WaterColour>` nullable, `note` nullable. `recordedAt` is the farm date at noon.
  - `WaterReadings`: `pondId`, `temperatureC`, `ph`, `oxygenMgL` real nullable, `colour` `textEnum<WaterColour>` nullable, `renewedPct` int nullable.
  - `Samples`: `batchId`, `pondId`, `fishCount` int, `totalWeightG` int.
  - `Observations`: `siteId`, `pondId` nullable, `category` `textEnum<ObservationCategory>`, `ok` bool nullable (condition checks), `note` nullable (a column named `text` would hide Drift's `text()` builder).
  - `HealthEvents`: `pondId`, `signs` (`warningSignsConverter`), `suspectedIssue` nullable, `actions` (`healthActionsConverter`).
  - `Treatments`: `pondId`, `batchId` nullable, `product`, `dose`, `advisedBy` nullable.
  - `Visits` (Reference): `siteId`, `startedAt`, `endedAt` nullable, `summary` nullable.
  - `schemaVersion => 3`; `from2To3` creates the seven tables.

- [ ] **Step 1: Write the failing tests.** `schema_v3_test.dart`: a daily log saved with `warningSigns: {rubbing, whiteSpots}` reads back as the same set; one with no signs reads back `{}`; a value `'rubbing,someFutureSign'` written raw reads back as `{rubbing}`; a health event's `actions` round-trip; a daily log's `deaths` defaults to 0 and `ateFast` to false.
- [ ] **Step 2: Run to verify it fails.** `flutter test test/db/schema_v3_test.dart` → FAIL (not defined).
- [ ] **Step 3: Implement**, then run `dart run build_runner build --delete-conflicting-outputs` and `dart run drift_dev make-migrations`, write `from2To3`, and fill the generated data-integrity test (a v2 pond and stocking survive, unchanged).
- [ ] **Step 4: Run to verify it passes.** `flutter test test/db/` → PASS.
- [ ] **Step 5: Commit** `feat(db): schema v3 with daily logs, water readings, samples, observations, health, treatments and visits`

### Task 2: Deaths, samples and the day's ration (domain)

**Files:**
- Modify: `lib/domain/occupancy.dart`, `lib/domain/ration.dart`
- Test: `test/domain/occupancy_test.dart`, `test/domain/ration_test.dart`

**Interfaces:**
- Produces:
  - `class SampleFact { const SampleFact({required this.batchId, required this.pondId, required this.avgWeightG, required this.date}); … }`
  - `class DeathFact { const DeathFact({required this.pondId, required this.count, required this.date}); … }`
  - `placements({required stockings, required transfers, List<SampleFact> samples = const [], List<DeathFact> deaths = const []})`. Facts are walked in date order; on the same date the order is stockings, moves, samples, deaths, each then in list order. A sample sets its pair's weight. Deaths follow Decision 4. `live` = `liveCount(stocked, transferredIn, transferredOut, deaths)`.
  - `int pondRationG({required List<({int biomassG, Phase phase})> batches, Leftover? lastLeftover, bool lastAteFast = false, required DomainConfig config})`: the sum of `suggestedRationG` per batch.

- [ ] **Step 1: Write the failing tests**

```dart
final d1 = DateTime(2026, 3, 1), d2 = DateTime(2026, 3, 2), d3 = DateTime(2026, 3, 15);
// deaths reduce the count
final a = placements(stockings: [stock('L1', 'E1', 1000, 12.5, d1)], transfers: const [],
    deaths: [DeathFact(pondId: 'E1', count: 30, date: d2)]);
expect(at(a, 'L1', 'E1').live.count, 970);
// shared in proportion, remainder to the largest share
final b = placements(stockings: [stock('L1', 'E1', 600, 12.5, d1), stock('L2', 'E1', 300, 20, d1)],
    transfers: const [], deaths: [DeathFact(pondId: 'E1', count: 10, date: d2)]);
expect((at(b, 'L1', 'E1').live.count, at(b, 'L2', 'E1').live.count), (593, 297));
// Review Focus 1: more deaths than fish
final c = placements(stockings: [stock('L1', 'E1', 50, 12.5, d1)], transfers: const [],
    deaths: [DeathFact(pondId: 'E1', count: 500, date: d2)]);
expect((at(c, 'L1', 'E1').live.count, at(c, 'L1', 'E1').live.inconsistent), (0, true));
// deaths before any stocking
final e = placements(stockings: [stock('L1', 'E1', 100, 12.5, d2)], transfers: const [],
    deaths: [DeathFact(pondId: 'E1', count: 5, date: d1)]);
expect(at(e, 'L1', 'E1').live.count, 100); // nothing to die yet: dropped, documented
// a sample sets the weight
final f = placements(stockings: [stock('L1', 'E1', 1000, 12.5, d1)], transfers: const [],
    samples: [SampleFact(batchId: 'L1', pondId: 'E1', avgWeightG: 31.2, date: d3)]);
expect(at(f, 'L1', 'E1').avgWeightG, 31.2);
// ration
expect(pondRationG(batches: [(biomassG: 100000, phase: Phase.growout), (biomassG: 50000, phase: Phase.fry)], config: cfg), 6500);
expect(pondRationG(batches: [(biomassG: 100000, phase: Phase.growout)], lastLeftover: Leftover.lots, config: cfg), 3400);
expect(pondRationG(batches: const [], config: cfg), 0);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/` → FAIL.
- [ ] **Step 3: Implement.** Keep a running count per pair during the walk; finish with `liveCount`.
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): deaths and samples in fish per pond, pond ration`

### Task 3: Repositories for daily logs, water readings and samples

**Files:**
- Create: `lib/db/repositories/daily_log_repository.dart`, `lib/db/repositories/reading_repository.dart`
- Modify: `lib/db/repositories/batch_repository.dart` (`currentPlacements` adds sample and death facts), `lib/db/repositories/providers.dart`
- Test: `test/db/daily_log_repository_test.dart`, `test/db/reading_repository_test.dart`, `test/db/batch_repository_test.dart`

**Interfaces:**
- Consumes: `EventWrites`, `isCurrentEvent`, `Session`, `farmDateToUtc`, `farmDate`, `StaleEventException`.
- Produces (each repository is `(AppDatabase db, Session session, {String? visitId})`; every insert stamps `visitId`):
  - `class DailyLogInput { pondId, date, feedGivenG, feedings?, leftover?, ateFast, deaths, deathSigns, warningSigns, waterColour?, note?, observedBy? }`.
  - `DailyLogRepository`:
    - `Future<String> save(DailyLogInput input)`: if a current log for (pond, farm date) exists, supersede it; otherwise insert. `feedGivenG < 0` or `deaths < 0` → `ArgumentError`.
    - `Future<void> saveWeek(List<DailyLogInput> inputs)`: one transaction, each through `save`.
    - `Future<DailyLog?> forDay(String pondId, DateTime date)`.
    - `Stream<List<DailyLog>> watchRange(DateTime from, DateTime to)`: current logs in [from, to] farm dates.
    - `Stream<Set<String>> watchLoggedPondsOn(DateTime date)`.
    - `Future<DailyLog?> lastBefore(String pondId, DateTime date)`.
    - `Future<void> delete(String id)`.
  - `ReadingRepository`:
    - `Future<String> addWaterReading(WaterReadingInput)`: refused with `ArgumentError` when temperature, pH, oxygen, colour and renewed % are all null.
    - `Future<String> addSample(SampleInput)`: `fishCount ≤ 0` or `totalWeightG ≤ 0` → `ArgumentError`.
    - `Stream<WaterReading?> watchLatestWaterReading(String pondId)`, `Stream<List<Sample>> watchSamples(String batchId)`, plus `correct…`/`delete…` for each, through `EventWrites`.
  - `currentPlacements(db)` now passes `SampleFact` (avg = totalWeightG / fishCount) and `DeathFact` (from current daily logs with deaths > 0).

- [ ] **Step 1: Write the failing tests**
  - Saving a log for E1 on 01/03, then again on 01/03, leaves one current log carrying the second values, with `supersedesId` set (Review Focus 2).
  - Logs dated 01/03 and 02/03 are both current.
  - `forDay` finds the log whatever the phone zone (run under `TZ=UTC` too).
  - A log with 30 deaths lowers `currentPlacements` by 30.
  - A sample of 40 fish weighing 1 248 g sets the pair's weight to 31.2 g.
  - A water reading with every field null throws `ArgumentError`, and so does a sample of 0 fish; neither writes a row.
  - With `visitId: 'v1'`, the saved rows carry `v1`.
- [ ] **Step 2: Run to verify it fails.** `flutter test test/db/` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** `flutter test && TZ=UTC flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(db): daily logs, water readings and samples`

### Task 4: Repositories for health, observations and visits

**Files:**
- Create: `lib/db/repositories/health_repository.dart`, `lib/db/repositories/visit_repository.dart`
- Modify: `lib/db/repositories/providers.dart`
- Test: `test/db/health_repository_test.dart`, `test/db/visit_repository_test.dart`

**Interfaces:**
- Produces:
  - `HealthRepository(db, session, {visitId})`:
    - `Future<String> report({required String pondId, required Set<WarningSign> signs, String? suspectedIssue, required bool isolate, required bool technicianCalled})`: writes a health event. `isolate` sets the stored status to `isolated`, in the same transaction.
    - `Future<String> release(String pondId)`: writes a `released` event and sets the stored status to `empty`.
    - `Future<String> addTreatment(TreatmentInput)`.
    - `Stream<List<HealthEvent>> watchForPond(String pondId)`, `Stream<List<Treatment>> watchTreatments(String pondId)`.
  - `ObservationRepository` lives in `visit_repository.dart`:
    - `Future<String> addObservation({String? pondId, required ObservationCategory category, bool? ok, String? note})`.
    - `Stream<List<Observation>> watchForVisit(String visitId)`.
  - `VisitRepository(db, session)`:
    - `Future<String> start()`: throws `StateError` when this phone already has an open visit.
    - `Stream<Visit?> watchOpen()`: this site's visit with `endedAt == null` started on this device.
    - `Future<void> setSummary(String id, String? summary)`, `Future<void> end(String id)`.
    - `Stream<List<Visit>> watchAll()`: newest first.
  - Providers: `openVisitProvider = StreamProvider<Visit?>`. Every event repository provider is built with `visitId: ref.watch(openVisitProvider).value?.id`.

- [ ] **Step 1: Write the failing tests.**
  - Reporting with `isolate: true` makes the stored status `isolated`, and `BatchRepository.transfer` out of that pond then throws `PondIsolatedException`.
  - `release` makes the stored status `empty`, so the pond's derived status is `stocked` when it has fish.
  - A treatment is stored with its batch.
  - `start` twice throws `StateError`.
  - `end` clears `watchOpen`.
  - Review Focus 3: start a visit, close the database, reopen it on the same file (`NativeDatabase` on a temp file), and `watchOpen` still returns the visit.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(db): health events, treatments, observations and visits`

### Task 5: Worker widgets and Malagasy strings

**Files:**
- Create: `lib/features/common/pictograms.dart`, `lib/features/common/sign_grid.dart`, `lib/features/common/colour_swatches.dart`, `lib/features/common/leftover_picker.dart`, `lib/features/common/big_number_field.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `lib/l10n/labels.dart`
- Test: `test/features/worker_widgets_test.dart`

**Interfaces:**
- Produces:
  - `IconData warningSignIcon(WarningSign s)`, `IconData leftoverIcon(Leftover l)`, `Color waterColourValue(WaterColour c)`.
  - Labels on `EnumLabels`: `warningSign(WarningSign)`, `leftover(Leftover)`, `waterColour(WaterColour)`, `observationCategory(ObservationCategory)`, each with fr and mg ARB keys (`signNoAppetite`, …, `leftoverNone`, …, `waterClear`, …).
  - `SignGrid({required Set<WarningSign> options, required Set<WarningSign> selected, required ValueChanged<Set<WarningSign>> onChanged})`: a grid of 56 dp tiles, each icon plus label, toggling.
  - `ColourSwatches({WaterColour? value, required ValueChanged<WaterColour?> onChanged})`: five swatches; tapping the selected one clears it.
  - `LeftoverPicker({Leftover? value, bool ateFast, required onChanged})`: three pictograms, plus the "ate fast" toggle once "none" is chosen.
  - `BigNumberField({label, controller, decimal, suffix, hint})`: a 72 dp tall field with a large font and the numeric keypad. `hint` shows the target (the suggested ration) as a large number above it.

- [ ] **Step 1: Write the failing tests.**
  - Every `WarningSign`, `Leftover` and `WaterColour` has a distinct label in fr and in mg.
  - The sign grid toggles a sign on and off.
  - Tapping the selected swatch clears it.
  - "Ate fast" only appears once "none" is chosen.
  - Every tile measures ≥ 56 × 56 dp.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.** In `app_mg.arb`, every key used by these widgets and by Task 6's screens gets a Malagasy value. Add `"@@x-review": "M8"` metadata noting the strings are unreviewed.
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat: worker pictograms, sign grid, swatches and big number field`

### Task 6: Daily log screen and worker mode

**Files:**
- Create: `lib/features/daily_log/daily_log_screen.dart`, `lib/features/daily_log/worker_home_screen.dart`, `lib/features/daily_log/daily_log_providers.dart`
- Modify: `lib/features/ponds/pond_overview.dart` (`PondOverview` gains `rationG` and `isolated`), `lib/features/ponds/pond_detail_screen.dart` (button "Journal du jour"), `lib/features/more/more_screen.dart` ("Mode ouvrier"), `lib/router.dart`, `lib/l10n/*.arb`
- Test: `test/features/daily_log/daily_log_screen_test.dart`, `test/features/daily_log/worker_home_test.dart`

**Interfaces:**
- Consumes: `DailyLogRepository` (Task 3), Task 5 widgets, `pondRationG` (Task 2).
- Produces:
  - `PondOverview.rationG`: `pondRationG` over its batches with known weight, using the pond's last log before today. 0 with no fish.
  - Routes: `/worker` (`WorkerHomeScreen`, outside the shell) and `/log/:pondId?date=yyyy-mm-dd` (`DailyLogScreen`, pushed; the date defaults to today).
  - **Worker home:** one big tile per active pond, in its colour with its code. A tick shows on ponds logged today (`watchLoggedPondsOn`) and a red border on isolated ponds. The exit button sits in the app bar. Entering sets the locale to `mg`; exit sets it back to `fr` and goes to `/more`.
  - **Daily log screen:** the pond badge with the date. The suggested ration is shown large ("≈ 4,2 kg"). Below it: feed (`BigNumberField`, kg, required), feedings chips, leftovers, deaths (`BigNumberField`, defaults to 0), death signs once deaths > 0, the warning sign grid, water colour, and "+" for a note. An existing log for the day pre-fills every field. Save shows a green confirmation (`SnackBar` with a check) and pops back.

- [ ] **Step 1: Write the failing tests.**
  - Worker mode from More shows tiles E1 and E2 with Malagasy labels.
  - Tapping E1, entering feed `4,2` and leftovers "some", then saving: the tile shows the tick, and the stored log has `feedGivenG` 4200 and `leftover` some.
  - Opening E1 again shows 4,2, and saving again leaves one current log (Review Focus 2).
  - With a batch of 1 000 at 100 g (growout, 4 %), the screen shows "4 kg". After a log with leftovers "lots", tomorrow shows "3,4 kg".
  - Review Focus 1: deaths `500` in a pond of 50 fish saves; the pond card then shows 0 with "À vérifier", and the next ration is 0.
  - An isolated pond's tile and screen show the red banner.
  - Exit returns to More, in French.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(daily-log): worker home and daily log screen`

### Task 7: Water reading and sample screens

**Files:**
- Create: `lib/features/readings/water_reading_screen.dart`, `lib/features/readings/sample_screen.dart`
- Modify: `lib/features/ponds/pond_detail_screen.dart` (latest reading with out-of-range values in red, buttons "Relevé d'eau" and "Échantillonnage" per batch), `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/readings/water_reading_test.dart`, `test/features/readings/sample_test.dart`

**Interfaces:**
- Consumes: `ReadingRepository` (Task 3), `waterIssues`, `sampleResult`, `DomainConfig.sampleMinFish`.
- Produces: routes `/ponds/:id/water` and `/ponds/:id/sample?batchId=` (pushed). On the water form, the pH field takes a comma decimal; an out-of-range value turns red with its target ("cible 6,5 à 8,5"). On the sample form, fish count and total weight in kg are required; the average weight and "petit échantillon (moins de 30)" show live.

- [ ] **Step 1: Write the failing tests** (Review Focus 4).
  - Saving an empty water form shows "Obligatoire" and writes nothing.
  - pH `7,5` saves as 7.5.
  - Oxygen `2` shows in red before saving, and on the pond page after.
  - A sample of 0 fish shows "Obligatoire".
  - 20 fish weighing `0,62` kg shows "31 g" and the small-sample warning; after saving, the pond page shows the batch's weight as 31 g.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(readings): water readings and samples`

### Task 8: Transcription grid

**Files:**
- Create: `lib/features/transcription/transcription_screen.dart`, `lib/features/transcription/week.dart`
- Modify: `lib/features/more/more_screen.dart` ("Saisie des fiches"), `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/transcription/week_test.dart`, `test/features/transcription/transcription_test.dart`

**Interfaces:**
- Produces:
  - `List<DateTime> weekOf(DateTime farmDay)`: Monday to Sunday of the farm week, as date-only values (pure).
  - Route `/more/transcription`. The screen has a week picker (‹ week ›), a worker picker (active people, required), and the grid (rows: days `lun. 30/03`; columns: pond badges). Each cell has two small number fields (kg, deaths), with a sign tap-through opening `SignGrid` in a bottom sheet. Existing logs show greyed out; tapping one pushes `/log/:pondId?date=`. Save calls `saveWeek` with `observedBy` set to the chosen person.

- [ ] **Step 1: Write the failing tests**

```dart
expect(weekOf(DateTime(2026, 4, 1)).first, DateTime(2026, 3, 30)); // Wednesday → Monday 30/03
expect(weekOf(DateTime(2026, 4, 1)).last, DateTime(2026, 4, 5));
```
  - Widget test (Review Focus 5, also run under `TZ=UTC`): choose the week of 01/04/2026 and worker "Rakoto", enter E1 on 31/03 as 3 kg and 2 deaths, save. One log exists with farm date 31/03, `feedGivenG` 3000, `deaths` 2 and `observedBy` Rakoto's id.
  - A day already logged on the phone shows its value greyed out and isn't written again.
  - Saving without choosing a worker shows "Obligatoire".
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(transcription): weekly grid for paper sheets`

### Task 9: Health screens

**Files:**
- Create: `lib/features/health/report_problem_screen.dart`, `lib/features/health/treatment_screen.dart`, `lib/features/health/health_info.dart`
- Modify: `lib/features/ponds/pond_detail_screen.dart` (red banner; "Signaler un problème", "Lever l'isolement", "Traitement", health history), `lib/features/ponds/ponds_screen.dart` (red banner on isolated cards), `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/health/health_test.dart`

**Interfaces:**
- Consumes: `HealthRepository` (Task 4), `SignGrid`.
- Produces:
  - Routes `/ponds/:id/problem` and `/ponds/:id/treatment` (pushed).
  - **Problem screen:** a sign grid; "Problème suspecté" (optional); tick boxes "Isoler l'étang" and "Technicien ou vétérinaire appelé". Fixed text: "Isoler, ne déplacer ni poissons ni eau, appeler un technicien avant tout traitement."
  - **Info card:** the three diseases from DOMAIN with their signs, headed "Information, pas un diagnostic".
  - **Treatment screen:** batch (from the pond's batches), product, dose, date, advised by.
  - Release asks for confirmation.

- [ ] **Step 1: Write the failing tests.**
  - Reporting "rubbing" with "Isoler" ticked shows the red banner on the card and the page, and the pond's Transférer screen shows the isolated banner with no save.
  - "Lever l'isolement", confirmed, removes the banner, and the pond shows "Empoissonné".
  - A treatment shows in the pond's health history.
  - No screen contains a product suggestion: the treatment product field starts empty and has no dropdown of products.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(health): problems, isolation, release and treatments`

### Task 10: Visit tab

**Files:**
- Create: `lib/features/visit/visit_screen.dart`, `lib/features/visit/condition_check.dart`, `lib/features/visit/visit_checklist.dart`
- Modify: `lib/features/shell/member_shell.dart` (tabs Étangs, Visite, Plus), `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/visit/visit_checklist_test.dart`, `test/features/visit/visit_screen_test.dart`

**Interfaces:**
- Consumes: `VisitRepository`, `ObservationRepository` (Task 4), `PondOverview`, `sampleDueAlert`, `ReadingRepository` streams.
- Produces:
  - `class VisitChecklist { final List<Pond> waterDue; final List<(Batch, Pond)> samplesDue; final List<Pond> conditionsDue; }`.
  - `VisitChecklist buildChecklist({required List<PondOverview> ponds, required List<WaterReading> readingsThisVisit, required List<Sample> samplesThisVisit, required List<Observation> observationsThisVisit, required Map<(String, String), DateTime> lastSampleOrStocking, required DateTime today, required DomainConfig config})`: pure. Each list holds what's still to do. A stocked pond is due for water until this visit has a reading for it; a (batch, pond) is due for a sample when `sampleDueAlert` fires and this visit has no sample for it; a pond is due for conditions until all five categories have an observation in this visit.
  - **Visit tab, no visit open:** "Démarrer une visite" plus past visits (date, member, ended or not).
  - **Visit tab, visit open:** sections Eau, Échantillons, État des étangs, Biosécurité (tick boxes from DOMAIN §Biosecurity), Observations (free text plus category), Résumé (text, saved as you leave the field), then "Terminer la visite" (asks for confirmation).
  - **Condition check screen:** five rows per pond (OK, or problem plus note).

- [ ] **Step 1: Write the failing tests.**
  - `buildChecklist`: two stocked ponds and one reading for E1 leave `waterDue == [E2]`. A batch stocked 14 days ago is due for a sample; one sampled in this visit isn't.
  - Widget: start a visit; the checklist lists E1 under Eau. Record a water reading from it; E1 leaves the list, and the reading's `visitId` is the visit's.
  - Mark E1's five conditions OK; E1 leaves État des étangs.
  - Type a summary, then end the visit; the tab shows "Démarrer une visite", and the visit has `endedAt` and the summary.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(visit): visit checklist with water, samples, conditions and summary`

### Task 11: Milestone check

**Files:**
- Create: `integration_test/m3_recording_test.dart`

- [ ] **Step 1: Write the walk-through.**
  1. Set up the site, two ponds and a worker, and stock E1 with 1 000 fish at 15 g.
  2. In worker mode, log E1 (feed 0,6 kg, 3 deaths, leftovers "some", sign "rubbing"), then exit.
  3. Start a visit: water reading on E1 (pH 7,2, O₂ 4,5), a sample (30 fish, 0,6 kg), conditions OK, a summary, end the visit.
  4. Transcribe E1 for the day before (0,5 kg, 1 death) as Rakoto.
  5. Report a problem on E1 with isolation, then release it.
  6. Assert: E1 shows 996 fish estimated, its weight is 20 g, and it's stocked.
- [ ] **Step 2: Run it on the emulator in airplane mode.** Start `Dobo_API26_2GB` with `-gpu swangle_indirect`, turn on airplane mode, run `adb shell pm clear mg.dobo.dobo`, then `flutter test integration_test/m3_recording_test.dart -d emulator-5554`. Expected: passes.
- [ ] **Step 3: Persistence.** `adb shell pm clear`, then `flutter run --no-resident --target integration_test/m3_recording_test.dart`, then force-stop, `adb install -r` the normal debug APK, and launch. Expected: the pond list shows E1 with 996 fish, offline.
- [ ] **Step 4: Size.** `flutter build apk --release --split-per-abi`: the ARM APKs stay under 25 MB.
- [ ] **Step 5: Commit** `test: M3 walk-through as an on-device integration test`

---

## Out of scope for this plan

Accounts, roles, sync and the worker's locked-down app (M4). Alerts and the dashboard, including the duplicate pond-day flag and FCR display (M5). The visit report and photos (M6). Feed lots and stock, pond preparation, harvests and sales (M7). Paper sheet PDFs, Malagasy review and custom pictograms (M8).
