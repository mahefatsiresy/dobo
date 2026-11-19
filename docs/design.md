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
3. **The pond tag is the anchor.** On every list a pond starts with its
   code on its colour, like the stake on the dike.
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
- The pond tag on a list row is a **stake**: a 64 dp wide strip of the
  pond's colour down the row's left edge, the code centred in Bold.
  Elsewhere (alert rows, page headers) it is a 56 dp square with 4 dp
  corners.
- Buttons, inputs and dialogs: 8 dp corners. Buttons are 56 dp tall:
  filled ink for the main action, outlined ink for the others.

## Building blocks

In `lib/theme/` (look) and `lib/features/common/` (widgets):

- `PondTag` (square) and `PondStake` (list strip).
- `AttentionBand`: danger (filled `danger`, white text and icon) or warning
  (`warningFill`, 4 dp `warning` left edge, ink text, `warning` icon).
- `EstimatedLabel`: `≈ value` on screen, the word kept for reports.
- Added when step 2 first needs them: section header, action tile.

## Steps

| Step | Screen | Status |
|---|---|---|
| 0 + 1 | Foundation, ponds list | planned: `docs/superpowers/plans/2026-11-19-design-ponds-list.md` |
| 2 | Pond detail | decided below; plan after step 1 merges |
| 3 | Worker home and daily log | own round of questions first |
| 4 | Alerts | " |
| 5 | Visit | " |
| 6 | Reports | " |
| 7 | Batches, feed and the other "More" forms | " |
| 8 | Web console (takes the colours and type) | " |

Each step is one branch, merged locally after the user has seen
screenshots from seeded demo farms on the host and on the test phone.

### Step 1: ponds list (decided)

- Code order (E1, E2…): people find a pond by its stake.
- Above the list, one line each: today's total ration across ponds
  (`≈`), and how many ponds have a danger band.
- A stocked pond's row:

  ```
  ┌────────────────────────────────────────────┐
  │ ⚠  Oxygène bas, et 1 autre alerte          │ ← band, only when needed
  ├──────┬─────────────────────────────────────┤
  │      │ Grossissement            ≈ 2,4 kg   │ ← ration: the loud number
  │  E1  │ ≈ 1 240 poissons         ✓ Journal  │
  │      │ ≈ 186 kg, 150 g                     │
  └──────┴─────────────────────────────────────┘
  ```

  - The band names the most urgent item (isolated, inconsistent count, then
    alerts in alert order) and how many more.
  - Phase replaces role and structure; density shows only out of range.
  - When the pond should not be fed today (pre-harvest fast, low oxygen,
    surface swimming), the ration's place shows the stop-feeding sign
    instead, and the pond adds nothing to the total. **[Claude's call]**
  - Tapping anywhere opens the pond.
- Empty, preparing and ready ponds: one line with the stake, the status
  and the next prep step.
- Admins add a pond from a plain last row, not a floating button.

### Step 2: pond detail (decided, to fine-tune after step 1)

- Top: tag, phase and status; the attention bands; today (ration as the
  loud number, the daily log tick).
- Middle: each batch with its figures and growth, the latest water
  reading, the charts, the health history.
- "Journal du jour" is a bar pinned to the bottom.
- Stocking, water, sample, transfer, problem, treatment, prep and release
  are a grid of icon tiles, 2 per row, showing only those that apply.
- Edit and archive move to the app bar's ⋮ menu.
