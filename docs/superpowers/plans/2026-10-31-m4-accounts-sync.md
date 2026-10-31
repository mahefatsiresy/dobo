# M4: Accounts and Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phones sync through Supabase without ever losing or overwriting a record. Every user has an account with a role, a worker's phone opens straight onto the worker home, admins manage members, groups and per-site settings, and a phone's whole database can be exported and imported as a backup with no network.

**Architecture:** The server mirrors every synced Drift table in Postgres. A trigger stamps each write with a global `server_seq`, under an advisory lock per association, so seq order is commit order. Clients push through one RPC, `sync_push`, which upserts row by row: events are insert-or-ignore, reference rows are last-write-wins with the old version kept in `reference_history`, and each row is accepted or refused on its own. Clients pull each table with a `server_seq` cursor through PostgREST, under RLS. On the phone, `lib/sync/` holds a table registry, a row codec (SQLite ⇄ JSON), a `SyncApi` interface (Supabase implementation plus an in-memory fake for tests), the `SyncEngine` and a `SyncController` that decides when to sync. Accounts go through an `AuthGateway`, so widget tests run without a server.

**Tech Stack:** Flutter 3.47.8, Drift 2.35, flutter_riverpod 3, go_router 18. New: `supabase_flutter`, `share_plus`, `file_picker`, `path_provider` (direct). Server: Supabase CLI 2.122 (installed) on rootless podman, Postgres with RLS, pgTAP (`supabase test db`), one Deno edge function.

**Spec:** `CLAUDE.md`, `docs/SPEC.md` (§3 roles, §4 data model, §6 navigation, §7 sync, §9 language, F14, §11 M4). The decisions below are Claude's calls, made without the user, and can be revisited.

## Decisions (Claude's calls)

1. **Server for development: a local Supabase stack.** It runs with the installed Supabase CLI (`supabase start`) on rootless podman (the user's choice) (`DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock`, with `-x vector,logflare` if those containers fail). The app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `--dart-define-from-file=env/<name>.json`. `env/*.json` is gitignored and `env/example.json` is committed. The emulator reaches the host at `http://10.0.2.2:54321`. Moving to the hosted project is a final step the user runs (Task 14).
2. **Members and auth users are separate rows.** `members.id` is what `entered_by` stores, and the server-only column `members.user_id` links a member to `auth.users`. This is how a phone that already holds M2/M3 data gets claimed without rewriting anything: the association is created with the phone's existing association, site and placeholder user ids, and the placeholder user id becomes the founder's `members.id`.
3. **Sign-in.**
   - Members use email and password (8 characters or more).
   - Workers use a username and a 6-digit PIN typed on the number pad, confirmed by the user, stored as the auth user `<username>@ouvriers.dobo.invalid`.
   - Every account except the founder's is created by an admin through the `create-account` edge function, using the admin API with `email_confirm: true`, so no email is ever sent.
   - The founder signs up from the app. Email confirmation is off.
4. **First launch** shows a Welcome screen with four choices: sign in (member), sign in (worker), create the association, import a backup. Signing in or creating the association needs the network; importing a backup doesn't.
   - An M3 phone that already has a local session keeps working offline. Its sync screen offers "Créer le compte de l'association" until the phone is linked to an account.
5. **Only creating an account needs the network.** Editing a member (name, group, role, flags, language, active), groups and setting overrides are synced reference rows that work offline, like ponds. Deactivating a member sets `active = false`, and RLS then gives that account nothing. The auth user is left in place.
6. **Roles on the server (RLS).** Reads: any active member, worker included, can read every synced table of their association. Writes:

   | Table | insert | update |
   |---|---|---|
   | `daily_logs` | worker, member | — |
   | other event tables | member | — |
   | `batches` | member | member |
   | `visits` | member | member, own rows only |
   | `ponds` | admin | member (status changes come from health events) |
   | `sites`, `people`, `groups`, `setting_overrides` | admin | admin |
   | `members` | edge function only | admin; or the member themselves, `locale` only (trigger) |

   No client can delete. Event rows can't be updated (trigger). Neither is enforced in v1: limiting a worker to their assigned site (there is one site), and column-level limits on pond updates.
7. **No foreign keys between synced tables** on the server, only `association_id → associations`. Rows from different phones can arrive in any order, and sync must never refuse a row for that.
8. **Sequence and lock.** A `before insert or update` trigger on every synced table takes `pg_advisory_xact_lock(hashtext(association_id::text))`, then sets `server_seq = nextval('sync_seq')` and `server_received_at = now()`. Because writes in one association are serialised, a pull cursor can never skip a row that commits late with a lower seq. Each table has its own cursor on the phone (`pull_cursor:<table>` in `local_meta`).
9. **Last-write-wins and retries.** `sync_push` handles each kind of row as follows:
   - **Event rows:** `on conflict (id) do nothing`, and a retry gets the stored seq back.
   - **Reference rows:** upserted. The row being replaced is copied into the server-only `reference_history` table.
   - **Repeated write:** a reference row whose `(id, device_id, updated_at_device)` matches the current row, or any version in `reference_history`, was already applied once. It's acknowledged with the current seq and changes nothing, so a lost acknowledgement can't let an old edit overwrite a newer one when it's retried.
10. **The phone after a sync.**
    - Push runs before pull.
    - An accepted row becomes `synced` only if it hasn't been edited since it was read. The check is on `updated_at_device` for reference rows; events never change.
    - Pull inserts events if they're new, and overwrites a local reference row only when that row is `synced`. Local `pending` or `rejected` versions stay put.
    - A refused row stays on the phone as `rejected`, with the server's code and message. Refused rows go back to `pending` when a different member signs in on the phone, or when someone taps "Réessayer" on the sync screen.
11. **When sync runs:** on app start, on resume, every 5 minutes while the app is in the foreground, after sign-in, and on "Synchroniser". There's no connectivity package: a failed call means offline. Push sends 200 rows per call and pull fetches 500 rows per request.
12. **Logout** removes only `user_id` from `local_meta` and signs out of Supabase. Every row, the device id, `association_id` and `site_id` all stay. If rows are still pending, a dialog says how many and that they'll be sent at the next sync. Signing in afterwards must be with a member of the same association. On a phone holding another association's data, sign-in is refused and the user is pointed to the backup export.
13. **Role on the phone, offline.** `Session` gains `role`, `isAdmin` and `isSales`. They're read from the local `members` row when it exists. Before that row arrives, they come from `local_meta` (written at sign-in from the server's answer). An M3 phone that has neither counts as `member` + admin, because it's the founder's phone.
14. **Language.** Each member row stores `locale`, defaulting to `mg` for workers and `fr` for members, and the app applies it whenever the session changes. More gets a "Langue" item that edits the member's own row. The Welcome and sign-in screens have an FR | MG switch, and their strings exist in both ARB files.
15. **Backup.**
    - **Export:** `VACUUM INTO` a file `dobo-<dd-mm-yyyy>.sqlite` in the temp directory, shared with `share_plus`.
    - **Import:** `file_picker`. The backup is copied, then opened as an `AppDatabase` so any older schema is migrated, then attached.
    - **Merge, never replace:** events are insert-or-ignore. A reference row is taken when it's new, or when its `updated_at_device` is newer than the local one. Rows keep the `sync_state`, `device_id` and `entered_by` they had in the backup.
    - **Session:** a phone with no session takes the backup's association, site and user from its `local_meta`. Pull cursors and the device id are never copied. A backup from another association is refused before anything is written.
16. **Setting overrides** are rows `(site_id, key, value)` whose id is `uuid.v5(siteId, key)`, so two admins overriding the same key edit the same row (last-write-wins). Going back to the DOMAIN value sets `value` to null. `lib/domain/config_overrides.dart` lists every numeric field of `DomainConfig` (feeding guides excluded) as a key. Ranges become `.min` and `.max`, and maps get one key per enum value. `applyOverrides` ignores unknown keys, and values that would leave a range with min greater than max.

## Global Constraints

- Offline-first: no screen waits on the network except sign-in, creating the association and creating an account. Each of those shows "Connexion nécessaire" when the call fails offline.
- Sync, logout, sign-in and import never delete or overwrite a local event row, and never drop a local pending or rejected row. `sync_state`, `sync_error` and `local_meta` never leave the phone.
- Every server table carries the SPEC §4 sync columns, plus `server_seq bigint` and `server_received_at timestamptz`. Postgres types: `uuid` ids, `timestamptz`, `boolean`, `integer`, `double precision`, `text`. Enum sets are the same comma-separated text as on the phone.
- The anon key is the only key in the app. The service role key lives only in the edge function's environment and in the server tests' env vars.
- Schema change: `schemaVersion` 3 → 4. Write `from3To4` with `stepByStep`, run `make-migrations`, fill the generated v3→v4 data-integrity test (a v3 pond and daily log survive), and commit the snapshot and the generated files.
- `lib/domain/` stays pure Dart. Every string comes from the ARB files. Member screens are in French; Welcome, sign-in and anything a worker sees also need `app_mg.arb` entries.
- Touch targets ≥ 56 dp. Every save goes through `SaveOnce`, and every pushed screen has a working Back.
- `flutter analyze` is clean, and `flutter test` passes under the machine zone and under `TZ=UTC`. Server tests are tagged `server`, excluded by default in `dart_test.yaml`, and run with `flutter test --tags server` while the local stack is up. SQL tests run with `supabase test db`.
- Commits use a conventional prefix and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Branch: `feat/m4-accounts-sync`.
- The arm64 release APK stays under 25 MB.

## Review Focus

1. **A row edited while its push is in flight:** the edit stays `pending` and goes out at the next sync. It's never marked `synced` by the earlier acknowledgement. Test in Task 7.
2. **A push accepted by the server whose answer never arrives:** the retry creates no duplicate. A reference row retried after another phone changed it doesn't bring back the old version. Tests in Task 3 and Task 7.
3. **Two phones pushing at the same time:** neither phone's pull ever skips a row. The trigger holds the association's advisory lock until commit. Tests in Task 1 (the lock is taken) and Task 8 (two concurrent pushes, then each phone pulls every row).
4. **Signing in on a phone that holds unsynced records of another association:** refused with the backup hint, and no row or `local_meta` key changes. Test in Task 9.
5. **Weeks offline (5 000 pending rows), with the network dropping in the middle:** rows go out in batches of 200. Batches already accepted stay `synced`, the rest stay `pending`, and the next sync carries on. Test in Task 7.

---

### Task 1: Local Supabase and the synced tables

**Files:**
- Create: `supabase/config.toml` (via `supabase init`), `supabase/migrations/20261031000001_sync_tables.sql`, `supabase/tests/sync_tables_test.sql`, `env/example.json`
- Modify: `.gitignore` (`env/*.json`, `!env/example.json`, `supabase/.temp/`)

**Interfaces:**
- Produces (SQL):
  - Tables `associations(id uuid pk, name text not null, created_at timestamptz default now())`, `groups`, `members`.
  - The 13 synced data tables, named as in Drift (`sites`, `people`, `ponds`, `batches`, `visits`, `stockings`, `transfers`, `daily_logs`, `water_readings`, `samples`, `observations`, `health_events`, `treatments`) and `setting_overrides`. Each column has the same snake_case name as in Drift, minus `sync_state` and `sync_error`.
  - `groups`: `name`. `members`: `name`, `group_id`, `person_id`, `role text check (role in ('worker','member'))`, `is_admin`, `is_sales`, `active`, `locale`, `login`, plus server-only `user_id uuid unique references auth.users`. `setting_overrides`: `site_id`, `key`, `value double precision`. All three also carry the sync columns and `updated_at_device`.
  - `sequence sync_seq`; trigger function `stamp_sync()` (Decision 8) on every synced table, `groups` and `members` included.
  - Table `reference_history(id bigserial, table_name text, row_id uuid, row jsonb, replaced_at timestamptz default now())`, filled by a `before update` trigger on reference tables.
  - Trigger `refuse_event_update()` raising `event rows are immutable` on event tables.
  - `config.toml`: `[auth.email] enable_confirmations = false`.

- [ ] **Step 1: Start the stack.** `systemctl --user start podman.socket`, export `DOCKER_HOST`, `supabase init`, `supabase start`. Expected: it prints the API URL, anon key and service role key; put them in `env/local.json` (emulator URL `http://10.0.2.2:54321`) and `env/host.json` (`http://127.0.0.1:54321`). **If the stack can't start on podman, stop and ask the user. Don't swap in another backend.**
- [ ] **Step 2: Write the failing pgTAP tests.** In `sync_tables_test.sql`, as the postgres role:
  - Inserting two ponds gives increasing `server_seq` and a set `server_received_at`.
  - Updating a pond raises its `server_seq` and adds a `reference_history` row holding the old `code`.
  - After an insert in the same transaction, `exists(select 1 from pg_locks where locktype = 'advisory' and pid = pg_backend_pid())`.
  - `update daily_logs set deaths = 9` throws `event rows are immutable`.
  - `has_column` checks for every synced table's columns.
- [ ] **Step 3: Run to verify it fails.** `supabase test db` → FAIL (no tables).
- [ ] **Step 4: Implement** the migration, then `supabase db reset`.
- [ ] **Step 5: Run to verify it passes.** `supabase test db` → PASS.
- [ ] **Step 6: Commit** `feat(server): synced tables with server sequence, history and immutable events`

### Task 2: Roles, RLS and creating the association

**Files:**
- Create: `supabase/migrations/20261031000002_roles_rls.sql`, `supabase/tests/roles_test.sql`

**Interfaces:**
- Consumes: Task 1 tables.
- Produces (SQL):
  - `current_member() returns members` (security definer, stable): the active member row for `auth.uid()`, or null.
  - `is_member()`, `is_admin()`, `my_association() returns uuid`.
  - RLS is enabled on every table, with the policies in Decision 6.
  - Trigger `guard_member_update()`: a non-admin may change only `locale` and the sync stamps on their own row. Removing admin or active from the last active admin raises `last_admin`.
  - `create_association(p_association_id uuid, p_association_name text, p_group_id uuid, p_group_name text, p_member_id uuid, p_member_name text, p_locale text) returns void`, security definer. It inserts the association, the group and the founder (`member`, admin, `user_id = auth.uid()`, `login` = the auth email). It raises `already_member` if the caller has a member row, and `association_exists` if the id is taken.

- [ ] **Step 1: Write the failing pgTAP tests.** Set up three auth users (admin, member, worker) in one association and one user in another association. Switch users with `set local role authenticated; set local request.jwt.claims = '{"sub":"…"}'`. Assert:
  - The worker can insert a `daily_logs` row but gets `42501` inserting `water_readings` or updating a pond.
  - The member can insert a `samples` row and update a pond's `status`, but gets `42501` inserting a pond or a person.
  - The admin can insert a pond, a group and a setting override.
  - Nobody can delete.
  - The other association sees 0 rows of the first one.
  - A member deactivated by the admin then sees 0 rows.
  - The member can change their own `locale`, but changing their own `is_admin` raises.
  - Removing the only admin's `is_admin` raises `last_admin`.
  - `create_association` makes the caller an admin, and a second call raises `already_member`.
- [ ] **Step 2: Run to verify it fails.** `supabase test db` → FAIL.
- [ ] **Step 3: Implement** the migration, then `supabase db reset`.
- [ ] **Step 4: Run to verify it passes.** `supabase test db` → PASS.
- [ ] **Step 5: Commit** `feat(server): roles, row-level security and association creation`

### Task 3: The push RPC

**Files:**
- Create: `supabase/migrations/20261031000003_sync_push.sql`, `supabase/tests/sync_push_test.sql`

**Interfaces:**
- Produces:
  - `sync_push(p_table text, p_rows jsonb) returns table(id uuid, server_seq bigint, server_received_at timestamptz, error_code text, error_message text)`, security invoker, so RLS applies.
  - `p_table` must be one of the synced table names, otherwise it raises `unknown_table`.
  - It loops over the rows, each in its own `begin … exception when others` block, so a refused row returns its `SQLSTATE`/`SQLERRM` and the others still commit.
  - Rows go in with `jsonb_populate_record(null::public.<table>, row)`. Incoming `server_seq` and `server_received_at` are ignored, and the trigger sets them.
  - Events: `on conflict (id) do nothing`. Reference rows: Decision 9.

- [ ] **Step 1: Write the failing pgTAP tests.**
  - Pushing two daily logs as the worker returns two rows with a seq and no error.
  - Pushing the same two again returns the same seqs, and the count is still 2.
  - A batch of [a daily log, a water reading] pushed as the worker returns the log accepted and the reading with `error_code = '42501'`; the log is stored.
  - Pond P is pushed by device A (`updated_at_device` t1), then by device B (t2), then A's t1 version is retried: P keeps B's `code`, and the retry returns P's current seq.
  - `sync_push('auth.users', '[]')` raises `unknown_table`.
- [ ] **Step 2: Run to verify it fails.** `supabase test db` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(server): sync_push with per-row results, idempotent retries and last-write-wins`

### Task 4: Creating accounts (edge function)

**Files:**
- Create: `supabase/functions/create-account/index.ts`, `test/server/server_env.dart`, `test/server/create_account_test.dart`, `dart_test.yaml`
- Modify: `pubspec.yaml` (`supabase_flutter`)

**Interfaces:**
- Produces:
  - `POST /functions/v1/create-account` with body `{memberId, name, role: 'member'|'worker', login, secret, groupId?, personId?, isAdmin, isSales, locale}`.
  - The caller's JWT must belong to an active admin; otherwise 403 `not_admin`.
  - For a worker, the auth email is `<login>@ouvriers.dobo.invalid` and `secret` must be 6 digits. For a member, `login` is the email and `secret` has at least 8 characters. Otherwise 400 `bad_secret`.
  - A login already in use gives 409 `login_taken`.
  - It creates the auth user with `email_confirm: true`, inserts the `members` row with the caller's association, and answers 200 with that row as JSON.
- Produces (`server_env.dart`): `ServerEnv.fromEnvironment()`, which reads `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY`, and `Future<SupabaseClient> signedInClient(String email, String password)`.
- `dart_test.yaml`: `tags: {server: {}}` and `exclude_tags: server`.

- [ ] **Step 1: Write the failing server test** (`@Tags(['server'])`). The founder signs up and calls `create_association`. Then the founder creates worker `rakoto` with PIN `123456`, and a client can sign in as `rakoto@ouvriers.dobo.invalid` / `123456` and read the ponds. Creating `rakoto` again gives `login_taken`, a PIN `12ab56` gives `bad_secret`, and the worker calling the function gives `not_admin`.
- [ ] **Step 2: Run to verify it fails.** `supabase functions serve` in the background, then `flutter test --tags server test/server/create_account_test.dart` → FAIL (404).
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(server): create-account edge function for members and workers`

### Task 5: Schema v4 and the session's role

**Files:**
- Create: `lib/db/tables/groups.dart`, `members.dart`, `setting_overrides.dart`
- Modify: `lib/domain/types.dart`, `lib/db/database.dart`, `lib/db/session.dart`, `lib/db/repositories/setup_repository.dart`, `lib/db/repositories/providers.dart`, `test/helpers.dart`
- Test: `test/db/schema_v4_test.dart`, `test/db/setup_repository_test.dart`, generated v3→v4 tests

**Interfaces:**
- Produces:
  - `enum MemberRole { worker, member }` in `types.dart`.
  - Tables (`SyncedRow`, `ReferenceRow`):
    - `Groups` (`name`).
    - `Members` (`name`, `groupId` nullable, `personId` nullable, `role` `textEnum<MemberRole>`, `isAdmin` and `isSales` bool default false, `active` bool default true, `locale` text, `login` nullable).
    - `SettingOverrides` (`siteId`, `key`, `value` real nullable; null means "back to the DOMAIN value").
  - `Session` gains `final MemberRole role; final bool isAdmin; final bool isSales;` (Decision 13) and `bool get isWorker`.
  - `SetupRepository`:
    - `Stream<Session?> watchSession()` replaces `currentSession()` and re-emits when `local_meta` or `members` change.
    - `completeSetup({required String siteName, String? locationNote, Session? ids, MemberRole role = MemberRole.member, bool isAdmin = true})` uses `ids` when given.
    - `Future<void> writeSignIn({required String associationId, required String memberId, required String siteId, required MemberRole role, required bool isAdmin, required bool isSales})`.
    - `Future<void> clearUser()`.
  - `sessionProvider` becomes a `StreamProvider<Session?>`.
  - `appTest` gains `MemberRole role = MemberRole.member, bool isAdmin = true`.

- [ ] **Step 1: Write the failing tests.**
  - A members row round-trips.
  - `watchSession` reads the role from the members row when present, from `local_meta` when not, and gives member + admin when neither exists.
  - `clearUser` leaves `association_id`, `site_id`, `device_id` and every data row in place, and the session becomes null.
  - The v3→v4 data-integrity test keeps a pond and a daily log.
- [ ] **Step 2: Run to verify it fails.** `flutter test test/db/` → FAIL.
- [ ] **Step 3: Implement**, then `build_runner`, `make-migrations`, and `from3To4`. The existing tests must still pass with the stream session.
- [ ] **Step 4: Run to verify it passes.** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(db): schema v4 with groups, members and setting overrides; session carries the role`

### Task 6: Table registry and row codec

**Files:**
- Create: `lib/sync/sync_tables.dart`, `lib/sync/row_codec.dart`
- Test: `test/sync/row_codec_test.dart`

**Interfaces:**
- Produces:
  - `enum RowKind { reference, event }`
  - `class SyncTable { final TableInfo<Table, Object?> info; final RowKind kind; String get name => info.actualTableName; }`
  - `List<SyncTable> syncTables(AppDatabase db)` in push order: `groups, members, sites, people, ponds, batches, visits, setting_overrides, stockings, transfers, daily_logs, water_readings, samples, observations, health_events, treatments`.
  - `const localOnlyColumns = {'sync_state', 'sync_error', 'server_seq', 'server_received_at'}`.
  - `Map<String, Object?> toServer(SyncTable t, Map<String, Object?> sqliteRow)`: drops `localOnlyColumns`; turns bool columns 0/1 into `false`/`true` and date columns into UTC ISO-8601 strings, from each column's `DriftSqlType`.
  - `Map<String, Variable<Object>> fromServer(SyncTable t, Map<String, Object?> json)`: keeps only the table's columns (so the server-only `user_id` is dropped), parses dates to UTC `DateTime`, and sets `sync_state = 'synced'`.

- [ ] **Step 1: Write the failing tests.**
  - `syncTables(db)` names every table in `db.allTables` except `local_meta`; a test fails if a new table isn't registered.
  - A daily log with `ateFast: true`, `warningSigns: {rubbing}` and `recordedAt` 01/03/2026 12:00 UTC becomes `{'ate_fast': true, 'warning_signs': 'rubbing', 'recorded_at': '2026-03-01T12:00:00.000Z', …}` with none of the local-only keys.
  - The server's `'2026-03-01T12:00:00+00:00'` reads back as the same instant.
  - A JSON with an extra `user_id` key decodes without it.
- [ ] **Step 2: Run to verify it fails.** `flutter test test/sync/` → FAIL.
- [ ] **Step 3: Implement.** Read pending rows with `customSelect('SELECT * FROM "<name>" …')` so `row.data` has the raw SQLite values.
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(sync): table registry and SQLite ⇄ JSON row codec`

### Task 7: Sync engine

**Files:**
- Create: `lib/sync/sync_api.dart`, `lib/sync/sync_engine.dart`, `test/sync/fake_sync_api.dart`
- Test: `test/sync/sync_engine_test.dart`

**Interfaces:**
- Consumes: Task 6.
- Produces:
  - `abstract interface class SyncApi { Future<List<PushOutcome>> push(String table, List<Map<String, Object?>> rows); Future<List<Map<String, Object?>>> pull(String table, {required int afterSeq, required int limit}); }`
  - `class PushOutcome { final String id; final int? serverSeq; final DateTime? serverReceivedAt; final String? errorCode; final String? errorMessage; bool get accepted => errorCode == null; }`
  - `class SyncOffline implements Exception {}` and `class SyncSignedOut implements Exception {}`, thrown by `SyncApi` implementations.
  - `class SyncEngine { SyncEngine(AppDatabase db, SyncApi api, {int pushBatch = 200, int pullLimit = 500}); Future<SyncReport> run(); Future<int> retryRejected(); }`. `run` pushes then pulls (Decision 10) and stores `last_sync_at` once both are done. Progress already made is kept when it throws.
  - `class SyncReport { final int pushed, rejected, pulled; }`
  - `FakeSyncApi`: an in-memory server holding a global seq, insert-or-ignore for events, Decision 9 for reference rows, an optional `refuse(table, code)` rule, and `failAfterCalls(n)` that throws `SyncOffline`.

- [ ] **Step 1: Write the failing tests.** Two in-memory databases (phones A and B) share one `FakeSyncApi`.
  - A daily log on A syncs, then appears on B after B syncs. Both copies are `synced` with the same `server_seq`.
  - Pond E1 is renamed on A and on B offline. A syncs, then B, then A again: both phones show B's name, and the server's history holds A's.
  - Review Focus 1: a pond is edited between the push read and the acknowledgement (the fake's push callback edits it). After `run`, it's still `pending` with the new value, and the next `run` pushes it.
  - Review Focus 2: the fake accepts a push then throws `SyncOffline` instead of answering. The next `run` gives no duplicate on the server and every row ends `synced`.
  - Review Focus 5: 5 000 daily logs, with `failAfterCalls(10)`. `run` throws `SyncOffline`, 2 000 rows are `synced` and 3 000 `pending`. The next `run` finishes them.
  - With `refuse('water_readings', '42501')`: the reading ends `rejected` with `sync_error` containing `42501`, it's still in the table, and the daily log in the same sync is `synced`. `retryRejected()` returns 1 and sets it back to `pending`.
  - Pull doesn't overwrite a local `pending` pond.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** `flutter test test/sync/` → PASS.
- [ ] **Step 5: Commit** `feat(sync): push/pull engine with per-row rejection and safe acknowledgement`

### Task 8: Supabase transport and auth gateway

**Files:**
- Create: `lib/sync/supabase_sync_api.dart`, `lib/sync/auth_gateway.dart`, `lib/sync/supabase_auth_gateway.dart`, `lib/sync/server_config.dart`, `test/sync/fake_auth_gateway.dart`
- Modify: `lib/main.dart`
- Test: `test/server/sync_e2e_test.dart`, `test/server/schema_parity_test.dart`

**Interfaces:**
- Consumes: Tasks 2–4, 7.
- Produces:
  - `SupabaseSyncApi(SupabaseClient client) implements SyncApi`. Push is `rpc('sync_push', params: {'p_table': …, 'p_rows': …})`; pull is `from(table).select().gt('server_seq', afterSeq).order('server_seq').limit(limit)`. Socket and timeout errors become `SyncOffline`, and 401 or failed refresh becomes `SyncSignedOut`.
  - `class RemoteMember { final String id, associationId, associationName, siteId, name; final MemberRole role; final bool isAdmin, isSales; final String locale; }`
  - `abstract interface class AuthGateway { bool get hasSession; Future<void> signIn({required String email, required String password}); Future<void> signUp({required String email, required String password}); Future<void> signOut(); Future<RemoteMember> myMember(); Future<void> createAssociation({required String associationId, required String associationName, required String groupId, required String groupName, required String memberId, required String memberName, required String locale}); Future<Map<String, Object?>> createAccount(NewAccount account); }`
  - `class NewAccount`, holding the edge function's body fields.
  - `AuthFailed(String code) implements Exception`, for a wrong password or the server codes from Tasks 2 and 4.
  - `String workerEmail(String username) => '$username@ouvriers.dobo.invalid'`.
  - `server_config.dart`: `const supabaseUrl = String.fromEnvironment('SUPABASE_URL')`, likewise `supabaseAnonKey`, and `bool get serverConfigured`.
  - `main.dart` calls `Supabase.initialize` only when `serverConfigured`.
  - Providers `authGatewayProvider` and `syncApiProvider` (null when not configured), overridden with fakes in widget tests.

- [ ] **Step 1: Write the failing server tests.**
  - Parity: for each `syncTables` entry, every Drift column except `localOnlyColumns` exists in `information_schema.columns` with a matching type family.
  - End to end: two phones on two signed-in clients (admin, worker). The admin creates a pond and syncs; the worker syncs, logs a day and syncs; the admin syncs and sees the log, `entered_by` the worker's member id.
  - Review Focus 3: both phones push 100 rows at the same time (`Future.wait`), then each pulls, and each sees all 200 rows.
- [ ] **Step 2: Run to verify it fails.** `flutter test --tags server test/server/` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS; the default `flutter test` stays green without a server.
- [ ] **Step 5: Commit** `feat(sync): Supabase transport and auth gateway`

### Task 9: Welcome, sign-in, the association and the worker's locked app

**Files:**
- Create: `lib/db/repositories/account_repository.dart`, `lib/features/account/welcome_screen.dart`, `login_screen.dart`, `create_association_screen.dart`, `account_screen.dart`
- Modify: `lib/router.dart`, `lib/app.dart`, `lib/features/setup/` (removed; its screen becomes `create_association_screen.dart`), `lib/features/more/more_screen.dart`, `lib/features/daily_log/worker_home_screen.dart`, both ARB files
- Test: `test/db/account_repository_test.dart`, `test/features/account/account_test.dart`

**Interfaces:**
- Consumes: Tasks 5, 8.
- Produces:
  - `AccountRepository(AppDatabase db, SetupRepository setup, AuthGateway auth)` with:
    - `Future<void> signIn({required String login, required String secret, required bool worker})`: refuses with `AuthFailed('other_association')` before writing anything when `local_meta.association_id` is set and differs (Decision 12).
    - `Future<void> createAssociation({required String associationName, required String groupName, required String memberName, required String email, required String password, required String siteName, String? locationNote})`: reuses the local ids when a session exists (Decision 2).
    - `Future<int> pendingCount()`
    - `Future<void> signOut()`
  - Routes: `/welcome`, `/welcome/login?worker=1`, `/welcome/create`, `/more/account`.
  - Redirects:
    - No session: anything outside `/welcome…` goes to `/welcome`.
    - A worker session: anything except `/worker` and `/log/…` goes to `/worker`.
    - A member session: `/`, `/welcome…` and `/worker…` aren't redirected (members still reach worker mode from More).
  - The worker home hides its exit button when `session.isWorker`.
  - `DoboApp` sets the locale from the member row whenever the session changes (Decision 14).

- [ ] **Step 1: Write the failing tests** (with `FakeAuthGateway`).
  - Review Focus 4: the phone holds association A with pending daily logs, and the fake's member belongs to B. `signIn` throws `other_association`, and `local_meta` and the row counts are unchanged.
  - Signing in as a worker on an empty phone writes the session with the worker role; the app opens on `/worker` with no exit button and in Malagasy; `/ponds` redirects to `/worker`.
  - `createAssociation` on an M3 phone sends the existing association, site and user ids to the gateway.
  - `signOut` with 3 pending rows shows the dialog naming 3. After confirming, the app is on `/welcome` and all rows are still there.
  - Offline (the fake throws `SyncOffline`), the sign-in screen shows "Connexion nécessaire".
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(account): welcome, sign-in, association creation and the worker's locked app`

### Task 10: When to sync, and sync status

**Files:**
- Create: `lib/sync/sync_controller.dart`, `lib/sync/sync_status_repository.dart`, `lib/features/sync/sync_badge.dart`, `lib/features/sync/sync_screen.dart`
- Modify: `lib/app.dart`, `lib/features/shell/member_shell.dart`, `lib/features/daily_log/worker_home_screen.dart`, `lib/router.dart` (`/more/sync`), both ARB files
- Test: `test/sync/sync_status_repository_test.dart`, `test/features/sync/sync_test.dart`

**Interfaces:**
- Consumes: Tasks 7–9.
- Produces:
  - `enum SyncRunState { idle, running, offline, signedOut, unlinked, notConfigured }`.
  - `class SyncView { final SyncRunState state; final DateTime? lastSyncAt; }`.
  - `syncControllerProvider` (Notifier) with `Future<void> syncNow()`. Only one sync runs at a time; calls made while one runs return the running one. It runs at the times in Decision 11, with a 5-minute `Timer.periodic` cancelled when the app is paused.
  - `SyncStatusRepository(AppDatabase db)` with `Stream<({int pending, int rejected})> watchCounts()` and `Stream<List<RejectedRow>> watchRejected()`; `RejectedRow` has `table`, `id`, `recordedOrUpdatedAt`, `errorCode`, `errorMessage`.
  - The badge sits on the "Plus" tab and on the worker home app bar: a pending count, red when anything is rejected.
  - The sync screen shows the last sync time (`dd/mm/yyyy HH:mm`, Madagascar time), pending and rejected counts, the rejected list with French reasons for `42501` ("Votre rôle ne permet pas cet enregistrement") and `last_admin`, and the buttons "Synchroniser", "Réessayer les refusés", "Se reconnecter" (signedOut) and "Créer le compte de l'association" (unlinked).

- [ ] **Step 1: Write the failing tests.**
  - The counts follow inserts and state changes.
  - With a `FakeSyncApi` override, tapping "Synchroniser" clears the badge.
  - A refused row shows in the list with the role reason; "Réessayer" sets it back to pending.
  - Two `syncNow()` calls at the same time run the engine once.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(sync): sync triggers, status badge and sync screen`

### Task 11: Backup export and import

**Files:**
- Create: `lib/db/backup.dart`, `lib/features/sync/backup_actions.dart`
- Modify: `pubspec.yaml` (`share_plus`, `file_picker`, `path_provider`), `lib/features/sync/sync_screen.dart`, `lib/features/account/welcome_screen.dart`, both ARB files
- Test: `test/db/backup_test.dart`

**Interfaces:**
- Produces:
  - `Future<File> exportBackup(AppDatabase db, Directory dir)`
  - `Future<ImportResult> importBackup(AppDatabase db, File backup)` with `class ImportResult { final int added, updated; }`. It throws `BackupRefused('other_association' | 'not_a_backup')` before writing anything (Decision 15).
  - Providers `backupSharerProvider` and `backupPickerProvider`, wrapping `share_plus` and `file_picker` so tests can override them.

- [ ] **Step 1: Write the failing tests**, using files in a temp directory.
  - Exporting phone A, then importing into an empty phone B, gives B A's session (not A's device id) and every row, with the same `sync_state`.
  - Importing the same file twice reports 0 added the second time.
  - A pond edited later on B is kept over the backup's older version; an older one on B is replaced.
  - A backup from another association is refused, and B is unchanged.
  - A v3 backup (built with the generated v3 schema) is migrated and imported.
  - A text file is refused as `not_a_backup`.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(backup): export and import the phone's database`

### Task 12: Administration: members and groups (F14)

**Files:**
- Create: `lib/db/repositories/member_repository.dart`, `lib/features/admin/admin_screen.dart`, `members_screen.dart`, `member_form_screen.dart`, `groups_screen.dart`
- Modify: `lib/features/more/more_screen.dart` (Administration and Langue), `lib/features/ponds/ponds_screen.dart` and `pond_detail_screen.dart` (create and edit for admins only), `lib/router.dart` (`/more/admin/…`), `lib/features/people/` (admins only), ARB
- Test: `test/db/member_repository_test.dart`, `test/features/admin/admin_test.dart`

**Interfaces:**
- Consumes: Tasks 5, 8, 10.
- Produces:
  - `MemberRepository(AppDatabase db, Session session, AuthGateway auth)` with:
    - `Stream<List<Member>> watchAll()`, grouped by group then name.
    - `Future<void> update(String id, {required String name, String? groupId, required MemberRole role, required bool isAdmin, required bool isSales, required bool active, required String locale})`: offline, marks the row pending.
    - `Future<void> setOwnLocale(String locale)`.
    - `Future<String> create(NewAccount account)`: online, inserts the returned row as `synced`.
  - `GroupRepository` with `watchAll()`, `create(name)` and `rename(id, name)`.
  - Member form fields: name, group, role (Membre / Ouvrier), admin, vente, langue, actif. A new member also gets an email and password (≥ 8). A new worker gets a username and PIN (6 digits, number pad) and an optional linked person.
  - Non-admins see neither Administration, People, "Ajouter un étang" nor pond Edit.

- [ ] **Step 1: Write the failing tests.**
  - The admin creates worker "Rakoto" through the fake; it shows in the list under its group.
  - A 5-digit PIN keeps Save disabled.
  - Editing a member offline marks the row pending.
  - A member who isn't an admin doesn't see Administration or "Ajouter un étang".
  - Choosing "Malagasy" in Langue switches the app at once and marks the member row pending.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** → PASS.
- [ ] **Step 5: Commit** `feat(admin): members, accounts, groups and role-aware menus`

### Task 13: Per-site setting overrides

**Files:**
- Create: `lib/domain/config_overrides.dart`, `lib/db/repositories/settings_repository.dart`, `lib/features/admin/settings_screen.dart`
- Modify: `lib/domain/config.dart` (`copyWith`), the 8 feature files that read `DomainConfig.defaults`, `lib/router.dart`, ARB
- Test: `test/domain/config_overrides_test.dart`, `test/features/admin/settings_test.dart`

**Interfaces:**
- Produces:
  - `class ConfigKey { final String key; final String section; final num Function(DomainConfig) read; final DomainConfig Function(DomainConfig, num) write; final bool isInt; }`. `section` is the DOMAIN heading, e.g. `'§Water quality'`.
  - `final List<ConfigKey> configKeys`, with keys like `'rationRate.growout'`, `'temperatureC.min'`, `'densityPerM2.earth.max'`, `'minOxygenMgL'`.
  - `DomainConfig applyOverrides(DomainConfig base, Map<String, num> overrides)`.
  - `SettingsRepository(AppDatabase db, Session session)` with `Stream<Map<String, num>> watch()` (null values left out), `set(String key, num value)` and `clear(String key)`. Both upsert the row with id `uuid.v5(siteId, key)`; clearing sets `value` to null, so the clear syncs like any edit.
  - `domainConfigProvider` (`StreamProvider<DomainConfig>`) replaces every `DomainConfig.defaults` read outside `lib/domain/`.

- [ ] **Step 1: Write the failing tests.**
  - `applyOverrides(defaults, {'minOxygenMgL': 4})` gives an oxygen minimum of 4 and changes nothing else.
  - `{'temperatureC.min': 40}` (greater than the max of 32) is ignored.
  - `{'nope': 1}` is ignored.
  - For every key, `write(defaults, read(defaults))` equals `defaults`.
  - Every numeric field is covered: a test lists the expected key count.
  - Widget: the admin sets O₂ min to 4 with "3" shown beside it, and a water reading of 3.5 now shows in red.
- [ ] **Step 2: Run to verify it fails.** → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(settings): per-site overrides of farming numbers`

### Task 14: Milestone check

**Files:**
- Create: `integration_test/m4_sync_test.dart`, `docs/deploy.md`

- [ ] **Step 1: Write the walk-through** (run with `--dart-define-from-file=env/local.json`).
  1. Online, the founder creates the association with site "Ambohidratrimo", a pond E1, a worker account `rakoto` (PIN 123456), and a stocking of 1 000 fish at 15 g in E1, then syncs.
  2. Turn on airplane mode (`adb shell svc wifi disable; svc data disable`). Still signed in as the founder, log E1 in worker mode and add a water reading. The badge shows 2.
  3. Turn the network back on (`svc wifi enable`) and tap "Synchroniser". The badge clears.
  4. Check `psql` on the host: `daily_logs` and `water_readings` hold the rows, with `entered_by` = the founder's member id.
- [ ] **Step 2: Second phone.** On a second emulator (`Medium_Phone`), sign in as `rakoto`. It opens on the worker home in Malagasy with E1 and the day's tick. Log a day, sync, and see the row in `psql`.
- [ ] **Step 3: Persistence.** Force-stop, `adb install -r` the debug APK, launch offline: the records and the session are still there, and the badge shows anything pending.
- [ ] **Step 4: Backup.** Export from phone 1, import on a wiped phone 2 offline; the ponds and logs appear.
- [ ] **Step 5: Size.** `flutter build apk --release --split-per-abi`: arm64 is under 25 MB.
- [ ] **Step 6: Write `docs/deploy.md`** for the user: create the hosted project; `supabase link`, `db push`, `functions deploy create-account`; turn off email confirmation; fill `env/prod.json`; `flutter build apk --dart-define-from-file=env/prod.json`.
- [ ] **Step 7: Commit** `test: M4 walk-through with two phones, airplane mode and backup`

---

## Out of scope for this plan

The dashboard, alerts and the duplicate pond-day flag (M5). Visit reports and photo upload (M6). Sales permissions in use, feed, preparation and harvest (M7). Limiting workers to an assigned site and column-level write limits (later, when there are several sites). Changing a password from the app.
