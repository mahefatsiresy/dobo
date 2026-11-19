# Design step 4: Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Alerts tab lists what needs doing across the farm in two sections, "Danger" then "À faire". Each row is the band from the pond page and opens its fix. The badge, the ponds list and the tab share one danger count.

**Architecture:**
- **Sections:** a pure function, `alertSections`, turns the pond overviews and the alerts into the two sections. Each item is a pond (or none) plus an `AttentionLead`, reusing `pond_attention.dart`'s lead types.
- **Danger count:** one provider, `dangerPondsProvider`, gives the danger count. It feeds the shell's badge (in place of `dangerCountProvider`), the ponds list's top line and the tab's "Danger" heading.
- **Bands:** `AttentionBand` gains an optional `leading` widget, used for the pond's `PondCode`.

**Tech Stack:** Flutter 3.47.8, flutter_riverpod 3, go_router 18, ARB l10n, `flutter_test` goldens. No new packages.

**Spec:** `docs/design.md` (principles, §Step 4), `docs/SPEC.md` F7, `docs/DOMAIN.md` §Alert rules.

## Decisions (Claude's calls)

1. **What goes in each section:**
   - **Danger:** every pond's danger leads, in `pondAttention` order (isolated, inconsistent, then danger alerts in `compareAlerts` order), ponds in code order; then farm-wide danger alerts (`pondId == null`).
   - **À faire:** the warning alerts, in the same pond and farm-wide order.
   - Ponds that are archived or unknown to the overviews are left out.
2. **Taps:**
   - an alert opens `alertRoute(a)`; with no route, the band has no chevron;
   - isolated and inconsistent items open `/ponds/<id>`.
3. **The danger count** = the number of ponds whose `pondAttention` severity is danger, plus the farm-wide danger alerts. The ponds list's top line keeps its wording, "N étangs en danger", and counts the ponds only. The badge and the "Danger" heading show the full count.
4. **`AttentionBand.leading`** sits before the severity icon. On the alerts tab it is `PondCode` in the band's ink: paper on danger, ink on warning. The swatch keeps the pond's colour.
5. **Headings:** `alertsDanger` "Danger {count}" / "Loza {count}"; `alertsTodo` "À faire {count}" / "Atao {count}". Both are `titleMedium`, 16 dp padding. A section with nothing in it isn't shown.
6. **Nothing open:** `Icons.task_alt` in `ok`, size 48, above `alertsEmpty`, centred.
7. **The chips go.** `alertsAll` stays in the ARB files (other screens may use it). Check with `grep`; delete it if unused.

## Global Constraints

- No schema, sync or server change; alert rules unchanged (`lib/domain/alerts/`).
- Every string from the ARB files, every key in both; mg drafts; regenerate `docs/mg-review.csv`; check for an existing key before adding one.
- Colours from the theme (guard test); pond colour only as `PondCode`'s swatch on this tab.
- Touch targets ≥ 56 dp (tappable bands are 56 dp); no text below 14 sp.
- `dart format` only touched files; never commit `failures/`.
- At the end of each task: `flutter analyze` clean; `flutter test` and `TZ=UTC flutter test` pass.
- Commits: conventional prefix and the `Co-Authored-By` line. Branch: `design/alerts` from `main`.

## Review Focus

1. **A pond with both a danger and a warning item** shows in both sections, and each row opens its own fix. Covered in Task 1.
2. **Farm-wide items** (feed stock low, feed too old) appear last in their section, with no pond code, and open the feed screen. Covered in Task 1 (unit) and Task 2.
3. **The badge equals the "Danger" heading,** and the ponds list's line equals the ponds part, on the demo farm. Covered in Task 2.
4. **Alerts still loading:** a spinner, not "nothing open". Covered in Task 2.
5. **Long Malagasy alert text** in a band with a code and a chevron wraps without overflow at 130 % text. Covered in Task 2.

---

### Task 1: Sections and one danger count

**Files:**
- Create: `lib/features/alerts/alert_sections.dart`
- Modify: `lib/features/alerts/alert_providers.dart` (`dangerPondsProvider` replaces `dangerCountProvider`), `lib/features/shell/member_shell.dart`, `lib/features/ponds/ponds_screen.dart` (top line from the provider), `test/features/alerts/alert_providers_test.dart`
- Test: `test/features/alerts/alert_sections_test.dart`

**Interfaces:**
- Consumes: `PondOverview`, `Alert`, `pondAttention` and the `AttentionLead` types (`pond_attention.dart`), `compareAlerts` order (alerts already sorted).
- Produces:

```dart
class SectionItem {
  const SectionItem({required this.pond, required this.lead});
  final Pond? pond;           // null: farm-wide
  final AttentionLead lead;
}

({List<SectionItem> danger, List<SectionItem> todo}) alertSections(
  List<PondOverview> overviews,   // active ponds, in code order
  List<Alert> alerts,             // compareAlerts order
);

/// Ponds whose band is danger, and farm-wide danger alerts.
final dangerPondsProvider = Provider<({int ponds, int farmWide})>(...);
```

- [ ] **Step 1: Write the failing tests** (fixtures from `test/fixtures.dart`):
  - Isolated E4 plus a warning on E4 put `LeadIsolated` in danger and the warning in todo.
  - A danger alert on E5 plus inconsistent E5 give `[LeadInconsistent, LeadAlert]` for E5, in that order.
  - Ponds are in code order within a section, even when alerts arrive out of pond order.
  - A farm-wide feed alert comes after every pond item in its section, with `pond == null`.
  - An alert for a pond not among the overviews is left out.
  - On the demo farm (`appTest`, clock at `demoNow`), `dangerPondsProvider` is `(ponds: 3, farmWide: 0)` and the shell badge reads "3".
- [ ] **Step 2: Run** `flutter test test/features/alerts/alert_sections_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `alertSections` and `dangerPondsProvider`. Then switch the badge and the ponds list to `dangerPondsProvider`, delete `dangerCountProvider`, and update `alert_providers_test.dart`.
- [ ] **Step 4: Run** the full suite in both time zones and `flutter analyze`. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(alerts): danger and to-do sections, one danger count for badge and list`.

### Task 2: The Alerts tab

**Files:**
- Modify: `lib/features/common/attention_band.dart` (`leading`), `lib/features/alerts/alerts_screen.dart` (rewrite), `lib/l10n/app_fr.arb`, `lib/l10n/app_mg.arb`, `docs/mg-review.csv`, `test/features/alerts/alerts_screen_test.dart`
- Delete: `lib/features/alerts/alert_tile.dart` if nothing else uses it (`grep -rn AlertTile lib`)
- Test: `test/features/alerts/alerts_design_test.dart`, goldens `goldens/alerts_fr.png`, `alerts_mg.png`

**Interfaces:**
- Consumes: `alertSections`, `dangerPondsProvider` (Task 1); `AttentionBand`, `PondCode`, `bandText` (`pond_row.dart`), `alertRoute`.

- [ ] **Step 1: Write the failing tests** (demo farm, clock at `demoNow`, 360 × 2400 dp):
  - **Order:** the "Danger 3…" heading, then the danger bands E2 (oxygen), E4 (isolated), E5 (inconsistent), E5 (mortality), then the "À faire" heading and its bands, in pond code order.
  - **Count:** the "Danger" heading's count equals the badge.
  - **Taps:** the E4 isolated band opens E4's page; the E2 sample band opens the sample screen.
  - **Rows:** each band has a `PondCode`; no full-colour square of 56 dp (no `PondTag`) on the tab.
  - **No chips** (`ChoiceChip`).
  - **Feed alerts:** a farm with a feed lot past 90 days shows a band without a code, last in Danger, which opens the feed screen.
  - **Nothing open:** a farm with no alerts shows the tick and `alertsEmpty`.
  - **Loading:** with `alertsProvider` loading (`settle: false`), a spinner.
  - **Large text:** in `mg` at 130 % text, no overflow.
  - **Goldens:** fr and mg at 360 × 780.
- [ ] **Step 2: Run** `flutter test test/features/alerts/alerts_design_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Decisions 2 and 4–7, plus the ARB keys.
- [ ] **Step 4:** Update `alerts_screen_test.dart`: the chip test goes, and the badge test reads `dangerPondsProvider`'s total. Run the full suite in both time zones and `flutter analyze`. Look at the goldens. Expected: PASS.
- [ ] **Step 5: Commit:** `feat(alerts): two sections of bands, each opening its fix`.

### Task 3: Alerts on the phone

**Files:**
- Modify: `tool/design_demo.dart` (`DEMO_PAGE=alerts` opens `/alerts`; member session)

- [ ] **Step 1:** Add the page. Run `tool/design_screenshots.sh MNSO6HW8WOQOPB9T alerts` with the phone unlocked and Stay awake on. Look at the PNGs.
- [ ] **Step 2: Commit:** `test: design screenshots of the alerts tab`.

Then a fresh whole-branch review, the fixes it calls for, the screenshots shown to the user, and the merge.
