# Product spec — Dobo

Farming numbers and rules referenced here (thresholds, rates, durations, formulas) are defined once in `DOMAIN.md`. Items marked **[Claude's call]** were decided during planning without the user; they can be revisited.

## 1. Why this exists

A family association farms tilapia in ponds in Madagascar. Workers on site feed and watch the fish daily and write on paper. Once or twice a week a member of the association visits, does the checks, and reports back to the family. The family's first question after a visit is "what's the report, what did you see?"

Today the paper log can't calculate anything: no biomass, no feed ration, no FCR, no early warning. Records are scattered and traceability for buyers (Annex C of the handbook) is hard to produce.

**Success:** after each visit, every member can read a clear report built from that visit's data and the workers' notes; workers' and members' records are never lost, even with no network for days; the farm follows the handbook's routines (sampling, water checks, prep, quarantine) because the app reminds them.

## 2. Goals, non-goals, anti-goals

**Goals (v1)**
- Record everything the handbook's production log, weekly sheet and batch sheet ask for (Annexes A, B, C).
- Calculate biomass, ration, phase, FCR, survival, density and prep doses automatically.
- Raise alerts and due tasks from the rules in DOMAIN §Alert rules.
- Build a visit report automatically and share it with all members.
- Work fully offline; sync when a connection appears.
- Be usable by a newly trained worker with no prior phone experience.

**Non-goals (v1)**
- Money: prices, costs, income, profit sharing between groups. (Planned later; keep the schema open.)
- Sensors, automatic feeders, hardware integration.
- A web dashboard. Members use the phone app.
- Disease diagnosis or treatment advice.
- Bulk photo storage.

**Anti-goals: failure even if it technically works**
- A record entered offline is lost or silently overwritten.
- Entering a day in the app takes longer than writing the paper sheet.
- The worker screen needs reading long text or typing.
- The report shows estimated numbers (biomass, live count) as if they were exact.

## 3. People and roles

Structure: **Association → Group (family branch) → Member.** Each member belongs to one group. Workers are `Person` records with no account unless trained.

| Role | Who | Can do |
|---|---|---|
| `worker` | The one trained worker with a phone | Daily log for assigned site's ponds; view pond status and today's tasks. Nothing else. |
| `member` | Family representatives | Everything a worker can, plus transcription, visits, water readings, samples, observations, treatments, pond prep, feed stock, batch stocking and transfers, read all reports. |
| `sales` | A permission flag on selected members | Record harvests and sales; manage customers. |
| `admin` | One or more members | Manage sites, ponds, groups, people, accounts, roles, settings and threshold overrides. |

`sales` and `admin` are flags added to a member, not separate accounts. Permissions are enforced by Supabase RLS on the server and by hiding UI on the device. Groups are for attribution and report display only: they never limit what a member sees or edits.

## 4. Data model

Every synced table carries: `id` (UUIDv7), `association_id`, `entered_by`, `observed_by` (nullable `Person`), `recorded_at` (the date/time the user says it happened), `created_at_device`, `device_id`, `server_received_at`, `server_seq`. Event tables add `supersedes_id` and `is_tombstone`.

**Reference entities (editable, last-write-wins):**
- `Association`, `Group`, `Member` (account, group, flags), `Person` (workers and others; optional link to a Member).
- `Site`: name, location note. v1 runs one site: the app creates it at setup and hides site pickers; the schema keeps `site_id` everywhere so more sites can be added later.
- `Pond`: site, code (short, painted on a stake: "E1"), colour tag for worker screens, structure type (defaults to `earth`, editable to `tank` or `cage`), role, water supply type, length, width, surface (computed, overridable), depth inlet/outlet, status (`empty`, `preparing`, `ready`, `stocked`, `isolated`): a pond holding fish shows `stocked` and one without shows `empty`, derived from its records; `preparing` and `ready` are set by hand on a pond without fish; `isolated` is set and lifted only by health events (F9).
- `Batch`: code, species/strain, hatchery, certificate number, monosex flag, stocked date, initial count, initial average weight, planned harvest date, status (`quarantine`, `active`, `harvesting`, `closed`).
- `Customer`: name, type (market, restaurant, supermarket, exporter, individual), contact.
- `Settings`: per-site overrides of `config.dart` values.

**Event records (append-only):**
- `Stocking`: batch into pond, count, average weight, acclimatised (yes/no).
- `Transfer`: batch from pond A to pond B, count, average weight (sorting by size or quarantine release).
- `DailyLog`: pond, date, feed given (g), feed lot, number of feedings, leftover (`none`, `some`, `lots`), ate-fast flag, deaths count, death appearance signs, warning signs, water colour, optional note.
- `WaterReading`: pond, time, temperature, pH, oxygen, colour, water renewed (%).
- `Sample`: batch, pond, fish count, total weight → average weight.
- `Observation`: pond or site, category (dike, predators, inlet screen, nets, fence, theft, other), text, optional photo.
- `HealthEvent`: pond, suspected issue, signs, action taken (`isolated`, `technician_called`, `released`).
- `Treatment`: pond, batch, product, dose, date, advised by.
- `PrepStep`: pond, step (DOMAIN §Pond preparation), done date, dose used.
- `FeedDelivery`: feed type/phase, pellet size, protein %, kg, manufacture date, supplier → creates a feed lot. `FeedDiscard`: lot, kg, reason.
- `Harvest`: batch, pond, date, count, total weight, partial/final.
- `Sale`: harvest or batch, date, customer, weight, form (DOMAIN §Harvest), delivery note. No price in v1.
- `Visit`: site, member, start/end, links to the records entered during it; `VisitReport` (see §6).

**Derived, never stored or synced:** live count, biomass, phase, ration, FCR, survival, density, feed stock on hand, alerts, tasks. Recomputed from records by `lib/domain/`.

## 5. Features

### F1. Farm setup (admin)
Create site, ponds and people. Pond setup computes surface from length × width and shows DOMAIN §Ponds design guidance as soft warnings. Each pond gets a code and a colour so workers recognise it on screen and on paper.

### F2. Batch lifecycle (member)
- **Stock a batch:** pick a pond that is `ready` (warn, not block, if prep is incomplete), enter hatchery, certificate, count and weight. Show the resulting density against the structure's range and an acclimatisation reminder. New batches start in `quarantine` when placed in a quarantine pond.
- **Transfer / sort:** move part or all of a batch to another pond. Blocked from an `isolated` pond.
- **Phase:** shown automatically from the latest sample, with recommended feed, pellet size and feedings/day.
- **Close:** a final harvest closes the batch and produces the traceability sheet (F12).

### F3. Daily log (worker, and members)
The most-used screen; designed for the worker.
1. Home shows today's ponds as big coloured tiles with their code; a tick on ponds already logged today.
2. Tap a pond → one screen: feed given (number pad, kg, with today's suggested ration shown as a big number to aim for), leftover (3 pictograms), deaths (number pad, default 0), warning signs (pictogram grid, optional), water colour (5 colour swatches, optional).
3. Save → green confirmation, back to tiles.

No typing, no navigation beyond these two levels. Large icons, Malagasy labels. A note field exists but is never required.

### F4. Transcription (member)
Enter workers' paper sheets quickly. A grid for one site and one week: rows are days, columns are ponds, each cell takes feed kg and deaths, with signs as an optional tap-through. `observed_by` is set to the worker named on the sheet. Days already logged on the worker's phone show their values so the member can spot gaps without double-entering.

### F5. Visit (member)
Starting a visit groups everything entered until the member ends it. Checklist for the visit:
- water reading for each stocked pond;
- sample for each batch that is due;
- pond and dike condition (dikes, inlet screens, predator nets, fence, grass), each OK / problem + note;
- biosecurity reminders (DOMAIN §Biosecurity);
- free observations, optional photo;
- the member's own summary text.
Ending the visit builds the visit report (F8).

### F6. Pond and batch dashboard (all)
Per pond: batch, phase, estimated live count, estimated biomass, today's suggested ration and feedings/day, latest water reading with out-of-range values in red, days since last sample, last period FCR with trend arrow, survival, density, open alerts. Charts: average weight over time, deaths per day, FCR per sample.

### F7. Alerts and tasks (all)
A single list of open alerts and due tasks from DOMAIN §Alert rules, sorted danger first, filterable by pond. Each links to the screen that resolves it (a sample due opens the sample form). Workers see only tasks they can act on (feeding guidance, pre-harvest fast, stop-feeding advice).

### F8. Visit report (member writes, everyone reads)
Built automatically when a visit ends; the member reviews, adds the summary, and publishes. After sync, every member sees it in a reports list (newest first, unread marked). Sections:
1. Header: site, date, member, group, period covered (since the previous report).
2. Summary: the member's text.
3. Alerts: open danger and warning alerts.
4. Health: deaths per pond in the period (worker records included, with who observed), warning signs, health events, treatments.
5. Water: latest reading per pond, out-of-range flagged.
6. Growth: per batch average weight, estimated biomass, period FCR and trend, survival. Estimated values labelled "estimated".
7. Feed: given in the period per pond, stock on hand, days of stock left, lots ageing.
8. Next: sample dates, harvest dates, quarantine releases, prep steps due.
9. Observations and photos.
Export as PDF and share via any installed app (e.g. WhatsApp) without needing the server.

### F9. Health (member)
Record a health event: pick signs, mark the pond `isolated` (blocks transfers out, shows a red banner on that pond everywhere), log who was called, record treatments. Information cards from DOMAIN §Health. Release isolation with a new event.

### F10. Pond preparation (member)
Per pond, the DOMAIN §Pond preparation checklist with doses computed from the pond's surface, waiting timers (drying, rest) and a final "ready to stock" state.

### F11. Feed stock (member)
Record deliveries (creating feed lots with manufacture date) and discards. Daily logs draw from a lot (default: oldest usable lot of the right type). Stock on hand, days remaining and lot age alerts.

### F12. Harvest, sales, traceability (sales role)
- Pre-harvest: set a planned harvest date; triggers the fasting alert.
- Harvest: count, total weight, partial or final.
- Sale: customer, weight, form, linked to the harvest and so to the batch.
- Traceability sheet per batch (Annex C): batch, stocking date, strain, origin and certificate, initial count and weight, pond history, treatments, harvest weights, cycle FCR, survival, customers. PDF export.

### F13. Paper sheets (member)
Print or PDF-export blank sheets for workers that mirror F3 and F4 exactly: pond codes and colours pre-filled, a row per day, boxes for feed and deaths, the warning-sign and water-colour pictograms to tick. The paper and the transcription grid have the same layout so copying is mechanical.

### F14. Accounts and administration (admin)
Invite members, assign group and flags, create the worker's account, deactivate accounts. Edit per-site setting overrides with the DOMAIN value shown beside each.

### F15. Exports (member)
Annex A production register and Annex B weekly sheet as PDF and CSV, for any date range and pond.

## 6. Navigation

- **Worker:** Home (pond tiles + today's tasks) → Daily log. That's all.
- **Member:** tabs for Ponds (dashboard), Visit, Alerts, Reports, More (transcription, batches, feed, prep, health, sales if flagged, exports, paper sheets, admin if flagged, sync status).

## 7. Sync

Design goal: a phone can be offline for weeks, several phones record the same ponds, and nothing is ever lost or overwritten.

- **Local first:** writes go to SQLite immediately and are marked `pending`. The UI never waits on the network.
- **Push:** when online (and on app open, on resume, every few minutes while online, and on a manual "sync now"), pending rows are sent in batches. The server upserts by `id`, so retries are idempotent. Confirmed rows become `synced`.
- **Pull:** the client asks for rows with `server_seq` greater than its last cursor, for its association, and applies them.
- **Event records** never conflict: they are only inserted. Corrections and deletions arrive as new rows (`supersedes_id`, `is_tombstone`); readers take the latest non-superseded version.
- **Reference entities** (ponds, batches, people, customers, settings) use last-write-wins per row by `server_seq`. Only admins and members edit them, so conflicts are rare; the losing version stays in an audit table.
- **Duplicates across phones** (a worker and a member both logging the same pond-day): both kept, and the dashboard and report flag "two daily logs for E1 on 12/03" for a member to resolve by superseding one.
- **Permissions:** RLS rejects rows the role can't write. A rejected row stays on the device, marked `rejected` with the reason, visible in sync status. It is never silently dropped.
- **Auth offline:** first login needs network. The session persists, and the app keeps working offline indefinitely. Role changes apply at next sync.
- **Sync status** is always visible: a small badge with pending count, and a screen with last sync time, pending, rejected, and a "sync now" button.
- **Backup:** export the full local database as a file and share it (cable, Bluetooth, any app), and import it on another phone, for a phone that breaks or can't reach the network for a long time.

## 8. Photos

- Optional on observations, health events and visit reports.
- Compressed on capture **[Claude's call]**: long edge 1280 px, JPEG quality ~70, target ≤ 250 KB.
- Stored in the app's files on the device. Only photos marked "upload" go to Supabase Storage, subject to a per-association cap set by an admin.
- Reports include uploaded photos; local-only photos appear only on the phone that took them.

## 9. Language and accessibility

- French and Malagasy from day one. Default language follows the role (Malagasy for `worker`, French for members); every user can switch to their preferred language in settings, and that choice is stored on their account and follows them across phones.
- Worker screens use pictograms for every option, with an optional audio label later.
- Numbers: decimal comma display (`12,5 kg`), number pad input.
- High contrast; must be readable outdoors in sunlight.

## 10. Future (design must not block)

- Money: feed prices, fingerling costs, sale prices, profit per batch and per group.
- Several sites (the schema already supports it; v1 hides it).
- Water sensors and automatic readings.
- Voice notes for workers.

## 11. Milestones

Each ends with tests passing and an airplane-mode test on an Android emulator (CLAUDE.md §Working).

| # | Milestone | Contents |
|---|---|---|
| M0 | Scaffold | Flutter app (Android), `flutter_lints`, Riverpod, go_router, l10n skeleton (fr, mg with fallback delegates), Drift database with sync columns, folder layout |
| M1 | Domain core | `config.dart`, all DOMAIN formulas and alert rules as pure Dart functions with tests |
| M2 | Farm setup | F1, F2 (local only) |
| M3 | Recording | F3, F4, F5 (without report), F9, water readings, samples |
| M4 | Accounts and sync | Supabase schema and RLS, auth, roles, F14, push/pull, sync status, backup export/import |
| M5 | Guidance | F6, F7 |
| M6 | Visit report | F8 with PDF and share |
| M7 | Operations | F10, F11, F12 |
| M8 | Paper and exports | F13, F15, Malagasy translation review, field test with the worker |

## 12. Open questions for the user

1. Lowest Android version among the members' and worker's phones (assumed Android 8).
