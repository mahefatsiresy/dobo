# M8: Paper and Exports Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The last v1 milestone:
- **F13 paper sheets:** blank weekly sheets for workers, printed or shared as PDF, that copy into the transcription grid cell by cell.
- **F15 exports:** the handbook's Annex A production register and Annex B weekly sheet, as PDF and CSV, for any date range and pond.
- **Malagasy:** every string gets a Malagasy draft, plus a review sheet a native speaker can correct in a spreadsheet and feed back into the app.
- **Field test:** a written protocol for trying the worker screens and the paper sheet with the worker.

**Architecture:**
- **Rows are domain, layout is feature.** `lib/domain/exports/register.dart` and `weekly.dart` turn facts into typed rows: pure Dart, tested first, no strings. `lib/features/exports/` formats those rows into PDF and CSV in the phone's language.
- **The paper sheet has no data.** `lib/features/paper/paper_sheet_pdf.dart` draws empty pages from the pond list, the week and the pictogram outlines.
- **One set of pictograms on screen and paper.** The `pdf` package can't read Flutter's icon font (CFF, `OTTO`). So a dev script extracts the outlines of the same Material glyphs the screens use into `lib/features/common/pictogram_paths.dart` as SVG path data, and the PDF draws them with `pw.SvgImage`. When the worker's own artwork arrives after the field test, both places change together.
- **Printing** goes through the `printing` package (Android print service). Sharing reuses M6's `sharePdfFile`.
- **Malagasy** completeness is enforced by a test. `tool/mg_review.dart` round-trips `docs/mg-review.csv` against `lib/l10n/app_mg.arb`.

**Tech Stack:** Flutter 3.47.8, Drift 2.35, flutter_riverpod 3 (no codegen), go_router 18, ARB l10n, `pdf` 3.13, `share_plus`. New: `printing` (app). Dev only: Python `fonttools` in a throwaway venv, used once to generate the pictogram paths.

**Spec:** `CLAUDE.md`; `docs/SPEC.md` (F3, F4, F13, F15, §6 navigation, §9 language, §11 M8); `docs/DOMAIN.md` (§Water quality thresholds, §Sampling, §Formulas live count); handbook Annexes A and B (`Dossier_Elevage_Tilapia_Etangs.docx`):
- Annex A columns: Date | Étang / Lot | Provenance alevins | Quantité aliment (kg) | Mortalité (nb) | Ventes (kg) | Observations, with "une ligne par intervention (alimentation, mouvement de stock, vente)".
- Annex B columns: Date | Temp. (°C) | pH | Oxygène (mg/L) | Aliment distribué (kg) | Mortalité (nb) | Poids moyen échantillon (g), "étang par étang, sur une base hebdomadaire".

The decisions below are Claude's calls, made without the user. They can be revisited.

## Decisions (Claude's calls)

1. **Malagasy for every screen.**
   - SPEC §9 lets any user switch to Malagasy, so all of `app_fr.arb` (646 keys, 566 with no Malagasy yet) gets a Malagasy draft. This is Claude's best effort.
   - Member screens still default to French.
   - The drafts stay marked unreviewed (`@@x-review`) until the review sheet says otherwise.
   - Review is done in `docs/mg-review.csv`, with columns `key;description;fr;mg;ok`, opened in LibreOffice or Google Sheets. The reviewer edits `mg` and writes `ok`. `dart run tool/mg_review.dart import` writes the `mg` column into `app_mg.arb`. `export` regenerates the sheet, keeps the `ok` marks, and clears a mark when the French text changed since.
2. **Paper sheet layout: one A4 landscape page per pond per week.**
   - **Page header:** the pond code, large, on its colour; the week ("Herinandro / Semaine du 09/11/2026 au 15/11/2026"); a line "Mpiasa / Ouvrier : ________".
   - **Rows:** the 7 days, Monday to Sunday, each labelled with the Malagasy weekday, the French short weekday and dd/mm.
   - **Columns, left to right, as on the daily log screen (F3):**
     - a feed box "Sakafo / Aliment (kg)";
     - a deaths box "Maty / Morts";
     - 3 leftover pictograms;
     - the 13 warning-sign pictograms;
     - the 5 water-colour swatches.

     Each pictogram column has a box to tick on every row.
   - **Footer:** a numbered legend of the pictograms with their Malagasy and French labels.
   - **Mirrors the transcription grid:** a member copies page E1 into column E1, day by day. The grid's tap-through sheet takes everything the page has (Decision 4).
3. **Options when printing.**
   - The first week defaults to the current week, with previous/next arrows as in transcription.
   - Week count: 1, 2 or 4 weeks (default 1). Several weeks print in the order week 1 ponds, then week 2 ponds.
   - Ponds: the active ponds, all ticked by default, in the transcription order (`pondsProvider`).
4. **Transcription takes leftover and water colour.**
   - The cell's signs sheet gains the leftover picker and the water-colour swatches (existing widgets).
   - The cell's icon shows filled when any of signs, leftover or colour is set.
   - Both go into `DailyLogInput.leftover` and `waterColour`. Nothing else on the transcription screen changes.
5. **Paper sheets are bilingual, exports are not.**
   - Workers read Malagasy and members transcribe in French, so every paper label prints "mg / fr", from `lookupAppLocalizations` of both locales.
   - The Annex A/B PDFs and CSVs use the phone's language, like the traceability sheet.
6. **Pictograms on paper are the screen's glyphs.**
   - `tool/pictogram_paths.py` reads Flutter's `MaterialIcons-Regular.otf` and the codepoints in Flutter's `icons.dart`, for the icons `pictograms.dart` uses. It writes one 24×24 SVG path string per `WarningSign` and `Leftover` into `lib/features/common/pictogram_paths.dart`, a generated file that is committed. Material Icons are Apache 2.0; the generated file says so.
   - Water colours print as filled squares in `waterColourValue`, with the label number beneath for black-and-white printers.
   - Pond colours print through `pondColourValue`. The code is always printed too, so a grey printout still works.
7. **Annex A, the production register: one row per record.**

   | Row | Étang / Lot | Provenance | Aliment | Mortalité | Ventes | Observations |
   |---|---|---|---|---|---|---|
   | daily log (counted only) | pond / batch codes in the pond at the end of that day | | feed kg | deaths (blank when 0) | | signs, water colour, note |
   | stocking | pond / batch | batch hatchery, certificate | | | | "Mise en charge : 1 000 × 20 g" |
   | transfer | "E1 → E2" / batch | | | | | "Transfert : 400 × 85 g" |
   | harvest | pond / batch | | | | | "Récolte finale : 950 poissons, 240 kg" |
   | sale | pond of its harvest / batch | | | | kg | customer, form |
   | treatment | pond / batch if any | | | | | product, dose, advised by |
   | health event | pond | | | | | suspected issue, signs, actions |

   - Rows are sorted by farm date, then by kind in the table's order, then by pond code.
   - The range covers farm days from–to, both included.
   - The pond filter keeps rows whose pond is that pond. A transfer counts for both its ponds.
   - Ponds are named from all ponds, archived ones included, so old records keep their codes.
8. **Annex B, the weekly sheet: one row per pond per week.**
   - The range snaps to whole weeks, from the Monday on or before `from` to the Sunday on or after `to`. The PDF header shows the snapped dates.
   - Temperature, pH and oxygen each come from the latest reading in the week that has that value.
   - Feed and deaths are the sums of the week's counted logs.
   - The average weight is each batch's latest sample in the week in that pond, as "45 g" for one batch or "L1 : 45 g ; L2 : 120 g" for several. The CSV writes a single batch's weight as a bare number.
   - A pond appears when it held fish on any day of the range or has any log, reading or sample in it. Its weeks with nothing recorded stay as blank rows, so a missed water check shows.
   - The footer reminds the targets from `DomainConfig`: oxygen at least 3 mg/L, not the handbook's 0.8 (DOMAIN §Water quality).
9. **CSV for a French spreadsheet:**
   - UTF-8 with a BOM, `;` separator, CRLF line ends;
   - decimal comma, no thousands separator (`formatForInput`), dates `dd/mm/yyyy`;
   - headers in the phone's language;
   - fields with `;`, `"`, CR or LF are quoted, with `"` doubled.
10. **Export screen defaults.**
    - The register covers the last 30 farm days to today. The weekly sheet covers the last 8 weeks.
    - Pond: all.
    - A "to" date before the "from" date disables both buttons and shows "La date de fin est avant la date de début."
    - An export with no rows still builds: the PDF says "Rien à signaler" and the CSV has only its header.
11. **File names** (ASCII, safe on any file system, through the existing slug rule):
    - `registre-<site>-<from>-<to>.pdf|csv`;
    - `suivi-hebdo-<site>-<from>-<to>.pdf|csv`;
    - `fiches-<first monday>.pdf`.
12. **Navigation.**
    - More gets "Fiches papier" (`/more/paper`) and "Exports" (`/more/exports`), for every member, after Transcription.
    - Workers never see them (SPEC §6).
13. **The field test is the user's.**
    - `docs/field-test.md` is the protocol: what to ask the worker to do, what to time against the paper sheet, what to note per pictogram, and how to swap a pictogram afterwards.
    - Claude draws no artwork.

## Global Constraints

- Offline first: every M8 screen, PDF, CSV and print works in airplane mode. Nothing in M8 needs the network. No schema change (`schemaVersion` stays 6).
- `lib/domain/` imports neither Flutter nor Drift (`test/domain/purity_test.dart`). M8 adds no farming number: thresholds on paper come from `DomainConfig`.
- Weights are integer grams, shown in kg with a decimal comma. Dates are farm dates via `farmDate`, `daysBetween` and `farmDateToUtc`, displayed `dd/mm/yyyy`. Weeks are built from day numbers (`weekOf`), never by adding 24 h.
- Every string comes from the ARB files, with every key in both `app_fr.arb` and `app_mg.arb` (enforced from Task 7 on). Touch targets ≥ 56 dp. Every pushed screen has a working Back.
- Estimated values say "estimé" wherever they appear. The exports show only recorded values (feed, deaths, readings, samples, sales), so nothing in them is estimated.
- No money anywhere (CLAUDE.md §6).
- At the end of each task: `flutter analyze` has no issues, and `flutter test` and `TZ=UTC flutter test` pass.
- Commits use a conventional prefix and end with the `Co-Authored-By` line. Branch: `feat/m8-paper-exports` from `main`.

## Review Focus

1. **Two logs for one pond-day** (worker phone and transcription before a member resolves it): the register shows one row and the weekly sums count it once (`countedLogs`). Tests in Task 4.
2. **A year of records:** the register PDF for 365 days × 6 ponds spans many pages with the header repeated on each, builds without a timeout, and the CSV has every row. Tests in Task 5.
3. **A batch moved mid-week:** both ponds' weekly rows carry their share, the transfer row appears under either pond's filter, and the log rows name the batch in the right pond on each side of the move. Tests in Task 4.
4. **A note, customer name or Malagasy text with `;`, quotes, a line break or accents:** the CSV quotes it and stays one record; the PDF prints the accents with Noto Sans. Tests in Task 5.
5. **A Malagasy draft that drops a placeholder** (`{count}`, `{date}`): the completeness test fails before it ships. Test in Task 7.

---

### Task 1: Pictogram outlines for paper

**Files:**
- Create:
  - `tool/pictogram_paths.py`: the generator. Its docstring gives how to run it (`python3 -m venv <dir> && <dir>/bin/pip install fonttools`, then `<dir>/bin/python -I tool/pictogram_paths.py`);
  - `lib/features/common/pictogram_paths.dart` (generated, committed).
- Test: `test/features/common/pictogram_paths_test.dart`.

**Interfaces:**
- Produces:
  - `String warningSignPath(WarningSign s)` and `String leftoverPath(Leftover l)`: SVG path data in a 24×24 box, y down;
  - `String pictogramSvg(String path, {String fill = '#000000'})`: `<svg xmlns=… viewBox="0 0 24 24"><path d="…" fill="…"/></svg>`.
- The script maps each enum value to the icon name used in `lib/features/common/pictograms.dart` (that file stays the source of which icon). It finds the codepoint in `$FLUTTER_ROOT/packages/flutter/lib/src/material/icons.dart` and the glyph through the font's `cmap`. It draws with `SVGPathPen` through a `TransformPen` of scale `24 / unitsPerEm`, y flipped against the ascender. It writes Dart with a header naming the font, its licence and the regeneration command.

- [ ] **Step 1: Write the failing test.**
  - `every sign and leftover has a path`: for each value, the path is non-empty and starts with `M`.
  - `the outlines fit the 24 box`: every number in the path is within -1…25.
  - `pictogramSvg builds a pdf image`: `pw.SvgImage(svg: pictogramSvg(warningSignPath(WarningSign.whiteSpots)))` lays out in a one-page `pw.Document` that saves to bytes starting `%PDF`.
- [ ] **Step 2: Run it to see it fail.** `flutter test test/features/common/pictogram_paths_test.dart`. Expected: FAIL, file missing.
- [ ] **Step 3: Implement.** Write and run the script. If a glyph's codepoint isn't found, the script stops with the icon name and doesn't write a partial file.
- [ ] **Step 4: Run it to see it pass.** Also eyeball one page: write a scratch PDF of all 16 pictograms to the scratchpad and render it with `pdftoppm` (or open it) to confirm the outlines aren't upside down.
- [ ] **Step 5: Commit.** `feat(paper): pictogram outlines from the screen icons, for PDFs`

### Task 2: The paper sheet PDF

**Files:**
- Create: `lib/features/paper/paper_sheet_pdf.dart`.
- Modify:
  - `lib/l10n/app_fr.arb` and `app_mg.arb`: `paperTitle`, `paperWeek(from, to)`, `paperWorker`, `paperFeedKg`, `paperDeaths`, `paperLeftover`, `paperSigns`, `paperWater`, `paperLegend`, `weekdayMon` … `weekdaySun` (mg full names, fr short), `paperFileWeek`;
  - `lib/features/reports/share_report.dart`: nothing; reuse `pdfFonts()`.
- Test: `test/features/paper/paper_sheet_pdf_test.dart`.

**Interfaces:**
- Consumes: `warningSignPath`, `leftoverPath`, `pictogramSvg` (Task 1); `weekOf` (`lib/features/transcription/week.dart`); `pondColourValue`, `waterColourValue`; `lookupAppLocalizations`.
- Produces:
  - `class PaperPond { const PaperPond({required String code, required PondColour colour}); }`;
  - `Future<Uint8List> buildPaperSheetPdf({required List<PaperPond> ponds, required DateTime firstWeek, int weeks = 1, required pw.Font regular, required pw.Font bold})`: `firstWeek` is any farm day in the first week; one page per pond per week, in week-then-pond order;
  - `List<String> paperSheetLabels(AppLocalizations mg, AppLocalizations fr)`: every printed label as "mg / fr", for the test to check, and used by the builder;
  - `String paperFileName(DateTime firstWeek)` → `fiches-<yyyy-mm-dd of that Monday>.pdf`.
- Layout: A4 landscape, 24 pt margins, fixed `pw.Table` with 7 day rows of ≥ 44 pt. The column widths of Decision 2 fit 794 pt; tune within it. A light grid. Tick boxes 14 pt. The pond badge cell is filled with the pond colour, with black or white text by luminance, like `PondBadge`.

- [ ] **Step 1: Write the failing tests.**
  - `three ponds over two weeks make six pages`: count `/Type /Page` objects (not `/Pages`) in the saved bytes, or `doc.document.pdfPageList.pages.length` before saving. Expected 6.
  - `the labels are bilingual`: `paperSheetLabels(mg, fr)` contains `'Maty / Morts'`-shaped entries for feed, deaths, leftover, signs and water, plus the 13 sign labels as `"${mg.signX} / ${fr.signX}"`.
  - `the week runs Monday to Sunday`: for a Wednesday `firstWeek` of 11/11/2026, the header label is `paperWeek('09/11/2026', '15/11/2026')`; for `weeks: 2` across a month end (30/11/2026), the second week starts 07/12/2026.
  - `no ponds builds one page saying there are no ponds`: one page, no throw.
  - `paperFileName is fiches-2026-11-09.pdf` for any day of that week.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/paper`
- [ ] **Step 3: Implement.** Fonts in tests come from `assets/fonts/` via `File`, as in `trace_pdf_test.dart`.
- [ ] **Step 4: Run them to see them pass.** Render one page to PNG in the scratchpad (`pdftoppm -r 60`) and look at it. Every column fits, the legend fits on the page, and the pictograms read.
- [ ] **Step 5: Commit.** `feat(paper): weekly worker sheet as a bilingual PDF`

### Task 3: Paper sheet screen, printing, and transcription that takes everything on the sheet

**Files:**
- Create: `lib/features/paper/paper_sheet_screen.dart`, `lib/features/paper/print_pdf.dart`.
- Modify:
  - `pubspec.yaml`: add `printing` (latest stable);
  - `lib/router.dart`: `/more/paper`;
  - `lib/features/more/more_screen.dart`: "Fiches papier" after Transcription;
  - `lib/features/transcription/transcription_screen.dart`: `_Cell` gains `Leftover? leftover` and `WaterColour? waterColour`; `_pickSigns` sheet shows `LeftoverPicker`, `SignGrid` and `ColourSwatches`; `isEmpty` and `clear` cover both; the save passes them;
  - ARB: `morePaper`, `paperWeeks` (1, 2 or 4), `paperPrint`, `paperShare`, `paperNoPonds`, `transcriptionCellDetails` (the sheet title).
- Test: `test/features/paper/paper_sheet_screen_test.dart`, `test/features/transcription/transcription_screen_test.dart` (create it if the existing transcription tests live elsewhere; check `grep -rl TranscriptionScreen test` first and extend that file).

**Interfaces:**
- Consumes: `buildPaperSheetPdf`, `paperFileName` (Task 2); `pdfFonts`, `sharePdfFile` (`share_report.dart`); `pondsProvider`; `weekOf`.
- Produces:
  - `typedef PdfPrinter = Future<void> Function(String name, Uint8List bytes);`
  - `final pdfPrinterProvider = Provider<PdfPrinter>(...)`: by default `Printing.layoutPdf(name: name, onLayout: (_) async => bytes)`. Tests override it, as `reportSharerProvider` is overridden.
- Screen:
  - the week row (arrows and "Semaine du …", as in transcription);
  - the week-count choice (1, 2, 4) as `ChoiceChip`s ≥ 56 dp;
  - one `FilterChip` per active pond showing its `PondBadge`, all selected at first;
  - two full-width 56 dp buttons, "Imprimer" and "Partager le PDF", disabled while no pond is selected or while building. Building uses `SaveOnce` so a double tap builds once.

- [ ] **Step 1: Write the failing tests.**
  - `printing sends the chosen ponds and weeks`: with ponds E1, E2, E3, untick E2, pick 2 weeks, tap Imprimer. The fake printer gets one call with a name `fiches-<monday>.pdf` and bytes starting `%PDF`. Assert the page count is 4.
  - `share writes the file and opens the share sheet`: the fake sharer gets `fiches-<monday>.pdf`.
  - `no pond ticked disables both buttons`.
  - `the More tab lists Fiches papier for a member` (not for the worker home: the worker has no More).
  - Transcription: `a cell's leftover and water colour are saved`: fill E1 Monday with 5 kg, open the cell sheet, pick "Misy sisa kely"/`some` and `darkGreen`, save. The repository has a log with `leftover == Leftover.some` and `waterColour == WaterColour.darkGreen`. `a cell with only a colour still asks for feed`: the feed-missing notice shows.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/paper test/features/transcription`
- [ ] **Step 3: Implement.** `flutter pub add printing`. Check that `flutter build apk --debug` still builds (the plugin's Android side compiles with `minSdk` 26).
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(paper): print or share worker sheets; transcription takes leftover and water colour`

### Task 4: Register and weekly rows (domain)

**Files:**
- Create: `lib/domain/exports/register.dart`, `lib/domain/exports/weekly.dart`.
- Modify: `lib/domain/farm_facts.dart`: `LogFact` gains `String? note`; `lib/db/repositories/facts_repository.dart` fills it.
- Test: `test/domain/exports/register_test.dart`, `test/domain/exports/weekly_test.dart`.

**Interfaces:**
- Consumes: `FarmFacts`, `countedLogs`, `placementsOf(f, until:)`, `ReadingInfo` (`alerts/farm_alerts.dart`), `HealthLine`, `TreatmentLine` (`report/report_content.dart`), `farmDate`, `farmDayNumber`, `daysBetween`.
- Produces (`register.dart`):
  - `class SaleFact { const SaleFact({required DateTime date, required String batchId, required String pondId, required int weightG, required String customerId, required ProductForm form}); }`: `pondId` is its harvest's pond;
  - `sealed class RegisterRow { DateTime get date; String get pondId; List<String> get batchIds; }` with:
    - `LogRow(LogFact log, batchIds)`;
    - `StockingRow(StockingFact s)`;
    - `TransferRow(TransferFact t)`: `pondId` is `fromPondId`, plus `toPondId`;
    - `HarvestRow(HarvestFact h)`;
    - `SaleRow(SaleFact s)`;
    - `TreatmentRow(String pondId, TreatmentLine t)`;
    - `HealthRow(String pondId, HealthLine h)`;
  - `List<RegisterRow> productionRegister({required FarmFacts facts, List<SaleFact> sales = const [], List<(String, TreatmentLine)> treatments = const [], List<(String, HealthLine)> health = const [], required DateTime from, required DateTime to, String? pondId})`: sorted per Decision 7. Sorting by pond code is the formatter's job; the domain sorts by date, then by kind, then by `pondId`.
- Produces (`weekly.dart`):
  - `class WeeklyRow { final String pondId; final DateTime weekStart; final double? temperatureC, ph, oxygenMgL; final int feedG; final int deaths; final Map<String, double> avgWeightGByBatch; bool get isEmpty; }`;
  - `(DateTime from, DateTime to) wholeWeeks(DateTime from, DateTime to)`;
  - `List<WeeklyRow> weeklySheet({required FarmFacts facts, List<(String, ReadingInfo)> readings = const [], required DateTime from, required DateTime to, required List<String> pondIds})`: `pondIds` is the order and the filter (one id for a pond filter). Rows come pond by pond, weeks oldest first.

- [ ] **Step 1: Write the failing tests.** Dates as farm days in 2026.
  - register:
    - `logs, stocking, transfer, harvest and sale come out in date then kind order`;
    - `two logs for one pond-day make one row, the newer`;
    - `a log names the batches in its pond at the end of that day`: a batch stocked in E1 on the 1st and transferred to E2 on the 5th; a log in E1 on the 4th names it, a log in E1 on the 6th doesn't, a log in E2 on the 6th does;
    - `the pond filter keeps a transfer for both its ponds`;
    - `from and to are both included, by farm day`: a log at 23:30 Antananarivo on the `to` day is in; one at 00:30 the next day is out. Run under `TZ=UTC` too;
    - `a treatment with no batch and a health event are rows of their pond`;
    - `nothing in range is an empty list`.
  - weekly:
    - `wholeWeeks snaps Wednesday–Tuesday to Monday–Sunday`;
    - `each parameter is the latest of the week that has it`: a Monday reading with pH 7 and oxygen 5, and a Thursday reading with oxygen 2 and no pH, give pH 7 and oxygen 2;
    - `feed and deaths sum the counted logs`: a duplicated pond-day counts once;
    - `a batch's latest sample in the week is its weight; two batches give two entries`;
    - `a pond that held fish with no records shows blank weeks`;
    - `a pond with no fish and no records is left out`;
    - `a batch moved mid-week`: E1 gets the logs and samples before the move, E2 after;
    - `zero fish, zero feed`: a pond holding fish but with no logs has `feedG == 0` and `deaths == 0`, and `isEmpty` is true when there's also no reading or sample.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/domain/exports`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass,** plus `TZ=UTC flutter test test/domain` and `test/domain/purity_test.dart`.
- [ ] **Step 5: Commit.** `feat(domain): production register and weekly sheet rows (Annex A, B)`

### Task 5: Register and weekly sheet as PDF and CSV

**Files:**
- Create:
  - `lib/features/exports/csv.dart`: pure Dart, no Flutter import, so `tool/` can use it;
  - `lib/features/exports/export_tables.dart`: rows → header and cell strings in a language;
  - `lib/features/exports/export_pdf.dart`;
  - `lib/features/exports/load_exports.dart`: loads everything from providers and repositories.
- Modify:
  - `lib/db/repositories/reading_repository.dart`: `Stream<List<WaterReading>> watchWaterReadingsBetween(DateTime from, DateTime to)` (farm dates, both included, current rows, `currentEvents` order);
  - ARB: the Annex A and B column headers in the handbook's French, the observation phrases of Decision 7, `exportRegisterTitle`, `exportWeeklyTitle`, `exportPeriod(from, to)`, `exportThresholds(...)`, `exportNothing` (reuse `reportNothing` if it reads right).
- Test: `test/features/exports/csv_test.dart`, `export_tables_test.dart`, `export_pdf_test.dart`; `test/db/reading_repository_test.dart` (extend).

**Interfaces:**
- Consumes: Task 4's rows; `formatDate`, `formatForInput`, `formatKg`, labels in `lib/l10n/labels.dart`; `pdfFonts`; the slug rule in `traceFileName` (extract it to `String fileSlug(String text, String fallback)` in `lib/features/reports/share_report.dart` and use it in the three file-name functions).
- Produces:
  - `String encodeCsv(List<List<String>> rows)`: BOM, `;`, CRLF, quoting per Decision 9;
  - `List<List<String>> decodeCsv(String text)`: reads what `encodeCsv` writes and what LibreOffice saves (`;`, optional BOM, LF or CRLF, quoted fields with newlines);
  - `class ExportTable { final String title; final String period; final List<String> header; final List<List<String>> rows; final String? footer; }`;
  - `class ExportNames { final Map<String, String> ponds; final Map<String, String> batches; final Map<String, BatchOrigin> origins; final Map<String, String> customers; }` with `BatchOrigin(hatchery, certificateNo)`;
  - `ExportTable registerTable(List<RegisterRow> rows, ExportNames names, AppLocalizations l10n, Locale locale, {required DateTime from, required DateTime to})`: sorts same-day same-kind rows by pond code;
  - `ExportTable weeklyTable(List<WeeklyRow> rows, ExportNames names, DomainConfig config, AppLocalizations l10n, Locale locale, {required DateTime from, required DateTime to})`: the pond code is the first column;
  - `List<List<String>> csvRows(ExportTable t)`: header and rows only (no title, so it opens as a plain table);
  - `Future<Uint8List> buildExportPdf(ExportTable t, {required pw.Font regular, required pw.Font bold})`: A4 landscape `MultiPage`, title and period on page 1, `pw.TableHelper.fromTextArray` (or a `pw.Table` with a repeated header row) so the header repeats on every page, footer and page numbers;
  - `String exportFileName(String kind, String site, DateTime from, DateTime to, String ext)`, where `kind` is `registre` or `suivi-hebdo`;
  - `Future<(List<RegisterRow>, ExportNames)> loadRegister(WidgetRef ref, {from, to, pondId})` and `Future<(List<WeeklyRow>, ExportNames)> loadWeekly(WidgetRef ref, {from, to, pondId})`.

- [ ] **Step 1: Write the failing tests.**
  - csv:
    - `a field with ; " CR or LF is quoted with doubled quotes`;
    - `the file starts with a BOM and ends lines with CRLF`;
    - `decodeCsv reads back encodeCsv` for rows with `é`, `;`, `"`, `\n` and an empty field;
    - `decodeCsv reads LF files without a BOM`.
  - export tables (French):
    - `a log row reads 12/03/2026 | E1 / L26-01 | | 12,5 | 3 | | Nage en surface, eau vert foncé, <note>`, with the sign and colour labels from l10n;
    - `a stocking row carries the hatchery and certificate`;
    - `a sale row has its kg under Ventes and the customer and form under Observations`;
    - `zero deaths print blank`;
    - `weekly rows print 26,5 / 7,2 / 4 and 'L1 : 45 g ; L2 : 120 g' for two batches`;
    - `the weekly footer says oxygène ≥ 3 mg/L from the config`;
    - `an empty register has one row saying Rien à signaler in the PDF table and none in csvRows`.
  - pdf:
    - `a year of register rows builds several pages`: 365 × 6 log rows, the PDF saves, more than 20 pages, within the default test timeout;
    - `both tables build as PDF` (bytes start `%PDF`);
    - `file names`: `exportFileName('registre', 'Ferme Soa', 01/10/2026, 31/10/2026, 'csv') == 'registre-Ferme-Soa-2026-10-01-2026-10-31.csv'`.
  - repository: `watchWaterReadingsBetween keeps both ends and leaves out superseded and deleted readings`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/exports test/db/reading_repository_test.dart`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.** Render page 1 of the register to PNG in the scratchpad and look at it.
- [ ] **Step 5: Commit.** `feat(exports): production register and weekly sheet as PDF and CSV`

### Task 6: Exports screen

**Files:**
- Create: `lib/features/exports/exports_screen.dart`.
- Modify: `lib/router.dart` (`/more/exports`); `lib/features/more/more_screen.dart` ("Exports" after Fiches papier); ARB (`moreExports`, `exportKindRegister`, `exportKindWeekly`, `exportFrom`, `exportTo`, `exportPond`, `exportAllPonds`, `exportPdf`, `exportCsv`, `exportEndBeforeStart`).
- Test: `test/features/exports/exports_screen_test.dart`.

**Interfaces:**
- Consumes: Task 5's loaders, tables, `buildExportPdf`, `encodeCsv`, `exportFileName`; `sharePdfFile` (rename nothing; add `shareFile(ref, name, bytes)` beside it if a CSV needs a different name, or use it as is: it writes bytes and shares).
- Screen, top to bottom:
  - the kind (two `ChoiceChip`s: "Registre de production (annexe A)", "Suivi hebdomadaire (annexe B)"; switching kind resets the dates to that kind's default per Decision 10);
  - two `DateField`s (`lib/features/common/date_field.dart`);
  - a pond dropdown ("Tous les étangs" plus every active pond);
  - the end-before-start notice when it applies;
  - two 56 dp buttons, "PDF" and "CSV", each through `SaveOnce`.

- [ ] **Step 1: Write the failing tests.** On a farm with E1 stocked and 3 days of logs:
  - `the register CSV of E1 is shared with its rows`: the fake sharer receives `registre-<site>-<from>-<to>.csv`; decode it with `decodeCsv` and expect a header plus 4 rows (stocking and 3 logs);
  - `the weekly PDF is shared`: `suivi-hebdo-….pdf`, bytes `%PDF`;
  - `an end date before the start disables both buttons and says so`;
  - `switching to the weekly sheet sets 8 weeks back`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/features/exports/exports_screen_test.dart`
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run them to see them pass.**
- [ ] **Step 5: Commit.** `feat(exports): exports screen for the register and the weekly sheet`

### Task 7: Malagasy for every string, and the review sheet

**Files:**
- Create:
  - `test/l10n/mg_complete_test.dart`;
  - `tool/mg_review.dart`: `export` and `import`, logic in top-level functions;
  - `test/tool/mg_review_test.dart`;
  - `docs/mg-review.csv` (generated).
- Modify: `lib/l10n/app_mg.arb` (every key); `README.md` (a short "Malagasy review" section: export, edit in a spreadsheet, import, `flutter gen-l10n`).

**Interfaces:**
- Consumes: `encodeCsv`, `decodeCsv` (Task 5, `package:dobo/features/exports/csv.dart`).
- Produces (`tool/mg_review.dart`):
  - `List<List<String>> reviewRows({required Map<String, dynamic> fr, required Map<String, dynamic> mg, List<List<String>> previous = const []})`: a header `key;description;fr;mg;ok`, then one row per template key in `app_fr.arb` order. `description` is the fr `@key.description` or empty. `ok` is kept from `previous` only when that row's `fr` equals the current French.
  - `Map<String, dynamic> applyReview(Map<String, dynamic> mg, List<List<String>> sheet)`: sets each non-empty `mg` cell. It keeps `@@locale` and the other `@@` entries and adds no `@key` metadata. Once every row is `ok`, it drops `@@x-review`.
  - `main(args)`: `export [csv]` (default `docs/mg-review.csv`) and `import [csv]`. The ARB is written with 2-space indent and a trailing newline, keys in template order.
- Translation conventions (write them at the top of `docs/mg-review.csv`'s companion README section):
  - official Malagasy (*malagasy ofisialy*), plain words over loanwords where a farmer would use them;
  - farming terms as in the existing worker strings: *trondro* fish, *sakafo* feed, *dobo* pond, *maty* deaths;
  - units, codes and numbers unchanged;
  - ICU placeholders and plural or select keywords unchanged; only the text inside branches is translated.

- [ ] **Step 1: Write the failing tests.**
  - `mg_complete_test.dart`:
    - `every French key has a Malagasy text`: no key missing, none empty;
    - `no Malagasy text drops a placeholder`: for each key, every placeholder declared in `app_fr.arb`'s `@key.placeholders` and used in the French text (`{name}` or `{name,`) also appears in the Malagasy text;
    - `the mg file has no key the French lacks`.
  - `mg_review_test.dart`:
    - `export keeps ok marks whose French is unchanged and clears the others`;
    - `import sets the corrected Malagasy and leaves the rest`;
    - `import drops @@x-review only when every row is ok`;
    - `a CSV saved by LibreOffice (LF, no BOM) imports`.
- [ ] **Step 2: Run them to see them fail.** `flutter test test/l10n test/tool`. Expected: the completeness test lists 566 missing keys.
- [ ] **Step 3: Implement.**
  - Write the tool.
  - Translate in batches by key prefix (setup and ponds; batches; recording and visit; alerts and dashboard; reports; sync and admin; feed, prep and sales; paper and exports), with one commit per batch. Each batch passes `flutter gen-l10n` and the placeholder test before its commit.
  - Last, run `dart run tool/mg_review.dart export` and commit the CSV.
- [ ] **Step 4: Run them to see them pass,** plus the whole suite. Widget tests that pump in `mg` and match French text must still pass. Where one did by fallback, it now matches the Malagasy, so fix the test's expectation, not the string.
- [ ] **Step 5: Commit** (the last batch). `feat(l10n): Malagasy drafts for every screen, with a review sheet`

### Task 8: Field test protocol

**Files:**
- Create: `docs/field-test.md`.
- Modify: `README.md` (link it); `lib/features/common/pictograms.dart` (doc comment points to the protocol and the generator).

The protocol covers:
1. **Setup:** a release APK against the hosted project, the worker's account, two printed weeks of paper sheets.
2. **Timing:** the worker logs today's ponds on the phone, and the same on paper. Note both times. The anti-goal is the phone being slower (SPEC §2).
3. **Pictograms:** for each of the 13 signs, 3 leftovers and 5 colours, show the icon alone and ask what it means. Note recognised or not, and the worker's own word in Malagasy. The table to fill is in the doc.
4. **Paper:** after a week, a member transcribes the paper sheet. Note any box that didn't map to the grid.
5. **Afterwards:**
   - pictograms not recognised get new artwork. The swap is: new SVG paths in `pictogram_paths.dart` (by hand or from the generator with other glyphs), and the matching screen icons in `pictograms.dart`;
   - Malagasy wording fixes go through `docs/mg-review.csv`.

No tests: it's a document. Commit: `docs: field test protocol for the worker screens and paper sheet`.

### Task 9: M8 walk-through and the emulator check

**Files:**
- Create: `integration_test/m8_paper_exports_test.dart`.

- [ ] **Step 1: Write the walk-through.** On a farm with E1 and E2 stocked 30 days ago and a week of worker logs:
  1. More → Fiches papier: untick E2, 2 weeks, Partager (sharer stubbed). The PDF has 2 pages.
  2. Transcription: copy one paper day into E1, with leftover `some` and colour `darkGreen`. The pond page's last log shows them.
  3. More → Exports: the register CSV for the last 30 days (stubbed sharer) decodes with a stocking row and the logs. The weekly PDF builds.
  4. Switch the language to Malagasy in More. The Ponds tab title and the Exports screen show Malagasy text, not French.
- [ ] **Step 2: Run it on the 2 GB emulator in airplane mode.** `flutter test integration_test/m8_paper_exports_test.dart -d <emulator>`. Then run every walk-through except M4's (as in M7 Task 10, adding M8). Expected: PASS.
- [ ] **Step 3: Print check.** On the emulator, tap Imprimer for real once. The Android print preview opens with "Save as PDF" and shows the sheet. Note it in the commit body.
- [ ] **Step 4: Check the size.** `flutter build apk --release --split-per-abi`. Write the ARM APK sizes in the commit body, compared with M7's. If `printing` adds more than 3 MB, flag it to the user.
- [ ] **Step 5: Run the whole suite.** `flutter analyze && flutter test && TZ=UTC flutter test`. Expected: no issues, all pass.
- [ ] **Step 6: Commit.** `test: M8 walk-through with paper sheets, exports and Malagasy`

## Not in M8

New pictogram artwork (after the field test, from its notes). The native-speaker review itself (the user, via `docs/mg-review.csv`). Audio labels for the worker (SPEC §9 "later"). Money (v2). A web dashboard. Several sites. Excel `.xlsx` output (CSV opens in any spreadsheet).
