# Design step 6: Reports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Reports tab, the report page (draft and published) and the report PDF take the design: by topic, compact, bands for alerts, the worst first, ink with colour only for ponds and urgency, "Partager" / "Publier" pinned.

**Architecture:**
- **Pure ordering:** a pure-Dart module (`lib/domain/report/report_order.dart`) decides what the screen and the PDF both show in which order: health blocks worst first, and observations split into problems, free notes and the ponds that were in order. The two renderers can't disagree.
- **Shared pieces:**
  - `WaterValues` (frozen values plus issues) under the visit's `ReadingValues`.
  - `CodedBand` (the Alerts tab's band with its pond code), extracted for reuse.
  - `pondColoursProvider` (all ponds, archived ones included).
- **Unchanged:** the report format. Pond colours come from the phone's pond records.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, `pdf` + `printing`, ARB l10n, `flutter_test` goldens, `pdftotext` (poppler) in one test.

**Spec:** `docs/design.md` (principles, §Step 6), `docs/SPEC.md` F8, `docs/DOMAIN.md` §Alert rules.

## Decisions (Claude's calls)

1. **Health order** (`orderHealth`):
   1. Ponds with signs or health events first.
   2. Then by deaths, highest first.
   3. Then by pond code.

   Within a pond: signs and events merged by date, newest first, then treatments by date, newest first.
2. **Observations** (`splitObservations`):
   - **problems:** `ok == false`, in pond code order;
   - **notes:** `ok == null`, in pond code order, farm-wide ones last;
   - **inOrder:** the codes of ponds that have any `ok == true` answer and no `ok == false` answer, sorted.
3. **Empty lines** (new keys, fr / mg drafts):

   | Key | Section | French |
   |---|---|---|
   | `reportAlertsNone` | Alerts | "Aucune alerte" |
   | `reportHealthNone` | Health | "Aucun mort, aucun signe" |
   | `reportNextNone` | Next | "Rien de prévu" |
   | `reportObservationsNone` | Observations | "Aucune observation" |

   Keep `reportNoFish`, `reportNoFeed`, `reportNoSummary`. Delete `reportNothing` if nothing uses it any more. Empty lines are `bodyMedium` in `inkMuted`.
4. **Row shapes on screen:** every pond line starts with `PondCode` in a 72 dp column (the ponds list's slot). Lines under a pond indent to 72 dp.
   - **Water:** `WaterValues` after the date, as "15/03 28 °C pH 7,2 O₂ 5 mg/L". A pond with no reading shows `reportNoReading`.
   - **Growth, line 1:** `reportGrowthLine` "{batch} {weight} ({date}), ≈ {biomass}, ≈ {fish} poissons".
   - **Growth, line 2:** "IC 1,6 ↑, survie 98 %", where ↑ (worse) is in `warning`.
   - **Health, line 1:** "500 morts (Rakoto 4, Hery 2)".
   - **Health, sign and event lines:** `Icons.error` in `danger`.
   - **Health, treatment lines:** `Icons.medication` in ink.
   - **Feed:** `Table` rows of code and kg (right-aligned, tabular), a bold total row, then the stock lines.
   - **Next:** "15/03 : échantillonnage L-E2" with the pond code.
   - **Observations:** problems with `Icons.report_problem` in `warning`, then notes with `Icons.notes`, then `Icons.check_circle` in `ok` and `reportInOrder` "Tout en ordre : {ponds}".
5. **Alerts:** `CodedBand` per alert, danger first then warning (content order is already `compareAlerts`), with no `onTap`. Farm-wide alerts have no code.
6. **Header:**
   - the site and date as `titleLarge`, as `reportHeaderTitle` "{site}, {date}";
   - `reportAuthor` / `reportAuthorGroup`, then `reportPeriod`;
   - published: `reportPublishedOn` in `bodySmall`;
   - draft: `reportDraftNote` "Brouillon : visible par vous seul jusqu'à la publication" in `bodySmall`.
7. **Draft:** the summary `TextField` sits right under the header, before the Summary heading's place, with hint `reportSummaryHint` "Ce que vous avez vu, en quelques mots". A published report shows the summary text under its heading.
8. **Pinned bars:** the published report has `FilledButton.icon(Icons.share, reportShare)`, 56 dp, and the app-bar share icon goes. The draft keeps "Publier".
9. **List:**
   - **Draft row first:** `Icons.edit`, `reportDraftRow` "À publier : {date}", chevron. No tinted card.
   - **Report row, first line:** an 8 dp ink dot when unread (space kept when read), then `reportCardTitle` "{date}, {member}", bold while unread, then a chevron.
   - **Report row, below:** `reportPeriod`; then, if any danger, `Icons.error` in `danger` and `reportDangerCount` "{count, plural, =1{1 en danger} other{{count} en danger}}" in `danger`.
   - **Rows:** at least 56 dp, separated by 1 dp `line` rules.
   - **Empty:** `reportsEmpty` becomes "Aucun rapport. Le rapport se prépare à la fin d'une visite."
10. **PDF:**
    - **Fonts:** Atkinson Hyperlegible Next Regular and Bold, with Noto Sans Regular and Noto Sans Math Symbols as fallback.
    - **Colours:** the theme's hex values (`DoboColors.standard`), converted to `PdfColor`.
    - **Pond swatch:** a 7 pt square of the pond's colour (from `pondColourValue`) before its code.
    - **Bands:** danger filled with white text; warning filled `warningFill` with a 3 pt `warning` left edge.
    - **Estimates:** "186 kg (estimé)".
    - **Footer:** "Dobo · {site} · {date} · {page}/{pages}" in 8 pt `inkMuted`.
    - **Order:** the same as the screen (Decisions 1–5).
11. **`pondColoursProvider`** = `Provider<Map<String, PondColour>>` from `PondRepository.watchAll()` (archived included). An unknown id means no swatch, code only.

## Global Constraints

- No schema, sync, server or report-format change (`ReportContent.currentFormat` stays 2).
- Every string from the ARB files, every key in both; mg drafts; regenerate `docs/mg-review.csv` with `dart run tool/mg_review.dart export`; check for an existing key before adding one. Edit ARB files line by line; never re-serialise a whole file.
- Colours from the theme (guard test); `Colors.*` only for pond tags.
- Touch targets ≥ 56 dp; no text below 14 sp on screen; long Malagasy text wraps.
- On screen an estimate starts with `≈` (`EstimatedLabel`); the PDF says *estimé*.
- `dart format` only touched files, by name; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/reports`.

## Review Focus

1. **A report from before step 5** has inspection answers with no pond id (or the free-form ones) and must still render. `splitObservations` puts `ok == true` answers without a pond into no pond's line and drops nothing else. Covered in Task 1.
2. **A pond archived or deleted since the report** shows its code without a swatch on screen and in the PDF, without throwing. Covered in Tasks 2 and 5.
3. **A long report** (40 ponds, every section full) still lays out in the PDF across pages, with the footer on each page. Covered in Task 5 (the existing 40-pond test, plus a footer check).
4. **A report published in Malagasy and read in French** shows French labels (content is frozen data, labels come from the reader's locale), as today. Covered in Task 3 (golden in mg of a report built in fr).
5. **The draft while its content loads:** "Publier" stays disabled until the summary has loaded, as today, and the summary box is not empty-then-filled under the member's thumb. Covered in Task 3.

---

### Task 1: The report's order, pure

**Files:**
- Create: `lib/domain/report/report_order.dart`
- Test: `test/domain/report/report_order_test.dart`

**Interfaces:**
- Produces:

```dart
/// Decision 1.
List<PondHealth> orderHealth(List<PondHealth> health, Map<String, String> pondCodes);

/// One health block's lines under its deaths line, in order.
sealed class HealthEntry { DateTime get at; }
final class SignsEntry extends HealthEntry { final DatedSigns signs; }
final class EventEntry extends HealthEntry { final HealthLine event; }
final class TreatmentEntry extends HealthEntry { final TreatmentLine treatment; }
List<HealthEntry> healthEntries(PondHealth h);

/// Decision 2.
({List<ReportObservation> problems, List<ReportObservation> notes, List<String> inOrder})
    splitObservations(List<ReportObservation> observations, Map<String, String> pondCodes);
```

- [ ] **Step 1: Write the failing tests:**
  - `orderHealth`: E5 (deaths 500, no signs), E2 (deaths 1, one sign) and E1 (deaths 20) give `[E2, E5, E1]`. Equal deaths and no signs go in code order.
  - `healthEntries`: a sign on 14/03, an event on 13/03 and a treatment on 15/03 give `[SignsEntry 14/03, EventEntry 13/03, TreatmentEntry 15/03]`.
  - `splitObservations`:
    - E3 has five `ok: true` answers; E1 has four `ok: true` and a dike `ok: false`; there is one note on E2 and a farm-wide note.
    - This gives problems `[E1 dike]`, notes `[E2 note, farm-wide]` and `inOrder ['E3']`.
    - An `ok: true` answer with `pondId == null` (an old report) appears nowhere and throws nothing.
- [ ] **Step 2: Run** `flutter test test/domain/report/report_order_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** in pure Dart (no Flutter imports).
- [ ] **Step 4: Run** the test, then the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(reports): health worst first and observations split, for screen and PDF`.

### Task 2: Shared pieces: water values, coded band, pond colours

**Files:**
- Create: `lib/features/common/coded_band.dart`
- Modify:
  - `lib/features/readings/reading_values.dart` (`WaterValues`; `ReadingValues` builds on it)
  - `lib/features/alerts/alerts_screen.dart` (uses `CodedBand`)
  - `lib/features/ponds/pond_overview.dart` (`pondColoursProvider`)
- Test: `test/features/common/coded_band_test.dart`, `test/features/ponds/pond_overview_test.dart`

**Interfaces:**
- Produces:

```dart
/// Values with their issues already known (a report's frozen reading).
class WaterValues extends StatelessWidget {
  const WaterValues({double? temperatureC, double? ph, double? oxygenMgL, WaterColour? colour,
      Map<WaterParam, Severity> issues = const {}, Widget? leading});
}
/// An AttentionBand with the pond's code in the 72 dp slot (key 'codeSlot'); no slot when [code] is null.
class CodedBand extends StatelessWidget {
  const CodedBand({required BandSeverity severity, required String text, String? code, PondColour? colour, VoidCallback? onTap});
}
final pondColoursProvider = Provider<Map<String, PondColour>>(...);
```

- [ ] **Step 1: Write the failing tests:**
  - **`CodedBand` code:** with code E2 and a colour, it shows `PondCode` inside a 72 dp `codeSlot`.
  - **`CodedBand` without a colour:** the code shows with no swatch.
  - **`CodedBand` without a code:** no slot.
  - **`pondColoursProvider`:** it includes an archived pond.
  - **Existing tests:** the alerts tab and pond page tests pass unchanged.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - If `PondCode` has no way to show a code without a swatch, give it an optional colour (`PondColour? colour`), with no swatch when it's null.
  - The Alerts tab replaces its inline band-with-slot by `CodedBand`. Its goldens must not change.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. The alerts goldens are unchanged. Expected: PASS.
- [ ] **Step 5: Commit:** `refactor: water values, the coded band and pond colours, shared`.

### Task 3: The report page

**Files:**
- Modify: `lib/features/reports/report_sections.dart` (rewrite), `lib/features/reports/report_screen.dart`, `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`, `test/features/reports/report_screen_test.dart`
- Test: `test/features/reports/report_design_test.dart`, goldens `report_fr_top.png`, `report_fr_bottom.png`, `report_mg_top.png`, `report_draft_fr.png`

**Interfaces:**
- Consumes: Task 1's functions; Task 2's `WaterValues`, `CodedBand`, `pondColoursProvider`; `EstimatedLabel`, `PondCode`.
- Produces: ARB keys from Decisions 3, 6, 7 and 4 (`reportInOrder`, `reportHeaderTitle`, `reportDraftNote`, `reportSummaryHint`). `reportGrowthLine` gets new text, and `reportDeathsBy` "{deaths} ({observers})" is added.

- [ ] **Step 1: Write the failing tests.** Use the demo farm with the clock at `demoNow`. A visit started and ended at `demoNow`, with E1's water read and its inspection all OK, and a dike problem on E3. Open its draft, then publish it.
  - **Order:** headings in F8 order: Résumé, Alertes, Santé, Eau, Croissance, Aliment, À venir, Observations.
  - **Alerts:** `CodedBand`s, danger before warning, with no chevron. Tapping one stays on the report.
  - **Health:** E4 (isolated, with an event) comes before E5 (500 deaths). E4's event line has `Icons.error`.
  - **Water:** E2's line shows "O₂ 2 mg/L" with `Icons.error`, all on one line under E2's code.
  - **Growth:** "≈" appears before the biomass and the fish count; the word "estimé" appears nowhere on the screen.
  - **Feed:** a total row.
  - **Observations:**
    - the E3 problem comes before the "Tout en ordre : E1" line;
    - E3 is not in that line.
  - **Empty sections:** on a farm with no fish, the empty lines `reportHealthNone` and `reportAlertsNone`.
  - **Published:** "Partager" is in `bottomNavigationBar`, and the app bar has no share icon.
  - **Draft:**
    - "Brouillon : visible par vous seul…" shows under the header;
    - the summary `TextField` with its hint sits above the "Alertes" heading;
    - "Publier" is pinned and stays disabled until the summary has loaded (existing test kept).
  - **Archived pond:** a report naming a pond archived since shows its code with no swatch.
  - **Large text:** in mg at 130 %, the published report and the draft don't overflow.
  - **Goldens:** the published report in fr (top and scrolled to the bottom) and mg (top); the draft in fr. All at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/reports/`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 3–8 and the ARB keys. Remove keys that are now unused. Regenerate l10n and the review sheet.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`, and look at the goldens. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(reports): the report by topic, compact, alerts as bands, Partager pinned`.

### Task 4: The Reports list

**Files:**
- Modify: `lib/features/reports/reports_screen.dart`, ARB files, `docs/mg-review.csv`, `test/features/reports/report_screen_test.dart` (list tests)
- Test: `test/features/reports/reports_list_design_test.dart`, goldens `reports_fr.png`, `reports_mg.png`

**Interfaces:**
- Produces: ARB keys `reportDraftRow` and `reportDangerCount`, plus new text for `reportCardTitle` and `reportsEmpty` (Decision 9).

- [ ] **Step 1: Write the failing tests:**
  - **Rows:** a draft and two published reports (one unread with 2 dangers, one read with none) give the draft row first, with a pencil.
  - **Unread row:** a dot and bold title, then "! 2 en danger" with `Icons.error`.
  - **Read row:** no danger line, and no `Chip` and no `Card` anywhere on the screen.
  - **Taps:** a row opens its report.
  - **Empty:** the new `reportsEmpty` text.
  - **Large text:** mg at 130 % doesn't overflow.
  - **Goldens:** fr and mg at 360 × 780.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** Decision 9.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(reports): the list in ink, unread dot, dangers in words`.

### Task 5: The report PDF

**Files:**
- Modify:
  - `lib/features/reports/report_pdf.dart` (rewrite of the layout)
  - `lib/features/reports/share_report.dart` (Atkinson fonts and pond colours)
  - `lib/features/common/pdf_theme.dart` (`pdfTheme` accepts a fallback list)
  - `test/features/reports/report_pdf_test.dart`

**Interfaces:**
- Consumes: Task 1; `pondColoursProvider` (Task 2); `pondColourValue` (`pond_colour.dart`); `DoboColors.standard`.
- Produces:

```dart
Future<Uint8List> buildReportPdf(ReportContent content, AppLocalizations l10n, Locale locale, {
  Future<Uint8List?> Function(String photoKey)? photoBytes,
  required pw.Font regular, required pw.Font bold, List<pw.Font> fallback = const [],
  Map<String, PondColour> pondColours = const {},
});
pw.ThemeData pdfTheme({required pw.Font regular, required pw.Font bold, List<pw.Font> fallback = const []});
```

- [ ] **Step 1: Write the failing tests.** Where `pdftotext` is missing, these tests are skipped with a reason.
  - **Text order:** for the full report, the text (`pdftotext -layout`) has the headings in F8 order. The health pond with signs comes before the one with more deaths. "(estimé)" follows the biomass.
  - **Footer:** each page's text ends with "Dobo · Ambohidratrimo · 20/03/2026 · n/N"; the 40-pond report has N > 1.
  - **Fonts:** the PDF bytes contain `AtkinsonHyperlegibleNext`.
  - **Missing colour:** a pond with no colour builds with no error.
  - **Paper sheets and exports** still build (their existing tests pass with the new `pdfTheme` signature).
- [ ] **Step 2: Run** `flutter test test/features/reports/report_pdf_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Decision 10. `shareReport` loads Atkinson Regular and Bold (`assets/fonts/AtkinsonHyperlegibleNext-*.ttf`), plus Noto Regular and Symbols as fallback, and reads `pondColoursProvider`.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Render page 1 (`pdftoppm -png -r 80`) into the scratchpad and look at it. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(reports): the PDF takes the app's look`.

### Task 6: Reports on the phone

**Files:**
- Modify: `tool/design_demo.dart` (`DEMO_PAGE=reports` opens `/reports` with one published report and one draft; `DEMO_PAGE=report` opens the published report), `tool/design_screenshots.sh` (page names)

- [ ] **Step 1:** Add the pages. Seed them as Task 3's test does, with `startedAt` and `endedAt` at `demoNow`, publishing through `ReportRepository.publish` with the draft's content. Run `tool/design_screenshots.sh MNSO6HW8WOQOPB9T reports report` with the phone unlocked. Look at the PNGs.
- [ ] **Step 2: Commit:** `test: design screenshots of the reports`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots and a rendered PDF page shown to the user, and the merge.
