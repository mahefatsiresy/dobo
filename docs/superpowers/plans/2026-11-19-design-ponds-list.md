# Design step 0 + 1: Foundation and Ponds List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the phone app its own look, built for reading at a glance (ink on white, Atkinson Hyperlegible Next, severity bands, `≈` estimates), and rebuild the member's Ponds list on it so a member sees within 2 seconds which ponds need them and how much to feed each one.

**Architecture:**
- **Theme:** a new `lib/theme/` holds the tokens (`DoboColors`, a `ThemeExtension`), the type scale and `doboTheme()`, which `lib/app.dart` uses in place of the blue seed. The console keeps its own theme until its step.
- **Shared widgets:** `PondTag`, `PondStake`, `AttentionBand` and the `≈` `EstimatedLabel` live in `lib/features/common/`. Every raw `Colors.*` hue in `lib/features/` moves to tokens, and a guard test keeps it that way.
- **Ponds list:** rebuilt from the existing `pondOverviewsProvider`, `pondAlertsProvider`, `loggedTodayProvider`, `stopFeedingProvider` and `prepProgressAllProvider`. Which band a row shows comes from a pure function, `pondAttention`, tested on its own.
- **Proof:** committed golden tests of the building blocks and of the list (French and Malagasy) on a seeded demo farm. The same farm feeds an on-device screenshot run for the user's review.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, ARB l10n, Drift (in-memory for tests), `flutter_test` goldens, `integration_test` + `flutter drive` for device screenshots. New assets: Atkinson Hyperlegible Next Regular, SemiBold and Bold TTFs (SIL OFL), from `github.com/googlefonts/atkinson-hyperlegible-next` `fonts/ttf/`. No new packages.

**Spec:** `docs/design.md` (principles, tokens, step 1 decisions), `CLAUDE.md`, `docs/SPEC.md` (F6, §2 anti-goals, §9).

## Decisions (Claude's calls)

1. **Token values:** the hex table in `docs/design.md` §Colour, as written.
2. **Where the theme lives:** in `lib/theme/` (`tokens.dart`, `dobo_theme.dart`), added to CLAUDE.md §Layout. It's plain Flutter, so the console may import it in its own step.
3. **The colour scheme:**
   - `ColorScheme.fromSeed(seedColor: ink, dynamicSchemeVariant: DynamicSchemeVariant.monochrome)`, then `copyWith`: `primary: ink`, `onPrimary: paper`, `surface: paper`, `onSurface: ink`, `onSurfaceVariant: inkMuted`, `outline: line`, `outlineVariant: line`, `error: danger`, `onError: paper`, `surfaceTint: transparent`.
   - The app bar and navigation bar are `paper` with `ink` text. The navigation indicator is `shade`.
4. **Fonts:**
   - pubspec declares the family `Atkinson Hyperlegible Next` (400, 600, 700) and a family `Noto Sans` (400, 700) on the existing `assets/fonts/NotoSans-*.ttf` files, so the fallback costs no APK size.
   - The theme sets `fontFamily: 'Atkinson Hyperlegible Next'` and `fontFamilyFallback: ['Noto Sans']`.
   - Checked on 19/11: Atkinson covers every French and Malagasy letter and `≈`, lacks U+202F (the separator `intl` puts in `1 000`), and has `tnum`. Noto Sans has U+202F.
5. **Tabular figures:** the theme's `headlineSmall` and `titleMedium` carry `FontFeature.tabularFigures()`. Body text keeps proportional figures.
6. **A 56 dp minimum is set in the theme** for `FilledButton`, `OutlinedButton` and `TextButton`, so screens no longer repeat `minimumSize`. Existing explicit sizes may stay.
7. **`EstimatedLabel`:** shows `≈ value` (non-breaking space after `≈`), with the semantics label `value estimé` (l10n `estimated`). The on-screen report sections keep the word: `report_sections.dart` already writes `l10n.estimated` itself and stays as it is, as do the PDFs.
8. **Which band a row shows** (`pondAttention`), first match wins:
   - isolated: danger, text `pondIsolatedBanner`;
   - inconsistent count: danger, text `inconsistent`;
   - the pond's first alert (alerts already arrive in `compareAlerts` order, danger first): its severity, text `alertText`.

   "More" counts every other item: isolated, inconsistent and alerts together.
9. **The top lines:**
   - The total ration sums `rationG` over ponds with no stop-feeding reason, marked `≈`. It is hidden when the total is 0.
   - The danger line counts ponds whose band is danger. At 0 it reads "Aucun étang en danger" with an `ok` tick.
   - Both lines are hidden when there are no ponds.
10. **When a pond shouldn't be fed today** (`stopFeedingProvider(pondId)` not empty), the ration slot shows `Icons.no_meals` in `danger` and the text `workerStopFeeding`. It doesn't use the large worker `StopFeedingSign`.
11. **Short rows:**
    - `preparing` shows "status : next prep step" (`prepStep(progress.next)`), or the status alone when `next` is null;
    - `ready` and `empty` show the status alone;
    - an isolated pond with no fish keeps its band and is a short row.
12. **`PondBadge` becomes `PondTag`** (rename, 4 dp corners, Atkinson Bold), keeping its `code`/`colour` API and its luminance rule for ink (black on yellow, white on blue). `PondStake` is new.
13. **Goldens:**
    - Committed PNGs under `test/**/goldens/`.
    - Rendered at 360 × 780 dp, pixel ratio 2, with real fonts loaded by a helper that reads `FontManifest.json` (so Material icons render too).
    - Regenerate with `flutter test --update-goldens <file>`.
    - The clock is fixed to 2026-03-15 09:00 Madagascar (06:00 UTC) through `clockProvider`, and `farmTodayProvider` follows it.
14. **Device screenshots:** `integration_test/design_screens_test.dart`, run with `flutter drive --driver=test_driver/screenshots.dart`, writes PNGs to `build/screenshots/`. The user approved debug installs on the test phone `MNSO6HW8WOQOPB9T` (19/11).
15. **Section header and action tile are built in step 2**, the first screen that uses them.

## Global Constraints

- Phone stays offline-first; no task touches the database schema (`schemaVersion` stays 6), sync or the server.
- `lib/domain/` imports neither Flutter nor Drift. `pondAttention` lives in `lib/features/ponds/`, not in domain: it decides presentation, not farming.
- Nothing reachable from `lib/main_web.dart` gains a phone-only import (the existing import-graph test).
- Every user-facing string comes from the ARB files, with every key in both `app_fr.arb` and `app_mg.arb`. New Malagasy texts are drafts, and `docs/mg-review.csv` is regenerated with `dart run tool/mg_review.dart export`.
- Touch targets ≥ 56 dp; no text below 14 sp; no animation added.
- Pond tag colours (`pondColourValue`) do not change: the paper sheets print them.
- Display formats unchanged: decimal comma, `dd/mm/yyyy`, kg/g through `lib/l10n/formatting.dart`.
- No money anywhere.
- At the end of each task: `flutter analyze` has no issues, and `flutter test` and `TZ=UTC flutter test` pass.
- Commits use a conventional prefix and end with the `Co-Authored-By` line. Branch: `design/ponds-list` from `main`.

## Review Focus

1. **Large system text** (Android font size at 130 %, common on older phones): rows wrap and nothing overflows. Covered in Task 5 with `textScaler: TextScaler.linear(1.3)`.
2. **A stocked pond whose batch has no known weight** (biomass null, ration 0; only reachable from odd synced records): the row shows the fish count, no ration and no `≈ 0 kg`, and adds nothing to the total. Covered in Task 5 on the row widget.
3. **A pond that must not be fed** (fast before harvest, low oxygen) shows the stop sign and never a ration, and the total leaves it out. Covered in Task 5.
4. **Light tags** (yellow): the code stays readable on the stake and the square tag. Covered in the Task 3 golden.
5. **A pond with several problems at once** (isolated, inconsistent and alerts): one band, the most urgent first, with the right "and N more". Covered in Task 4.

---

### Task 1: Theme, tokens and fonts

**Files:**
- Create: `lib/theme/tokens.dart`, `lib/theme/dobo_theme.dart`, `assets/fonts/AtkinsonHyperlegibleNext-{Regular,SemiBold,Bold}.ttf`, `assets/fonts/OFL-Atkinson.txt`
- Modify: `pubspec.yaml` (fonts section and assets comment), `lib/app.dart:77-79`, `CLAUDE.md` (§Layout gets `lib/theme/`; §Conventions gets "Colours and type come from `lib/theme/` and `docs/design.md`; features never name a `Colors.*` hue except pond tags.")
- Test: `test/theme/dobo_theme_test.dart`, `test/golden_fonts.dart` (helper)

**Interfaces:**
- Produces:
  - `class DoboColors extends ThemeExtension<DoboColors>`, with the fields `paper, ink, inkMuted, line, shade, danger, dangerFill, warning, warningFill, ok, okFill` (`Color`) and `series` (`List<Color>`). It has `static const DoboColors standard` and `copyWith`/`lerp`.
  - `extension DoboThemeX on BuildContext { DoboColors get dobo; }`
  - `ThemeData doboTheme()`.
  - `Future<void> loadAppFonts()` in `test/golden_fonts.dart`.

- [ ] **Step 1: Write the failing tests** in `test/theme/dobo_theme_test.dart`:

```dart
test('scheme is ink on paper with danger as error', () {
  final t = doboTheme();
  expect(t.colorScheme.primary, const Color(0xFF17262B));
  expect(t.colorScheme.surface, const Color(0xFFFFFFFF));
  expect(t.colorScheme.error, const Color(0xFFA3151B));
  expect(t.extension<DoboColors>(), DoboColors.standard);
  expect(t.brightness, Brightness.light);
});
test('type: Atkinson with Noto fallback, tabular figures on numbers', () {
  final t = doboTheme().textTheme;
  expect(t.bodyMedium!.fontFamily, 'Atkinson Hyperlegible Next');
  expect(t.bodyMedium!.fontFamilyFallback, ['Noto Sans']);
  expect(t.headlineSmall!.fontSize, 28);
  expect(t.headlineSmall!.fontFeatures, contains(const FontFeature.tabularFigures()));
  expect(t.bodySmall!.fontSize, greaterThanOrEqualTo(14));
});
test('buttons are at least 56 dp tall', () {
  final s = doboTheme().filledButtonTheme.style!;
  expect(s.minimumSize!.resolve({})!.height, 56);
});
testWidgets('the app uses the Dobo theme', ...); // pump DoboApp via appTest; Theme.of(...).colorScheme.primary == ink
```

- [ ] **Step 2: Run** `flutter test test/theme/dobo_theme_test.dart`. Expected: FAIL, `doboTheme` is not defined.
- [ ] **Step 3: Add the fonts.** Download the three static TTFs and `OFL.txt` (saved as `OFL-Atkinson.txt`) into `assets/fonts/`. Declare both families in `pubspec.yaml` (Decision 4).
- [ ] **Step 4: Implement `tokens.dart` and `dobo_theme.dart`** with the values in `docs/design.md` §Colour and §Type and Decisions 3, 5 and 6. Then set `theme: doboTheme()` in `lib/app.dart`.
- [ ] **Step 5: Implement `loadAppFonts()`.** Read `FontManifest.json` with `rootBundle.loadString`, and for each family load every asset into a `FontLoader(family)`. Material icons come in as `MaterialIcons`.
- [ ] **Step 6: Run** `flutter test test/theme/` and then the full `flutter test`. Expected: PASS. Fix any widget test that relied on the default theme's colours by asserting tokens instead.
- [ ] **Step 7: Commit:** `feat(theme): ink-on-paper theme with Atkinson Hyperlegible Next`.

### Task 2: Raw colours to tokens

**Files:**
- Modify (every `Colors.<hue>` in `lib/features/` outside `pond_colour.dart`, `pdf_theme.dart` and `*_pdf.dart`):
  - `common/number_field.dart`, `common/notice.dart`, `common/mini_chart.dart`
  - `ponds/pond_charts.dart`, `ponds/pond_detail_screen.dart`, `ponds/pond_figures.dart`, `ponds/pond_form_screen.dart`
  - `feed/feed_stock_screen.dart`
  - `alerts/alert_tile.dart`
  - `reports/reports_screen.dart`, `reports/report_sections.dart`
  - `daily_log/daily_log_screen.dart`, `daily_log/stop_feeding_sign.dart`, `daily_log/worker_home_screen.dart`
  - `visit/visit_screen.dart`, `visit/condition_check.dart`
  - `sync/sync_screen.dart`
  - `batches/batch_detail_screen.dart`
  - `prep/prep_screen.dart`
- Test: `test/theme/no_raw_colours_test.dart`

**Interfaces:**
- Consumes: `context.dobo` (Task 1).

- [ ] **Step 1: Write the failing guard test.** It reads every `.dart` file under `lib/features/` except `common/pond_colour.dart`, `common/pdf_theme.dart` and files ending `_pdf.dart`. It fails on any match of `RegExp(r'Colors\.(red|amber|green|orange|blue|purple|teal|grey|yellow|brown|pink|indigo|cyan|lime|deepOrange|deepPurple|lightBlue|lightGreen|blueGrey)\b')` and lists file:line in the failure message. `Colors.white`, `Colors.black` and `Colors.transparent` stay allowed.
- [ ] **Step 2: Run** it. Expected: FAIL, listing about 33 lines.
- [ ] **Step 3: Replace each hue** with its token:

  | Hue now | Token |
  |---|---|
  | red shades 700–900, `Colors.red` | `danger` |
  | `red.shade50`, `red.shade100` | `dangerFill` |
  | amber 800–900, orange 800 | `warning` |
  | green (any shade) | `ok` |
  | `green.shade100` | `okFill` |
  | grey | `inkMuted` |
  | `pond_charts` batch colours | `series` |

  `Notice` and `AlertTile` keep their APIs.
- [ ] **Step 4: Run** the guard and the full `flutter test`, then `TZ=UTC flutter test`. Expected: PASS.
- [ ] **Step 5: Commit:** `refactor(theme): severity and status colours come from the theme`.

### Task 3: Building blocks: tags, band, `≈`

**Files:**
- Create: `lib/features/common/attention_band.dart`
- Modify: `lib/features/common/pond_colour.dart` (rename `PondBadge` to `PondTag` everywhere; add `PondStake`), `lib/features/common/estimated.dart`
- Modify (tests that expect the word *estimé* on screen): `test/features/ponds/ponds_screen_test.dart` and the others `grep -rln "estimé" test` finds; report and PDF tests keep the word.
- Test: `test/features/common/building_blocks_test.dart`, golden `test/features/common/goldens/building_blocks.png`

**Interfaces:**
- Consumes: `context.dobo`, `doboTheme()`, `loadAppFonts()` (Task 1).
- Produces:
  - `class PondTag extends StatelessWidget { const PondTag({required String code, required PondColour colour}); }` (56 dp square, 4 dp corners);
  - `class PondStake extends StatelessWidget { const PondStake({required String code, required PondColour colour}); }` (64 dp wide, fills its parent's height, so the row must be an `IntrinsicHeight` or have a fixed height);
  - `enum BandSeverity { danger, warning }`;
  - `class AttentionBand extends StatelessWidget { const AttentionBand({required BandSeverity severity, required String text}); }` (min height 40 dp, full width, icon `Icons.error` for danger or `Icons.warning_amber` for warning, text wraps);
  - `EstimatedLabel` with the same constructor as now.

- [ ] **Step 1: Write the failing tests:**

```dart
testWidgets('estimated value starts with ≈ and reads "estimé" to screen readers', (t) async {
  await t.pumpWidget(_wrap(const EstimatedLabel(value: '1 240')));
  expect(find.text('≈ 1 240'), findsOneWidget);
  expect(find.text('estimé'), findsNothing);
  expect(t.getSemantics(find.byType(EstimatedLabel)), matchesSemantics(label: '1 240 estimé'));
});
testWidgets('danger band is filled danger with white text', ...);   // container colour == DoboColors.standard.danger; Text colour == paper
testWidgets('warning band is warningFill with a warning left edge', ...);
testWidgets('stake: dark ink on yellow, white on blue', ...);       // the Text colour for PondColour.yellow is black, for blue is white
testWidgets('building blocks golden', (t) async {
  await loadAppFonts();
  // 360x780 dp, pixel ratio 2: PondTag and PondStake in yellow, blue and black;
  // a danger band and a warning band with a long Malagasy text; EstimatedLabel
  // in headlineSmall and in bodySmall.
  await expectLater(find.byKey(const Key('blocks')), matchesGoldenFile('goldens/building_blocks.png'));
});
```

- [ ] **Step 2: Run** `flutter test test/features/common/building_blocks_test.dart`. Expected: FAIL, `AttentionBand` is not defined.
- [ ] **Step 3: Implement** the widgets above. Do the `PondBadge` → `PondTag` rename across `lib/` and `test/`, and switch `EstimatedLabel` to `≈` (Decision 7).
- [ ] **Step 4: Generate the golden** with `flutter test --update-goldens test/features/common/building_blocks_test.dart`. Open the PNG and check by eye that the fonts and icons render (not boxes) and the yellow tag is readable. Then run the full `flutter test`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(common): pond tag and stake, attention band, ≈ for estimates`.

### Task 4: Which band a pond row shows

**Files:**
- Create: `lib/features/ponds/pond_attention.dart`
- Test: `test/features/ponds/pond_attention_test.dart`

**Interfaces:**
- Consumes: `PondOverview` (`pond_overview.dart`), `Alert`, `Severity`, `PondStatus`, `BandSeverity` (Task 3).
- Produces:

```dart
sealed class AttentionLead {}            // what the band names
final class LeadIsolated extends AttentionLead {}
final class LeadInconsistent extends AttentionLead {}
final class LeadAlert extends AttentionLead { LeadAlert(this.alert); final Alert alert; }

class PondAttention {
  const PondAttention({required this.severity, required this.lead, required this.more});
  final BandSeverity severity;
  final AttentionLead lead;
  final int more;                         // other items besides the lead
}

/// Null when the pond needs nothing (no band).
PondAttention? pondAttention(PondOverview overview, List<Alert> alerts);
```

- [ ] **Step 1: Write the failing tests**, building overviews with `buildPondOverview` and `test/fixtures.dart` rows:
  - no alerts, stocked: `null`;
  - one warning alert: `warning`, `LeadAlert` with that alert, `more == 0`;
  - warning then danger in the list as given, sorted by `compareAlerts` (danger first): the lead is the danger alert, `more == 1`;
  - isolated with 2 alerts: `danger`, `LeadIsolated`, `more == 2`;
  - isolated and inconsistent with 1 alert: `LeadIsolated`, `more == 2`;
  - inconsistent only: `danger`, `LeadInconsistent`, `more == 0`;
  - isolated with no fish and no alerts: `danger`, `LeadIsolated`, `more == 0`.
- [ ] **Step 2: Run** `flutter test test/features/ponds/pond_attention_test.dart`. Expected: FAIL, `pondAttention` is not defined.
- [ ] **Step 3: Implement `pondAttention`** (Decision 8). Items in order: isolated, inconsistent, then the alerts as given. The lead is the first item, and severity is the lead's: danger for isolated and inconsistent, the alert's own severity otherwise.
- [ ] **Step 4: Run** the test. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(ponds): one attention band per pond, most urgent first`.

### Task 5: The ponds list

**Files:**
- Modify: `lib/features/ponds/ponds_screen.dart` (rewrite; delete `_AlertCounts`), `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv` (regenerated)
- Create: `lib/features/ponds/pond_row.dart` (`StockedPondRow`, `ShortPondRow`), `test/demo_farm.dart`
- Test: `test/features/ponds/ponds_screen_test.dart` (rewrite), goldens `test/features/ponds/goldens/ponds_list_fr.png`, `ponds_list_mg.png`

**Interfaces:**
- Consumes:
  - `pondOverviewsProvider`, `pondAlertsProvider(pondId)`, `loggedTodayProvider`, `stopFeedingProvider(pondId)`, `prepProgressAllProvider`, `sessionProvider`;
  - `pondAttention` (Task 4);
  - `PondStake`, `AttentionBand`, `EstimatedLabel` (Task 3).
- Produces: `Future<DemoFarm> seedDemoFarm(AppDatabase db)` in `test/demo_farm.dart`, used here and by Task 6. `DemoFarm` holds the pond ids by code. With the clock at 2026-03-15 (Decision 13), it seeds:

  | Pond | Colour | State |
  |---|---|---|
  | E1 | blue | growout, ~1 240 fish at 150 g, sampled 3 days ago, a normal water reading today, logged today, no alerts |
  | E2 | yellow | stocked, oxygen 2 mg/L read today (danger) and sample overdue (warning) |
  | E3 | green | stocked, a normal water reading today, sample overdue (warning only) |
  | E4 | red | isolated by a health event, stocked |
  | E5 | purple | deaths logged above the live count (inconsistent) |
  | E6 | orange | stocked, harvest planned tomorrow (stop feeding) |
    | P1 | black | preparing, drained and dried, next step `treat` |
  | P2 | blue | empty |

  It writes through the existing repositories, as `ponds_screen_test.dart` does today.
- New ARB keys (fr; mg drafts alongside):
  - `pondsRationTotal`: "Ration du jour, tous les étangs : {amount}"
  - `pondsDangerCount`: `{count, plural, =0{Aucun étang en danger} =1{1 étang en danger} other{{count} étangs en danger}}`
  - `bandMore`: `{lead}, et {count, plural, =1{1 autre} other{{count} autres}}`
  - `pondLogDone`: "Journal fait"
  - `pondLogNotYet`: "Pas encore de journal"
  - `pondPrepNext`: "{status} : {step}"

- [ ] **Step 1: Write the failing widget tests** (`appTest` with `clockProvider` overridden to the fixed time, `seedDemoFarm`, then `pumpAndSettle`):
  - code order: the vertical order of `E1…E6, P1, P2` texts is the list order;
  - E1 shows `≈ 186 kg`-style biomass, the ration as `≈ … kg` in `headlineSmall`, "Journal fait", and no `AttentionBand`;
  - E2's band is danger, its text starts with the oxygen alert's text and ends "et 1 autre";
  - E4 shows a danger band "Étang isolé";
  - E5 shows a danger band "À vérifier";
  - E6 shows "workerStopFeeding" text and no `kg` ration in its row;
  - Review Focus 2: stocking always records a weight, so the repositories can't produce a pond with no weight. Pump `StockedPondRow` alone with a hand-built `PondOverview` (`biomassG: null`, `rationG: 0`, one batch with `phase: null`). It shows the `≈` fish count, no `kg` text and no stop sign;
  - the total line equals the sum of the rations of E1, E2, E3, E4 and E5 (not E6), formatted with `formatKg`, prefixed `≈`;
  - the danger line reads "3 étangs en danger" (E2, E4, E5);
  - P1 reads "En préparation : Traitement" (from the ARB `pondStatus` and `prepStep` labels), and its row is shorter than E1's;
  - the admin sees "Ajouter un étang" as the last row and no `FloatingActionButton`; a non-admin (`isAdmin: false`) sees neither;
  - tapping E3's row opens `/ponds/<E3 id>`;
  - with `MediaQuery` `textScaler: TextScaler.linear(1.3)` and locale `mg`, `tester.takeException()` is null after scrolling to the end (no overflow; Review Focus 1);
  - golden `ponds_list_fr.png` (top of the list at 360 × 780) and `ponds_list_mg.png` (same, locale `mg`).
- [ ] **Step 2: Run** `flutter test test/features/ponds/ponds_screen_test.dart`. Expected: FAIL.
- [ ] **Step 3: Add the ARB keys** in both files, run `flutter gen-l10n` (or `build_runner`, as the project does), then `dart run tool/mg_review.dart export`.
- [ ] **Step 4: Implement `StockedPondRow` and `ShortPondRow`** in `pond_row.dart`. The layout is the wireframe in `docs/design.md` §Step 1:
  - `IntrinsicHeight` → `Row` of `PondStake` and a padded `Column`, with the band above when there is one;
  - a 1 dp `line` rule between rows;
  - the whole row is one `InkWell`, at least 56 dp tall.
- [ ] **Step 5: Rewrite `PondsScreen`** with the two top lines (Decision 9), the rows in `pondOverviewsProvider` order (already by code), and the admin "add" row, in a `ListView` with no floating button.
- [ ] **Step 6: Generate the goldens** with `--update-goldens`, look at both PNGs, then run `flutter test`, `TZ=UTC flutter test` and `flutter analyze`. Expected: PASS, no issues.
- [ ] **Step 7: Commit:** `feat(ponds): ponds list for a glance: stakes, bands, the ration first`.

### Task 6: Screenshots on the test phone

**Files:**
- Create: `integration_test/design_screens_test.dart`, `test_driver/screenshots.dart`
- Modify: `README.md` (Tests: one line on goldens and on the screenshot run)

**Interfaces:**
- Consumes: `seedDemoFarm` (Task 5), `appTest`-like setup from `test/helpers.dart`.

- [ ] **Step 1: Write `test_driver/screenshots.dart`.** It calls `integrationDriver(onScreenshot: (name, bytes, [args]) async { File('build/screenshots/$name.png')..createSync(recursive: true)..writeAsBytesSync(bytes); return true; })`.
- [ ] **Step 2: Write `integration_test/design_screens_test.dart`.** It opens an in-memory database with `seedDemoFarm`, fixes the clock, pumps `DoboApp`, and takes `binding.convertFlutterSurfaceToImage()` then `takeScreenshot` for:
  - `ponds_fr_top` and `ponds_fr_bottom`;
  - `ponds_mg_top` and `ponds_mg_bottom`, after switching `localeControllerProvider` to `mg`.
- [ ] **Step 3: Run it** with `flutter drive --driver=test_driver/screenshots.dart --target=integration_test/design_screens_test.dart -d MNSO6HW8WOQOPB9T`. Expected: `All tests passed` and four PNGs in `build/screenshots/`.
- [ ] **Step 4: Look at each PNG.** Check sunlight-level contrast, that nothing is clipped, that the stake codes are readable and that the ration is the loudest number. Fix anything off in Tasks 3–5's code (update goldens if so).
- [ ] **Step 5: Commit:** `test: device screenshots of the ponds list from a demo farm`.

Then show the user the four screenshots and the two goldens before the branch is merged.
