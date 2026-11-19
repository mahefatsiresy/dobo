# Field test with the worker

M8 ends with the app tried on the farm by the worker who will use it every
day. The point is to find out, before the app replaces the paper log, whether:

- the worker can record a day on the phone without help, and faster than on
  paper (SPEC §2 anti-goal), on the screens of design step 3
  (`docs/design.md`): a normal day is the feed, the leftover and Save on
  one screen; signs, water colour and feedings sit behind their own
  buttons;
- each pictogram means to the worker what the app thinks it means;
- the paper sheet copies into the transcription grid box by box.

Run it over two visits about a week apart. One member runs it and takes the
notes. Write the notes in this file's tables (a copy, or a printout).

## Before the first visit

- A release APK built from `main` (design step 3 or later) against the
  hosted project (`docs/deploy.md`), on the worker's phone, signed in with
  the worker's account. Check that the worker home shows the ponds holding
  fish and "0 / N vita" at the top.
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
time: finding the pond, typing the feed, closing the number pad, the
leftover, Save, or (on a pond with something to report) finding the signs
or the colour.

Watch in particular:

- After typing the feed, does the worker find Save ("Tehirizo") with the
  number pad still open, or close the pad first, or press back and lose
  the day?
- Does the worker read the ration at the top (the bowl and the kg) as the
  amount to give?
- After saving, does the worker see the tick on the tile and the count
  at the top ("2 / 5 vita") go up?

### 1b. A day with something to report (timed)

On one pond, ask the worker to record a day where they saw a warning sign
and noticed the water colour (choose them with the worker, from what they
see that day, or pretend). The signs are behind **Famantarana**, the colour
behind **Loko ny rano**, the number of feedings behind **Impiry**; each
opens its own page with a large **Vita** button.

| Pond | Phone (s) | Found Famantarana alone? | Found Loko ny rano alone? | Pressed Vita, or back? |
|---|---|---|---|---|
| | | | | |

Then ask for a day with deaths: once the number is above 0, **Endrika**
(what the dead fish looked like) appears beside it. Note whether the worker
notices it.

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
| 22 | Feed bowl (the amount to give) | | |
| 23 | Don't feed (crossed fork and knife) | | |
| 24 | Tick on a pond tile (done today) | | |

Numbers 1–21 are the ones printed on the paper sheet; 22–24 are on the
phone only (the worker home and the daily log).

For 22: at small sizes the bowl can look like a helmet. If the worker
doesn't say "food" or "how much to give", mark it **no**.

For 23: also ask whether the sign is big enough to notice at a glance on
the daily log screen, where it is smaller than the ration on other ponds.

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
  - the screen icon, in `lib/features/common/pictograms.dart` (the feed
    bowl is `feedIcon` there; it is on screen only, so it has no paper
    outline);
  - the paper outline, in `lib/features/common/pictogram_paths.dart`. If the
    replacement is another Material icon, change `pictograms.dart` and rerun
    `tool/pictogram_paths.py` (its header says how). For your own artwork,
    replace the path by hand: an SVG path in a 24 × 24 box.
  Show the new one to the worker before printing more sheets.
- **Malagasy words:** correct them in `docs/mg-review.csv`, then import
  (README, "Malagasy review").
- **Phone slower than paper:** note the slow step in an issue; it's a
  product question for the family before the app replaces paper.
- **Save lost under the number pad, or signs and colour not found behind
  their buttons:** note it with the step; it decides whether the daily
  log changes before the app replaces paper (`docs/design.md` §Step 3).
