# Field test with the worker

M8 ends with the app tried on the farm by the worker who will use it every
day. The point is to find out, before the app replaces the paper log, whether:

- the worker can record a day on the phone without help, and faster than on
  paper (SPEC §2 anti-goal);
- each pictogram means to the worker what the app thinks it means;
- the paper sheet copies into the transcription grid box by box.

Run it over two visits about a week apart. One member runs it and takes the
notes. Write the notes in this file's tables (a copy, or a printout).

## Before the first visit

- A release APK built against the hosted project (`docs/deploy.md`), on the
  worker's phone, signed in with the worker's account. Check that the worker
  home shows today's ponds.
- Two weeks of paper sheets printed for every pond (Plus → Fiches papier,
  2 weeks, Imprimer), and a pen.
- A watch or a second phone for timing.
- Airplane mode on the worker's phone for the whole first visit: the farm
  may have no signal, and the test must hold without it.

## Visit 1: the phone and the pictograms

### 1. Recording a day (timed)

Ask the worker to record today for every stocked pond, first on paper, then
on the phone, without help. Time each one. Don't explain anything until both
are done.

| Pond | Paper (s) | Phone (s) | Help needed? What for? |
|---|---|---|---|
| | | | |
| | | | |
| | | | |

If the phone is slower than paper on most ponds, note which step takes the
time (finding the pond, typing the feed, the leftover, the signs, the colour,
saving).

### 2. The pictograms, one by one

Show each pictogram alone. On the phone that's the daily log screen; on paper
it's the legend number hidden by a finger. Ask "what does this mean?" and
write the worker's words in Malagasy. Mark it **yes** if the meaning matches,
**no** otherwise.

| # | Pictogram (app meaning) | Worker's words | Yes / no |
|---|---|---|---|
| 1 | Leftover: all eaten | | |
| 2 | Leftover: a little left | | |
| 3 | Leftover: a lot left | | |
| 4 | Not eating | | |
| 5 | Swimming at the surface | | |
| 6 | Staying near the banks | | |
| 7 | Swimming in circles | | |
| 8 | Abnormal colour | | |
| 9 | Skin wounds | | |
| 10 | Pale or swollen gills | | |
| 11 | Deaths in a group | | |
| 12 | Rubbing | | |
| 13 | Too much mucus | | |
| 14 | White spots | | |
| 15 | Bulging eyes | | |
| 16 | Bleeding fins | | |
| 17 | Water clear | | |
| 18 | Water light green | | |
| 19 | Water green | | |
| 20 | Water dark green | | |
| 21 | Water brown, cloudy | | |

The numbers are the ones printed on the paper sheet.

### 3. The words on screen

While the worker uses the phone, write down every Malagasy word they stop at,
misread, or would say differently. Those go into `docs/mg-review.csv`.

| Screen | Word on screen | What the worker would say |
|---|---|---|
| | | |

## Between the visits

The worker fills the paper sheet every day for a week, as well as (or
instead of) the phone.

## Visit 2: the paper sheet

A member copies the week's sheet into Plus → Saisie des fiches, page by page
(page E1 into column E1).

| Pond | Boxes on the sheet that had no place in the grid | Boxes left empty that the worker meant to fill |
|---|---|---|
| | | |

Then turn the phone's network back on, sync, and check on a member's phone
that the worker's days arrived.

## Afterwards

- **A pictogram marked no:** it needs new artwork. Draw or choose a
  replacement with the worker's description in mind, then change it in two
  places:
  - the screen icon, in `lib/features/common/pictograms.dart`;
  - the paper outline, in `lib/features/common/pictogram_paths.dart`. If the
    replacement is another Material icon, change `pictograms.dart` and rerun
    `tool/pictogram_paths.py` (its header says how). For your own artwork,
    replace the path by hand: an SVG path in a 24 × 24 box.
  Show the new one to the worker before printing more sheets.
- **Malagasy words:** correct them in `docs/mg-review.csv`, then import
  (README, "Malagasy review").
- **Phone slower than paper:** note the slow step in an issue; it's a
  product question for the family before the app replaces paper.
