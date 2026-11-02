# M6: Visit Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ending a visit builds the visit report (F8). The member reviews it, adds a summary and photos, and publishes it. After sync, every member finds it in a Reports tab, with unread reports marked, and can share it as a PDF through any app (WhatsApp, Bluetooth) without the server. Two more pieces come with it:
- **Photos** (SPEC §8, deferred here from M3) on observations, health events and the report itself.
- **One identity per human.** Every account gets a `Person`, and "who observed" is resolved the same way everywhere, so a worker's own phone logs show the worker's name.

**Architecture:**
- **A report is a frozen snapshot.** At publish time the phone builds a `ReportContent` from its data and stores it as JSON in an append-only `visit_reports` row. Every phone shows exactly what the author published, in the reader's own language, even if their data differs or changes later. A draft (an ended visit with no report yet) is never stored; it is rebuilt live from the data.
- **Pure domain logic.** `lib/domain/people.dart` (who observed), `lib/domain/report/report_content.dart` (the model and its JSON) and `lib/domain/report/build_report.dart` (records → content). Screens and the PDF only draw a `ReportContent`.
- **Photos** are files on the device, plus a synced `photos` event row per photo. A separate uploader sends the photos marked "upload" to a private Supabase Storage bucket after each sync. Other phones download them when they show them.
- **Schema v5:** two synced event tables (`visit_reports`, `photos`) and two device-only tables (`report_reads`, `photo_uploads`).

**Tech Stack:** Flutter 3.47.8, Drift 2.35, flutter_riverpod 3 (no codegen), go_router 18, ARB l10n, Supabase. New dependencies: `pdf`, `image_picker`, `flutter_image_compress` (latest stable), and Noto Sans Regular and Bold (OFL) as font assets for the PDF.

**Spec:** `CLAUDE.md`; `docs/SPEC.md` (§3 roles, §4 data model, F5, F8, §6 navigation, §7 sync, §8 photos, §9 language, §11 M6); `docs/DOMAIN.md` (§Formulas, §Water quality, §Sampling, §Alert rules). The decisions below are Claude's calls, made without the user. They can be revisited.

## Decisions (Claude's calls)

1. **Snapshot, not recomputation.** A report is a historical document: what the member saw and said that day. Recomputing it on each phone would change its numbers whenever a correction or a late log arrives, and two members would read different reports. The snapshot is built when the member taps Publier, so its alerts, water, growth and "next" dates are "as of publishing". The period sections cover the report's period. `ReportContent` carries `format: 1`, so later milestones can add fields; a phone reading an unknown higher format shows "Mettez l'application à jour".
2. **One report per visit.** Publishing a visit that already has a current report is refused (`ReportAlreadyPublished`). v1 has no editing or rebuilding after publishing. The summary is copied into the snapshot at publishing. Until then it lives on `Visit.summary`, as in M3.
3. **Period covered** (F8 §1): farm days from the previous report's last day to this visit's day, **both included**.
   - The visit's day is the farm day of `visit.endedAt`.
   - The previous report is the current report for the site with the latest `periodTo` that is ≤ this visit's day, other than this visit's own report.
   - **First report:** the 7 days up to the visit day (`firstReportDays = 7`, a display constant in `build_report.dart`, not a farming number).
   - Sharing the boundary day means a worker's log written that evening, after the previous report, still lands in a report. The header prints both dates, so the overlap is visible.
4. **Drafts.** A member's latest ended visit with no current report is their draft. It shows first in the Reports list as "Brouillon — à publier". Ending a visit opens the draft straight away. Older unreported visits (all of M3–M5's) are never offered.
5. **Section contents:**
   - **Alerts:** the danger and warning alerts open at publishing, in the Alerts-tab order. They include the duplicate pond-day alert (SPEC §7).
   - **Health,** per pond with something to report:
     - deaths in the period, from `countedLogs` (a pond-day logged twice counts once), split by who observed (Decision 8);
     - warning signs by day;
     - health events and treatments dated in the period.
   - **Water:** every pond holding fish, with its latest reading (or "aucun relevé") and its `waterIssues`.
   - **Growth:** one line per (batch, pond) with live fish:
     - latest weighing point's average weight and date;
     - estimated biomass and live count;
     - latest period FCR with its note (stalled / shared pond / no sample yet) and trend;
     - batch survival.
   - **Feed:** feed given in the period per pond, plus the total. Stock on hand, days left and lot ages need feed lots (M7): `feedStock` stays `null` and the section says "Stock d'aliment : à partir de la gestion des stocks".
   - **Next:**
     - the next weighing per (batch, pond): latest weighing point + `sampleIntervalDays`;
     - planned harvests on or after the visit day;
     - quarantine release: the first stocking + `quarantineDays.min`, for batches in `quarantine`.

     Prep steps come in M7. Items are sorted by date.
   - **Observations and photos:**
     - the visit's condition checks marked "problem", with their notes;
     - one line listing what was OK;
     - free observations;
     - the photos of the observations, of the period's health events, and of the visit.
6. **Estimated values** (live count, biomass) carry "estimé" on screen (`EstimatedLabel`) and in the PDF.
7. **Unread** is per phone: a device-only `report_reads` table, never synced. A member's own reports count as read. Opening a report marks it read. The Reports tab badge shows the unread count. A member usually has one phone; syncing read marks is not worth a table.
8. **Who observed is resolved when reading, never stamped.** CLAUDE.md says `observed_by` is set "when different" from the person entering, and that stays the rule: the worker's own logs keep `observed_by` empty. The observer of a record is `observed_by` if set, otherwise the `Person` linked to the account in `entered_by`. Because this happens at read time, every log recorded since M3 gets the right name too. If `observed_by` names a person this phone doesn't have yet, the name is "inconnu", never the typist's name.
9. **Every account gets a `Person`.** Its id is deterministic: `accountPersonId(memberId)`, a UUIDv5 of the member id under a fixed namespace. Only admins may write `people` (RLS), so admin phones create the missing ones:
   - after each successful sync;
   - right after creating an account.

   Two admin phones doing it at once write the same id and the same values, so last-write-wins merges them into one row. A worker already linked to a person keeps that link. The member form stays the only place to rename an account, and renaming also renames the linked person, in one transaction. The person form shows a linked person's name read-only, with "Renommer depuis Admin › Membres". Person pickers (the transcription observer, the worker link) list every active person, with linked ones suffixed "(membre)" or "(ouvrier)".
10. **Photos** (SPEC §8):
    - **Capture:** camera only, with `image_picker` (`maxWidth`/`maxHeight` 1280). Then `flutter_image_compress`: long edge 1280 px, JPEG quality 70, retried once at quality 50 if the file is over 250 KB.
    - **Storage:** saved as `<docs>/photos/<photoKey>.jpg`. `photoKey` is the first row's id and stays the same when the row is corrected.
    - **Upload flag:** "Envoyer" (upload) is a toggle that writes a superseding row. It can only be set on the phone that holds the file.
    - **Deleting** writes a tombstone and deletes the local file. An already-uploaded copy stays on the server in v1.
    - **Owners:** an observation, a health event, or a visit. A correction of an observation keeps its photos: queries follow the supersede chain (`chainIds`).
    - **A photo never blocks a save.** A capture or compression failure shows a message, and the record still saves.
11. **Upload, download and the cap:**
    - **Bucket:** private bucket `photos`, at path `<associationId>/<photoKey>.jpg`.
    - **Upload:** `PhotoUploader` runs after each successful sync. It sends current upload-marked photos whose file is on this phone and that `photo_uploads` doesn't mark done. "Already exists" counts as done.
    - **Cap:** a **count** of photos per association, so the server can enforce it in a Storage insert policy. The default is 300, about 75 MB at 250 KB each. An admin sets it with setting key `photoUploadCap`. A refused upload stays on the phone with reason `cap`, shown on the sync screen.
    - **Download:** other phones download a photo into the cache directory the first time they show it, if online. Otherwise they show "Photo pas encore disponible".
12. **PDF:**
    - built with `pdf` only. `printing` waits for M8's paper sheets, which need printing; sharing needs only `share_plus`, already a dependency;
    - A4, Noto Sans, trend in words ("en hausse", "en baisse", "stable") rather than arrow glyphs;
    - only photos present on this phone (taken or downloaded), at most 2 per row;
    - file name `rapport-<site>-<yyyy-mm-dd>.pdf`, written to the temp directory, shared with `SharePlus`;
    - written in the sharer's language.
13. **Navigation** (SPEC §6):
    - Tabs: Ponds, Visit, Alerts, **Reports**, More.
    - Routes: `/reports` (list), `/reports/draft/:visitId` (preview: summary, visit photos, Publier), `/reports/:reportId` (published report with Partager).
    - Ending a visit goes to `/reports/draft/:visitId`.
    - Workers never see reports.
14. **Language.** Member screens and the PDF stay French, as in M5. The `mg` ARB gets the new keys with French text, marked for M8's review.

## Global Constraints

- Offline first: building, publishing, reading and sharing a report all work in airplane mode. Only photo upload/download and account creation touch the network.
- `schemaVersion` goes 4 → 5 with a migration, `dart run drift_dev make-migrations`, the committed `drift_schemas/` snapshot and the generated migration test (CLAUDE.md §Code generation). The server gets one migration; `test/server/schema_parity_test.dart` passes.
- `lib/domain/` imports neither Flutter nor Drift (`test/domain/purity_test.dart`). No new farming number is added; every one used comes from `DomainConfig`.
- Weights are integer grams; dates are farm dates via `farmDate`, `daysBetween` and `farmDateToUtc`; ordering uses recorded dates, never the device clock.
- Every string comes from the ARB files. Touch targets ≥ 56 dp. Every pushed screen has a working Back. Publier, Envoyer and photo delete go through `SaveOnce`.
- No money anywhere (CLAUDE.md §6).
- At the end of each task: `flutter analyze` has no issues, and `flutter test` and `TZ=UTC flutter test` pass.
- Commits use a conventional prefix and end with the `Co-Authored-By` and `Claude-Session` lines. Branch: `feat/m6-visit-report` from `main`.

## Review Focus

1. **A pond-day logged on two phones:** the report counts its deaths and feed once and lists the duplicate under Alerts. Test in Task 4.
2. **A worker's own phone logs** (no `observed_by`, entered by the worker's account) show the worker's name in Health, including logs from before M6. With no linked person yet, they show the account's name; an `observed_by` this phone can't resolve shows "inconnu". Tests in Task 1 and Task 4.
3. **A report published offline on phone A** reaches phone B, whose own data differs. B shows A's numbers unchanged and marks the report unread; A's own copy is never unread. Test in Task 5.
4. **Photos while offline for days or past the cap:** the photo stays on the phone, pending with its reason; the report opens and its PDF builds, with missing photos skipped and no throw. Tests in Task 8 and Task 9.
5. **A visit with nothing recorded, on a farm with no fish:** every section shows its empty line (no "NaN", no crash), and the PDF still builds. Tests in Task 4, Task 6 and Task 7.

---

### Task 1: Who observed

**Files:**
- Create: `lib/domain/people.dart`
- Modify: `lib/db/ids.dart`, `lib/domain/farm_facts.dart` (`LogFact`), `lib/db/repositories/facts_repository.dart`
- Test: `test/domain/people_test.dart`, `test/db/ids_test.dart`, `test/db/facts_repository_test.dart`

**Interfaces:**
- Produces (`ids.dart`): `String accountPersonId(String memberId)`, a UUIDv5 under a fixed namespace constant `_accountPersonNamespace` (a UUID literal chosen once).
- Produces (`people.dart`):
  - `class AccountRef { const AccountRef({required String name, String? personId}); }`
  - `class PeopleDirectory { const PeopleDirectory({Map<String, String> people = const {}, Map<String, AccountRef> accounts = const {}}); }`. `people` maps person id to name; `accounts` maps member id to `AccountRef`.
  - `String? observerKey({String? observedBy, required String enteredBy})`: `observedBy`, else the account's `personId`, else `'account:$enteredBy'`.
  - `String? observerName({String? observedBy, required String enteredBy})`: the person's name, else (only when `observedBy` is null) the account's name, else `null`.
- Produces (`farm_facts.dart`): `LogFact` gains `final String enteredBy` (default `''`) and `final String? observedBy`. `currentFacts` fills them.

- [ ] **Step 1: Write the failing tests.**
  - `accountPersonId is stable and differs per member`: two calls give the same value; two members give two values; the result is a valid UUID.
  - `worker's own log resolves to the linked person`: `observedBy: null`, `enteredBy: 'm1'`, accounts `{'m1': AccountRef(name: 'rakoto', personId: 'p1')}`, people `{'p1': 'Rakoto'}`. Gives key `'p1'` and name `'Rakoto'`.
  - `transcribed log resolves to the observer, not the typist`.
  - `account with no person falls back to the account name`.
  - `unknown observed_by gives null name, never the typist`.
  - `currentFacts carries enteredBy and observedBy`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/people_test.dart test/db/ids_test.dart test/db/facts_repository_test.dart`. Expected: FAIL (undefined names).
- [ ] **Step 3: Implement.** `accountPersonId` uses `Uuid().v5`.
- [ ] **Step 4: Run them to see them pass**, plus `test/domain/purity_test.dart`.
- [ ] **Step 5: Commit.** `feat(domain): who observed a record, resolved from person or account`

### Task 2: Every account gets a Person

**Files:**
- Modify:
  - `lib/db/repositories/person_repository.dart`: `ensureAccountPeople`;
  - `lib/db/repositories/member_repository.dart`: `update` renames the linked person; `create` calls `ensureAccountPeople` when the session is admin;
  - `lib/sync/sync_controller.dart`: after a successful `SyncEngine.run`, admins run `ensureAccountPeople`;
  - `lib/features/people/person_form_screen.dart`, `lib/features/people/people_screen.dart`;
  - `lib/features/people/people_providers.dart`: `peopleDirectoryProvider`, `personLabelsProvider`;
  - `lib/features/transcription/transcription_screen.dart`, `lib/features/admin/member_form_screen.dart` (picker labels);
  - `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`;
  - `docs/SPEC.md` §4: "`Person`: every human, workers and members; each account links to one".
- Test: `test/db/person_repository_test.dart`, `test/db/member_repository_test.dart`, `test/features/people_test.dart`, `test/sync/sync_engine_test.dart` (controller hook)

**Interfaces:**
- Consumes: `accountPersonId`, `PeopleDirectory` (Task 1).
- Produces:
  - `Future<int> PersonRepository.ensureAccountPeople()`: for every member with `personId == null`, it inserts (or ignores) a person `{id: accountPersonId(m.id), name: m.name}` and sets `m.personId`, in one transaction, marking both pending. Returns how many it linked.
  - `final peopleDirectoryProvider = Provider<AsyncValue<PeopleDirectory>>`, built from the people and members streams.
  - `final personLabelsProvider = Provider<Map<String, String>>`: person id to display label, e.g. "Hery (membre)".

- [ ] **Step 1: Write the failing tests.**
  - `ensureAccountPeople links unlinked members only`: a worker linked to `p9` keeps `p9`; a member with no person gets `accountPersonId(id)`. It returns 1.
  - `ensureAccountPeople twice writes nothing the second time` (returns 0, no new pending rows).
  - `a person already pulled from another admin is reused`: insert the deterministic person first; there is still one person row.
  - `renaming a member renames the linked person`.
  - `sync on an admin session links accounts; on a member session it doesn't` (fake API).
  - Widget: `linked person's name is read-only with the Admin hint`, and `transcription picker shows "Hery (membre)"`.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.** `flutter test && TZ=UTC flutter test`.
- [ ] **Step 5: Commit.** `feat(people): every account has a person, created by admin phones`

### Task 3: Schema v5 and the server

**Files:**
- Create:
  - `lib/db/tables/visit_reports.dart`, `lib/db/tables/photos.dart`, `lib/db/tables/report_reads.dart`, `lib/db/tables/photo_uploads.dart`;
  - `supabase/migrations/20261101000001_reports_photos.sql`, `supabase/tests/reports_photos_test.sql`.
- Modify:
  - `lib/db/database.dart`: tables, `schemaVersion: 5`, the migration step;
  - `lib/domain/types.dart`: `enum PhotoOwner { observation, healthEvent, visit }`;
  - `lib/sync/sync_tables.dart`: `visit_reports` and `photos` as events, after `treatments`;
  - `lib/db/events.dart`: `chainIds`;
  - `lib/db/backup.dart`, only if it lists tables explicitly.
- Generated: `drift_schemas/`, `test/db/default/generated/schema_v5.dart`, migration test.
- Test: `test/db/schema_v5_test.dart`, `test/db/default/migration_test.dart`, `test/db/events_test.dart`, `test/server/schema_parity_test.dart`

**Interfaces:**
- Produces (Drift classes `VisitReport`, `Photo`, `ReportRead`, `PhotoUpload`):
  - `VisitReports with SyncedRow, EventRow`: `visitId`, `siteId`, `periodFrom` and `periodTo` (`dateTime`, farm days via `farmDateToUtc`), `content` (text, JSON).
  - `Photos with SyncedRow, EventRow`: `ownerKind` (`textEnum<PhotoOwner>`), `ownerId`, `photoKey`, `upload` (bool, default false), `bytes` (int).
  - `ReportReads` (device only): `reportId` primary key, `readAt`.
  - `PhotoUploads` (device only): `photoKey` primary key, `uploadedAt` nullable, `error` nullable.
- Produces (`events.dart`): `Future<Set<String>> chainIds<T extends Table, R>(TableInfo<T, R> table, String id)`: `id` and every id it supersedes, transitively.
- Server:
  - both tables with the sync columns, added to `sync_push`'s table list and to the read and insert loops; `write_own` uses `is_member()`;
  - bucket `photos` (private);
  - Storage `select` policy: `name like my_association()::text || '/%'`;
  - Storage `insert` policy: the same check, plus `is_member()`, plus a count of the association's objects below `coalesce((select max(value) from setting_overrides where association_id = my_association() and key = 'photoUploadCap'), 300)`.

- [ ] **Step 1: Write the failing tests.**
  - `v4 → v5 keeps every row and adds the four tables` (the generated migration test, plus `schema_v5_test.dart` inserting into each table).
  - `chainIds follows two corrections back to the first id`.
  - SQL (`reports_photos_test.sql`): a member inserts a `visit_reports` row; a worker gets `42501`; a Storage insert past a cap of 2 is refused; reading another association's photo returns nothing.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/db` and `supabase test db` (per `docs/deploy.md`).
- [ ] **Step 3: Implement.** Then `dart run build_runner build --delete-conflicting-outputs` and `dart run drift_dev make-migrations`.
- [ ] **Step 4: Run them to see them pass,** plus `flutter test --tags server` against the local server.
- [ ] **Step 5: Commit.** `feat(db): schema v5 with visit reports, photos, read marks and upload queue`

### Task 4: Report content and its builder

**Files:**
- Create: `lib/domain/report/report_content.dart`, `lib/domain/report/build_report.dart`
- Test: `test/domain/report/report_content_test.dart`, `test/domain/report/build_report_test.dart`

**Interfaces:**
- Consumes: `FarmFacts`, `countedLogs`, `placementsOf`, `weighPoints`, `fcrPeriods`, `fcrTrend`, `batchSurvival`, `waterIssues`, `Alert`, `PeopleDirectory`, `DomainConfig`.
- Produces (`report_content.dart`). Every class has `toJson()` and `fromJson`:
  - `class ReportContent { static const currentFormat = 1; int format; ReportHeader header; String? summary; Map<String, String> pondCodes; Map<String, String> batchCodes; List<Alert> alerts; List<PondHealth> health; List<PondWater> water; List<BatchGrowth> growth; List<PondFeed> feed; int feedTotalG; Object? feedStock /* null until M7 */; List<NextItem> next; List<ReportObservation> observations; List<String> visitPhotoKeys; }`
  - `class ReportHeader { String siteName; DateTime visitDay; String memberName; String? groupName; DateTime periodFrom; DateTime periodTo; DateTime builtAt; }`
  - `class ObserverDeaths { String? name; int deaths; }`. A null `name` means unknown.
  - `class PondHealth { String pondId; int deaths; List<ObserverDeaths> byObserver; List<DatedSigns> signs; List<HealthLine> events; List<TreatmentLine> treatments; }`
  - `class HealthLine { DateTime at; Set<WarningSign> signs; String? suspectedIssue; Set<HealthAction> actions; List<String> photoKeys; }`
  - `class TreatmentLine { DateTime at; String? batchId; String product; String dose; String? advisedBy; }`
  - `class PondWater { String pondId; DateTime? at; double? temperatureC; double? ph; double? oxygenMgL; WaterColour? colour; List<WaterIssue> issues; }`
  - `enum FcrNote { stalled, shared, noSample }`
  - `class BatchGrowth { String batchId; String pondId; double avgWeightG; DateTime weighedOn; int liveCount; int biomassG; double? fcr; FcrNote? fcrNote; FcrTrend? trend; double? survival; }`
  - `class PondFeed { String pondId; int feedG; }`
  - `enum NextKind { sample, harvest, quarantineRelease }` and `class NextItem { NextKind kind; DateTime date; String pondId; String batchId; }`
  - `class ReportObservation { String? pondId; ObservationCategory category; bool? ok; String? note; List<String> photoKeys; }`
  - `ReportContent.fromJson` throws `UnsupportedReportFormat` when `format > currentFormat`.
  - Alert facts are encoded as tagged values (`{"d": iso}` for a DateTime, `{"e": "<EnumType>", "v": name}` for an enum, `{"s": [...]}` for a set of `WarningSign`), through one registry that lists every enum type found in `facts:` maps under `lib/domain/alerts/`.
- Produces (`build_report.dart`):
  - `const firstReportDays = 7;`
  - `(DateTime from, DateTime to) reportPeriod({required DateTime visitDay, DateTime? previousPeriodTo})`
  - `class ReportInputs { ReportHeader header; String? summary; FarmFacts facts; Map<String, String> pondCodes; Map<String, String> batchCodes; Map<String, BatchInfo> batches; List<Alert> alerts; Map<String, ReadingInfo> latestReadings; List<(String pondId, HealthLine line)> healthLines; List<(String pondId, TreatmentLine line)> treatments; List<ReportObservation> observations; List<String> visitPhotoKeys; PeopleDirectory people; DomainConfig config; }`. The caller passes only health events and treatments dated in the period.
  - `ReportContent buildReportContent(ReportInputs inputs)`

- [ ] **Step 1: Write the failing tests.** Use the M5 fixture farm: pond `E1` with batch `L1`, 1000 fish at 10 g stocked 01/03, visit on 20/03.
  - `round-trips an alert of every AlertKind` (build one with representative facts for each kind; `fromJson(toJson(x))` equals field by field).
  - `round-trips a full content` and `rejects format 2`.
  - `reportPeriod`: no previous gives 13/03–20/03; previous to 15/03 gives 15/03–20/03; previous on the same day gives 20/03–20/03.
  - `deaths split by observer`: a worker-phone log with 9 deaths (entered by the worker account linked to Rakoto) and a transcribed log with 3 observed by Hery. Gives `deaths: 12`, byObserver `[Rakoto 9, Hery 3]`, largest first.
  - `a pond-day logged on two phones counts once` (Review Focus 1), with the duplicate alert passed through `alerts`.
  - `logs outside the period are left out`; `a log at 23:30 Madagascar on the boundary day counts` (run under `TZ=UTC` too).
  - `growth line is estimated from placements`: after a 30 g sample, `avgWeightG 30`, `liveCount` and `biomassG` from placements, `fcr` from the last period.
  - `shared pond gives FcrNote.shared`, `no sample gives FcrNote.noSample`, `negative gain gives FcrNote.stalled`.
  - `zero fish`: a pond with every fish dead has no growth line, and its deaths still appear in Health.
  - `next`: weighing on 01/03 + `sampleIntervalDays`; a quarantine batch's release on stocking + `quarantineDays.min`; a planned harvest before the visit day is left out; items sorted by date.
  - `empty farm and empty visit` (Review Focus 5): all lists empty, `feedTotalG 0`, nothing throws.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/report`.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass,** under `TZ=UTC` too, plus the purity test.
- [ ] **Step 5: Commit.** `feat(domain): visit report content, its JSON and its builder`

### Task 5: Report repository and providers

**Files:**
- Create: `lib/db/repositories/report_repository.dart`, `lib/features/reports/report_providers.dart`
- Modify:
  - `lib/db/repositories/providers.dart`: `reportRepositoryProvider`;
  - `lib/db/repositories/health_repository.dart`: `watchEventsBetween`, `watchTreatmentsBetween`;
  - `lib/db/repositories/visit_repository.dart`: `watchLatestEndedByMe`.
- Test: `test/db/report_repository_test.dart`, `test/features/reports/report_providers_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 3, 4; `alertsProvider`, `farmFactsProvider`, `pondsProvider`, `batchSummariesProvider`, `peopleDirectoryProvider`.
- Produces (`report_repository.dart`):
  - `class ReportAlreadyPublished implements Exception {}`
  - `Future<String> publish({required String visitId, required ReportContent content})`: in one transaction, it refuses when a current report exists for `visitId`, inserts the row (`recordedAt` = `content.header.builtAt`), and marks it read.
  - `Stream<List<VisitReport>> watchAll()`: current reports for the site, `periodTo` descending, then `recordedAt` descending.
  - `Stream<VisitReport?> watchForVisit(String visitId)`
  - `Future<DateTime?> previousPeriodTo({required DateTime visitDay, required String excludingVisitId})`
  - `Future<void> markRead(String reportId)`
  - `Stream<Set<String>> watchUnreadIds()`: current reports not entered by `session.userId` and not in `report_reads`.
- Produces (`report_providers.dart`):
  - `final reportsProvider = StreamProvider<List<VisitReport>>`
  - `final reportContentProvider = Provider.family<ReportContent?, String>`, keyed by report id. It parses once per row and returns null on `UnsupportedReportFormat`; the screen then shows the update message.
  - `final unreadCountProvider = Provider<int>`
  - `final draftVisitProvider = StreamProvider<Visit?>`: my latest ended visit, when it has no current report.
  - `final draftReportProvider = FutureProvider.family<ReportContent, String>`, keyed by visit id. It builds `ReportInputs` from the providers and repositories above, with the summary from `Visit.summary` and photo keys from Task 8's `PhotoRepository`. Until Task 8 lands, it passes empty lists.

- [ ] **Step 1: Write the failing tests.**
  - `publish twice for one visit throws ReportAlreadyPublished and writes one row`.
  - `a pulled report from another member is unread until markRead` (Review Focus 3): apply it with `applyServerRow`; it is in `watchUnreadIds`; after `markRead` it isn't. `my own published report is never unread`.
  - `previousPeriodTo ignores this visit's report and later reports`.
  - `draftVisitProvider is null once the draft is published` and `offers only the latest ended visit`.
  - `draftReportProvider uses the previous report's periodTo`.
  - `pulled report content renders A's numbers on B`: B's facts differ, and `reportContentProvider` still returns A's deaths.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(reports): publish, list, unread marks and live drafts`

### Task 6: Report screens and the Reports tab

**Files:**
- Create: `lib/features/reports/reports_screen.dart`, `lib/features/reports/report_screen.dart`, `lib/features/reports/report_sections.dart`
- Modify:
  - `lib/features/shell/member_shell.dart`: Reports tab before More, with an unread badge;
  - `lib/router.dart`: the three routes (Decision 13);
  - `lib/features/visit/visit_screen.dart`: `_end` goes to the draft;
  - `lib/features/alerts/alert_tile.dart`: if needed, accept pond and batch codes from a map instead of providers, so report alerts draw from the snapshot;
  - `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`.
- Test: `test/features/reports/reports_screen_test.dart`, `test/features/reports/report_screen_test.dart`, `test/features/visit/visit_screen_test.dart`

**Interfaces:**
- Consumes: Task 5 providers, `EstimatedLabel`, `SaveOnce`, `formatKg`, `formatDate`, `formatDecimal`.
- Produces:
  - `class ReportSections extends StatelessWidget { const ReportSections({required ReportContent content}); }`: the nine F8 sections in order. Headings: "Résumé", "Alertes", "Santé", "Eau", "Croissance", "Aliment", "À venir", "Observations et photos". Each empty section shows one line ("Rien à signaler", "Aucun relevé", …).
  - `ReportScreen.draft(visitId)`: `ReportSections` from `draftReportProvider`, a multi-line summary field saved to `Visit.summary` on change (debounced), the visit's photo strip (Task 8), and Publier. Publier rebuilds the content with the latest summary, publishes, and replaces the route with `/reports/:id`.
  - `ReportScreen.published(reportId)`: `ReportSections` from `reportContentProvider`, `markRead` on open, and Partager (Task 7).
  - `ReportsScreen`: the draft card first, then one card per report. A card shows the visit day, member and group, the period, a danger-count chip, and bold text plus a dot when unread.

- [ ] **Step 1: Write the failing tests.**
  - `ending a visit opens its draft`.
  - `publishing shows the report and clears the draft card`.
  - `an unread report is bold, opening it clears the tab badge`.
  - `estimated biomass carries "estimé"`; `shared pond FCR shows "—" with "bassin partagé"`.
  - `empty report shows each section's empty line` (Review Focus 5).
  - `unknown format shows "Mettez l'application à jour"`.
  - `no overflow on 360 × 640` for a full report (`tester.view.physicalSize`).
  - `a worker session has no Reports tab or route`.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.**
- [ ] **Step 5: Commit.** `feat(reports): reports tab, draft review with publish, and the report page`

### Task 7: PDF and sharing

**Files:**
- Create: `lib/features/reports/report_pdf.dart`, `lib/features/reports/share_report.dart`, `assets/fonts/NotoSans-Regular.ttf`, `assets/fonts/NotoSans-Bold.ttf`, `assets/fonts/OFL.txt`
- Modify: `pubspec.yaml` (`pdf`, font assets), `lib/features/reports/report_screen.dart` (Partager), the ARB files
- Test: `test/features/reports/report_pdf_test.dart`

**Interfaces:**
- Consumes: `ReportContent`, `AppLocalizations`, `PhotoFiles.existingFile` (Task 8; until then a parameter defaulting to "no photos").
- Produces:
  - `Future<Uint8List> buildReportPdf(ReportContent content, AppLocalizations l10n, Locale locale, {Future<Uint8List?> Function(String photoKey)? photoBytes, required pw.Font regular, required pw.Font bold})`
  - `Future<void> shareReport(WidgetRef ref, ReportContent content)`: loads the fonts from the assets, builds the PDF, writes `rapport-<site>-<yyyy-mm-dd>.pdf` to the temp directory, and shares it with `SharePlus.instance.share`.

- [ ] **Step 1: Write the failing tests.**
  - `builds a full report` (the bytes start with `%PDF` and the document has ≥ 1 page).
  - `builds an empty report` (Review Focus 5).
  - `a missing photo is skipped, not thrown` (Review Focus 4): `photoBytes` returns null for one key and throws for another.
  - `a 40-pond report spans pages without error`.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.** Sections in the F8 order; estimated values suffixed "(estimé)"; trend in words; header with site, date, member, group and period.
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(reports): PDF export shared through any app`

### Task 8: Photos: capture and storage

**Files:**
- Create: `lib/db/repositories/photo_repository.dart`, `lib/features/photos/photo_capture.dart`, `lib/features/photos/photo_files.dart`, `lib/features/photos/photo_strip.dart`, `lib/features/photos/photo_providers.dart`
- Modify:
  - `pubspec.yaml` (`image_picker`, `flutter_image_compress`);
  - `lib/features/visit/visit_screen.dart` (the free-observation sheet), `lib/features/health/report_problem_screen.dart`, `lib/features/reports/report_screen.dart` (draft);
  - `lib/features/reports/report_providers.dart`: photo keys into `ReportInputs`;
  - `lib/features/reports/share_report.dart`: `photoBytes` from `PhotoFiles`;
  - the ARB files.
- Test: `test/db/photo_repository_test.dart`, `test/features/photos/photo_strip_test.dart`, `test/android_manifest_test.dart` (if image_picker changes the manifest)

**Interfaces:**
- Produces:
  - `abstract interface class PhotoCapture { Future<Uint8List?> takeCompressed(); }`. `CameraPhotoCapture` implements it per Decision 10; `photoCaptureProvider` exposes it, and tests override it.
  - `class PhotoFiles { PhotoFiles(Directory docs, Directory cache); File ownFile(String key); Future<File?> existingFile(String key); }`. `existingFile` returns the own file, else the cached one, else null.
  - `PhotoRepository`:
    - `Future<String> add({required PhotoOwner owner, required String ownerId, required Uint8List jpeg})`: writes the file first, then the row; returns the key.
    - `Future<void> setUpload(String photoKey, bool upload)`: throws `StateError` when the file isn't on this phone.
    - `Future<void> delete(String photoKey)`: tombstone, then deletes the file.
    - `Stream<List<Photo>> watchFor(PhotoOwner owner, Set<String> ownerIds)`
    - `Future<List<String>> keysFor(PhotoOwner owner, Set<String> ownerIds)`
  - `class PhotoStrip extends ConsumerWidget { const PhotoStrip({required PhotoOwner owner, required String ownerId}); }`: 72 dp thumbnails, an "Ajouter une photo" camera button (56 dp), and on tap a sheet with Envoyer / Ne pas envoyer and Supprimer.

- [ ] **Step 1: Write the failing tests.**
  - `add writes the file then the row; a failed file write leaves no row`.
  - `setUpload supersedes and keeps the key`; `setUpload on a phone without the file throws`.
  - `delete tombstones and removes the file`.
  - `watchFor follows an observation's correction` (via `chainIds`).
  - Widget (fake `PhotoCapture`): `adding a photo shows its thumbnail`; `capture returning null saves nothing`; `capture throwing shows the message and the observation still saves`.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite.**
- [ ] **Step 5: Commit.** `feat(photos): compressed capture on observations, health events and reports`

### Task 9: Photos: upload, download and the cap

**Files:**
- Create: `lib/sync/photo_store.dart`, `lib/sync/supabase_photo_store.dart`, `lib/sync/photo_uploader.dart`
- Modify:
  - `lib/sync/providers.dart`: `photoStoreProvider`;
  - `lib/sync/sync_controller.dart`: run `PhotoUploader` after a successful sync and after `ensureAccountPeople`;
  - `lib/features/sync/sync_screen.dart`: photos waiting to upload, with their reasons;
  - `lib/features/photos/photo_files.dart`: `fetch` downloads into the cache;
  - `lib/features/admin/settings_screen.dart`: a "Photos" section with the cap (`photoUploadCap`, default 300, kept out of `DomainConfig`);
  - `lib/domain/config_overrides.dart`: ignore `photoUploadCap`, if unknown keys aren't already ignored;
  - `docs/SPEC.md` §8: "the cap is a number of photos (default 300)";
  - the ARB files.
- Test: `test/sync/photo_uploader_test.dart`, `test/sync/fake_photo_store.dart`, `test/features/sync/sync_test.dart`, `test/features/admin/settings_test.dart`, `test/server/sync_e2e_test.dart`

**Interfaces:**
- Produces:
  - `abstract interface class PhotoStore { Future<void> upload(String path, Uint8List bytes); Future<Uint8List?> download(String path); }`. It throws `PhotoAlreadyStored`, `PhotoCapReached` or `SyncOffline`.
  - `class PhotoUploader { PhotoUploader(AppDatabase db, PhotoStore store, PhotoFiles files, Session session); Future<int> run(); }`: uploads eligible photos (Decision 11), records `photo_uploads`, and returns the count sent. It stops at the first `SyncOffline`.
  - `Future<File?> PhotoFiles.fetch(String key, PhotoStore? store)`: `existingFile`, else a download to the cache, else null.
  - `Stream<List<(String photoKey, String? error)>> watchPendingUploads()` on `PhotoRepository`.

- [ ] **Step 1: Write the failing tests.**
  - `uploads only marked photos whose file is here, once`.
  - `already stored counts as done`.
  - `cap reached leaves it pending with reason cap, and the next run retries` (Review Focus 4).
  - `offline stops the run and loses nothing`.
  - `fetch caches a download and returns null offline`.
  - Widget: `sync screen lists 2 photos waiting, one at the cap`; `admin sets the cap to 500`.
  - Server e2e: `a photo uploaded by phone A downloads on phone B`.
- [ ] **Step 2: Run them to see them fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the full suite,** plus `flutter test --tags server`.
- [ ] **Step 5: Commit.** `feat(sync): photo upload after sync, downloads on demand, per-association cap`

### Task 10: M6 walk-through and the emulator check

**Files:**
- Create: `integration_test/m6_visit_report_test.dart`

- [ ] **Step 1: Write the walk-through.** On a farm with E1 and L1 (stocked 15 days ago through the repository), with the worker account linked to Rakoto, and with 4 deaths logged on the worker's account and 2 transcribed for Hery:
  1. Start a visit; record a water reading with oxygen 3, a sample, a dike problem with a photo (fake capture), and a summary.
  2. End the visit. The draft shows "Rakoto 4 · Hery 2", the low-oxygen alert, and "estimé" on biomass.
  3. Publish. The Reports list shows it, not bold.
  4. Partager builds the PDF (the share call is stubbed).
  5. Kill and reopen the app. The report and photo are still there.
- [ ] **Step 2: Run it on the 2 GB emulator in airplane mode.** `flutter test integration_test/m6_visit_report_test.dart -d <emulator>`. Expected: PASS.
- [ ] **Step 3: Check sync by hand on two phones.** With the local Supabase server (`docs/deploy.md`):
  1. Phone A (member) publishes offline, with one photo marked Envoyer.
  2. Network on; A syncs; B syncs. B shows the report unread, with A's numbers and the photo downloaded.
  3. B shares the PDF to Files, and the photo is in it.
  4. An admin phone's sync links every account to a person, and the People list shows them once.

  Write the results in the commit body.
- [ ] **Step 4: Check the size.** `flutter build apk --release --split-per-abi`. Write the ARM APK sizes in the commit body; if one is over 30 MB, flag it to the user before merging.
- [ ] **Step 5: Run the whole suite.** `flutter analyze && flutter test && TZ=UTC flutter test`. Expected: no issues, all pass.
- [ ] **Step 6: Commit.** `test: M6 walk-through with report, photos and sharing`

## Not in M6

Feed stock, lot ages and prep steps in the report (M7 fills `feedStock` and the "next" prep items). Editing or rebuilding a published report. Deleting uploaded photos from the server. Syncing read marks across phones. Printing and paper sheets (M8). Malagasy review of report strings (M8).
