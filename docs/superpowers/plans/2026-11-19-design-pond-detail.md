# Design step 2: Pond Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the pond page so a member sees what needs them, what to feed and what's in the pond, and finds the next action under their thumb. The 10 stacked full-width buttons go.

**Architecture:**
- **Shared pieces** (`lib/features/common/`): `AttentionBand` gains an optional tap with a chevron. New are `ActionTile` (icon and label, ≥ 56 dp, for the grid and the batch actions) and `FoldedSection` (a one-line title and summary that opens on a tap, with no animation, building its child only when open).
- **Summaries:** the one-line summaries of the folded sections come from pure functions in `lib/features/ponds/pond_summaries.dart`.
- **The screen:** `PondDetailScreen` is rewritten from the providers it already uses, plus `dailyLogForDayProvider` for "Donné".
- **Screenshots:** the demo tool gets a page argument, so the device run covers the pond page too.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, ARB l10n, `flutter_test` goldens on the bundled fonts. No new packages.

**Spec:** `docs/design.md` (principles, tokens, §Step 2), `CLAUDE.md`, `docs/SPEC.md` (F2, F6, F9, F10).

## Decisions (Claude's calls)

1. **Bands:**
   - The page shows **every** item as its own band, in `pondAttention` order: isolated, inconsistent, then the alerts.
   - An alert band with a route (`alertRoute(a)`, not this pond's own page) opens it, as `AlertTile` does today.
   - Isolated and inconsistent bands have no tap.
   - `AlertTile` stays for the Alerts tab.
2. **Header:**
   - The app bar title is `PondCode`.
   - The first line of the page is the phase or phases, as on the list. Without fish it is the status (with the next prep step while preparing, `pondPrepNext`).
   - Role labels repeat phase labels ("Grossissement"), so the role, structure and surface move to the folded "Étang" summary, e.g. "Grossissement, étang en terre, 500 m²" (Decision 7).

3. **The pinned bar,** a `FilledButton.icon` 56 dp tall in the `Scaffold.bottomNavigationBar`, inside `SafeArea` with 12 dp padding:
   - fish in the pond (`liveCount > 0 || inconsistent`): "Journal du jour" → `/log/<id>?lot=1`;
   - status `ready`: "Empoissonner" → `/stock?pondId=<id>`;
   - otherwise: "Préparer l'étang" → `/ponds/<id>/prep`.
4. **The grid** (2 per row, `ActionTile`), shown only when it applies, in this order:
   - "Relevé d'eau" (always);
   - "Signaler un problème" (always);
   - "Traitement" (always);
   - "Lever l'isolement" (when isolated);
   - "Préparation" (no fish, unless it is the bar);
   - "Empoissonner" (unless it is the bar).

   A pond without fish has no daily log action anywhere.
5. **⋮ menu:** "Modifier" (admins, as today) and "Archiver" (everyone, as today; the repository still refuses a pond with fish). Its tooltip is `moreActions`.
6. **Today:**
   - The left column holds the log tick ("Journal fait" / "Pas encore de journal") and, when today's log exists, "Donné : 7,0 kg" (`formatKg(feedGivenG)`).
   - The right column holds the ration as the loud number (or the stop sign), as on the list.
   - The section is hidden without fish.
7. **Folded sections:**
   - **"Poids moyen"**, one line per batch: `growthSummary`, the latest weight and, with two or more points, the change since the previous one, e.g. "150 g, +12 g en 14 j". With one point it shows the weight alone.
   - **"Morts par jour":** `deathsSummary`, the total over `deathsPerDay`, e.g. "4 morts en 30 j".
   - **"IC par période":** the latest period's `fcrValue` text with its arrow, or "—".
   - **"Santé":** `healthSummary` with the event and treatment count and the latest date. It is hidden when there are none, as today.
   - **"Étang":** the summary is role, structure and surface. It opens on the inlet/outlet depths when known, and the density with its range.

   Charts and history build only once opened.
8. **Water:** each value out of range gets `Icons.error` (oxygen, danger) or `Icons.warning_amber` (others, warning) before it, in the matching token colour.
9. **Batch block:**
   - The code is in `titleMedium`.
   - One line has ≈ fish, the average weight and ≈ biomass.
   - The growth lines and the feeding guide follow.
   - Then a `Row` of two `Expanded` `ActionTile`s: "Peser" (`weighAction`) → `/sample/<id>?batchId=`, and "Transférer" → `/transfer?...`.
10. **New ARB keys** (fr; mg drafts alongside):

    | Key | French | Malagasy draft |
    |---|---|---|
    | `pondPrepare` | "Préparer l'étang" | "Hanomana ny dobo" |
    | `weighAction` | "Peser" | "Lanjaina" |
    | `feedGiven` | "Donné : {amount}" | "Nomena : {amount}" |
    | `growthSummary` | "{weight}, {delta} en {days} j" | "{weight}, {delta} tao anatin'ny {days} andro" |
    | `deathsSummary` | "{count, plural, =0{Aucun mort} =1{1 mort} other{{count} morts}} en {days} j" | "Maty {count} tao anatin'ny {days} andro" |
    | `healthSummary` | "{count, plural, =1{1 événement} other{{count} événements}}, dernier le {date}" | "Zava-nitranga {count}, ny farany {date}" |
    | `pondFacts` | "Étang" | "Dobo" |
    | `moreActions` | "Plus d'actions" | "Asa hafa" |

11. **Screenshots:** `tool/design_demo.dart` reads `DEMO_PAGE`: `list` (the default), or a pond code such as `E2`, which opens `/ponds/<id>` after the first frame through `routerProvider`. `tool/design_screenshots.sh DEVICE [pages…]` takes the pages, defaulting to `list E1 E2 P1`, and saves `<page>_<locale>_{top,bottom}.png`.

## Global Constraints

- Phone stays offline-first; no schema, sync or server change (`schemaVersion` stays 6).
- Every user-facing string from the ARB files, every key in `app_fr.arb` and `app_mg.arb`. New Malagasy texts are drafts; regenerate `docs/mg-review.csv` with `dart run tool/mg_review.dart export`. Add keys as text before the closing brace; never re-serialise the ARB files.
- Colours from `context.dobo` or the theme only (the guard test). Pond colour appears only as `PondCode`'s swatch on this page.
- Touch targets ≥ 56 dp; no text below 14 sp; folding has no animation.
- Estimated figures with `≈` (`EstimatedLabel`, `approx`); the report and PDFs untouched.
- `dart format` only the files a task touches.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/pond-detail` from `main`.

## Review Focus

1. **A pond with several batches:** each batch block has its own Peser and Transférer acting on that batch, and the weight summary has one line per batch. Covered in Task 3.
2. **An isolated pond:** the band is at the top and "Lever l'isolement" is in the grid. Transférer still opens the transfer screen, which refuses, as today (`health_test.dart`). Covered by the existing health tests, updated in Task 3.
3. **Large text (130 %) in Malagasy:** two `ActionTile`s side by side wrap their labels and nothing overflows. Covered in Task 1 (tile) and Task 3 (page).
4. **A pond page opened before the alerts load:** no bands claiming all is well, and no ration. Same rule as the list: spinner until `alertsProvider` has a value. Covered in Task 3.
5. **Today's log edited after the page opened:** "Donné" updates. `dailyLogForDayProvider` is a `FutureProvider` that the daily log screen invalidates on save. Covered in Task 3.

---

### Task 1: Tap on bands, action tiles, folded sections

**Files:**
- Modify: `lib/features/common/attention_band.dart`, `docs/design.md` (§Building blocks: `ActionTile`, `FoldedSection`, band tap)
- Create: `lib/features/common/action_tile.dart`, `lib/features/common/folded_section.dart`
- Test: `test/features/common/building_blocks_test.dart` (extend; regenerate `goldens/building_blocks.png`)

**Interfaces:**
- Produces:
  - `AttentionBand({required BandSeverity severity, required String text, VoidCallback? onTap})`: with `onTap`, the whole band is an `InkWell` with a trailing `Icons.chevron_right` in the band's ink;
  - `ActionTile({required IconData icon, required String label, required VoidCallback onTap})`: an `OutlinedButton` at least 56 dp tall with the icon above a centred label that wraps (`maxLines` unset);
  - `FoldedSection({required String title, required String summary, required WidgetBuilder builder})`: an `ExpansionTile` with `expansionAnimationStyle: AnimationStyle.noAnimation`, the title (`titleMedium`) with the summary (`bodySmall`) under it, and `builder` called only when open.

- [ ] **Step 1: Write the failing tests:**
  - a band with `onTap` shows `Icons.chevron_right` and calls back on tap; without it, no chevron;
  - an `ActionTile` is ≥ 56 dp tall, and at `TextScaler.linear(1.3)` with the label "Lever l'isolement" in a 150 dp wide box, `tester.takeException()` is null;
  - a `FoldedSection` whose builder increments a counter: the counter is 0 and the summary is shown; after tapping the title, the counter is ≥ 1 and the child is shown, with no frames scheduled after one `pump()` (`tester.hasRunningAnimations` is false);
  - the blocks golden adds a tappable band, two tiles side by side and a folded section.
- [ ] **Step 2: Run** `flutter test test/features/common/building_blocks_test.dart`. Expected: FAIL (the `onTap` parameter and `ActionTile` are undefined).
- [ ] **Step 3: Implement** the three widgets.
- [ ] **Step 4:** Regenerate the golden with `--update-goldens` and look at it. Run the full suite. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(common): tappable bands, action tiles, folded sections`.

### Task 2: One-line summaries

**Files:**
- Create: `lib/features/ponds/pond_summaries.dart`
- Test: `test/features/ponds/pond_summaries_test.dart`

**Interfaces:**
- Consumes: `BatchGrowth`, `WeighPoint`, `PondGrowth` (`pond_growth.dart`, `domain/growth.dart`); `HealthEvent`, `Treatment` (database rows).
- Produces:

```dart
/// Latest weight and, with two points or more, its change since the
/// previous point over how many days.
({double weightG, double? deltaG, int? days}) weightTrend(BatchGrowth g);

/// Deaths over the chart window: total and window length in days.
({int deaths, int days}) deathsOverWindow(PondGrowth g);

/// Health events and treatments together: how many, and the latest date;
/// null when there are none.
({int count, DateTime latest})? healthTally(
  List<HealthEvent> events,
  List<Treatment> treatments,
);
```

- [ ] **Step 1: Write the failing tests:**
  - `weightTrend` with points 138 g on 01/03 and 150 g on 15/03 gives `(150, 12, 14)`; with one point, `(150, null, null)`; with a weight loss, a negative delta;
  - `deathsOverWindow` with `deathsPerDay: [0, 3, 1]` gives `(4, 3)`;
  - `healthTally`: none gives `null`; one event on 12/03 and one treatment on 10/03 give `(2, 12/03)`.
- [ ] **Step 2: Run** `flutter test test/features/ponds/pond_summaries_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.** Points are in date order (as `weighPoints` returns them). `days` is `daysBetween(previous.date, last.date)`.
- [ ] **Step 4: Run** the test. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(ponds): one-line summaries for growth, deaths and health`.

### Task 3: The pond page

**Files:**
- Modify: `lib/features/ponds/pond_detail_screen.dart` (rewrite; `_LatestReading`, `_HealthHistory` and `_growthLines` are kept and restyled), `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`
- Delete: `lib/features/ponds/pond_figures.dart` if nothing else uses it once the page is rewritten (`grep -rn PondFigures lib`)
- Modify (tests that tap moved buttons):
  - `test/features/ponds/pond_detail_test.dart`: "Modifier" and "Archiver" now go through ⋮;
  - `test/features/readings/sample_test.dart`: "Échantillonnage" becomes "Peser";
  - `test/features/prep/prep_screen_test.dart`: "Préparation" is now the bar's "Préparer l'étang" on an empty pond;
  - any other failure the full suite shows.
- Test: `test/features/ponds/pond_detail_design_test.dart` (new), goldens `test/features/ponds/goldens/pond_E2_fr.png`, `pond_E2_mg.png`, `pond_P1_fr.png`

**Interfaces:**
- Consumes:
  - `pondOverviewsProvider`, `pondAlertsProvider`, `alertsProvider`, `stopFeedingProvider`, `loggedTodayProvider`, `dailyLogForDayProvider((pondId, farmToday))`, `pondGrowthProvider`, `healthEventsProvider`, `treatmentsProvider`, `latestReadingProvider`, `sessionProvider`;
  - `pondAttention` and `bandText` (`pond_attention.dart`, `pond_row.dart`);
  - Task 1's widgets and Task 2's functions;
  - `seedDemoFarm` and `demoNow` (`test/demo_farm.dart`).

- [ ] **Step 1: Write the failing tests** in `pond_detail_design_test.dart` (demo farm, clock at `demoNow`, 360 × 2400 dp; open the pond by tapping its row):
  - **E2 bands:** a danger band starting "Oxygène" and a warning band naming the sample (two bands, no "et 1 autre"). Tapping the sample band opens the sample screen.
  - **E2 today:** "Ne pas nourrir", no `rationKey`, "Pas encore de journal".
  - **E1 today:** the ration in `headlineSmall`, "Journal fait" and "Donné : 7,4 kg" (the demo log's 7 400 g).
  - **E1 pinned bar:** the `bottomNavigationBar` holds a `FilledButton` "Journal du jour". There is no other "Journal du jour" on the page.
  - **P1 pinned bar:** the bar says "Préparer l'étang". No "Journal du jour" anywhere, no "Préparation" tile, an "Empoissonner" tile.
  - **A ready pond:** set P2 ready with `PondRepository.setStatus` in the test. The bar says "Empoissonner" and no "Empoissonner" tile shows.
  - **E4 grid:** shows "Lever l'isolement"; E1's grid doesn't.
  - **Two batches in one pond:** stock a second batch into E3 in the test. Two "Peser" tiles; tapping the second opens `/sample/<E3>?batchId=<second batch>`.
  - **⋮ menu:** it holds "Modifier" for an admin and not for a non-admin; "Archiver" for both.
  - **Charts are folded:** no `MiniChart` is built until "Poids moyen" is tapped. The summary reads "150 g" for E1.
  - **Loading:** with `alertsProvider` overridden to `AsyncLoading` (`settle: false`), a spinner and no band, no ration.
  - **Large text:** at 130 % text in `mg` on E4, `takeException()` is null after scrolling to the end.
  - **Goldens:** E2 (fr, mg) and P1 (fr) at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/ponds/pond_detail_design_test.dart`. Expected: FAIL.
- [ ] **Step 3: Add the ARB keys** (Decision 10), then run `flutter gen-l10n` and `dart run tool/mg_review.dart export`.
- [ ] **Step 4: Rewrite `PondDetailScreen`** to `docs/design.md` §Step 2 and Decisions 1–9. Sections are separated by 1 dp `Divider`s. The content is in a `ListView` with 16 dp side padding; bands run full width.
- [ ] **Step 5:** Update the tests listed under Files. Then run `flutter test`, `TZ=UTC flutter test` and `flutter analyze`. Expected: all pass.
- [ ] **Step 6:** Generate the three goldens with `--update-goldens` and look at each. Fix anything clipped, broken mid-word or off-principle, then regenerate.
- [ ] **Step 7: Commit:** `feat(ponds): pond page for a glance: bands, today, batches, folded trends, one pinned action`.

### Task 4: Pond page on the phone

**Files:**
- Modify: `tool/design_demo.dart`, `tool/design_screenshots.sh`, `README.md` (the script line)

**Interfaces:**
- Consumes: `seedDemoFarm` (returns pond ids by code) and `routerProvider`.

- [ ] **Step 1: The demo reads `DEMO_PAGE`.** It keeps the `DemoFarm` map. When the page isn't `list`, it opens `'/ponds/${farm[page]}'` after the first frame through `ProviderScope.containerOf` → `routerProvider`.
- [ ] **Step 2: The script takes a page list** (default `list E1 E2 P1`), builds once per page and locale, and names the files `<page>_<locale>_top.png` / `_bottom.png`.
- [ ] **Step 3: Run** `tool/design_screenshots.sh MNSO6HW8WOQOPB9T` with the phone unlocked and Stay awake on. Expected: 16 PNGs in `build/screenshots/`. Look at each, fix what's off in Task 3's code, and regenerate the goldens if anything changes.
- [ ] **Step 4: Commit:** `test: design screenshots of the pond page`.

Then a fresh whole-branch review, the fixes it calls for, and the screenshots shown to the user before merging.
