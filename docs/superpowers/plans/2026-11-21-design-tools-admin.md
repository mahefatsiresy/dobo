# Design step 7b: tools and admin pages — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transcription becomes one paper sheet per screen. The paper sheets, prep, sync, account, admin pages and exports take the step 7 form standard. The paper sheet PDF takes the app's look.

**Architecture:**
- **Shared pieces:** the pieces of step 7 (`PinnedAction`, `PondChoice`, `ChoiceButtons`/`ChoiceField`, `DetailsFold`, `FormMenu`, `confirmDelete`, `showDone`, `FoldedSection`, `AttentionBand`) and the customer picker's pattern (a go_router route that pops with an id).
- **New shared pieces:** `PondChoice(multi: …)` for picking many ponds, a person picker route, and a pure `transcription_sheet.dart` deciding a sheet's rows and what a save sends.
- **No change** to schema, sync, server, domain formulas or the paper sheet's layout.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, Drift, `pdf`, ARB l10n, `flutter_test` goldens.

**Spec:** `docs/design.md` (principles, §Step 7 form standard, §Step 7b), `docs/SPEC.md` F4, F10, F13, F14, F15, §7.

## Decisions (Claude's calls)

1. **Transcription state** (`lib/features/transcription/transcription_sheet.dart`, pure Dart):

   ```dart
   class DayEntry { String kg; String deaths; Set<WarningSign> signs; Leftover? leftover; bool ateFast; WaterColour? colour;
     bool get isEmpty; bool get hasDetails; }
   /// What the sheet of (pond, week) sends: one input per typed day; days already logged are never in [typed].
   ({List<DailyLogInput> inputs, List<DateTime> missingFeed}) sheetInputs({
     required String pondId, required String personId, required Map<DateTime, DayEntry> typed});
   ```

   - A day with anything typed but no feed is listed in `missingFeed`, and nothing is sent while that list is not empty.
   - Deaths left empty means 0.
   - Typing lives in the screen state keyed by (pondId, monday, day). It is kept across switching pond or week and dropped after a save.
2. **Transcription screen:**
   - **Worker:** a 56 dp `InputDecorator` row "Fiche de" that opens `/more/transcription/person`. That route is a person picker: active people without an account first, then members, by name. It pops with the person id.
   - **Week:** ‹ › with `weekOfLabel`.
   - **Ponds:** `PondChoice` over active ponds. Captions: `✓` (`transcriptionSaved`) when every day of the week is logged or this session saved it, and `•` (`transcriptionUnsaved`) when it has unsaved typing. The first pond is picked to start.
   - **Day rows:** 56 dp each. A day label ("Lun 09/11", `EEE dd/MM`), a feed `NumberField` (suffix kg, flex 3), a deaths `NumberField` (suffix ✝, flex 2), and a 56 dp `IconButton` with `Icons.add` (or the picked pictograms, at most 3 at 20 dp, in a `Row`).
   - **A day already logged:** one ink line "7,0 kg · ✝ 2" with `transcriptionLogged` "déjà saisi" in `bodySmall` and a chevron, opening `/log/:pondId?date=…&lot=1`.
   - **Missing feed:** that row's feed field gets `errorText: ''`, and one danger band under the rows reads `transcriptionFeedMissing` "{days} : la quantité d'aliment manque".
   - **Pinned:** `PinnedAction(Icons.check, transcriptionSave "Enregistrer la fiche {pond}")`. With no worker picked, it shows `fieldRequired` under the worker row and saves nothing. After saving: `showDone(transcriptionSaved "Fiche {pond} enregistrée")`, then the next pond in code order with no ✓ and nothing typed is picked.
   - **Leaving with unsaved sheets:** `PopScope(canPop: false)` asks `transcriptionLeave` "Quitter sans enregistrer les fiches {ponds} ?", with `transcriptionStay` "Rester" and `transcriptionQuit` "Quitter".
   - **The + page:** a `PickerScreen` titled `transcriptionCellDetails` with `LeftoverPicker`, `SignGrid` and `ColourSwatches`, one under the other with titles, and `done` "Fait".
3. **Paper sheets screen:**
   - **Week:** ‹ ›.
   - **Weeks:** `ChoiceField<int>` with 1–4.
   - **Ponds:** `PondChoice(multi: true)`, all picked to start, with `paperPondsLabel` as its title.
   - **Count:** a line `paperPages` "{count, plural, =1{1 page} other{{count} pages}} : {ponds} étangs × {weeks} semaines".
   - **Actions:** "Imprimer" pinned, and an outlined "Partager le PDF" above the pinned bar, at the foot of the body. While the PDF builds, both are disabled and `exportBuilding` shows above them.
4. **`PondChoice(multi: true)`**: `values: Set<String>` and `onChangedMany: ValueChanged<Set<String>>`. A tap toggles a pond, picked ones are filled, and a lone option is not auto-picked. The single-pick API is unchanged.
5. **Paper PDF look:**
   - **Fonts:** Atkinson Hyperlegible Next Regular and Bold through `pdfTheme(fallback: [Noto Sans, Noto Sans Math Symbols])`, as `share_report.dart` does.
   - **Lines:** in `ink` (`#17262B`, from `DoboColors.standard`) instead of `PdfColors.grey600`. The pond tag keeps its full colour.
   - Widths, rows and pages are unchanged.
6. **Prep page:**
   - **Header:** the app bar title `prepTitle`, with the pond's status as a second line.
   - **Step rows:** one per `PrepStep`, in order, 56 dp, a number then the step name. Then:
     - **done:** `Icons.check_circle` in `ok`, the date (and "jusqu'au …" for dry and rest), a chevron; it opens `_StepPage` filled in;
     - **next:** `Icons.radio_button_checked` in ink, the name in Bold, the dose line (`prepLimeDose` / `prepManureDose` / `prepNoSurface`), then an outlined 56 dp `prepDoneToday` "Fait aujourd'hui";
     - **to come:** `Icons.radio_button_unchecked` in `inkMuted`, with its dose line when it has one.
   - **"Fait aujourd'hui":** for drain, dry, fill and rest, `PrepRepository.record(pondId, step, on: today)` then `showDone(prepStepDone "Étape enregistrée")`. For treat and fertilise it opens `_StepPage` with today's date and the dose for this pond filled in.
   - **`_StepPage`** (a page, replacing `_StepDialog`): date, product `ChoiceField` (treat: quicklime or chlorine; fertilise: manure), dose `NumberField`. It pins `prepSaveStep` "Enregistrer l'étape", and ⋮ holds Supprimer (`confirmDelete` with `prepDeleteConfirm` "Supprimer l'étape {step} du {date} ?").
   - **Mark ready:** pinned `PinnedAction(Icons.check, prepMarkReady)` while `canMarkReady`. Its confirmation dialog keeps today's text, with warning `AttentionBand`s for skipped steps and a short rest.
7. **Sync page:**
   - **Bands at the top:**
     - `rejected > 0`: danger `syncRejectedCount`;
     - `offline` / `failed` / `signedOut` / `unlinked` / `notConfigured`: warning with today's state strings;
     - `running`: an ink line with a 20 dp progress indicator.
   - **Under the bands:** `syncNever` or `syncLast`, `syncPending`, `syncPhotosWaiting` (and `syncPhotoCap` as a warning band).
   - **Refused rows:** a row each (`tableLabel` · date, then the reason), with `Icons.block` in `danger`, then an outlined "Renvoyer" (`syncRetry`) when there are any. "Se reconnecter" stays an outlined button when signed out.
   - **Backup:** a `FoldedSection` `backupSection` "Sauvegarde", summary `backupSummary` "Exporter ou importer une copie", holding the two outlined buttons.
   - **Pinned:** `syncNow`, disabled while running.
8. **Account page:** the name (`titleLarge`), then `accountRole` and the group in `bodySmall`, then a language row (current language and a chevron, the More dialog), then an outlined "Se déconnecter" at the foot with today's dialog. A worker's account shows the same.
9. **Admin pages:**
   - **The Administration page:** three rows with summaries:
     - `adminMembersSummary` "{active} actifs, {workers, plural, =0{aucun ouvrier} =1{1 ouvrier} other{{workers} ouvriers}}";
     - `adminGroupsSummary` "{count, plural, =1{1 branche} other{{count} branches}}";
     - `adminSettingsSummary` "{count, plural, =0{Valeurs du manuel} =1{1 valeur modifiée} other{{count} valeurs modifiées}}" (overrides for this site).
   - **Members list:** rows of name (with `memberYou` "vous" for the signed-in account), then role and group on a `bodySmall` line. Inactive members are folded in `FoldedSection` `membersInactive` "Inactifs". The last row is `memberAdd` "Ajouter un membre"; the FAB goes.
   - **Groups list:** rows that open the rename dialog, and a last row `groupAdd` "Ajouter une branche"; the FAB goes.
   - **People list:** active people by name, inactive folded (`peopleInactive` "Inactifs"), and a last row `personAdd` "Ajouter une personne"; the FAB goes.
   - **Member form:**
     - role as `ChoiceField<MemberRole>`; language as `ChoiceField<String>` (fr/mg);
     - group through a picker route `/more/admin/groups/pick` (rows, tick on current, "Aucune" first), on the customer picker's pattern;
     - person: an existing `DropdownButtonFormField` becomes the same pattern, a picker route `/more/people/pick`;
     - admin, sales and active as `SwitchListTile`s (56 dp, no padding);
     - resets in ⋮ (`resetPassword` / `resetPin`) opening `ResetSecretDialog` as today;
     - pinned `memberAddAction` "Ajouter le membre" or `save`.
10. **Settings page:**
    - **Sections:** one `FoldedSection` per section in today's order, summary `settingsChanged` "{count, plural, =0{Valeurs du manuel} =1{1 modifiée} other{{count} modifiées}}" from the overrides in the form.
    - **A value:** inside a section, its label, the field(s), and `settingDefault` (today's string) in `bodySmall`. A changed value has a `TextButton` `settingReset` "Rétablir" that clears its field.
    - **Pinned:** `save`, then `showDone(settingsSaved)`. `settingsIntro` stays above the sections.
11. **Exports:**
    - **Fields:** `ChoiceField<ExportKind>` with today's labels; from and to `DateField`s; `PondChoice(multi: true)` titled `exportPond`, none picked meaning all, captioned by a line `exportAllPonds` while none is picked.
    - **Date order:** `exportEndBeforeStart` as a danger band under the dates, which disables both actions.
    - **Weekly sheets:** `exportWeeklyWholeWeeks` as an ink line when the kind is weekly.
    - **Actions:** the pinned button is `exportPdf` (`Icons.picture_as_pdf`), with an outlined `exportCsv` above the bar at the body's foot.
    - **Several ponds:** today the export takes one pond or all. The export functions take `Set<String>? pondIds` (null = all) and filter by membership. `load_exports.dart` and `export_tables.dart` change their filter from one id to a set, with tests.
12. **Strings:** new keys in both ARB files (mg drafts), `docs/mg-review.csv` regenerated, unused keys removed at the end (the script from step 7).
13. **Demo additions** (`seedDemoAdmin(db, farm)` in `test/demo_farm.dart`, written in Task 1 and used by every task's tests):
    - person "Rakoto" (worker, no account) and "Soa" (inactive);
    - a second member "Hery" (member, sales flag) inserted into `members`;
    - one setting override (oxygen minimum 3,5);
    - two of Rakoto's daily logs this week for E1, transcribed;
    - one daily log row marked rejected (`syncState: rejected`, `syncError: '42501'`).

    P1's prep already has drain and dry.

## Global Constraints

- No schema, sync, server or domain-formula change; no new package.
- Every string from the ARB files, every key in both; mg drafts; regenerate `docs/mg-review.csv`; remove keys nothing uses any more. Edit ARB files line by line.
- Colours from the theme (guard test); `Colors.*` only for pond tags.
- Touch targets ≥ 56 dp; no text below 14 sp on screen; long Malagasy text wraps.
- Append-only: transcription saves through `saveWeek`; prep through `PrepRepository`.
- Design tests fix the clock (`clockProvider`) so goldens never follow the real date.
- `dart format` only touched files, by name; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/tools-admin`.

## Review Focus

1. **Transcribing a week that crosses into a day already logged on the worker's phone:** the logged day is never sent again, and other days of that sheet still save. Covered in Task 1.
2. **Typing in E2, switching to E3, saving E3:** E2's typing survives, still marked •, and leaving asks about E2 only. Covered in Task 1.
3. **A worker deactivated while their sheet is open:** the picker no longer lists them; the sheet still saves under the person picked. Covered in Task 1.
4. **Exports with several ponds:** the CSV and PDF hold rows of the picked ponds only, and all ponds when none is picked. Covered in Task 6.
5. **Settings "Rétablir" then Enregistrer:** the override is removed (the handbook value applies again), not saved as an empty value. Covered in Task 5.

---

### Task 1: Transcription, one sheet per screen

**Files:**
- Create: `lib/features/transcription/transcription_sheet.dart`, `lib/features/people/person_picker.dart`, `seedDemoAdmin` in `test/demo_farm.dart`, `test/features/transcription/transcription_sheet_test.dart`, `test/features/transcription/transcription_design_test.dart`, goldens `transcription_fr.png`, `transcription_mg.png`
- Modify: `lib/features/transcription/transcription_screen.dart` (rewrite), `lib/router.dart` (`/more/transcription/person`), ARB files, `docs/mg-review.csv`, `test/features/transcription/transcription_test.dart`

**Interfaces:**
- Produces: Decision 1's `DayEntry` and `sheetInputs`; `Future<String?> pickPerson(BuildContext context, {String? current})`.

- [ ] **Step 1: Write the failing tests.**
  - **`sheetInputs`:**
    - Mon "7,4" and Tue empty give one input with 7 400 g and deaths 0;
    - Wed with deaths "2" and no feed gives `missingFeed: [Wed]` and no inputs;
    - signs, leftover and colour are carried over;
    - `observedBy` is the person.
  - **Screen:**
    - the worker row opens the picker; Rakoto (no account) is listed before the members;
    - pond buttons show E1's caption ✓ once all its days are logged;
    - a logged day is one line with "déjà saisi" and opens `/log/…`.
  - **Unsaved sheets:** typing in E2 then picking E3 keeps E2's typing and E2's caption shows •; saving E3 leaves E2 •; Back asks "Quitter sans enregistrer les fiches E2 ?" (Review Focus 2).
  - **Missing feed:** deaths without feed shows the band and saves nothing.
  - **Saving:** the pinned "Enregistrer la fiche E1" saves with `observedBy`, shows "Fiche E1 enregistrée", and picks the next pond without ✓.
  - **A logged day in the week:** a day already logged stays out of the save while the others go through (Review Focus 1).
  - **The + page:** picking a sign and "Fait" shows its pictogram on the row.
  - **Large text:** mg at 130 % at 360 dp has no overflow and no horizontal scroll.
  - **Goldens:** fr and mg at 360 × 780.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 1, 2 and 12. Update the existing transcription tests to the new screen.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(transcription): one paper sheet per screen`.

### Task 2: Paper sheets screen and the PDF's look

**Files:**
- Modify: `lib/features/common/pond_choice.dart` (`multi`), `lib/features/paper/paper_sheet_screen.dart`, `lib/features/paper/paper_sheet_pdf.dart`, `lib/features/paper/print_pdf.dart` (fonts), ARB files, `test/features/paper/*`, `test/features/common/form_pieces_test.dart`
- Test: golden `paper_fr.png`

**Interfaces:**
- Produces: `PondChoice({…, bool multi = false, Set<String> values = const {}, ValueChanged<Set<String>>? onChangedMany})`.

- [ ] **Step 1: Write the failing tests:**
  - **`PondChoice(multi)`:** taps toggle; picked ones are filled; a lone option is not auto-picked.
  - **Paper screen:**
    - all ponds picked to start; the line reads "8 pages : 4 étangs × 2 semaines" after picking 2 weeks with 4 ponds;
    - unpicking a pond changes the count;
    - "Imprimer" is pinned; no `ChoiceChip`, no `FilterChip`.
  - **PDF:** the bytes contain `AtkinsonHyperlegibleNext`; `pdftotext` finds the same labels as before; the page count is still ponds × weeks.
  - **Golden:** the paper screen in fr.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 3–5.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(paper): pond buttons and a page count; the sheet in Atkinson and ink`.

### Task 3: Prep as a numbered sequence

**Files:**
- Modify: `lib/features/prep/prep_screen.dart` (rewrite; `_StepDialog` becomes a page route `/ponds/:id/prep/:step`), `lib/router.dart`, ARB files, `test/features/prep/prep_screen_test.dart`
- Test: `test/features/prep/prep_design_test.dart`, goldens `prep_fr.png`, `prep_mg.png`

- [ ] **Step 1: Write the failing tests** (demo farm, P1 with drain and dry done):
  - **Rows:** six rows numbered 1–6; Vider and Sécher with ✓ and dates; Traiter in Bold with "Fait aujourd'hui"; Remplir with ○.
  - **"Fait aujourd'hui" on Traiter:** it opens the step page with today's date and the lime dose filled in; "Enregistrer l'étape" saves it, then Fertiliser is next.
  - **"Fait aujourd'hui" on Remplir:** once it is next, one tap saves it dated today and shows "Étape enregistrée".
  - **Correcting:** a done row opens its page filled in; ⋮ Supprimer names the step and date.
  - **Mark ready:** "Marquer prêt" is pinned only once `canMarkReady`; the confirmation shows the skipped-step band.
  - **Large text and goldens:** mg at 130 % has no overflow; goldens fr and mg.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** Decision 6.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(prep): the checklist as its sequence, the next step one tap away`.

### Task 4: Sync and account

**Files:**
- Modify: `lib/features/sync/sync_screen.dart`, `lib/features/account/account_screen.dart`, ARB files, `test/features/sync/sync_test.dart`, `test/features/account/account_test.dart`
- Test: `test/features/sync/sync_design_test.dart`, goldens `sync_fr.png`, `account_fr.png`

- [ ] **Step 1: Write the failing tests:**
  - **Sync, refused:** a rejected row gives a danger band "1 refusé" and a row with its table, date and reason, plus "Renvoyer".
  - **Sync, offline:** a warning band.
  - **Sync, controls:** "Synchroniser maintenant" in the pinned bar, disabled while running; the backup buttons are hidden until "Sauvegarde" is opened.
  - **Account:** the name, the role and group line, the language row showing "Français", and "Se déconnecter" outlined at the foot.
  - **Large text and goldens:** mg at 130 % has no overflow on both pages; goldens.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 7 and 8.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(sync,account): the state first as a band, sync pinned, backup folded`.

### Task 5: Administration

**Files:**
- Create: `lib/features/admin/group_picker.dart`
- Modify:
  - `lib/features/admin/admin_screen.dart`, `members_screen.dart`, `member_form_screen.dart`, `groups_screen.dart`, `settings_screen.dart`
  - `lib/features/people/people_screen.dart`, `lib/features/people/person_picker.dart` (reused for the member's person)
  - `lib/router.dart`, ARB files, `test/features/admin/*`, `test/features/people_test.dart`
- Test: `test/features/admin/admin_design_test.dart`, goldens `admin_fr.png`, `members_fr.png`, `member_fr.png`, `settings_fr.png`

- [ ] **Step 1: Write the failing tests:**
  - **Administration page:** the three summaries ("2 actifs, aucun ouvrier", "1 branche", "1 valeur modifiée").
  - **Members list:**
    - "vous" on the own row;
    - inactive members folded;
    - the last row "Ajouter un membre";
    - no `FloatingActionButton` on members, groups or people.
  - **Member form:**
    - role and language by `ChoiceButtons`;
    - the group picker returns a group;
    - ⋮ holds "Réinitialiser le mot de passe";
    - the pinned "Ajouter le membre";
    - no `SegmentedButton`, no `DropdownButtonFormField`.
  - **Settings:**
    - sections folded with "1 modifiée" on Qualité de l'eau;
    - opening it shows the handbook value;
    - "Rétablir" then "Enregistrer" removes the override, so the oxygen minimum is back to the handbook's (Review Focus 5).
  - **People list:** inactive folded, "Ajouter une personne" as the last row.
  - **Large text and goldens:** mg at 130 % has no overflow on each page; goldens.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 9 and 10.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(admin): summaries, ruled lists, the member form and settings by section`.

### Task 6: Exports

**Files:**
- Modify: `lib/features/exports/exports_screen.dart`, `load_exports.dart`, `export_tables.dart`, ARB files, `test/features/exports/*`
- Test: golden `exports_fr.png`

- [ ] **Step 1: Write the failing tests:**
  - **Filtering:** `exportTables` with `pondIds: {E1, E3}` holds rows for E1 and E3 only; with null it holds all ponds (Review Focus 4).
  - **Screen:**
    - the kind by `ChoiceButtons`;
    - an end before the start gives a danger band and disables both actions;
    - the pinned "PDF", with "CSV" above it;
    - no `DropdownButtonFormField`, no `ChoiceChip`.
  - **Large text and golden:** mg at 130 % has no overflow; golden fr.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** Decision 11.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(exports): pond buttons, several ponds at once, the PDF pinned`.

### Task 7: On the phone

**Files:**
- Modify: `tool/design_demo.dart` (pages `transcription`, `paper`, `prep` (P1), `sync`, `account`, `admin`, `members`, `member` (Hery), `settings`, `exports`), `tool/design_screenshots.sh`

- [ ] **Step 1:** Add the pages (each seeds `seedDemoAdmin`), and run `tool/design_screenshots.sh <device> transcription paper prep sync account admin members member settings exports` with the phone unlocked. Look at every PNG in fr and mg.
- [ ] **Step 2: Commit:** `test: design screenshots of the tools and admin pages`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots shown to the user, the step marked merged in `docs/design.md`, and the local merge.
