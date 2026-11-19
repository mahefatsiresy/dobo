# Design step 5: Visit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Visit tab follows the member's walk along the dike. Before a visit it shows what a visit today would cover. During a visit it lists each pond in code order with its band and its checks. Finished checks keep their results and can be corrected. "Terminer la visite" is pinned at the bottom.

**Architecture:**
- **Checklist:** `buildChecklist` (`lib/features/visit/visit_checklist.dart`) changes from three "due" lists into per-pond groups of checks, each check done or open, with a done/total count. The same function with no visit records gives the counts before a visit, so the two screens always agree.
- **Corrections:** the water and sample forms learn to open an existing record and save a correction through the repository's existing `correctWaterReading` and `correctSample`.
- **Reading values:** the pond page's reading line becomes a shared `ReadingValues` widget, which the visit rows reuse.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, Drift, ARB l10n, `flutter_test` goldens. No new packages.

**Spec:** `docs/design.md` (principles, §Step 5), `docs/SPEC.md` F5, `docs/DOMAIN.md` §Sampling, §Water quality, §Biosecurity.

## Decisions (Claude's calls)

1. **Which checks a pond gets:**
   - **Water:** the pond has live fish, or was read in this visit.
   - **Sample:** one per batch with live fish in the pond that is due (`sampleDueAlert`, as today), or that was sampled in this visit.
   - **Inspection:** every active pond.

   Order within a pond: water, then samples by batch code, then inspection. Observations come after the checks and are not counted.
2. **Done:**
   - Water: a current reading in this visit.
   - Sample: a current sample in this visit.
   - Inspection: all five categories answered in this visit.

   A partly answered inspection is open and shows as a plain row.
3. **What a done row says:**
   - **Water:** `ReadingValues`, with out-of-range values marked as on the pond page.
   - **Sample:** "L-E1 : 152 g (40 poissons)".
   - **Inspection:** "tout en ordre", or the problem categories ("1 problème : digue") in `danger` with `Icons.error`.

   A done row has a leading `Icons.check_circle` in `ok`. An open row has the check's icon and a chevron: `Icons.water_drop`, `Icons.scale`, `Icons.fact_check`.
4. **Taps:**
   - Header line → `/ponds/<id>`.
   - Band → `alertRoute(alert)`; isolated or inconsistent → `/ponds/<id>`, as on the Alerts tab.
   - Open water row → `/water/<pond>`; done → `/water/<pond>?readingId=<id>`.
   - Sample row → `/sample/<pond>?batchId=<b>` plus `&sampleId=<id>` when done.
   - Inspection → `/visit/conditions/<pond>`.
5. **The pond header** is a 56 dp row: `PondCode`, then the phases of its batches (joined with ", "), or `l10n.pondStatus` when the pond has no fish, then a chevron. The band is `pondAttention`'s single band (`bandText`), full width on its own line under the header.
6. **Before a visit:** the "À faire aujourd'hui" heading, then one line per kind with a count above 0, then "Dernière visite : {date}, {member}" for the site's latest ended visit by anyone (name from `membersProvider`; the line is left out when there's no such visit or no name), then the start button. `pastVisits`, `noVisits` and `visitLine` go if nothing else uses them (check with `grep`).
7. **"Tout est en ordre":** a filled 56 dp button above the five rows. It saves every category as OK, correcting this visit's earlier answers that differ, then goes back.
8. **Observation form:** a wrap of `ChoiceChip`s, one per active pond (its code), above the category. Nothing is picked by default, and tapping the picked chip again unpicks it. The dialog returns `(String? pondId, ObservationCategory, String)`.
9. **End confirmation, with checks left:** "{count} contrôles pas faits : {items}. Terminer quand même ?" The items are "relevé E2", "échantillon L-E1" and "état E3", joined with `reportListSeparator`. With nothing left, the current `endVisitConfirm` text.
10. **Biosecurity:** `FoldedSection(title: sectionBiosecurity, summary: "7 rappels")`. Opened, it lists the seven texts, each as `bodyLarge` with a leading `Icons.shield_outlined`.
11. **The summary leaves the visit screen.** `setSummary` stays (the report draft uses it).

## Global Constraints

- No schema, sync, server or report-format change.
- Every string from the ARB files, every key in both; mg drafts; regenerate `docs/mg-review.csv`; check for an existing key before adding one.
- Colours from the theme (guard test). The pond colour shows only as `PondCode`'s swatch on this tab.
- Touch targets ≥ 56 dp; no text below 14 sp; long Malagasy text wraps.
- Corrections are new records (`supersedes_id`), never updates.
- `dart format` only touched files; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/visit`.

## Review Focus

1. **Correcting a reading made in this visit** leaves one current reading, so the row stays done with the new values and the count doesn't change. Covered in Task 2.
2. **A pond whose fish all went during the visit** (a final harvest after its reading): the water row stays because it was read in this visit, and nothing disappears under the member. Covered in Task 1.
3. **"Tout est en ordre" after a problem was recorded** corrects that answer to OK rather than adding a second answer, so the inspection shows "tout en ordre". Covered in Task 3.
4. **Leaving the visit screen and coming back** (the pond page, then back) keeps the open visit and its count. Covered in Task 4.
5. **Long Malagasy texts** (band, sample result, end confirmation) at 130 % text wrap without overflow. Covered in Task 4.

---

### Task 1: The checklist by pond

**Files:**
- Modify: `lib/features/visit/visit_checklist.dart` (rewrite), `lib/features/visit/visit_providers.dart`, `lib/features/visit/visit_screen.dart` (only enough to compile; rewritten in Task 4), `test/features/visit/visit_checklist_test.dart`

**Interfaces:**
- Produces:

```dart
sealed class VisitCheck { const VisitCheck(); bool get done; }
final class WaterCheck extends VisitCheck { final WaterReading? reading; }
final class SampleCheck extends VisitCheck { final Batch batch; final Sample? sample; }
final class InspectionCheck extends VisitCheck {
  final Map<ObservationCategory, Observation> answers; // this visit's, by category
  List<ObservationCategory> get problems;              // answered not OK, in conditionCategories order
}

class PondVisit {
  final PondOverview overview;
  final List<VisitCheck> checks;        // Decision 1 order
  final List<Observation> observations; // free ones (ok == null) about this pond, oldest first
}

class VisitChecklist {
  final List<PondVisit> ponds;             // active ponds, code order
  final List<Observation> farmObservations; // free, pondId == null
  int get done; int get total;
  List<(Pond, VisitCheck)> get open;       // pond order, then check order
}

VisitChecklist buildChecklist({ /* same parameters as today */ });

/// Before a visit: what one started now would cover.
final visitPreviewProvider = Provider<VisitChecklist?>(...); // buildChecklist with empty visit records
```

- [ ] **Step 1: Write the failing tests** in `visit_checklist_test.dart`. Replace the four existing tests with these:
  - A stocked pond gets `[WaterCheck, SampleCheck(L-…), InspectionCheck]` when its batch is due, and an empty pond only `[InspectionCheck]`.
  - Two batches in one pond give their sample checks in batch code order.
  - A reading in this visit makes `WaterCheck.done` true, with `reading` set.
  - A pond with no live fish that was read in this visit keeps its `WaterCheck`, which is done.
  - A batch sampled in this visit keeps its `SampleCheck` (done) even though it's no longer due.
  - An inspection with four answers is not done; with all five and one `ok: false` (dike), it is done with `problems == [dike]`.
  - Free observations land on their pond or in `farmObservations`. Condition answers (`ok != null`) appear in neither.
  - `done`/`total` count checks only. `open` lists open checks in pond, then check, order.
  - Ponds come out in code order even when the overviews arrive out of order.
- [ ] **Step 2: Run** `flutter test test/features/visit/visit_checklist_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** the model and `buildChecklist` (Decisions 1–2), then `visitPreviewProvider` beside `checklistProvider`, passing empty visit lists. Point the old screen's three sections at `open` filtered by check type until Task 4.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(visit): the checklist by pond, finished checks kept`.

### Task 2: Corrections and the reading line

**Files:**
- Create: `lib/features/readings/reading_values.dart`
- Modify: `lib/db/repositories/reading_repository.dart` (`getWaterReading`, `getSample`), `lib/features/readings/water_reading_screen.dart`, `lib/features/readings/sample_screen.dart`, `lib/router.dart` (`readingId`, `sampleId` query parameters), `lib/features/ponds/pond_detail_screen.dart` (`_LatestReading` uses `ReadingValues`)
- Test: `test/features/readings/water_reading_test.dart`, `test/features/readings/sample_test.dart`, `test/db/` reading repository test if one exists (`grep -rln addWaterReading test/db`)

**Interfaces:**
- Produces:

```dart
Future<WaterReading> getWaterReading(String id);   // ReadingRepository
Future<Sample> getSample(String id);
const WaterReadingScreen({required String pondId, String? readingId});
const SampleScreen({required String pondId, required String batchId, String? sampleId});

/// Temperature, pH, O₂ and colour of [reading] in a wrap; an out-of-range
/// value in danger or warning colour with its icon (the pond page's line).
class ReadingValues extends ConsumerWidget { const ReadingValues({required WaterReading reading}); }
```

- [ ] **Step 1: Write the failing tests:**
  - Opening `/water/<E1>?readingId=<id>` shows the reading's temperature, pH, oxygen, colour, date and time. Changing the oxygen and saving leaves one current reading for E1, with the new oxygen and `supersedesId == id`.
  - The same for `/sample/<E1>?batchId=<b>&sampleId=<id>`: fish count and weight filled in; saving supersedes.
  - The pond page still shows "O₂ 2 mg/L" with `Icons.error` in the demo E2 page test (existing test passes unchanged).
- [ ] **Step 2: Run** those tests. Expected: FAIL.
- [ ] **Step 3: Implement** the getters, the forms (load once in `initState` when an id is given; save with `correct…` instead of `add…`), the routes and `ReadingValues`, moved out of `_LatestReading`.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(readings): water readings and samples open for correction`.

### Task 3: "Tout est en ordre" and observations about a pond

**Files:**
- Modify: `lib/features/visit/condition_check.dart`, `lib/features/visit/visit_screen.dart` (`_ObservationDialog`), `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`, `test/features/visit/visit_screen_test.dart`

**Interfaces:**
- Produces: ARB `conditionsAllOk` "Tout est en ordre" / "Milamina avokoa", `observationPond` "Étang (facultatif)" / "Dobo (tsy voatery)". Check the existing keys first.

- [ ] **Step 1: Write the failing tests:**
  - On E1's inspection, tapping "Tout est en ordre" saves five observations with `ok: true` for E1 and returns to the visit.
  - After the dike was saved as a problem, "Tout est en ordre" leaves five current answers, all OK, and the dike answer supersedes the problem.
  - The observation dialog with chip E2 picked saves `pondId == E2`; with none picked, `pondId == null`; tapping the picked chip again unpicks it.
- [ ] **Step 2: Run** `flutter test test/features/visit/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 7 and 8 and the ARB keys. Regenerate l10n and the review sheet.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(visit): all in order in one tap; an observation can name its pond`.

### Task 4: The Visit tab

**Files:**
- Create: `lib/features/visit/visit_pond_group.dart` (the header, band, check rows and observations of one pond)
- Modify: `lib/features/visit/visit_screen.dart` (rewrite of `_start` and `_checklist`; the summary goes), `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`, `test/features/visit/visit_screen_test.dart`
- Test: `test/features/visit/visit_design_test.dart`, goldens `goldens/visit_start_fr.png`, `visit_fr.png`, `visit_mg.png`

**Interfaces:**
- Consumes: `VisitChecklist`, `PondVisit`, the `VisitCheck` types, `visitPreviewProvider` (Task 1); `ReadingValues` and the correction routes (Task 2); `pondAttention`, `bandText`, `alertRoute`, `pondAlertsProvider`, `AttentionBand`, `PondCode`, `FoldedSection`, `membersProvider`.
- Produces: ARB keys, French below, mg drafts:
  - `visitTodayHeading` "À faire aujourd'hui"
  - `visitWaterCount` "{count, plural, =1{1 relevé d'eau} other{{count} relevés d'eau}}"
  - `visitSampleCount` "{count, plural, =1{1 échantillonnage} other{{count} échantillonnages}}"
  - `visitInspectCount` "{count, plural, =1{1 étang à inspecter} other{{count} étangs à inspecter}}"
  - `visitLast` "Dernière visite : {date}, {member}"
  - `visitProgress` "{done} / {total}"
  - `visitInspection` "État de l'étang"
  - `visitAllInOrder` "tout en ordre"
  - `visitProblems` "{count, plural, =1{1 problème : {list}} other{{count} problèmes : {list}}}"
  - `visitSampleDone` "{batch} : {avg} ({count} poissons)"
  - `bioReminders` "{count} rappels"
  - `endVisitLeft` "{count, plural, =1{1 contrôle pas fait : {items}.} other{{count} contrôles pas faits : {items}.}} Terminer quand même ?"
  - `leftWater` "relevé {pond}", `leftSample` "échantillon {batch}", `leftInspection` "état {pond}"

  Reuse `startVisit` (rename its French text to "Commencer la visite"), `visitOpenSince`, `waterReading`, `sampling`, `sectionObservations`, `sectionBiosecurity`, `addObservation`, `endVisit`, `endVisitConfirm`.

- [ ] **Step 1: Write the failing tests** (demo farm, clock at `demoNow`, 360 × 2400 dp, `/visit`):
  - **Before:** "À faire aujourd'hui" with the water, sample and inspection counts from `visitPreviewProvider` on the demo farm, "Dernière visite" when an ended visit exists (none on a fresh farm: the line is absent), and no list of past visits.
  - **Start:** tapping "Commencer la visite" shows "Visite depuis" and "0 / N", where N is the preview's total.
  - **Groups:** pond headers (`PondCode`) appear in code order. E2's danger band sits between E2's header and its first check. E3 (no fish) has only "État de l'étang".
  - **Taps:**
    - E2's header opens E2's page.
    - E2's band opens its fix.
    - E1's water row opens the water form.
    - After a reading for E1 is saved, the row shows its values and a check icon, the count reads "1 / N", and tapping the row opens the form filled in.
  - **Back and forth:** open E1's page from its header, go back, and the visit and its count are unchanged.
  - **Sample done:** after a sample of 40 fish for 6,08 kg, the row reads "L-E1 : 152 g (40 poissons)".
  - **Inspection done:** with the dike as a problem, the row reads "1 problème : Digue" with `Icons.error`.
  - **Observations:** one about E2 shows inside E2's group; a farm-wide one shows under "Observations".
  - **Biosecurity:** folded, with "7 rappels"; it opens on a tap; no `Checkbox` anywhere on the screen.
  - **No summary field** on the screen.
  - **End:** "Terminer la visite" is in `bottomNavigationBar`. With E2's water and E3's inspection left, the dialog names "relevé E2" and "état E3", and confirming opens the report draft. With nothing left, the dialog shows `endVisitConfirm`.
  - **Large text:** in `mg` at 130 % text, no overflow, before and during.
  - **Goldens:** before (fr) and during (fr, mg) at 360 × 780, with E1 read and inspected.
- [ ] **Step 2: Run** `flutter test test/features/visit/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 3–6 and 9–11 and the ARB keys. Remove the keys that are now unused. Regenerate l10n and the review sheet.
- [ ] **Step 4:** Update the older tests in `visit_screen_test.dart` to the new screen (the summary test moves to the report draft if it isn't covered there already). Run the full suite in both time zones and `flutter analyze`. Look at the goldens. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(visit): the visit follows the walk, pond by pond`.

### Task 5: The visit on the phone

**Files:**
- Modify: `tool/design_demo.dart` (`DEMO_PAGE=visit-start` opens `/visit`; `DEMO_PAGE=visit` first starts a visit, saves a reading and an all-OK inspection for E1, then opens `/visit`), `tool/design_screenshots.sh` (the page names in its header)

- [ ] **Step 1:** Add the pages. Run `tool/design_screenshots.sh MNSO6HW8WOQOPB9T visit-start visit` with the phone unlocked and Stay awake on. Look at the PNGs.
- [ ] **Step 2: Commit:** `test: design screenshots of the visit tab`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots shown to the user, and the merge.
