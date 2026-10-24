# M2: Farm Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A member can set up the site, its ponds and people, stock batches into ponds, move fish between ponds, and correct or delete those records, all on the phone with no network. Each pond shows its estimated fish, biomass, density and phase.

**Architecture:** Schema v2 adds `people`, `ponds` and `batches` (reference rows, edited in place) and `stockings` and `transfers` (append-only events). Repositories in `lib/db/repositories/` stamp every write with a `Session` (association, user, device, site) and apply the status rules. A new pure function, `placements()` in `lib/domain/occupancy.dart`, turns stockings and transfers into each batch's fish per pond. Screens in `lib/features/` read Drift `watch` streams through Riverpod providers.

**Tech Stack:** Flutter 3.47.8, Drift 2.35 (`make-migrations`), flutter_riverpod 3, go_router 18, ARB l10n. No new dependencies.

**Spec:** `CLAUDE.md`, `docs/SPEC.md` (§3 roles, §4 data model, §5 F1 and F2, §6 navigation, §7 sync, §11 M2), `docs/DOMAIN.md` (§Ponds, §Phases, §Species and fingerlings, §Formulas). The decisions below fill gaps in the spec; they are Claude's calls, made without the user, and can be revisited.

## Decisions (Claude's calls)

1. **Who is writing, before accounts exist.** Setup creates a local `association_id` and a placeholder `user_id` (UUIDv7, stored in `local_meta`). Every write takes them from a `Session`. M4 replaces the source with the Supabase session and rewrites these ids on rows that are still `pending` before their first push. The app is not given to the family before M4, so no synced row ever carries a placeholder id.
2. **Batch holds identity, not numbers.** `batches` stores code, strain, hatchery, certificate, monosex, planned harvest date and status. The stocking date, initial count and initial weight come from the batch's current `Stocking` event, so a corrected stocking corrects the batch too.
3. **Average weights are stored as integer milligrams** (`avg_weight_mg`). CLAUDE.md asks for integer grams, but whole grams lose too much at fry and fingerling size (5 g against 5.4 g is an 8 % biomass error). Totals stay in grams. The domain keeps working in `double` grams.
4. **Statuses.**
   - Pond `empty`, `preparing` and `ready` are set by hand. The prep checklist (F10, M7) will drive them later.
   - Stocking a pond, or moving fish into it, sets it to `stocked`. A move that leaves a pond with no fish sets it back to `empty`.
   - Nothing sets `isolated` until M3 (F9). The block on moving fish out of an `isolated` pond is still built and tested now.
   - Batch status: stocking into a pond whose role is `quarantine` sets the batch to `quarantine`; any other pond sets it to `active`. Moving fish from a quarantine pond to a pond with another role sets the batch to `active`.
   - Closing a batch moves to M7 together with harvests (F12).
   - Correcting or deleting an event never changes a status. The member fixes the status by hand if needed.
5. **Warn, don't block,** in four cases: stocking a pond that isn't `ready`; stocking or moving fish into an `isolated` pond; an average stocking weight outside 10–20 g; moving more fish than the estimate says the pond holds. The estimate is an upper bound, so the farm's records are what's wrong in that last case, and the move is what happened on the ground. **Blocked:** moving fish out of an `isolated` pond, moving fish to the same pond, and a count ≤ 0.
6. **No unique constraints on synced tables.** Two phones can legitimately create the same pond code offline, so the database never refuses such a row. The repository refuses a duplicate pond code or batch code on this phone (codes are trimmed and compared without regard to case, among ponds that aren't archived); duplicates that arrive by sync are shown as they are.
7. **Nothing is deleted from the reference tables.** Ponds get `archived`, people get `active`. Batches will be closed in M7.
8. **Only the stocking avg weight exists until samples arrive (M3).** A pond's average weight for a batch is the weight of the most recent stocking or move into it. A move without a weight takes the source pond's weight at that moment. Phase, biomass and the feeding guide on screen come from that weight and are labelled "estimated".
9. **Navigation.** The member shell has two tabs in M2: **Ponds** and **More** (batches, people). The Visit, Alerts and Reports tabs from SPEC §6 are added in the milestones that build them, rather than shown empty now.
10. **Language.** M2 screens are member screens: French strings only. `app_mg.arb` gets no new keys, and `gen-l10n` falls back to French for them. Malagasy is reviewed in M8.
11. **Dates entered by hand** (stocking date, move date, planned harvest) are date-only. Each is stored as 12:00 Madagascar time in UTC and shown as `dd/mm/yyyy`.

## Global Constraints

- Offline only: no network code in M2. Every write is a local Drift transaction.
- Append-only events: `stockings` and `transfers` are only inserted. A correction is a new row with `supersedes_id`. A deletion is a copy of the target with `is_tombstone = true` and `supersedes_id = target.id`.
- Every synced row is written with `association_id`, `entered_by`, `device_id` from the `Session`; `sync_state` stays `pending`.
- Schema change: `schemaVersion` 1 → 2, migration written with Drift's `stepByStep`, then `dart run drift_dev make-migrations`; commit `drift_schemas/default/drift_schema_v2.json`, the generated steps file and the generated tests in `test/db/`.
- Nothing under `lib/domain/` imports Flutter, Drift or `lib/db/` (`test/domain/purity_test.dart` enforces it). `lib/db/` may import `lib/domain/` enums.
- Farming numbers come from `DomainConfig.defaults`; no DOMAIN value appears as a literal in `lib/`.
- Every user-facing string comes from `lib/l10n/app_fr.arb`. Numbers display with a decimal comma; number fields use the numeric keypad and accept `,` or `.`.
- Touch targets ≥ 56 dp on every button and list row.
- `flutter analyze` reports no issues and `flutter test` passes at the end of every task. Tests must pass under `TZ=UTC` as well as the machine zone.
- Commits: conventional prefix, body ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Work on branch `feat/m2-farm-setup` from `main`.

## Review Focus

1. **A stocking corrected below what has already been moved out** (stocked 1 000, moved 800, stocking corrected to 500): the source pond shows 0 fish flagged "inconsistent", never a negative number, and the screens don't crash. Tests in Task 4 and Task 9.
2. **The same pond code typed twice with different case or spaces** (`"E1"` and `" e1 "`): the second is refused as a duplicate; an archived `E1` doesn't block a new one. Test in Task 5.
3. **Decimal comma** in average weight or length (`12,5`): read as 12.5; `abc` or an empty field is "no value", not a crash. Test in Task 6.
4. **A stocking deleted after its batch was created:** the batch stays in the list with no fish and no initial numbers, and its pond doesn't show it. Test in Task 5.
5. **A failed write leaves nothing behind:** `stockBatch` with count 0 throws and leaves no `batches` row and no pond status change. Test in Task 5.

---

### Task 1: Schema v2

**Files:**
- Modify: `lib/domain/types.dart`, `lib/db/database.dart`
- Create: `lib/db/tables/people.dart`, `lib/db/tables/ponds.dart`, `lib/db/tables/batches.dart`, `lib/db/tables/stockings.dart`, `lib/db/tables/transfers.dart`, generated `lib/db/database.steps.dart`
- Test: `test/db/schema_v2_test.dart`, generated `test/db/migration_test.dart` and `test/db/generated/`

**Interfaces:**
- Produces (`types.dart`):
  - `enum PondStatus { empty, preparing, ready, stocked, isolated }`
  - `enum BatchStatus { quarantine, active, harvesting, closed }`
  - `enum PondColour { blue, green, yellow, orange, red, purple, brown, black }`: colours that stay distinct on paper and in sunlight.
- Produces (tables; all `with SyncedRow` plus `ReferenceRow` or `EventRow`; Drift class names `Person`, `Pond`, `Batch`, `Stocking`, `Transfer`):
  - `People` (Reference): `name` text, `phone` text nullable, `note` text nullable, `active` bool default true.
  - `Ponds` (Reference): `siteId` text, `code` text, `colour` `textEnum<PondColour>`, `structure` `textEnum<StructureType>` default `earth`, `role` `textEnum<PondRole>`, `waterSupply` `textEnum<WaterSupply>` nullable, `lengthM`, `widthM`, `surfaceM2Override`, `depthInletM`, `depthOutletM` real nullable, `status` `textEnum<PondStatus>` default `empty`, `archived` bool default false.
  - `Batches` (Reference): `siteId` text, `code` text, `strain`, `hatchery`, `certificateNo` text nullable, `monosex` bool nullable, `plannedHarvestOn` dateTime nullable, `status` `textEnum<BatchStatus>`.
  - `Stockings` (Event): `batchId`, `pondId` text, `count` int, `avgWeightMg` int, `acclimatised` bool nullable.
  - `Transfers` (Event): `batchId`, `fromPondId`, `toPondId` text, `count` int, `avgWeightMg` int nullable.
  - `AppDatabase.schemaVersion => 2`; `migration` uses `stepByStep(from1To2: …)` creating the five tables.

- [ ] **Step 1: Write the failing test** `test/db/schema_v2_test.dart` (in-memory DB, pattern of `test/db/database_test.dart`):

```dart
test('event rows default to current, not tombstoned', () async {
  // insert a Pond, a Batch, then a Stocking with recordedAt = DateTime.utc(2026, 3, 1, 9)
  expect(stocking.isTombstone, isFalse);
  expect(stocking.supersedesId, isNull);
  expect(stocking.syncState, SyncState.pending);
});
test('pond defaults: earth, empty, not archived', () async {
  expect((pond.structure, pond.status, pond.archived), (StructureType.earth, PondStatus.empty, false));
});
test('two ponds may share a code at database level', () async {
  // insert two ponds with code 'E1' → both rows exist (no unique constraint, Decision 6)
});
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/db/schema_v2_test.dart` → FAIL (tables not defined).
- [ ] **Step 3: Add the enums and tables, bump `schemaVersion` to 2, run** `dart run build_runner build --delete-conflicting-outputs`, **then** `dart run drift_dev make-migrations`, **write `from1To2` in `database.dart` with the generated `stepByStep`, and run both commands again.**
- [ ] **Step 4: Run to verify it passes.** `flutter test test/db/` → PASS, including the generated v1→v2 migration test; `drift_schemas/default/drift_schema_v2.json` exists.
- [ ] **Step 5: Commit** `feat(db): schema v2 with people, ponds, batches, stockings and transfers`

### Task 2: Current-version reads for event tables

**Files:**
- Create: `lib/db/events.dart`
- Test: `test/db/events_test.dart`

**Interfaces:**
- Consumes: `Stockings`, `Transfers` (Task 1).
- Produces:
  - `Expression<bool> isCurrentEvent(EventRow t, TableInfo<Table, Object?> table)`: true for rows that are not tombstones and that no row in the same table supersedes. In SQL terms: `is_tombstone = 0 AND id NOT IN (SELECT supersedes_id FROM <table> WHERE supersedes_id IS NOT NULL)`.
  - `extension EventWrites on AppDatabase` with `Future<String> supersede<T extends Table, D>(TableInfo<T, D> table, String oldId, Insertable<D> replacement)` (inserts `replacement` with `supersedesId = oldId`, `isTombstone = false`) and `Future<String> tombstone<T extends Table, D extends DataClass>(TableInfo<T, D> table, String id, Session s)` (reads the target, inserts a copy with a new id, `isTombstone = true`, `supersedesId = id`, the session's `enteredBy`/`deviceId` and a fresh `createdAtDevice`). Both run in a transaction and return the new row's id. `Session` comes from Task 3; until Task 3 lands, put `class Session` in `lib/db/session.dart` here (fields listed in Task 3).

- [ ] **Step 1: Write the failing tests** (use `stockings`; `s(count)` inserts a stocking):

```dart
test('a correction replaces the original', ...);           // A, B supersedes A → current = [B]
test('a correction of a correction leaves only the last', ...); // A, B⊃A, C⊃B → [C]
test('a tombstone hides the record and itself', ...);      // A, T tomb⊃A → []
test('deleting a correction does not bring back the original', ...); // A, B⊃A, T tomb⊃B → []
test('two corrections of the same record from two phones are both kept', ...); // A, B⊃A, C⊃A → {B, C}
test('tables do not see each other\'s supersedes', ...);  // transfer row with supersedesId = stocking A's id → A still current
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/db/events_test.dart` → FAIL.
- [ ] **Step 3: Implement** `lib/db/events.dart` (and `lib/db/session.dart`).
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(db): current-version reads, corrections and tombstones for events`

### Task 3: Session, farm dates and first-launch setup

**Files:**
- Modify: `lib/domain/dates.dart`, `lib/db/session.dart`, `lib/router.dart`, `lib/app.dart`, `lib/l10n/app_fr.arb`, `test/app_test.dart`
- Create: `lib/db/repositories/setup_repository.dart`, `lib/db/repositories/providers.dart`, `lib/features/setup/setup_screen.dart`
- Delete: `lib/features/home/home_screen.dart` and its ARB key `homeWelcome` (fr and mg); the Malagasy app test looks up a widget in the shell instead of `HomeScreen`
- Test: `test/domain/dates_test.dart`, `test/db/setup_repository_test.dart`, `test/features/setup_test.dart`, `test/app_test.dart`

**Interfaces:**
- Produces (`dates.dart`):
  - `DateTime farmDateToUtc(DateTime date)`: the calendar date of `date` (its year/month/day fields, whatever its zone) at 12:00 Madagascar time, as UTC. `DateTime.utc(y, m, d, 12).subtract(farmUtcOffset)`.
  - `DateTime farmDate(DateTime t)`: the Madagascar calendar day of `t` as a date-only `DateTime(y, m, d)` (local, used for display and pickers). Shares the conversion `daysBetween` uses.
- Produces (`session.dart`): `class Session { const Session({required this.associationId, required this.userId, required this.deviceId, required this.siteId}); final String associationId, userId, deviceId, siteId; }`
- Produces (`setup_repository.dart`): `class SetupRepository { SetupRepository(this.db); Future<Session?> currentSession(); Future<Session> completeSetup({required String siteName, String? locationNote}); }`. `completeSetup` creates `association_id` and `user_id` (`newId()`) in `local_meta`, inserts the site, stores `site_id`, all in one transaction; calling it twice throws `StateError`.
- Produces (`providers.dart`): `final sessionProvider = FutureProvider<Session?>`, `final setupRepositoryProvider = Provider<SetupRepository>`; later tasks add their repository providers here.
- Produces (`router.dart`): routes `/setup`, and a `StatefulShellRoute` with branches `/ponds` and `/more`; redirect to `/setup` while `sessionProvider` is null, and away from `/setup` once set. `/ponds` and `/more` show placeholder `Scaffold`s until Tasks 7–8.
- ARB keys: `setupTitle` "Installation", `setupSiteName` "Nom du site", `setupLocationNote` "Lieu (facultatif)", `setupStart` "Commencer", `tabPonds` "Étangs", `tabMore` "Plus", `fieldRequired` "Obligatoire".

- [ ] **Step 1: Write the failing tests**

```dart
// dates_test.dart (pass under TZ=UTC too)
expect(farmDateToUtc(DateTime(2026, 3, 1)), DateTime.utc(2026, 3, 1, 9));
expect(farmDate(DateTime.utc(2026, 3, 1, 21, 30)), DateTime(2026, 3, 2));
expect(daysBetween(farmDateToUtc(DateTime(2026, 3, 1)), farmDateToUtc(DateTime(2026, 3, 15))), 14);
// setup_repository_test.dart
expect(await repo.currentSession(), isNull);
final s = await repo.completeSetup(siteName: 'Ambohidratrimo');
expect(await repo.currentSession(), isA<Session>().having((x) => x.siteId, 'siteId', s.siteId));
expect(s.deviceId, await db.deviceId());
await expectLater(repo.completeSetup(siteName: 'X'), throwsStateError);
// setup_test.dart: fresh in-memory DB → setup screen; empty name + Commencer shows "Obligatoire";
// "Ambohidratrimo" + Commencer lands on the Étangs tab.
// app_test.dart: both tests override databaseProvider with AppDatabase(NativeDatabase.memory()),
// pre-run completeSetup, and look for 'Étangs' instead of 'Bienvenue'. The Malagasy test keeps its
// fallback assertion; the mg tab label falls back to French.
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/domain/dates_test.dart test/db/setup_repository_test.dart test/features/setup_test.dart test/app_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify they pass.** `flutter test && TZ=UTC flutter test && flutter analyze` → all pass, no issues.
- [ ] **Step 5: Commit** `feat: first-launch setup, session and member shell`

### Task 4: Fish per pond (domain)

**Files:**
- Create: `lib/domain/occupancy.dart`
- Modify: `lib/domain/pond.dart`
- Test: `test/domain/occupancy_test.dart`, `test/domain/pond_test.dart`

**Interfaces:**
- Consumes: `LiveCount`, `liveCount` (stock.dart).
- Produces:
  - `class StockingFact { const StockingFact({required this.batchId, required this.pondId, required this.count, required this.avgWeightG, required this.date}); … double avgWeightG; DateTime date; }`
  - `class TransferFact { const TransferFact({required this.batchId, required this.fromPondId, required this.toPondId, required this.count, this.avgWeightG, required this.date}); … double? avgWeightG; }`
  - `class Placement { final String batchId; final String pondId; final LiveCount live; final double? avgWeightG; }`
  - `List<Placement> placements({required List<StockingFact> stockings, required List<TransferFact> transfers})`: one entry per (batch, pond) pair that any fact touches. `live` = `liveCount(stocked: Σ stockings into the pair, transferredIn: Σ moves in, transferredOut: Σ moves out)`. Avg weight: walk all facts in `date` order (stockings before moves on the same date). A stocking sets its pair's weight; a move sets the destination's weight to its own `avgWeightG`, or to the source pair's current weight when null. Deaths and harvests join in M3/M7 as extra fact lists.
  - `double? pondSurfaceM2({double? lengthM, double? widthM, double? overrideM2})` in `pond.dart`: `overrideM2` when > 0, else `lengthM × widthM` when both > 0, else null.

- [ ] **Step 1: Write the failing tests**

```dart
final d1 = DateTime(2026, 3, 1), d2 = DateTime(2026, 3, 20);
Placement at(List<Placement> ps, String b, String p) => ps.singleWhere((x) => x.batchId == b && x.pondId == p);
final ps = placements(
  stockings: [StockingFact(batchId: 'L1', pondId: 'E1', count: 1000, avgWeightG: 12.5, date: d1)],
  transfers: [TransferFact(batchId: 'L1', fromPondId: 'E1', toPondId: 'E2', count: 300, avgWeightG: 30, date: d2)]);
expect(at(ps, 'L1', 'E1').live.count, 700);
expect(at(ps, 'L1', 'E2').live.count, 300);
expect(at(ps, 'L1', 'E1').avgWeightG, 12.5);
expect(at(ps, 'L1', 'E2').avgWeightG, 30.0);
// a move without weight carries the source weight
final q = placements(stockings: [...same...], transfers: [TransferFact(batchId: 'L1', fromPondId: 'E1', toPondId: 'E2', count: 300, date: d2)]);
expect(at(q, 'L1', 'E2').avgWeightG, 12.5);
// Review Focus 1: corrected stocking below what was moved out
final bad = placements(
  stockings: [StockingFact(batchId: 'L1', pondId: 'E1', count: 500, avgWeightG: 12.5, date: d1)],
  transfers: [TransferFact(batchId: 'L1', fromPondId: 'E1', toPondId: 'E2', count: 800, date: d2)]);
expect((at(bad, 'L1', 'E1').live.count, at(bad, 'L1', 'E1').live.inconsistent), (0, true));
// two batches in one pond stay separate; no facts → empty list
expect(placements(stockings: const [], transfers: const []), isEmpty);
// pond.dart
expect(pondSurfaceM2(lengthM: 30, widthM: 15), 450.0);
expect(pondSurfaceM2(lengthM: 30, widthM: 15, overrideM2: 420), 420.0);
expect(pondSurfaceM2(lengthM: 30), isNull);
expect(pondSurfaceM2(lengthM: 30, widthM: 15, overrideM2: 0), 450.0);
```

- [ ] **Step 2: Run to verify it fails.** `flutter test test/domain/occupancy_test.dart test/domain/pond_test.dart` → FAIL.
- [ ] **Step 3: Implement** `occupancy.dart` and `pondSurfaceM2`.
- [ ] **Step 4: Run to verify they pass.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(domain): fish per pond from stockings and transfers, pond surface`

### Task 5: Repositories for people, ponds, batches and moves

**Files:**
- Create: `lib/db/repositories/person_repository.dart`, `lib/db/repositories/pond_repository.dart`, `lib/db/repositories/batch_repository.dart`
- Modify: `lib/db/repositories/providers.dart`
- Test: `test/db/person_repository_test.dart`, `test/db/pond_repository_test.dart`, `test/db/batch_repository_test.dart`

**Interfaces:**
- Consumes: `Session` (Task 3), `isCurrentEvent`, `EventWrites` (Task 2), `farmDateToUtc` (Task 3), `placements`, `StockingFact`, `TransferFact` (Task 4).
- Produces (each repository takes `(AppDatabase db, Session session)`; every insert stamps `associationId`, `enteredBy = session.userId`, `deviceId`; every update sets `updatedAtDevice = utcNow()` and `syncState = pending`):
  - `PersonRepository`: `Stream<List<Person>> watchAll()` (active first, then by name), `Future<String> create({required String name, String? phone, String? note})`, `Future<void> update(String id, {required String name, String? phone, String? note, required bool active})`.
  - `PondRepository`: `Stream<List<Pond>> watchActive()` (site's non-archived ponds by code), `Future<Pond> get(String id)`, `Future<String> create(PondInput input)`, `Future<void> update(String id, PondInput input)`, `Future<void> setStatus(String id, PondStatus status)`, `Future<void> archive(String id)`. `PondInput` carries every editable `Ponds` column except `status`/`archived`. Duplicate code → `throw DuplicateCodeException(code)`. `PondColour nextFreeColour(List<Pond> ponds)`: first palette colour not used by an active pond, else `PondColour.blue`.
  - `BatchRepository`:
    - `Stream<List<BatchSummary>> watchAll()`; `class BatchSummary { final Batch batch; final Stocking? firstStocking; final int liveCount; }`, where `firstStocking` is the earliest current stocking and `liveCount` is the sum over its placements.
    - `Stream<List<Placement>> watchPlacements()`: current stockings and transfers → `placements()`, with `avgWeightMg / 1000` as grams and `recordedAt` as dates.
    - `Stream<List<BatchEvent>> watchHistory(String batchId)`: current stockings and transfers, newest first; `sealed class BatchEvent` with `StockingEvent(Stocking)` and `TransferEvent(Transfer)`.
    - `Future<String> stockBatch(StockInput input)`: one transaction. Inserts the batch (status per Decision 4), inserts the stocking, sets the pond to `stocked`, returns the batch id. `StockInput`: `code`, `strain?`, `hatchery?`, `certificateNo?`, `monosex?`, `plannedHarvestOn?`, `pondId`, `date`, `count`, `avgWeightMg`, `acclimatised?`. `count ≤ 0` or `avgWeightMg ≤ 0` → `ArgumentError`, before anything is written. Duplicate batch code in the site → `DuplicateCodeException`.
    - `Future<void> updateBatch(String id, BatchInput input)`: the identity fields only.
    - `String suggestBatchCode(List<Batch> batches, DateTime today)`: `L<yy>-<nn>`, where `nn` is one more than the highest `nn` already used that year, zero-padded to 2 (`L26-01`, `L26-02`, …).
    - `Future<String> transfer(TransferInput input)`: `batchId`, `fromPondId`, `toPondId`, `date`, `count`, `avgWeightMg?`. Same pond → `ArgumentError`; `count ≤ 0` → `ArgumentError`; source pond `isolated` → `PondIsolatedException`. Status effects per Decision 4, computed from `placements()` after the insert and in the same transaction.
    - `Future<String> correctStocking(String id, StockingCorrection c)` (count, avgWeightMg, date, acclimatised, pondId), `Future<String> correctTransfer(String id, TransferInput input)`, `Future<void> deleteStocking(String id)`, `Future<void> deleteTransfer(String id)`: via `EventWrites`; statuses untouched.
- Exceptions in `lib/db/repositories/errors.dart`: `DuplicateCodeException(String code)`, `PondIsolatedException(String pondId)`.

- [ ] **Step 1: Write the failing tests**

```dart
// pond_repository_test.dart
await ponds.create(input(code: 'E1'));
await expectLater(ponds.create(input(code: ' e1 ')), throwsA(isA<DuplicateCodeException>())); // Review Focus 2
await ponds.archive(e1Id);
expect(await ponds.create(input(code: 'E1')), isA<String>());
expect(nextFreeColour([pond(colour: PondColour.blue)]), PondColour.green);
// update marks the row pending again and bumps updatedAtDevice

// batch_repository_test.dart (ponds: E1 earth, Q1 quarantine, E2 earth; session s)
final l1 = await batches.stockBatch(stock(code: 'L26-01', pondId: q1, count: 1000, avgWeightMg: 12500));
expect((await batch(l1)).status, BatchStatus.quarantine);
expect((await ponds.get(q1)).status, PondStatus.stocked);
expect(stockingRow.enteredBy, s.userId);
await batches.transfer(move(l1, from: q1, to: e1, count: 1000));
expect((await batch(l1)).status, BatchStatus.active);
expect((await ponds.get(q1)).status, PondStatus.empty);
expect((await ponds.get(e1)).status, PondStatus.stocked);
await expectLater(batches.transfer(move(l1, from: e1, to: e1, count: 10)), throwsArgumentError);
await ponds.setStatus(e1, PondStatus.isolated);
await expectLater(batches.transfer(move(l1, from: e1, to: e2, count: 10)), throwsA(isA<PondIsolatedException>()));
// Review Focus 5
await expectLater(batches.stockBatch(stock(code: 'L26-02', pondId: e2, count: 0)), throwsArgumentError);
expect(await db.select(db.batches).get(), hasLength(1));
expect((await ponds.get(e2)).status, PondStatus.empty);
// corrections, on a fresh database: L26-01 stocked into E1 with 1 000 fish (stocking id st1), no moves
final st2 = await batches.correctStocking(st1, correction(count: 900));
expect(summaryOf(l1).liveCount, 900);
expect(summaryOf(l1).firstStocking!.id, st2);
// Review Focus 4
await batches.deleteStocking(st2);
expect(summaryOf(l1).firstStocking, isNull);
expect(summaryOf(l1).liveCount, 0);
expect(await batches.watchPlacements().first, isEmpty);
// codes
expect(batches.suggestBatchCode([], DateTime(2026, 3, 1)), 'L26-01');
expect(batches.suggestBatchCode([batch(code: 'L26-07'), batch(code: 'L25-12')], DateTime(2026, 3, 1)), 'L26-08');
// person_repository_test.dart: create, update active=false → sorted after active people
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/db/` → FAIL.
- [ ] **Step 3: Implement** the three repositories, `errors.dart`, and their providers (`personRepositoryProvider`, `pondRepositoryProvider`, `batchRepositoryProvider`, each built from `databaseProvider` and the loaded `sessionProvider`).
- [ ] **Step 4: Run to verify they pass.** `flutter test && TZ=UTC flutter test` → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(db): repositories for people, ponds, batches, stockings and transfers`

### Task 6: Shared form widgets, labels and number parsing

**Files:**
- Modify: `lib/l10n/formatting.dart`, `lib/l10n/app_fr.arb`
- Create: `lib/l10n/labels.dart`, `lib/features/common/number_field.dart`, `lib/features/common/date_field.dart`, `lib/features/common/pond_colour.dart`, `lib/features/common/estimated.dart`
- Test: `test/l10n/formatting_test.dart`, `test/features/common_widgets_test.dart`

**Interfaces:**
- Produces:
  - `double? parseDecimal(String text)`: trims; accepts `,` or `.` as the decimal mark; spaces (including the narrow no-break space) are ignored; `''` or non-numeric → null.
  - `String formatDate(DateTime t)` → `dd/mm/yyyy` of `farmDate(t)`.
  - `String formatGrams(double g, Locale l)` → `'12,5 g'` (one decimal at most); `String formatDecimal(double v, Locale l, {int decimals = 1})`.
  - `extension EnumLabels on AppLocalizations`: `String pondStatus(PondStatus)`, `structure(StructureType)`, `pondRole(PondRole)`, `waterSupply(WaterSupply)`, `pondColour(PondColour)`, `batchStatus(BatchStatus)`, `phase(Phase)`, `pondDesignWarning(PondDesignWarning)`, `densityStatus(DensityStatus)`; one ARB key per value (`pondStatusEmpty` "Vide", `structureEarth` "Étang en terre", `roleQuarantine` "Quarantaine", `phaseGrowout` "Grossissement", `warnSurfaceTooSmall` "Surface sous 200 m² (conseillé 200–1 000 m²)", …). Warning texts that quote a DOMAIN number take it as an ARB placeholder filled from `DomainConfig.defaults`.
  - `class NumberField extends StatelessWidget`: label, controller, `decimal` flag, optional suffix (`kg`, `g`, `m`, `m²`); numeric keypad (`TextInputType.numberWithOptions(decimal: decimal)`); height ≥ 56 dp.
  - `class DateField extends StatelessWidget`: shows `formatDate`, opens `showDatePicker` (locale `fr`), `onChanged(DateTime)` with a date-only value.
  - `Color pondColourValue(PondColour c)` and `class PondBadge extends StatelessWidget` (pond code on its colour, contrast-checked text colour).
  - `class EstimatedLabel extends StatelessWidget`: wraps a value with the ARB word `estimated` "estimé" (SPEC anti-goal: estimates never look exact).

- [ ] **Step 1: Write the failing tests**

```dart
expect(parseDecimal('12,5'), 12.5);   // Review Focus 3
expect(parseDecimal(' 12.5 '), 12.5);
expect(parseDecimal('1 250,5'), 1250.5);
expect(parseDecimal(''), isNull);
expect(parseDecimal('abc'), isNull);
expect(formatDate(DateTime.utc(2026, 3, 1, 21, 30)), '02/03/2026');
expect(formatGrams(12.5, const Locale('fr')), '12,5 g');
expect(formatGrams(250, const Locale('fr')), '250 g');
// common_widgets_test: NumberField uses the number keyboard and is ≥ 56 dp tall;
// every PondColour has a label and a distinct colour value.
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/l10n/ test/features/common_widgets_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify they pass.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat: form fields, enum labels and decimal-comma parsing`

### Task 7: People screens

**Files:**
- Create: `lib/features/people/people_screen.dart`, `lib/features/people/person_form_screen.dart`, `lib/features/more/more_screen.dart`
- Modify: `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/people_test.dart`

**Interfaces:**
- Consumes: `PersonRepository` (Task 5). The phone field is a plain text field with `TextInputType.phone`.
- Produces: routes `/more` (`MoreScreen`: rows "Lots", "Personnes"), `/more/people`, `/more/people/new`, `/more/people/:id`. ARB: `morePeople` "Personnes", `moreBatches` "Lots", `personName` "Nom", `personPhone` "Téléphone", `personNote` "Note", `personActive` "Actif", `save` "Enregistrer", `add` "Ajouter".

- [ ] **Step 1: Write the failing test.** Widget test with an in-memory DB and session: Plus → Personnes → Ajouter → name "Rakoto" → Enregistrer → list shows "Rakoto"; open it, untick Actif, save → row shows as inactive (greyed, sorted last); saving with an empty name shows "Obligatoire".
- [ ] **Step 2: Run to verify it fails.** `flutter test test/features/people_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(people): list and form`

### Task 8: Pond screens

**Files:**
- Create: `lib/features/ponds/ponds_screen.dart`, `lib/features/ponds/pond_form_screen.dart`, `lib/features/ponds/pond_detail_screen.dart`, `lib/features/ponds/pond_overview.dart`
- Modify: `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/ponds/pond_overview_test.dart`, `test/features/ponds/pond_form_test.dart`, `test/features/ponds/ponds_screen_test.dart`

**Interfaces:**
- Consumes: `PondRepository`, `BatchRepository.watchPlacements`, `BatchRepository.watchAll` (Task 5); `pondSurfaceM2`, `pondDesignWarnings`, `densityPerM2`, `densityStatus`, `biomassG`, `phaseFor`, `feedingGuideFor` (domain); Task 6 widgets.
- Produces:
  - `class PondOverview { final Pond pond; final double? surfaceM2; final List<BatchInPond> batches; final int liveCount; final bool inconsistent; final int? biomassG; final double? density; final DensityStatus? densityStatus; }`, `class BatchInPond { final Batch batch; final Placement placement; final Phase? phase; final int? biomassG; }`. Only placements with `count > 0` or `inconsistent` appear. `biomassG` is null when any batch in the pond has no weight.
  - `PondOverview buildPondOverview(Pond pond, List<Placement> placements, Map<String, Batch> batches, DomainConfig config)`: pure, in `pond_overview.dart`.
  - `final pondOverviewsProvider = StreamProvider<List<PondOverview>>`: combines the three streams.
  - Routes: `/ponds` (list), `/ponds/new`, `/ponds/:id`, `/ponds/:id/edit`.
  - **Ponds list:** one card per pond with `PondBadge`, role, status, live count and biomass with `EstimatedLabel`, density and its status (red when out of range); "Ajouter un étang" button; empty state "Aucun étang : ajoutez le premier".
  - **Pond form:** code, colour (8 swatches, the first free colour preselected), structure, role, water supply, length, width, surface (shows the computed value; editable override), depth at inlet/outlet, status (`empty`/`preparing`/`ready` only; `stocked`/`isolated` are shown, not chosen). Design warnings show live under the fields, in amber, never blocking. Duplicate code shows "Ce code existe déjà".
  - **Pond detail:** the overview figures; for each batch: code, phase, avg weight, count, biomass, feeding guide (protein, pellet, feedings/day); buttons "Empoissonner" (→ Task 9 with `pondId`), "Transférer" per batch (→ Task 10), "Modifier", "Archiver" (confirm dialog).

- [ ] **Step 1: Write the failing tests**

```dart
// pond_overview_test.dart (pure)
final o = buildPondOverview(pond(code: 'E1', length: 30, width: 15, structure: earth), [placement('L1', 'E1', 1000, 12.5)], {'L1': batchL1}, cfg);
expect((o.surfaceM2, o.liveCount, o.biomassG), (450.0, 1000, 12500));
expect(o.density, closeTo(2.22, 0.01));
expect(o.densityStatus, DensityStatus.within);
expect(o.batches.single.phase, Phase.pregrow);
// no surface → density and status null, no exception
expect(buildPondOverview(pond(code: 'E2'), [placement('L1', 'E2', 100, 12.5)], {...}, cfg).density, isNull);
// inconsistent placement (Review Focus 1) → liveCount 0, inconsistent true
// pond_form_test.dart: length 10, width 10 → shows "100 m²" and the surface-too-small and not-elongated
// warnings; Enregistrer still saves; second pond "e1" → "Ce code existe déjà".
// ponds_screen_test.dart: two ponds → two cards with codes; a stocked pond shows "1 000" and "estimé".
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/features/ponds/` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify they pass.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(ponds): pond list, form with design warnings, and detail`

### Task 9: Stocking and batch screens

**Files:**
- Create: `lib/features/batches/stock_screen.dart`, `lib/features/batches/batches_screen.dart`, `lib/features/batches/batch_detail_screen.dart`, `lib/features/batches/stocking_warnings.dart`
- Modify: `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/batches/stocking_warnings_test.dart`, `test/features/batches/stock_screen_test.dart`, `test/features/batches/batch_detail_test.dart`

**Interfaces:**
- Consumes: `BatchRepository` (Task 5), `PondOverview` (Task 8), `DomainConfig.stockingWeightG`, `acclimatisationMinutes`, `densityPerM2`.
- Produces:
  - `enum StockingWarning { pondNotReady, pondIsolated, weightOutsideRange, densityBelow, densityAbove }` and `Set<StockingWarning> stockingWarnings({required PondOverview target, required int addedCount, double? avgWeightG, required DomainConfig config})`: pure. Density is checked on (fish already in the pond + `addedCount`) over the pond surface.
  - Routes: `/stock?pondId=` (`StockScreen`), `/more/batches`, `/more/batches/:id`, `/more/batches/:id/stockings/:stockingId/edit`.
  - **Stock screen:** pond picker (ready ponds first, each with its status), batch code (prefilled with `suggestBatchCode`), date (today), count, avg weight (g, decimal), strain, hatchery, certificate, monosex (yes/no/unknown), planned harvest (optional), "Acclimatés 15–20 min" checkbox. A live panel shows the resulting density against the range and the warnings. A fixed reminder card reads "Faire flotter le sac fermé 15–20 min avant de lâcher les alevins." Save → batch detail.
  - **Batches list:** code, status, pond badges with counts, stocking date; tap → detail.
  - **Batch detail:** identity fields (edit), initial count, weight and date from `firstStocking`, current fish per pond, history (stockings and moves, newest first), each with "Corriger" (stocking: opens the stock form prefilled with the event values, identity fields hidden; saving calls `correctStocking`) and "Supprimer" (confirm → `deleteStocking`/`deleteTransfer`).

- [ ] **Step 1: Write the failing tests**

```dart
// stocking_warnings_test.dart
expect(stockingWarnings(target: overview(status: ready, surface: 500, live: 0, structure: earth), addedCount: 1500, avgWeightG: 15, config: cfg), isEmpty);
expect(stockingWarnings(target: overview(status: empty, surface: 500), addedCount: 1500, avgWeightG: 15, config: cfg), {StockingWarning.pondNotReady});
expect(stockingWarnings(target: overview(status: ready, surface: 500), addedCount: 4000, avgWeightG: 8, config: cfg),
    {StockingWarning.densityAbove, StockingWarning.weightOutsideRange});
expect(stockingWarnings(target: overview(status: isolated, surface: null), addedCount: 10, config: cfg), {StockingWarning.pondIsolated});
// stock_screen_test: pick E1 (ready, 500 m²), count 1500, weight "15" → shows "3,0 /m²" in range; Enregistrer → batch detail
// shows "L26-01", "1 500" and "15 g"; E1 is now "Empoissonné".
// batch_detail_test (Review Focus 1): stocking 1000, move 800 to E2, correct stocking to 500 →
// E1 row shows 0 with the inconsistent marker "À vérifier", E2 shows 800; no exception.
```

- [ ] **Step 2: Run to verify they fail.** `flutter test test/features/batches/` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify they pass.** → PASS; analyze clean.
- [ ] **Step 5: Commit** `feat(batches): stock a batch, batch list and detail with corrections`

### Task 10: Transfer screen and milestone check

**Files:**
- Create: `lib/features/batches/transfer_screen.dart`
- Modify: `lib/router.dart`, `lib/l10n/app_fr.arb`
- Test: `test/features/batches/transfer_screen_test.dart`

**Interfaces:**
- Consumes: `BatchRepository.transfer`, `correctTransfer`, `PondIsolatedException` (Task 5); `PondOverview` (Task 8); Task 6 widgets.
- Produces: route `/transfer?batchId=&fromPondId=` and `/more/batches/:id/transfers/:transferId/edit`. **Transfer screen:** batch and source pond (fixed when passed in), destination pond picker (excludes the source), date, count (shows "≈ N dans E1" from the overview), avg weight (optional). Warnings: count above the estimate, destination isolated, destination density out of range. A source pond that is `isolated` shows a red banner "Étang isolé : aucun poisson ne doit en sortir" and no save button.

- [ ] **Step 1: Write the failing test.** Stock L26-01 with 1 000 fish into Q1 (quarantine) → open the transfer screen from Q1 → pick E1, count 1000 → Enregistrer → Q1 shows "Vide", E1 shows 1 000 and the batch shows "Actif". With count 1200 a warning "Plus que l'estimation (1 000)" shows and saving is still allowed. With the source isolated, the banner shows and there's no Enregistrer button.
- [ ] **Step 2: Run to verify it fails.** `flutter test test/features/batches/transfer_screen_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the whole suite.** `flutter test && TZ=UTC flutter test && flutter analyze` → all pass, "No issues found!"
- [ ] **Step 5: Milestone check on Android.** `flutter build apk --debug`; start `Dobo_API26_2GB` with `-gpu swangle_indirect`; turn on airplane mode; install. Run through: setup → three ponds (one quarantine) → one person → stock a batch into the quarantine pond → move it to a grow-out pond → correct the stocking → kill the app (`adb shell am force-stop mg.dobo.dobo`) and reopen. Expected: every record and status is still there, nothing crashes, no network was needed. `flutter build apk --release --split-per-abi`: the ARM APKs stay under 25 MB.
- [ ] **Step 6: Commit** `feat(batches): move fish between ponds`

---

## Out of scope for this plan

Daily logs, water readings, samples, health and isolation (M3); accounts, roles, Supabase and sync (M4; the `Session` source and placeholder-id rewrite land there); alerts and the dashboard (M5); harvests, closing batches, the prep checklist and feed (M7); Malagasy strings for member screens (M8); several sites (SPEC §10).
