# M7: Operations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The farm's work outside daily feeding gets recorded and guided:
- **F10 pond preparation:** a per-pond checklist with doses and waiting times, ending in "ready to stock".
- **F11 feed stock:** deliveries create lots, discards are recorded, and daily logs draw from a lot. The app shows stock on hand, days left and lot ages, and raises alerts.
- **F12 harvest, sales and traceability:** for members with the sales flag. Harvests (partial or final) and sales to customers, and a traceability sheet per batch (Annex C) as a PDF.

M7 also fills the two gaps M6 left in the visit report: feed stock and the prep steps due.

**Architecture:**
- **Six new synced tables (schema v6).** Events: `prep_steps`, `feed_deliveries` (a delivery *is* a lot; its id is the lot id), `feed_discards`, `harvests`, `sales`. Reference: `customers`.
- **Harvests join the fish walk.** `occupancy.dart` subtracts harvested fish, so live count, biomass, period FCR, survival and alerts all see them. Nothing reads harvests on the side.
- **Feed stock is derived, never stored.** `lib/domain/feed_lots.dart` computes each lot's balance from deliveries, discards and counted daily logs. A daily log carries the lot it drew from. The repository stamps the default lot when saving; nobody picks one on the worker screen.
- **Prep progress is derived.** `lib/domain/prep.dart` reads the pond's current preparation cycle (the steps done since the pond last held fish) and gives the next step, doses and waiting dates.
- **The existing alert functions get their data.** `feedStockLowAlert`, `feedTooOldAlert` and `prepStepDueAlert` exist since M1; `farmAlerts` now calls them.
- **Traceability** is built by a pure `batchTrace` in `lib/domain/trace.dart` and drawn by a PDF builder that reuses M6's fonts and share flow.

**Tech Stack:** Flutter 3.47.8, Drift 2.35, flutter_riverpod 3 (no codegen), go_router 18, ARB l10n, Supabase, `pdf` and `share_plus` (both already dependencies). No new packages.

**Spec:** `CLAUDE.md`; `docs/SPEC.md` (§3 roles, §4 data model, F2 close, F10, F11, F12, F8 §7–§8, §6 navigation, §7 sync, §11 M7); `docs/DOMAIN.md` (§Pond preparation, §Formulas prep doses and cycle FCR, §Feed stock, §Harvest and delivery, §Alert rules). The decisions below are Claude's calls, made without the user. They can be revisited.

## Decisions (Claude's calls)

1. **One prep cycle per emptying.**
   - A pond's current cycle is the steps dated after the last farm day the pond held fish, or all its steps if it never held fish.
   - Prep is offered only on a pond with no fish (effective status `empty`, `preparing` or `ready`), from the pond page.
   - Recording any step sets the stored status to `preparing`, unless the pond is already `ready`.
2. **Steps are recorded by hand, except `rest`.**
   - `drain`, `dry`, `treat`, `fertilise` and `fill` are each a tap: "Fait" (done) with a date, defaulting to today.
   - `treat` takes a product (`quicklime` or `chlorine`) and the dose used in kg, both optional. `fertilise` takes the manure dose used in kg, optional.
   - The screen shows the dose range for the pond's surface (`prepDoses`, existing). For chlorine the handbook gives no dose, so none is shown or invented.
   - "Prêt à empoissonner" (ready to stock) records `rest` and sets the pond to `ready`. It is enabled once `fill` is done. Steps skipped and rest under `restDays.min` are listed as warnings and never block (SPEC F2 already warns at stocking).
3. **Waiting times** (DOMAIN §Pond preparation):
   - After `drain`, the screen shows "séchage jusqu'au <drain + dryingDays.min>–<drain + dryingDays.max>".
   - After `fill`, it shows "repos jusqu'au <fill + restDays.min>".
   - `prepStepDueAlert` (existing) fires once the minimum has passed and the next step isn't done: `dry` not recorded after `drain`, or `rest` not recorded after `fill`.
   - The report's Next section lists the same two dates (`NextKind.prepStep`).
4. **A delivery is a lot.** `feed_deliveries`:
   - fields: `phase` (the feed's phase, `Phase`), `pelletMm`, `proteinPct`, `weightG`, `manufacturedOn`, `supplier`, `label` (short text such as a sack mark, optional);
   - the lot shows as "<phase> <manufacture date>", with the label if any.

   `feed_discards`: `lotId`, `weightG`, `reason` (`mould`, `rancid`, `clumped`, `other`).
5. **Which lot a log draws from.**
   - When saving, `DailyLogRepository.save` and `saveWeek` stamp the **default lot**: the oldest usable lot (not past `feedAgeDangerDays`, balance > 0) whose phase matches the pond's phase, else the oldest usable lot of any phase, else none.
   - The pond's phase is the phase of the batch with the most biomass in it.
   - The worker never sees or picks a lot.
   - The member daily-log form shows the stamped lot in a small picker that can be changed. Transcription stamps the default and shows nothing.
   - Logs with no lot (all logs before M7, and any log saved with no usable lot) are drawn at read time, oldest first, from the lot that was the oldest with a balance left. Only logs dated on or after the first delivery count.
6. **Balances never block and never go negative.**
   - A lot's balance is delivered − discarded − drawn, floored at 0. What's drawn beyond it is reported as `overdrawnG`, and the stock screen says "plus d'aliment donné que livré : <kg>".
   - Two phones drawing the same lot offline is normal and only shows up in these numbers.
7. **Stock on hand and days left.**
   - **Stock on hand** = sum of the balances of usable lots (not expired). Expired lots show separately as "à ne pas utiliser".
   - **Daily usage** = counted feed over the last `feedUsageDays` farm days (today included) ÷ `feedUsageDays`.
   - `feedUsageDays = 7` is a new **[default]** number. It goes into `config.dart`, DOMAIN §Feed stock and the settings screen.
   - `feedStockLowAlert` is one farm-wide alert (no pond). Per-phase stock alerts can come later.
   - `feedTooOldAlert` fires per lot with a balance left.
8. **Harvests.** `harvests`:
   - fields: `batchId`, `pondId`, `count`, `weightG`, `isFinal`, `recordedAt` (farm day at `harvestHour`);
   - a harvest from an `isolated` pond is refused, like a transfer (DOMAIN §Health: move no fish);
   - a **partial** harvest subtracts its count;
   - a **final** harvest ends the batch's part in that pond. The estimated live fish left there become `unaccounted` (predation, theft or counting error) and the live count goes to 0. Traceability shows the unaccounted number;
   - harvesting more than the estimate on a partial harvest sets `inconsistent`, as deaths already do.
9. **Batch status follows harvests.**
   - The first harvest sets `harvesting`.
   - A final harvest that leaves the batch with no live fish in any pond sets `closed`.
   - Correcting or deleting a harvest recomputes the status (`closed` → `harvesting` → `active`/`quarantine` as the records say).
   - The status is a reference column written by the repository in the same transaction.
10. **Harvests in the numbers.**
    - **Period FCR:** harvested weight in the period counts in `outWeightG` (DOMAIN §Formulas already says so).
    - **Survival** becomes (live + harvested) ÷ entered. Harvested fish survived, and the old formula would read 0 % for a closed batch. The DOMAIN §Formulas line is updated to say this.
    - **Cycle FCR** (Annex C) = batch feed ÷ (harvested weight − stocked weight).
      - Batch feed is each counted pond-day's feed shared between the batches in the pond at the start of that day, in proportion to their biomass (estimated, so the sheet says "estimé").
      - Cycle FCR is shown only once the batch is `closed`; before that the sheet says "cycle en cours".
11. **Sales.** `sales`:
    - fields: `harvestId`, `batchId` (denormalised from the harvest for traceability queries), `customerId`, `weightG`, `form` (`ProductForm`), `deliveryNote` (optional text);
    - a sale always comes from a harvest; the form lists the batch's harvests, newest first;
    - sold weight over a harvest's weight is a warning, not a block: smoked and dried fish weigh less, so it is rare but possible to have a typo.

    `customers` (reference): `name`, `type` (`market`, `restaurant`, `supermarket`, `exporter`, `individual`), `contact` (optional), `archived`.

    No price anywhere. The schema stays open to adding price columns later.
12. **Who does what.**
    - Prep steps, deliveries and discards: members (RLS `is_member()`).
    - Harvests, sales and customers: members with the sales flag. A new server function `is_sales()` is used in their insert and update policies; the app hides the buttons from everyone else.
    - The planned harvest date stays editable by any member, as since M2: it drives the worker's fast.
    - The traceability PDF is open to every member.
13. **Navigation** (SPEC §6):
    - More gets **Aliment** (feed stock) for members and **Ventes** (harvests, sales, customers) for the sales flag.
    - The pond page gets **Préparation** when the pond has no fish.
    - The batch page gets **Récolter** (sales flag), **Vendre** (sales flag, once a harvest exists) and **Fiche de traçabilité** (all members).
14. **Report format 2.**
    - `ReportContent.feedStock` becomes a typed `FeedStockSection?`: stock on hand in g, days left, overdrawn g, and the lots with a balance (label, phase, manufacture date, balance, age).
    - `NextKind` gains `prepStep` (pond, step awaited, date).
    - `currentFormat` goes to 2. M6 phones show their existing "Mettez l'application à jour" for format-2 reports. M7 phones still read format 1.
15. **Traceability PDF.**
    - A4, Noto Sans, in the sharer's language, file name `tracabilite-<batch code>-<yyyy-mm-dd>.pdf`, shared through `share_plus` as in M6.
    - Sections follow Annex C: identity (code, strain, hatchery, certificate, monosex); stocking (date, count, average weight); pond history (stockings and transfers by date); treatments (rows whose `batchId` is the batch, or with no batch and dated while the batch was in that pond); harvests; sales by customer; cycle FCR; survival; unaccounted fish.
    - Estimated values say "estimé".

## Global Constraints

- Offline first: every M7 record, screen, alert and PDF works in airplane mode. Nothing in M7 needs the network.
- `schemaVersion` goes 5 → 6 with a migration, `dart run drift_dev make-migrations`, the committed `drift_schemas/` snapshot and the generated migration test (CLAUDE.md §Code generation). One server migration; `test/server/schema_parity_test.dart` passes.
- All six tables sync: events in `sync_push`'s event list, `customers` in its reference list, and all in `lib/sync/sync_tables.dart` (references before events, `customers` before `sales`).
- `lib/domain/` imports neither Flutter nor Drift (`test/domain/purity_test.dart`). The only new farming number is `feedUsageDays = 7` [default], in `config.dart`, `config_overrides.dart`, DOMAIN.md and the settings screen.
- Weights are integer grams, entered and shown in kg with a decimal comma. Dates are farm dates via `farmDate`, `daysBetween` and `farmDateToUtc`; ordering uses recorded dates, never the device clock.
- Every string comes from the ARB files, with keys in both `app_fr.arb` and `app_mg.arb` (the mg value may repeat the French until the M8 review). Touch targets ≥ 56 dp, number pad for numbers. Every pushed screen has a working Back. Every save goes through `SaveOnce`.
- No money anywhere (CLAUDE.md §6).
- At the end of each task: `flutter analyze` has no issues, and `flutter test` and `TZ=UTC flutter test` pass.
- Commits use a conventional prefix and end with the `Co-Authored-By` line. Branch: `feat/m7-operations` from `main`.

## Review Focus

1. **A final harvest when the estimate still shows fish:** the pond becomes empty, prep can start, the batch closes if no other pond holds it, and the leftover shows as unaccounted, never as deaths. Tests in Task 2 and Task 5.
2. **Feed logged before any delivery, or more feed logged than delivered** (pre-M7 logs, two phones on one lot): balances stop at 0, `overdrawnG` reports the excess, no alert claims negative stock, and saving a log never fails for lack of a lot. Tests in Task 3 and Task 5.
3. **A pond emptied, prepared, stocked, emptied and prepared again:** the second checklist starts empty and the first cycle's `fill` raises no alert. Test in Task 4.
4. **Correcting or deleting a final harvest** reopens the batch and puts the fish back in the live count. Test in Task 5.
5. **A format-2 report on an M6 phone and a format-1 report on an M7 phone:** the first shows "Mettez l'application à jour"; the second opens with "Stock d'aliment" shown as not available. Test in Task 9.

---

### Task 1: Schema v6 and the server

**Files:**
- Create:
  - `lib/db/tables/prep_steps.dart`, `feed_deliveries.dart`, `feed_discards.dart`, `harvests.dart`, `sales.dart`, `customers.dart`;
  - `supabase/migrations/20261106000001_operations.sql`, `supabase/tests/operations_test.sql`.
- Modify:
  - `lib/db/database.dart`: tables, `schemaVersion: 6`, `from5To6`;
  - `lib/domain/types.dart`: `enum PrepProduct { quicklime, chlorine, manure }`, `enum DiscardReason { mould, rancid, clumped, other }`, `enum CustomerType { market, restaurant, supermarket, exporter, individual }`;
  - `lib/sync/sync_tables.dart`; `lib/db/backup.dart`, only if it lists tables explicitly.
- Generated: `drift_schemas/`, `test/db/default/generated/schema_v6.dart`, the migration test.
- Test: `test/db/schema_v6_test.dart`, `test/db/default/migration_test.dart`, `test/server/schema_parity_test.dart`, `test/sync/sync_tables_test.dart` (new).

**Interfaces:**
- Produces (Drift data classes `PrepStepRow`, `FeedDelivery`, `FeedDiscard`, `Harvest`, `Sale`, `Customer`; `PrepStepRow` avoids clashing with the domain enum `PrepStep`):
  - `PrepSteps with SyncedRow, EventRow`: `pondId`, `step` (`textEnum<PrepStep>`), `product` (`textEnum<PrepProduct>`, nullable), `doseG` (int, nullable).
  - `FeedDeliveries with SyncedRow, EventRow`: `siteId`, `phase` (`textEnum<Phase>`), `pelletMm` (real, nullable), `proteinPct` (real, nullable), `weightG` (int), `manufacturedOn` (dateTime, a farm day), `supplier` (nullable), `label` (nullable).
  - `FeedDiscards with SyncedRow, EventRow`: `lotId`, `weightG`, `reason` (`textEnum<DiscardReason>`).
  - `Harvests with SyncedRow, EventRow`: `batchId`, `pondId`, `count`, `weightG`, `isFinal` (bool).
  - `Sales with SyncedRow, EventRow`: `harvestId`, `batchId`, `customerId`, `weightG`, `form` (`textEnum<ProductForm>`), `deliveryNote` (nullable).
  - `Customers with SyncedRow, ReferenceRow`: `name`, `type` (`textEnum<CustomerType>`), `contact` (nullable), `archived` (bool, default false).
- Server:
  - the six tables with the sync columns, the `stamp_sync` and `refuse_event_update` triggers on events, and a `server_seq` index;
  - `create function is_sales() returns boolean`, true for an active member with `is_sales`, shaped like `is_admin()`;
  - `prep_steps`, `feed_deliveries`, `feed_discards`: `write_own` with `is_member()`;
  - `harvests`, `sales`: insert with `is_sales()`;
  - `customers`: insert and update with `is_sales()`;
  - all readable by the association (`read_own`);
  - `sync_push` (re-created) lists them.

- [ ] **Step 1: Write the failing tests.**
  - `v5 → v6 keeps every row and adds the six tables` (generated), plus `schema_v6_test.dart` inserting one row into each table and reading its enums back.
  - SQL (`operations_test.sql`):
    - a member inserts a `prep_steps` and a `feed_deliveries` row;
    - a member without the sales flag gets `42501` on `harvests`, `sales` and `customers`;
    - a sales member succeeds;
    - a worker gets `42501` on all six.
  - `sync tables list customers before sales`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/db test/sync` and `supabase test db` (per `docs/deploy.md`).
- [ ] **Step 3: Implement.** Then `dart run build_runner build --delete-conflicting-outputs` and `dart run drift_dev make-migrations`.
- [ ] **Step 4: Run them to see them pass,** plus `tool/server_test.sh` against the local server.
- [ ] **Step 5: Commit.** `feat(db): schema v6 with prep steps, feed lots, harvests, sales and customers`

### Task 2: Harvests in the fish walk

**Files:**
- Modify:
  - `lib/domain/occupancy.dart`: `HarvestFact`, harvests in `placements`, `placementSnapshots` and `_walk`;
  - `lib/domain/stock.dart`: `liveCount` already takes `harvested`;
  - `lib/domain/farm_facts.dart`: `FarmFacts.harvests`;
  - `lib/domain/growth.dart`: harvests in `fcrPeriods`' out weight, `batchSurvival`;
  - `docs/DOMAIN.md` §Formulas survival line.
- Test: `test/domain/occupancy_test.dart`, `test/domain/growth_test.dart`.

**Interfaces:**
- Produces:
  - `class HarvestFact { String batchId; String pondId; int count; int weightG; bool isFinal; DateTime date; }`.
  - `Placement` gains `int harvested` and `int unaccounted` (both default 0). `live` stays the estimate after them.
  - `FarmFacts({..., List<HarvestFact> harvests = const []})`.
  - `double? batchSurvival(FarmFacts f, String batchId)`, now (live + harvested) ÷ stocked.
- Order in the walk on one date: stockings, moves, samples, deaths, then harvests (the harvest is the morning's last act before the fish leave; deaths logged that day happened before it).

- [ ] **Step 1: Write the failing tests** (`occupancy_test.dart`):
  - `a partial harvest of 300 from 1000 leaves 700`;
  - `a final harvest of 900 when 950 are estimated leaves 0 live and 50 unaccounted`;
  - `a final harvest of 1000 when 950 are estimated leaves 0 live and 0 unaccounted` (more than estimated is not negative);
  - `a partial harvest of 1200 from 1000 is inconsistent`;
  - `a final harvest in E1 leaves the batch's fish in E2 untouched`;
  - `deaths logged on the harvest day come off before the harvest`.

  `growth_test.dart`:
  - `harvested weight in a period counts as weight out`: stocked 1000 × 20 g, sample at 100 g, partial harvest 200 fish at 20 kg, sample at 150 g with 800 left, 60 kg feed → gain = (120 + 20) − 100 = 40 kg, FCR 1.5;
  - `survival counts harvested fish`: 1000 stocked, 50 dead, 950 harvested final → 0.95;
  - `survival with nothing stocked is null`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/occupancy_test.dart test/domain/growth_test.dart`
- [ ] **Step 3: Implement.** A final harvest sets `unaccounted = max(running − count, 0)` and then `running` to 0. `_shareDeaths` already ignores pairs with `running == 0`.
- [ ] **Step 4: Run them to see them pass,** plus `flutter test test/domain` (alerts, growth performance and the report builder must stay green).
- [ ] **Step 5: Commit.** `feat(domain): harvests leave the live count, count in FCR and in survival`

### Task 3: Feed lots, balances and the default lot

**Files:**
- Create: `lib/domain/feed_lots.dart`.
- Modify: `lib/domain/config.dart` (`feedUsageDays: 7`, doc line "DOMAIN §Feed stock [default]"), `lib/domain/config_overrides.dart`, `docs/DOMAIN.md` §Feed stock, `lib/features/admin/settings_screen.dart` (label key `cfgFeedUsageDays`).
- Test: `test/domain/feed_lots_test.dart`, `test/domain/config_test.dart`, `test/domain/config_overrides_test.dart`.

**Interfaces:**
- Produces:
  - `class FeedLotFact { String id; Phase phase; int weightG; DateTime manufacturedOn; DateTime deliveredOn; String? label; }`
  - `class FeedDiscardFact { String lotId; int weightG; DateTime date; }`
  - `LogFact` gains `String? feedLotId` (in `farm_facts.dart`).
  - `class FeedLotBalance { FeedLotFact lot; int balanceG; FeedAge age; }`
  - `class FeedStock { List<FeedLotBalance> lots; int onHandG; int expiredG; int overdrawnG; int dailyUsageG; double? daysLeft; }`
  - `FeedStock feedStock({required List<FeedLotFact> lots, required List<FeedDiscardFact> discards, required List<LogFact> countedLogs, required DateTime today, required DomainConfig config})`
  - `String? defaultFeedLot({required FeedStock stock, required Phase? pondPhase})`
  - `Phase? pondPhase(List<Placement> placements, String pondId, DomainConfig config)`: the phase of the batch with the most biomass in the pond; null when the pond is empty.
- Draw order (Decision 5): walk counted logs oldest first. A log with a known `feedLotId` draws from that lot. A log with none draws from the oldest lot (by `manufacturedOn`, then `deliveredOn`, then id) delivered on or before the log's day that still has a balance. A log dated before the first delivery draws nothing. A draw beyond a balance adds to `overdrawnG`.

- [ ] **Step 1: Write the failing tests** (`feed_lots_test.dart`):
  - `a 25 kg lot with 3 kg discarded and 4 kg drawn has 18 kg`;
  - `logs without a lot draw from the oldest lot with a balance`;
  - `logs before the first delivery draw nothing`;
  - `drawing 30 kg from a 25 kg lot leaves 0 and 5 kg overdrawn`;
  - `a lot at 90 days is expired and not on hand`;
  - `daily usage is the last 7 days' feed ÷ 7, and days left is on hand ÷ usage`;
  - `with no feed logged, days left is null`;
  - `the default lot matches the pond's phase, oldest first`;
  - `with no lot of the pond's phase, the default is the oldest usable lot`;
  - `with every lot empty or expired, there is no default`;
  - `pondPhase picks the batch with the most biomass`.

  `config_test.dart`: `feedUsageDays is 7`. `config_overrides_test.dart`: `feedUsageDays can be overridden`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/feed_lots_test.dart test/domain/config_test.dart test/domain/config_overrides_test.dart`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(domain): feed lot balances, stock on hand, days left and the default lot`

### Task 4: Prep progress, trace and the new alerts

**Files:**
- Create: `lib/domain/prep.dart`, `lib/domain/trace.dart`.
- Modify: `lib/domain/alerts/farm_alerts.dart` (feed and prep alerts), `lib/features/alerts/alert_providers.dart` (passes the new inputs; texts and links in Task 6–8).
- Test: `test/domain/prep_test.dart`, `test/domain/trace_test.dart`, `test/domain/alerts/farm_alerts_test.dart`.

**Interfaces:**
- Produces (`prep.dart`):
  - `class PrepStepFact { String id; String pondId; PrepStep step; DateTime date; PrepProduct? product; int? doseG; }`
  - `class PrepProgress { Map<PrepStep, PrepStepFact> done; PrepStep? next; DateTime? dryUntilMin; DateTime? dryUntilMax; DateTime? restUntil; bool canMarkReady; List<PrepStep> skipped; }`
  - `PrepProgress prepProgress({required String pondId, required List<PrepStepFact> steps, required DateTime? lastDayWithFish, required DomainConfig config})`: only steps dated after `lastDayWithFish` count; with two of a step, the latest wins.
  - `DateTime? lastDayWithFish(FarmFacts f, String pondId)`: the last farm day whose end-of-day placements had live fish in the pond (from `placementsOf` snapshots).
- Produces (`trace.dart`):
  - `class BatchTrace { int stockedCount; int stockedWeightG; int harvestedCount; int harvestedWeightG; int unaccounted; int live; double? survival; FcrResult? cycleFcr; int batchFeedG; }`. `cycleFcr` is null while the batch isn't `closed`.
  - `BatchTrace batchTrace(FarmFacts f, String batchId, {required BatchStatus status})`.
  - Batch feed (Decision 10): for each counted log, the pond's batches at the start of that day (`placementsOf(f, until: day before)`), shared by biomass; a pond holding one batch gives it all.
- `farmAlerts` gains `FeedStock? feedStock` and `Map<String, PrepProgress> prep` (by pond id), and emits:
  - `feedStockLowAlert(stockG: onHandG, dailyUsageG: ...)`, once;
  - `feedTooOldAlert` per lot with a balance;
  - `prepStepDueAlert` for a pond whose latest step is `drain` with no `dry`, or `fill` with no `rest`.

  An alert without a pond sorts after the pond alerts of the same severity and kind.

- [ ] **Step 1: Write the failing tests.**
  - `prep_test.dart`:
    - `no steps: next is drain, cannot mark ready`;
    - `drained on 1/3: dry from 6/3 to 8/3`;
    - `filled on 10/3: rest until 12/3, can mark ready`;
    - `fill without treat and fertilise lists them as skipped`;
    - `steps from before the pond last held fish are ignored` (Review Focus 3).
  - `trace_test.dart`:
    - `cycle FCR of a closed batch`: 1000 × 20 g stocked, 400 kg feed, final harvest 950 fish at 250 kg → 400 ÷ 230 ≈ 1.74;
    - `an open batch has no cycle FCR`;
    - `feed in a pond shared with another batch is split by biomass`;
    - `unaccounted fish are reported`;
    - `a batch with nothing harvested yet still reports stocked and live`.
  - `farm_alerts_test.dart`:
    - `a lot at 61 days with a balance warns, at 90 days is danger, empty lot is silent`;
    - `stock covering 5 days warns once, without a pond`;
    - `drained 5 days ago with no dry step is a prep alert`;
    - `a refilled pond from an earlier cycle raises nothing` (Review Focus 3).
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(domain): prep progress, batch trace and feed and prep alerts`

### Task 5: Repositories

**Files:**
- Create: `lib/db/repositories/prep_repository.dart`, `feed_repository.dart`, `harvest_repository.dart`, `customer_repository.dart`.
- Modify: `lib/db/repositories/facts_repository.dart` (harvests and `feedLotId` into `FarmFacts`), `daily_log_repository.dart` (lot stamping), `providers.dart`, `watch_tables.dart`.
- Test: `test/db/prep_repository_test.dart`, `feed_repository_test.dart`, `harvest_repository_test.dart`, `customer_repository_test.dart`, `daily_log_repository_test.dart`, `facts_repository_test.dart`.

**Interfaces:**
- `PrepRepository(db, session)`:
  - `Future<String> record(String pondId, PrepStep step, {required DateTime on, PrepProduct? product, int? doseG})`: refuses `PrepStep.rest`, and a pond with fish with the existing `PondNotEmptyException`; sets `preparing` unless `ready`;
  - `Future<String> markReady(String pondId, {required DateTime on})`: records `rest` and sets `ready`;
  - `Future<String> correct(String id, ...)` and `Future<void> delete(String id)` via `supersede`/`tombstone`;
  - `Stream<PrepProgress> watchProgress(String pondId)`.
- `FeedRepository(db, session)`:
  - `Future<String> deliver(FeedDeliveryInput)`, `Future<String> discard(String lotId, int weightG, DiscardReason reason, {required DateTime on})`, corrections and deletes;
  - `Stream<FeedStock> watchStock()`;
  - `Future<String?> defaultLotFor(String pondId, DateTime day)`.
- `DailyLogRepository.save`/`saveWeek`: when the input's `feedLotId` is null, stamp `defaultLotFor`. A null default saves a null lot, never fails (Review Focus 2). `DailyLogInput` gains `String? feedLotId`.
- `HarvestRepository(db, session)`:
  - `Future<String> harvest(HarvestInput)`: refuses an isolated pond (`PondIsolatedException`, as transfers do);
  - `Future<String> correct(String id, HarvestInput)` and `Future<void> delete(String id)`;
  - `Future<String> sell(SaleInput)`, with corrections and deletes;
  - `Stream<List<HarvestWithSales>> watchForBatch(String batchId)`.

  Every harvest write recomputes the batch status in the same transaction (Decision 9).
- `CustomerRepository(db, session)`: `create`, `update`, `archive`, `Stream<List<Customer>> watchActive()`.
- Providers named `<name>RepositoryProvider`, like the existing ones.

- [ ] **Step 1: Write the failing tests.**
  - `prep_repository_test.dart`: `recording drain sets preparing`; `mark ready records rest and sets ready`; `a pond with fish refuses a step`; `a step on a ready pond keeps it ready`.
  - `feed_repository_test.dart`: `a delivery shows in stock`; `a discard lowers it`; `deleting a delivery removes its stock`.
  - `daily_log_repository_test.dart`:
    - `a log is stamped with the oldest usable lot of the pond's phase`;
    - `a log with no lot available saves with no lot`;
    - `a chosen lot is kept`;
    - `a week of transcription is stamped day by day`.
  - `harvest_repository_test.dart`:
    - `the first harvest sets harvesting`;
    - `a final harvest of the batch's last pond closes it`;
    - `a final harvest in one of two ponds keeps it harvesting`;
    - `deleting the final harvest reopens the batch and restores the live count` (Review Focus 4);
    - `an isolated pond refuses a harvest`;
    - `a sale is listed under its harvest`.
  - `customer_repository_test.dart`: `archived customers are not offered`.
  - `facts_repository_test.dart`: `harvests and log lots reach FarmFacts`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/db`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(db): repositories for prep, feed stock, harvests, sales and customers`

### Task 6: Pond preparation screen (F10)

**Files:**
- Create: `lib/features/prep/prep_screen.dart`, `lib/features/prep/prep_providers.dart`.
- Modify: `lib/features/ponds/pond_detail_screen.dart` ("Préparation" button for a pond with no fish), the router (`/ponds/:id/prep`), `lib/features/alerts/alert_route.dart` and `alert_tile.dart` (prep alert text and link), `lib/l10n/app_fr.arb`, `app_mg.arb`, `lib/l10n/labels.dart`.
- Test: `test/features/prep/prep_screen_test.dart`, `test/features/alerts/alerts_screen_test.dart`.

**Interfaces:**
- Consumes `PrepRepository`, `prepProgress`, `prepDoses`.
- The screen: one row per step, in DOMAIN order, each with a done tick and date, or a "Fait" button (56 dp). `treat` and `fertilise` show the dose range in kg ("chaux vive 30–60 kg pour 300 m²") and open a dialog with the product (treat only) and an optional dose. After `drain` and `fill`, the waiting dates show under the step. "Prêt à empoissonner" sits at the bottom.

- [ ] **Step 1: Write the failing tests** (`prep_screen_test.dart`):
  - `a 300 m² pond shows quicklime 30–60 kg and manure 6–9 kg`;
  - `a pond without a surface shows no dose`;
  - `drain then fill shows the dates and enables ready`;
  - `marking ready lists skipped steps, then the pond shows Prêt`;
  - `a pond with fish shows no Préparation button`.

  `alerts_screen_test.dart`: `the prep alert opens the pond's checklist`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/prep test/features/alerts`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(prep): pond preparation checklist with doses, waiting dates and ready to stock`

### Task 7: Feed stock screens (F11)

**Files:**
- Create: `lib/features/feed/feed_stock_screen.dart`, `feed_delivery_screen.dart`, `feed_discard_screen.dart`, `feed_providers.dart`.
- Modify:
  - `lib/features/more/more_screen.dart` ("Aliment") and the router (`/more/feed`, `/more/feed/deliver`, `/more/feed/:lotId/discard`);
  - `lib/features/daily_log/daily_log_screen.dart` (lot picker, member only);
  - alert text and link for the feed alerts (both open `/more/feed`);
  - ARB files and `labels.dart`.
- Test: `test/features/feed/feed_stock_screen_test.dart`, `test/features/daily_log/daily_log_screen_test.dart`, `test/features/daily_log/worker_home_test.dart`.

**Interfaces:**
- Consumes `FeedRepository`, `FeedStock`.
- The stock screen:
  - shows stock on hand (big number, kg), days left, and the overdrawn line when > 0;
  - lists lots with a balance, oldest first: label, phase, manufacture date, age in days, balance, and the age badge (`old` orange, `expired` red "à ne pas utiliser");
  - each lot has a discard action;
  - a FAB adds a delivery.

- [ ] **Step 1: Write the failing tests.**
  - `feed_stock_screen_test.dart`:
    - `a 25 kg delivery shows 25 kg on hand`;
    - `a 61-day lot shows the old badge`;
    - `discarding 5 kg leaves 20 kg`;
    - `more fed than delivered shows the overdrawn line`.
  - `daily_log_screen_test.dart`: `a member sees and can change the stamped lot`.
  - `worker_home_test.dart`: `the worker's log screen shows no lot`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/feed test/features/daily_log`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(feed): deliveries, discards, stock on hand and lot ages`

### Task 8: Harvest, sales and customers screens (F12)

**Files:**
- Create: `lib/features/sales/harvest_screen.dart`, `sale_screen.dart`, `sales_screen.dart` (harvests list with their sales), `customers_screen.dart`, `customer_form_screen.dart`, `sales_providers.dart`.
- Modify: `lib/features/batches/batch_detail_screen.dart` (Récolter, Vendre, harvests and sales in the history), `lib/features/more/more_screen.dart` ("Ventes" for the sales flag), the router, ARB files, `labels.dart`.
- Test: `test/features/sales/harvest_screen_test.dart`, `sale_screen_test.dart`, `customers_screen_test.dart`, `test/features/batches/batch_detail_test.dart`.

**Interfaces:**
- Consumes `HarvestRepository`, `CustomerRepository`, `Session.isSales`.
- **Harvest form:**
  - fields: pond (only ponds holding the batch), date, count, total weight (kg), partial/final toggle;
  - shows the estimated live count beside the count;
  - a final harvest under the estimate shows "<n> poissons non retrouvés" before saving.
- **Sale form:**
  - fields: harvest (newest first), customer (picker, with "Nouveau client"), weight (kg), form (5 pictogram tiles), delivery note;
  - weight above the harvest's unsold weight warns.

- [ ] **Step 1: Write the failing tests.**
  - `harvest_screen_test.dart`:
    - `a final harvest under the estimate warns about 50 missing fish`;
    - `saving a final harvest closes the batch and empties the pond`;
    - `an isolated pond is not offered`.
  - `sale_screen_test.dart`:
    - `a sale lists under its harvest with customer and form`;
    - `selling more than the harvest warns but saves`.
  - `customers_screen_test.dart`: `a new customer appears in the sale picker`.
  - `batch_detail_test.dart`:
    - `Récolter and Vendre are hidden without the sales flag`;
    - `Fiche de traçabilité is shown to every member`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/sales test/features/batches`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(sales): harvests, sales and customers for the sales role`

### Task 9: Traceability PDF and the report's feed and prep

**Files:**
- Create: `lib/features/sales/trace_pdf.dart`.
- Modify:
  - `lib/domain/report/report_content.dart`: `FeedStockSection`, `NextKind.prepStep`, `currentFormat = 2`;
  - `lib/domain/report/build_report.dart`: fill both;
  - `lib/features/reports/` (the screen and `report_pdf` draw the feed section and prep items);
  - `batch_detail_screen.dart` (Fiche de traçabilité shares the PDF);
  - ARB files.
- Test: `test/domain/report/report_content_test.dart`, `test/domain/report/build_report_test.dart`, `test/features/sales/trace_pdf_test.dart`, `test/features/reports/report_pdf_test.dart`.

**Interfaces:**
- `class FeedStockSection { int onHandG; double? daysLeft; int overdrawnG; List<FeedLotLine> lots; }`, `class FeedLotLine { String? label; Phase phase; DateTime manufacturedOn; int balanceG; FeedAge age; }`, both with `toJson`/`fromJson`.
- `NextItem` for `prepStep` carries `pondId`, `pondCode`, `step` (the step awaited: `dry` or `rest`) and `date`.
- `Future<File> buildTracePdf(BatchTraceView view, AppLocalizations l10n)`, where `BatchTraceView` is the batch, its `BatchTrace`, its events, treatments, harvests and sales with customer names, gathered by a provider.

- [ ] **Step 1: Write the failing tests.**
  - `report_content_test.dart`:
    - `a format-2 report round-trips its feed stock and prep items`;
    - `a format-1 report reads with no feed stock`;
    - `format 3 is UnsupportedReportFormat`.
  - `build_report_test.dart`:
    - `the feed section has stock on hand, days left and lots with a balance`;
    - `a drained pond adds its drying date to Next, sorted by date`.
  - `trace_pdf_test.dart`:
    - `a closed batch's sheet builds with its cycle FCR, harvests and customers`;
    - `an open batch with no harvest builds and says cycle en cours`.
  - `report_pdf_test.dart`: `a report with feed stock builds`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/report test/features/sales test/features/reports`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat: traceability sheet as a PDF; the visit report shows feed stock and prep dates`

### Task 10: M7 walk-through and the emulator check

**Files:**
- Create: `integration_test/m7_operations_test.dart`.
- Modify: `test/server/sync_e2e_test.dart` (a harvest, sale and delivery cross phones; a non-sales member's harvest is rejected and kept on the phone).

- [ ] **Step 1: Write the walk-through.** On a farm with E1 (300 m², empty) and E2 (stocked 1000 × 20 g, 120 days ago, sampled at 250 g), with the founder flagged sales:
  1. Prep E1: drain 6 days ago (the drying alert shows), dry, treat with quicklime 45 kg, fertilise, fill 3 days ago; mark ready. E1 shows Prêt.
  2. Record a 50 kg growout delivery manufactured 65 days ago. The Alerts tab shows the feed-age warning.
  3. The worker logs E2 with 6 kg. The stock screen shows 44 kg.
  4. Harvest E2 final: 950 fish, 240 kg. The batch shows closed and E2 shows empty.
  5. Sell 200 kg fresh to a new customer "Marché Antsirabe".
  6. Share the traceability sheet (share stubbed): the PDF builds.
  7. End a visit and publish. The report shows feed stock and no fish in E2.
- [ ] **Step 2: Run it on the 2 GB emulator in airplane mode.** `flutter test integration_test/m7_operations_test.dart -d <emulator>`. Then run every walk-through except M4's: `flutter test integration_test/m2_farm_setup_test.dart integration_test/m3_recording_test.dart integration_test/m5_guidance_test.dart integration_test/m6_visit_report_test.dart integration_test/m7_operations_test.dart -d <emulator>`. Expected: PASS.
- [ ] **Step 3: Check sync on the local server** (`docs/deploy.md`): `tool/server_test.sh` with the extended `sync_e2e_test.dart`. Expected: PASS. Write the results in the commit body.
- [ ] **Step 4: Check the size.** `flutter build apk --release --split-per-abi`. Write the ARM APK sizes in the commit body; if one is over 30 MB, flag it to the user before merging.
- [ ] **Step 5: Run the whole suite.** `flutter analyze && flutter test && TZ=UTC flutter test`. Expected: no issues, all pass.
- [ ] **Step 6: Commit.** `test: M7 walk-through with prep, feed stock, harvest, sale and traceability`

## Not in M7

Prices, costs and profit (v2). Per-phase stock alerts. Picking a lot on the worker screen. Deleting server copies of anything. Paper sheets, Annex A/B exports and printing (M8). Malagasy review of M7 strings (M8).
