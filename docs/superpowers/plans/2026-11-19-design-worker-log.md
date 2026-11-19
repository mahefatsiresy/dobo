# Design step 3: Worker Home and Daily Log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A normal day's log takes the fewest taps, with no scrolling and nothing to read. The worker home shows only the ponds to feed, with the day's progress.

**Architecture:**
- **Shared widgets** (`lib/features/common/`):
  - `ChoiceTile` stops cutting its label;
  - `SignGrid` and `ColourSwatches` lay out two per row;
  - new: `PickerScreen` (a page with a pinned "Vita" button that returns what was picked) and `OptionButton` (a button showing a title and what was picked).
- **`DailyLogScreen`** is rebuilt around a one-screen normal day. Signs, water colour, feedings and death appearance each move to their own `PickerScreen`, opened with `Navigator.push` and returning a value; the log keeps all state until Save.
- **`WorkerHomeScreen`** filters to ponds holding fish and adds a progress line.
- **Data:** no change to schema, repositories or providers.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, ARB l10n, `flutter_test` goldens on the bundled fonts. No new packages.

**Spec:** `docs/design.md` (principles, §Step 3), `CLAUDE.md` (non-negotiable 3, field-worker screens), `docs/SPEC.md` F3 and §6 (worker navigation).

## Decisions (Claude's calls)

1. **The daily log counts as a worker screen.** Its ration is plain kg beside the feed pictogram, for members too (`docs/design.md` §Step 3). It never shows `≈`.
2. **The feed pictogram** is `Icons.rice_bowl`, in `pictograms.dart` as `feedIcon`. The field test checks it with the others.
3. **Picker screens** are a generic `PickerScreen<T>`, pushed with `Navigator.of(context).push<T>(MaterialPageRoute(...))`:
   - The title is in the app bar, which has a back arrow.
   - The body is the grid.
   - A pinned "Vita"/"Terminé" `FilledButton` (56 dp) pops with the current selection; back pops `null`, which keeps the previous value.
   - Signs and death appearance toggle; colour and feedings pick one, and tapping the picked one clears it.
4. **`OptionButton`** is an outlined tile, at least 72 dp tall, with:
   - its title (wrapping);
   - under the title, what was picked: up to 3 small pictograms and a "+N" for signs, the colour swatch, or the number for feedings;
   - nothing shown under the title when nothing is picked.

   The three sit in a row of `Expanded`; "Endrika" is a fourth, beside the deaths box.
5. **The normal-day screen** at 360 × 780 dp with the keyboard closed fits without scrolling, for a worker account and with the stop sign shown:
   - app bar;
   - ration line;
   - feed box;
   - leftover row;
   - deaths row;
   - option row;
   - pinned Save.

   Members' extras (feed lot, note) follow the option row and may scroll.
6. **Grids:** `SignGrid` and `ColourSwatches` take the parent's width through a `LayoutBuilder`: tile width = (width − 8) / 2. `ChoiceTile` drops `maxLines` (labels wrap fully). The leftover row stays three across, `Expanded`.
7. **Worker home:**
   - It shows `overviews.where((o) => o.liveCount > 0 || o.inconsistent)`.
   - The progress line is `workerProgress(done, total)`, counting those ponds and the logged ones among them. When `done == total` it becomes a tick and `workerAllDone`.
   - Without such ponds: `workerNoPonds`.
   - On the tile, the ration is `Icon(feedIcon)` with "7,4 kg", or the stop sign as now.
   - The logged tick is 44 dp (now 36).
8. **New ARB keys** (fr; mg drafts):

   | Key | French | Malagasy draft |
   |---|---|---|
   | `workerProgress` | "{done} / {total} faits" | "{done} / {total} vita" |
   | `workerAllDone` | "Tous les étangs sont faits" | "Vita daholo ny dobo" |
   | `workerNoPonds` | "Aucun étang avec des poissons" | "Tsy misy dobo misy trondro" |
   | `pickDone` | "Terminé" | "Vita" |
   | `feedingsButton` | "Repas" | "Impiry" |
   | `deathAppearanceButton` | "Aspect" | "Endrika" |

   Existing keys reused: `signsSeen`, `waterColourLabel`, `feedings` (picker title), `deathAppearance` (picker title), `feedGiven`, `deaths`, `leftovers`, `rationToday`, `save`.
9. **Other users of the shared grids** (`report_problem_screen`, `water_reading_screen`, `transcription_screen`, `settings_screen`) get the two-per-row layout too. Their tests are updated if they depend on positions.

## Global Constraints

- Phone stays offline-first; no schema, sync or server change.
- Every user-facing string from the ARB files, every key in `app_fr.arb` and `app_mg.arb`; new Malagasy texts are drafts; regenerate `docs/mg-review.csv`. Add keys as text before the closing brace; check for an existing key of the same name first (`grep '"key"'`).
- Colours from `context.dobo` / the theme (guard test); pond colour stays full on worker tiles and the log's tag.
- Touch targets ≥ 56 dp; no text below 14 sp; no animation.
- Every field optional except the feed, as now (`fieldRequired` on the feed only).
- `dart format` only the files a task touches; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/worker-log` from `main`.

## Review Focus

1. **Correcting a day already logged:** reopening a logged pond shows its feed, leftover, deaths and, on the buttons, its signs, colour and feedings. Saving again supersedes; nothing is lost from the sub-screens. Covered in Task 2.
2. **Back from a picker without "Vita"** keeps what was picked before, not an empty set. Covered in Task 2.
3. **Deaths back to 0** after picking an appearance: "Endrika" hides, and the saved log has no death signs (as today: `deaths > 0 ? _deathSigns : {}`). Covered in Task 2.
4. **The keyboard open on the feed box:** the pinned Save stays reachable (Scaffold resizes) and nothing overflows. Covered in Task 2 with `viewInsets`.
5. **A member transcribing** (`?date=`, `observedBy`) still sees the lot and the note, and saving keeps whose sheet it was. The existing tests are kept green. Covered in Task 2.

---

### Task 1: Two-per-row grids, picker screen, option button

**Files:**
- Modify: `lib/features/common/choice_tile.dart`, `lib/features/common/sign_grid.dart`, `lib/features/common/colour_swatches.dart`, `lib/features/common/pictograms.dart` (`feedIcon`)
- Create: `lib/features/common/picker_screen.dart`, `lib/features/common/option_button.dart`
- Test: `test/features/common/pickers_test.dart`, golden `test/features/common/goldens/signs_mg.png`

**Interfaces:**
- Produces:
  - `const IconData feedIcon` (`Icons.rice_bowl`);
  - `class PickerScreen<T> extends StatefulWidget { const PickerScreen({required String title, required String doneLabel, required T initial, required Widget Function(BuildContext, T value, ValueChanged<T> onChanged) builder}); }`: scrollable body, pinned done button that pops the current value;
  - `class OptionButton extends StatelessWidget { const OptionButton({required String title, Widget? picked, required VoidCallback onTap}); }`.

- [ ] **Step 1: Write the failing tests:**
  - At 360 dp, `SignGrid` lays out two tiles per row: the first two tiles share a `dy`, and the third is lower.
  - In `mg`, every sign's label renders in full: for each tile's `Text`, `RenderParagraph.didExceedMaxLines` is false and `maxLines` is null.
  - `ColourSwatches` is two per row.
  - Pushing a `PickerScreen<Set<WarningSign>>` with `initial: {rubbing}`, tapping a second sign and "Vita" returns both; tapping back returns `null`.
  - `OptionButton` without `picked` shows only its title; with `picked` it shows it; it is ≥ 72 dp tall.
  - Golden `signs_mg.png`: a `PickerScreen` of all 13 signs in `mg` at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/common/pickers_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 3, 4 and 6.
- [ ] **Step 4:** Generate and look at the golden. Run the full suite and update any position-dependent test of the other grid users (Decision 9). Expected: PASS.
- [ ] **Step 5: Commit:** `feat(common): two-per-row pictograms that never cut a label, picker screens, option buttons`.

### Task 2: The daily log on one screen

**Files:**
- Modify: `lib/features/daily_log/daily_log_screen.dart`, `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`
- Modify (tests): `test/features/daily_log/daily_log_screen_test.dart`, `test/features/daily_log/worker_home_test.dart` (log flows), and any other the full suite shows
- Test: `test/features/daily_log/daily_log_design_test.dart` (new), goldens `goldens/log_E1_mg.png`, `log_E1_fr.png`, `log_E2_mg.png`

**Interfaces:**
- Consumes: Task 1's widgets and `feedIcon`; the existing `DailyLogInput`, `dailyLogForDayProvider`, `stopFeedingProvider`, `StopFeedingSign`, `LeftoverPicker`, `BigNumberField`, `deathSigns`; `seedDemoFarm` and `demoNow`.

- [ ] **Step 1: Write the failing tests** (worker account, demo farm, clock at `demoNow`, 360 × 780 dp, open `/log/<E3>`, which is not logged yet):
  - **No scrolling:** the Save button, the leftover tiles, the deaths box and the three option buttons are all within the screen (`tester.getRect(...).bottom <= 780`), with no scroll offset. The same holds on E2 with the stop sign.
  - **A normal day in three actions:** enter "4" in the feed box, tap the "some left" leftover, tap Save. The saved log has 4000 g, `Leftover.some`, deaths 0, no signs, colour null, feedings null.
  - **Signs:** tap "Famantarana", tap two signs, then "Vita". The button shows two pictograms. Save stores both signs.
  - **Back keeps:** open "Famantarana" again, tap a third sign, press back. Still two pictograms; Save stores two.
  - **Colour and feedings:** pick "Maitso" and 3. Save stores `WaterColour.mediumGreen` and 3.
  - **"Endrika":** hidden at deaths 0; shown after typing 2. Pick one appearance, then type 0: "Endrika" hides and Save stores no death signs.
  - **No text field for a worker:** no "Fanamarihana"/"Ajouter une note" and no lot picker. For a member (`?lot=1`) both are there.
  - **The ration for the worker:** `Icon(feedIcon)` and "4 kg" (E3's ration as `formatKg`), with no text containing "≈". On E2 the stop sign shows instead and the feed is still required.
  - **Correcting:** open E1 (logged by the demo with 7 400 g, no signs). The feed box reads "7,4". Save with 7,0 supersedes it: there's one current log, with 7 000 g.
  - **Keyboard open:** with `tester.view.viewInsets` bottom set to 300 physical px, `takeException()` is null and Save is still hit-testable.
  - **Goldens:** E1 (mg, fr) and E2 (mg) at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/daily_log/daily_log_design_test.dart`. Expected: FAIL.
- [ ] **Step 3: Add the ARB keys** (Decision 8), then run `flutter gen-l10n` and the mg review export.
- [ ] **Step 4: Rebuild `DailyLogScreen`** to `docs/design.md` §Step 3 and Decisions 1, 3–5. Keep `_load`, `_save`, `SaveOnce`, the transcription path (`date`, `observedBy`) and `_LotPicker`.
  - The body is a `SingleChildScrollView`, for members' extras and the keyboard.
  - Save is the `bottomNavigationBar` (`SafeArea`, 12 dp padding, 56 dp).
  - The note is shown only when the session is not a worker account (`sessionProvider` `isWorker`).
- [ ] **Step 5:** Update the older tests (taps that moved behind buttons; "≈" expectations on the log). Run the full suite and `TZ=UTC`, and `flutter analyze`. Expected: all pass.
- [ ] **Step 6:** Generate and look at the goldens; fix anything clipped or broken mid-word; regenerate.
- [ ] **Step 7: Commit:** `feat(daily-log): a normal day on one screen; signs, colour and feedings on their own screens`.

### Task 3: The worker home

**Files:**
- Modify: `lib/features/daily_log/worker_home_screen.dart`
- Modify (tests): `test/features/daily_log/worker_home_test.dart`
- Test: `test/features/daily_log/worker_home_design_test.dart` (new), goldens `goldens/home_mg.png`, `home_fr.png`

**Interfaces:**
- Consumes: `pondOverviewsProvider`, `loggedTodayProvider`, `stopFeedingProvider`, `feedIcon`, `workerProgress`, `workerAllDone`, `workerNoPonds`.

- [ ] **Step 1: Write the failing tests** (worker account, demo farm, clock at `demoNow`):
  - The tiles are E1–E6 only, in code order. No P1 or P2.
  - The progress line reads "1 / 6 vita" (E1 is logged by the demo; E5's inconsistent count stays among the tiles).
  - After saving a log for every other pond (through the repository), the line is `workerAllDone` with a tick.
  - E3's tile shows `feedIcon` and "4 kg", with no "≈". E2's tile shows the stop sign and no kg.
  - On a farm whose ponds have no fish, the home shows `workerNoPonds`.
  - Goldens `home_mg.png` and `home_fr.png` at 360 × 780.
- [ ] **Step 2: Run** the new test. Expected: FAIL.
- [ ] **Step 3: Implement** Decision 7.
- [ ] **Step 4:** Update `worker_home_test.dart` for the filtered tiles and plain ration. Run the full suite in both time zones and `flutter analyze`. Look at the goldens. Expected: all pass.
- [ ] **Step 5: Commit:** `feat(worker): ponds to feed only, the day's progress, the ration to aim for`.

### Task 4: Worker screens on the phone

**Files:**
- Modify: `tool/design_demo.dart`, `tool/design_screenshots.sh`

- [ ] **Step 1: The demo understands two new pages:**
  - `DEMO_PAGE=worker` opens `/worker`;
  - `DEMO_PAGE=log-E1` opens `/log/<E1 id>`;
  - an unknown pond code throws instead of opening `/ponds/null`.

  The pages open once the router is on `/ponds` (wait for the location, up to 10 s), not after a fixed 2 s.
- [ ] **Step 2: Run** `tool/design_screenshots.sh MNSO6HW8WOQOPB9T worker log-E1 log-E2` with the phone unlocked and Stay awake on. Look at each PNG and fix what is off in Tasks 1–3.
- [ ] **Step 3: Commit:** `test: design screenshots of the worker screens`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots shown to the user, and the merge.
