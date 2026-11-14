# Dobo — tilapia pond farm tracker

Offline-first Android app for a family association in Madagascar that raises Nile tilapia in ponds. It replaces the paper production log and produces the **visit report** the family reads after each farm visit. A web console (SPEC F16) built from the same code lets admins found and manage the association.

Source handbook (French): `Dossier_Elevage_Tilapia_Etangs.docx`. `docs/DOMAIN.md` is its distilled, authoritative form; where the two disagree, ask the user.

## Read before working

- `docs/SPEC.md`: users, roles, features, screens, sync design, scope, milestones. Read before building or changing any feature.
- `docs/DOMAIN.md`: growth phases, thresholds, formulas, alert rules, checklists. Read before touching a calculation, an alert, or any number shown to a farmer.

## Non-negotiables

1. **Offline-first** on the phone. Every phone feature works with no network. On the phone, the local database is the source of truth; the server is a sync hub. A saved record survives sync, app updates, logout and crashes. Losing farm data is the one unforgivable bug. The web console is online only, but writes records by the same rules (2.) through the same sync push.
2. **Append-only records.** Daily logs, readings, samples, treatments, sales: a correction is a new record carrying `supersedes_id`; a deletion is a tombstone record. This keeps the traceability log intact and makes sync merge-free. See SPEC §Sync.
3. **Field-worker screens** are for someone who has never used a phone: one task per screen, touch targets ≥ 56dp, icons plus numbers, numeric keypad, every field optional except the number being recorded, nothing to type in free text. Entering a day must be faster than writing the paper sheet.
4. **Farming numbers live in `lib/domain/config.dart`**, each with the value and source line from DOMAIN.md. Screens, alerts and calculations read them from there; admins can override per site.
5. **Domain logic is pure Dart in `lib/domain/`** (no Flutter imports, no database), written test-first. Every formula in DOMAIN.md has a unit test, including its edge cases (zero fish, missing sample, negative gain).
6. **No money in v1.** No prices, costs or profit. Sales record quantity, form and customer; the schema stays open to adding price later.
7. **Photos are optional and scarce.** Compress on capture, keep on device, upload only the ones a user marks. See SPEC §Photos.

## Stack

Flutter, Drift, Supabase and a custom sync were chosen by the user; the packages named for state, routing, i18n and PDF are Claude's planning defaults.

- Flutter (stable), Dart with sound null safety, Android for the app and Flutter Web for the console (`lib/main_web.dart`). Phone-only code (Drift native, photo files, backup, `path_provider`) stays out of the web build through conditional imports. Phones are low-end and a few years old: test on a 2 GB RAM emulator, keep the APK moderate in size (a well-chosen package is fine; it needn't be minimal), avoid heavy animations. **[Claude's call]** `minSdk` 26 (Android 8).
- Local database: SQLite via Drift (`drift`, `drift_flutter`), with versioned schema migrations and a migration test per version.
- Backend: Supabase (`supabase_flutter`: Postgres, Auth, Storage). Row-level security enforces roles server-side; the app hides what a role can't do, the server refuses it.
- Sync: a custom push/pull engine in `lib/sync/` (SPEC §Sync), no third-party sync service.
- Web hosting: the console's static build on Cloudflare Pages (`docs/deploy.md`).
- State: Riverpod. Routing: `go_router`.
- i18n: `flutter_localizations` + ARB files, locales `fr` and `mg`. Every user-facing string comes from the ARB files. Flutter's Material and Cupertino localizations don't include Malagasy, so `mg` needs fallback delegates that serve French for built-in widget strings.
- IDs: `uuid` package (v7). Photos: `image_picker` + `flutter_image_compress`.
- PDF and sharing: `pdf` + `printing`, `share_plus` for visit reports, traceability sheets and paper sheets.
- Charts: `fl_chart`, animations off (`duration: Duration.zero`), behind `lib/features/common/mini_chart.dart`.
- Tests: `test` for domain and sync, `flutter_test` for widgets, Drift's in-memory database for repository tests.

## Layout

```
lib/domain/           pure Dart logic + config.dart (thresholds, rates, durations)
lib/db/               Drift tables, DAOs, migrations
lib/sync/             push/pull engine, sync status
lib/features/<name>/  screens, widgets and providers for one feature
lib/console/          the web console: its pages, layouts and server data layer
lib/l10n/             app_fr.arb, app_mg.arb
supabase/             SQL migrations, RLS policies
test/                 mirrors lib/
docs/                 SPEC.md, DOMAIN.md
```

Code generation (Drift, Riverpod, l10n): `dart run build_runner build --delete-conflicting-outputs` after changing tables or annotated providers. After any table change, bump `schemaVersion`, write the migration, and run `dart run drift_dev make-migrations`; commit the new `drift_schemas/` snapshot and the generated migration tests in `test/db/` (generated from schema v2 on).

## Glossary

Use these words in code, translation keys and conversation. The French term is what appears on paper sheets and in the handbook.

| Term | French | Meaning |
|---|---|---|
| Association | association | The whole family business; the top-level tenant. |
| Group | branche | A family branch. Members belong to exactly one group. |
| Member | membre | A family representative with an account; does farm visits. |
| Worker | ouvrier | Feeds and watches fish daily. Usually has no account; recorded as a `Person`. |
| Site | site | A farm location containing ponds. |
| Pond | étang / bassin | One water body with a structure type and a role (SPEC §Ponds). |
| Batch | lot | Fingerlings stocked together; the unit of traceability from stocking to sale. A batch can span ponds after sorting. |
| Phase | phase | Growth stage set by average weight (DOMAIN §Phases). |
| Daily log | journal | One pond-day: feed given, leftovers, deaths, warning signs. |
| Water reading | relevé d'eau | Temperature, pH, oxygen, colour for a pond at a time. |
| Sample | échantillonnage | Weighing 30–50 fish to get average weight. |
| Biomass | biomasse | Estimated live fish weight in a pond or batch. |
| FCR | IC (indice de conversion) | Feed given ÷ weight gained. |
| Visit | visite | A member's trip to the site; groups the checks done that day. |
| Visit report | rapport de visite | The auto-built summary of a visit, shared with all members. |
| Transcription | saisie des fiches | A member entering workers' paper sheets into the app. |

## Conventions

- **Units:** store fish and feed weights as integer grams; display kg or g. Area in m², depth in m, temperature °C, oxygen mg/L.
- **Time:** store UTC plus the device timezone; display `dd/mm/yyyy`, zone `Indian/Antananarivo`. Device clocks drift, so the server also stamps `server_received_at`; ordering and "since last visit" use the recorded date the user entered, not the clock.
- **IDs:** UUIDv7 generated on the device.
- **Who:** every record stores `entered_by` (the account) and, when different, `observed_by` (the `Person` who saw it, e.g. the worker whose paper sheet is being transcribed).

## Working

Build milestone by milestone (SPEC §Milestones). A milestone is done when its features pass their tests and work on an Android emulator in airplane mode, then sync correctly once the network is back. Console work is checked in a browser against the local server, and what it writes must then reach a phone by sync.
