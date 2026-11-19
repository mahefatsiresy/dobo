# Design — Dobo

How the app looks, and why. Decided with the user on 19/11/2026, step by
step, starting with the ponds screen. Items marked **[Claude's call]** were
decided without the user and can be revisited after the screenshots.

## Goal

**Glance first.** A member opens a screen and sees within 2 seconds what
needs them and what to do, readable on a low-end phone in full sunlight.
The app's own visual identity is built on top of that, never instead of it.

## Principles

1. **Colour means something, or it isn't there.** Colour says *which pond*
   (the tags, which match the painted stakes and paper sheets) or *how
   urgent* (danger, warning). Everything else is ink on white.
2. **Severity is a shape, not just a colour.** Danger and warning always come
   as a band with an icon and words, never a bare coloured number, so a red
   or yellow pond tag never reads as an alarm and people who can't tell
   colours apart still get the message.
3. **The pond code is the anchor.** On every list a pond starts with its
   code. Workers, who may read with difficulty, see it on its full colour,
   like the stake on the dike (worker screens, paper sheets). Members see
   the code in ink beside a small swatch of the colour, so the colour
   recalls the stake without competing with the severity bands (user's
   choice, 19/11).
4. **One loud number per row.** The number someone acts on (today's ration
   on the ponds list) is the biggest thing in the row. Other figures are
   quieter.
5. **Estimates look estimated.** On screen an estimated figure starts with
   `≈`. Reports and PDFs, which leave the app, keep the word *estimé* /
   *tombana*.
6. **Light theme only**, tuned for sunlight. No dark mode.
7. **Built for the hand:** touch targets ≥ 56 dp, text never below 14 sp,
   rows that wrap long Malagasy text rather than cut it, no decorative
   motion.

## Tokens

All in `lib/theme/`. Features read them through the theme
(`Theme.of(context)` and `context.dobo`); no feature names a raw
`Colors.*` hue (a test enforces it), except pond tag colours in
`pond_colour.dart`.

### Colour **[Claude's call: exact values]**

| Token | Hex | Use |
|---|---|---|
| `paper` | `#FFFFFF` | every surface |
| `ink` | `#17262B` | text, main buttons, icons; a very dark pond-water slate |
| `inkMuted` | `#4A5A5F` | secondary text (≥ 7:1 on white) |
| `line` | `#C9D2D4` | row rules, outlines |
| `shade` | `#EEF2F2` | pressed rows, quiet fills |
| `danger` | `#A3151B` | danger band fill (white text, 7.8:1), danger text |
| `dangerFill` | `#FBE4E4` | pale red behind a blocking notice |
| `warning` | `#8A5300` | warning icon and edge |
| `warningFill` | `#FFF1C2` | warning band fill (ink text) |
| `ok` | `#1E6B3A` | done ticks, saved confirmation |
| `okFill` | `#E2F1E6` | pale green behind an OK check |
| `series` | `#17262B`, `#2A7F86`, `#B5651D`, `#7A5BA6` | chart lines, one per batch |

### Type

**Atkinson Hyperlegible Next** (SIL OFL), bundled in Regular, SemiBold and
Bold (about 200 KB). It was drawn for legibility: 0/O, 1/l/I and 5/6/8
can't be confused. Numbers use its tabular figures (`tnum`) so columns of
kilos line up. Noto Sans (already bundled for the PDFs) is the fallback
for the few glyphs Atkinson lacks, such as the narrow no-break space
French uses in `1 000`.

| Role | Size / weight | Use |
|---|---|---|
| `headlineSmall` | 28 / Bold, tabular | the row's loud number (ration) |
| `titleLarge` | 22 / SemiBold | app bar titles |
| `titleMedium` | 18 / SemiBold | row titles, figures |
| `bodyLarge` | 16 / Regular, 1.4 line height | body text |
| `bodyMedium` | 16 / Regular | default text |
| `bodySmall` | 14 / Regular, `inkMuted` | secondary lines |
| `labelLarge` | 16 / SemiBold | buttons |

### Shape and space **[Claude's call]**

- Spacing on a 4 dp grid: 4, 8, 12, 16, 24, 32.
- Lists are full-width rows separated by a 1 dp `line` rule, not floating
  cards.
- On a member list row the pond is `PondCode`: the code in Bold ink beside
  a 12 dp square of its colour, in a 72 dp column down the left. Alert
  rows and page headers use `PondTag`, a 56 dp square of the colour with
  4 dp corners; worker screens keep their full-colour tiles.
- Buttons, inputs and dialogs: 8 dp corners. Buttons are 56 dp tall:
  filled ink for the main action, outlined ink for the others.

## Building blocks

In `lib/theme/` (look) and `lib/features/common/` (widgets):

- `PondTag` (colour square) and `PondCode` (ink code and swatch).
- `AttentionBand`: danger (filled `danger`, white text and icon) or warning
  (`warningFill`, 4 dp `warning` left edge, ink text, `warning` icon).
- `EstimatedLabel`: `≈ value` on screen, the word kept for reports.
- `AttentionBand` with `onTap`: ends with a chevron and opens what resolves
  it.
- `ActionTile`: an icon above its label, at least 56 dp, outlined ink; for
  action grids and the two actions of a batch.
- `FoldedSection`: one line (title and summary) that opens on a tap with
  no animation and builds its content only once opened.

## Steps

| Step | Screen | Status |
|---|---|---|
| 0 + 1 | Foundation, ponds list | merged 19/11 |
| 2 | Pond detail | merged 19/11 |
| 3 | Worker home and daily log | merged 19/11 |
| 4 | Alerts | merged 19/11 |
| 5 | Visit | merged 19/11 |
| 6 | Reports | " |
| 7 | Batches, feed and the other "More" forms | " |
| 8 | Web console (takes the colours and type) | " |

Each step is one branch, merged locally after the user has seen
screenshots from seeded demo farms on the host and on the test phone.

### Step 1: ponds list (decided)

- Code order (E1, E2…): people find a pond by its stake.
- Above the list: today's total ration across the ponds that may be fed
  (`≈`, the value never split from its label's line), and how many ponds
  have a danger band.
- A stocked pond's row:

  ```
  ┌────────────────────────────────────────────┐
  │ ■ E1  ⚠ Oxygène bas, et 1 autre            │ ← band, only when needed,
  │       ──────────────────────────────────── │   beside its own code
  │       Grossissement         Ration du jour │
  │       ≈ 1 240 poissons          ≈ 2,4 kg   │ ← ration: the loud number
  │       ≈ 186 kg, 150 g                      │
  │       ✓ Journal fait                       │
  └────────────────────────────────────────────┘
  ```

  - The band sits beside the pond's code, so it can't be read as the row
    above's. **[Claude's call, after the first goldens]**
  - The band names the most urgent item (isolated, inconsistent count, then
    alerts in alert order) and how many more.
  - The average weight follows the biomass only when the pond holds one
    batch.
  - Phase replaces role and structure; density shows only out of range.
  - When the pond should not be fed today (pre-harvest fast, low oxygen,
    surface swimming), the ration's place shows the stop-feeding sign
    instead, and the pond adds nothing to the total. **[Claude's call]**
  - Tapping anywhere opens the pond.
- Empty, preparing and ready ponds: one line with the code, the status
  and the next prep step.
- Admins add a pond from a plain last row, not a floating button.

### Step 2: pond detail (decided 19/11)

```
┌────────────────────────────────────────────┐
│ ←  ■ E2                                  ⋮ │ ← code and swatch; ⋮: edit, archive
├────────────────────────────────────────────┤
│ ! Oxygène dissous trop bas : 2 mg/L      › │ ← every band, each opens its fix
│ ⚠ Lot L-E2 : échantillonnage à faire     › │
│ Grossissement                              │
│                            Ration du jour  │
│ ✓ Journal fait                 ≈ 7,4 kg    │ ← or the stop-feeding sign
│ Donné : 7,0 kg                             │
├────────────────────────────────────────────┤
│ L-E2  ≈ 1 500 poissons, 60 g, ≈ 90 kg      │
│ Pesé il y a 3 j, IC 1,6 ↑, survie 98 %     │
│ [ ⚖ Peser ]          [ ⇄ Transférer ]      │ ← the batch's own actions
├────────────────────────────────────────────┤
│ Dernier relevé 15/03 : 28 °C  pH 7,2       │
│ ! O₂ 2 mg/L                                │ ← out of range: icon and colour
├────────────────────────────────────────────┤
│ ▸ Poids moyen        150 g, +12 g en 14 j  │ ← folded; opens on a tap
│ ▸ Morts par jour            4 morts en 30 j│
│ ▸ IC par période                 1,6 ↑     │
│ ▸ Santé       2 événements, dernier 12/03  │
│ ▸ Étang      Grossissement, terre, 500 m²  │
├────────────────────────────────────────────┤
│ [ 💧 Relevé d'eau ]  [ ⚠ Signaler ]        │ ← grid: only what applies
│ [ 💊 Traitement ]    [ + Empoissonner ]    │
├────────────────────────────────────────────┤
│ [        ✎ Journal du jour               ] │ ← pinned: follows the state
└────────────────────────────────────────────┘
```

- The pinned bar holds the next thing to do with the pond: "Journal du
  jour" while it holds fish, "Préparer l'étang" while empty or being
  prepared, "Empoissonner" once ready. A pond without fish has no daily
  log action. **[user, 19/11]**
- Each batch keeps its own Peser and Transférer, side by side. **[user]**
- Today shows what was given next to the suggestion once the day is
  logged. **[user]**
- Charts and health history start folded, as one line with a summary;
  they open on a tap, with no animation. **[user]**
- The app bar shows the code and swatch; edit (admins) and archive move to
  the ⋮ menu. Isolation is a band at the top like the list's; only the
  action bar is pinned. Every band shows, each opening the screen that
  resolves it. **[Claude's call]**

### Step 3: worker home and daily log (decided 19/11)

Measure: a normal day (feed given, leftovers, no deaths, no signs) takes
the fewest taps, with no scrolling and nothing to read. Built before the
field test, so the worker tries these screens. **[user]**

```
Worker home                          Daily log
┌──────────────────────────────┐     ┌──────────────────────────────┐
│ Androany 15/03       ☁ sync  │     │ [E1] 15/03/2026              │
│ 2 / 5 vita                   │     │ 🍚 7,4 kg   ← aim for this    │
│ ┌──────────┐ ┌──────────┐    │     │ ┌──────────────────────────┐ │
│ │   E1   ✓ │ │    E2    │    │     │ │ Sakafo nomena      kg    │ │
│ │ 🍚 7,4 kg│ │  ⊘ ~~    │    │     │ └──────────────────────────┘ │
│ └──────────┘ └──────────┘    │     │ ( ○ )  ( ◐ )  ( ● )   Sisa    │
│ ┌──────────┐ ┌──────────┐    │     │ ┌───────────────┐ [Endrika]  │
│ │   E3     │ │    E4    │    │     │ │ Maty        0 │  if > 0    │
│ │ 🍚 4 kg  │ │ 🍚 1,4 kg│    │     │ └───────────────┘            │
│ └──────────┘ └──────────┘    │     │ [Famantarana][Loko][Impiry]  │
└──────────────────────────────┘     │ [        ✓ Tehirizina      ] │ ← pinned
                                     └──────────────────────────────┘
```

- Worker home: tiles only for ponds holding fish (an inconsistent count
  stays), full colour, code order, a large tick once logged, and a line
  with the day's progress; one line with a tick when all are done.
- The ration on worker screens (the home and the daily log) is an
  instruction: plain kg beside a feed pictogram, no `≈`. The stop-feeding
  sign replaces it. Members' screens keep `≈`. **[user]**
- Daily log on one screen for a normal day: the ration to aim for, the
  feed box (the phone's number pad, not opened by itself), the three
  leftover pictograms, deaths (0), then three buttons that each open their
  own screen of pictograms: signs (Famantarana), water colour (Loko ny
  rano), feedings (Impiry, 1–6). "Endrika" (what the dead fish looked
  like) appears beside deaths once deaths are above 0. Save is pinned.
  **[user]**
- Workers never meet a text field: the note is for members only, as is
  the feed lot. **[user]**
- Pictogram grids are two per row; a label is never cut, it wraps. **[user]**
- The pictogram screens are pages with a back arrow and a large "Vita"
  button; what is picked returns to the log and nothing is saved until
  Save. Each button shows what was picked. **[Claude's call]**

### Step 4: alerts (decided 19/11)

The tab answers "what needs doing across the farm, most urgent first";
every row opens the screen that fixes it. The per-pond view stays on the
ponds list and the pond page. **[user]**

```
┌────────────────────────────────────────────┐
│ Alertes                                    │
│ Danger                                     │
│ ■ E2 ! Oxygène dissous trop bas : 2 mg/L › │ ← the pond page's bands
│ ■ E4 ! Étang isolé                       › │
│ ■ E5 ! À vérifier                        › │
│ ■ E5 ! 500 morts le 14/03/2026           › │
│ À faire                                    │
│ ■ E2 ⚠ Lot L-E2 : échantillonnage à faire › │
│ ■ E3 ⚠ Lot L-E3 : échantillonnage à faire › │
│ …                                          │
└────────────────────────────────────────────┘
```

- Two sections, "Danger" then "À faire" (warnings and due tasks), each in
  pond code order, farm-wide items last; a section with nothing in it
  doesn't show. **[user; empty sections: Claude's call]**
- Isolated ponds and fish counts to check are danger items here too, as on
  the bands; they open the pond's page. **[user]**
- Each row is the pond page's band with the pond's code and swatch at its
  start and a chevron; the full-colour squares and the pond chips go.
  **[user]**
- The tab's badge counts ponds in danger plus farm-wide danger items, from
  the same count as the list's "3 étangs en danger". **[user]**
- The section headings carry no number; the count lives on the badge only,
  so nothing on the tab seems to disagree with its rows. **[user, after
  review]**
- Nothing open: one line with a large tick. **[Claude's call]**

### Step 5: visit (decided 19/11)

A member walks the dike pond by pond, not the farm three times (water,
then samples, then conditions). The visit follows the walk. **[user]**

```
Before a visit                         During a visit
┌──────────────────────────────┐      ┌──────────────────────────────┐
│ Visite                       │      │ Visite depuis 08:40   5 / 11 │
│ À faire aujourd'hui          │      ├──────────────────────────────┤
│ 💧 4 relevés d'eau           │      │ ■ E1  Grossissement        › │ ← the pond page
│ ⚖ 2 échantillonnages         │      │   ✓ Relevé d'eau 28 °C pH 7,2│
│ ▣ 6 étangs à inspecter       │      │   ⚖ Échantillonnage L-E1   › │
│ Dernière visite : 12/03/2026,│      │   ✓ État : tout en ordre   › │
│ Rado                         │      ├──────────────────────────────┤
│ [ ▶ Commencer la visite    ] │      │ ■ E2  Grossissement        › │
└──────────────────────────────┘      │ ! Oxygène bas : 2 mg/L     › │ ← opens its fix
                                      │   💧 Relevé d'eau          › │
                                      │   ▣ État de l'étang        › │
                                      │   📝 Fuite côté sortie       │
                                      ├──────────────────────────────┤
                                      │ ■ E3  Vide                 › │
                                      │   ▣ État de l'étang        › │
                                      ├──────────────────────────────┤
                                      │ Observations                 │
                                      │ [ + Ajouter une observation ]│
                                      │ ▸ Biosécurité     7 rappels  │
                                      │ [   ⚑ Terminer la visite   ] │ ← pinned
                                      └──────────────────────────────┘
```

- Before a visit: what a visit today would cover (water readings,
  samples, ponds to inspect, by the same rules as the open visit's list),
  the last visit's date and member, and "Commencer la visite". Past
  visits live in Reports only. **[user]**
- During a visit: every active pond in code order. Its header line (code,
  swatch, phase or status) opens the pond page, where Signaler and
  Traitement live. The pond's band (the ponds list's: most urgent item
  and how many more) sits on its own line below and opens its fix. Then
  the checks: water, one sample per batch (batch code order), the
  inspection, then the pond's observations. A pond without fish has only
  its inspection. **[user; order within a pond: Claude's call]**
- A finished check stays in place with what it found: the reading's
  values, the sample's average and fish count, "tout en ordre" or the
  problems. Out of range or a problem shows in danger colour with its
  icon. Tapping it opens the form filled in, and saving records a
  correction. The top line counts finished checks (water, samples,
  inspections; observations don't count). **[user; correction and what
  counts: Claude's call]**
- The inspection starts with "Tout est en ordre": one tap saves the five
  checks as OK and goes back. OK / Problème per check stays below.
  **[user]**
- An observation may name a pond (a row of pond codes, none picked =
  farm-wide). It shows under its pond; farm-wide ones in "Observations"
  after the ponds. **[user]**
- Biosecurity is a folded reminder of the rules, no checkboxes: ticks
  that were never saved suggested a record that didn't exist. **[user]**
- "Terminer la visite" is pinned. The summary is written once, in the
  report draft. With checks left, the confirmation names them and the
  visit still ends; the report is unchanged in this step. **[user]**

