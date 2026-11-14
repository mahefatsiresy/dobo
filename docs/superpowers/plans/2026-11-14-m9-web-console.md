# M9: Web Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A web console for admins (SPEC F16):
- founding the association moves to the web, behind a founding code, and off the phones;
- admins manage the association name, groups, members and workers, and people;
- admins reset a password or PIN, in the console and on the phone.

**Architecture:**
- **One Flutter package, two entry points.** `lib/main.dart` stays the phone app. `lib/main_web.dart` starts `ConsoleApp` from `lib/console/`. The console shares `lib/domain/`, `lib/l10n/`, `lib/sync/auth_gateway.dart` types and `lib/db/ids.dart`, and never imports Drift or other phone-only packages. A test walks the import graph from `lib/main_web.dart` to keep it that way.
- **Online only, same record rules.** The console reads tables through PostgREST under row-level security and writes reference rows through the existing `sync_push`, as one more device. Its browser keeps one device id. Accounts go through edge functions: the existing `create-account` and two new ones, `found-association` and `reset-secret`.
- **Founding is a server transaction.** `found-association` checks the code, creates the login with the admin API, then calls the SQL function `found_association` (service role only). That function records the spent code and inserts the association, group, site, founder's person and founder's member row in one transaction.

**Tech Stack:** Flutter 3.47.8 (Android + Web), flutter_riverpod 3 (no codegen), go_router 18, ARB l10n, `supabase_flutter` 2, Supabase edge functions (Deno, `jsr:@supabase/supabase-js@2`), pgTAP. New direct dependency: `shared_preferences` (already pulled in by `supabase_flutter`), for the browser's device id. Hosting: Cloudflare Pages via `npx wrangler`.

**Spec:** `CLAUDE.md`; `docs/SPEC.md` (§3 roles, F14, F16, §6 navigation, §7 sync, §11 M9); `docs/deploy.md`. The decisions in F16 come from the user's grilling session (14/11/2026); the ones below are Claude's calls.

## Decisions (Claude's calls)

1. **Founding code.**
   - The secret is `FOUNDING_CODE` in the edge functions' environment: `supabase secrets set` on the hosted project, and `supabase/functions/.env` locally (gitignored; `supabase/functions/.env.example` is committed with `FOUNDING_CODE=dobo-local-founding`).
   - The code typed is trimmed, then compared exactly (case-sensitive). An unset secret refuses every code.
   - The spent record is the SHA-256 hex of the code, in the server-only table `founding_codes_spent`. A wrong code and a spent code both answer `403 bad_code`.
   - deploy.md says to make the code with `openssl rand -hex 12`.
2. **Founding ids come from the browser**, like every record id: association, group, site, member and the founder's person (`accountPersonId(memberId)`), plus the browser's device id. The founder's language is `fr`.
3. **A lost founding answer.** If the founding page gets `login_taken`, it signs in with the email and password typed. If that works and the account's association is the one this form planned, founding counts as done. Otherwise it signs out and shows "login taken". The form keeps its planned ids until it succeeds or the page is closed.
4. **`create_association` is dropped** from the server, along with the phone's `signUp` and `createAssociation`. Nothing calls them after this milestone.
5. **Local sign-ups are turned off** (`supabase/config.toml` `[auth] enable_signup = false`), as on the hosted project. Server tests found their association through a fixture, `ServerEnv.foundAssociation`, that uses the admin API and the SQL function with a random code hash. Only `found_association_test.dart` calls the edge function with the real local code. It clears the spent record first with `psql`.
6. **Renaming the association.** A new RLS policy lets an active admin update `associations.name` only (column grant). Phones don't show the association name, so nothing is synced.
7. **The console's data layer** is `ConsoleApi` (interface) with `SupabaseConsoleApi`, in `lib/console/data/`:
   - **Reads:** `select` on `groups`, `members` and `people`, ordered by name. Pages reload when opened and after each write. No realtime.
   - **Updates:** the full row as read, with the edits applied, `device_id` set to the browser's id, `updated_at_device` set to now (UTC), and `user_id`, `server_seq` and `server_received_at` removed.
   - **New rows:** `id: newId()`, `association_id` and `entered_by` set to the signed-in admin, and `created_at_device = updated_at_device = now`.
   - **Errors:** a `sync_push` outcome with an error becomes `ConsoleWriteFailed(code)`, e.g. `last_admin`, `42501`. No network becomes `SyncOffline`.
8. **Creating an account in the console** first pushes the person row `accountPersonId(memberId)`, named like the account, then calls `create-account` with that `personId`. This is the order phones end up in (`ensureAccountPeople`). A retry with the same form reuses the same `memberId`, so no second person is made.
9. **Reset.**
   - The `reset-secret` function takes `{memberId, secret}`. It checks that the caller is an active admin and that the target member is in the same association and has a login. It applies the creation rules: a worker gets a 6-digit PIN, a member a password of 8 characters or more. It then calls `auth.admin.updateUserById`.
   - Answers: `403 not_admin`, `404 no_member`, `400 bad_secret`, `200 {}`.
   - On the phone, the member form (edit mode, admins, online) gets a "Nouveau mot de passe" or "Nouveau code PIN" button that opens a dialog.
10. **Shared validation** moves to `lib/domain/accounts.dart`, used by the phone's member form, the console and the reset dialogs. Its error codes are the server's: `bad_login`, `bad_secret`. These aren't farming numbers, so they stay out of `config.dart`.
11. **CORS.** All three functions answer `OPTIONS` with `204`, and add these headers to every answer:
    - `Access-Control-Allow-Origin: *` (the console authenticates with a bearer token, not cookies);
    - `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type`;
    - `Access-Control-Allow-Methods: POST, OPTIONS`.

    The shared code lives in `supabase/functions/_shared/http.ts`.
12. **The console's routes** use go_router's default hash URLs (`/#/membres`), so Cloudflare Pages needs no rewrite rule. The routes:
    - `/fonder` (public);
    - `/connexion` (public);
    - `/association`, `/groupes`, `/membres`, `/personnes` (admins).

    After sign-in the console opens `/membres`.
13. **Who may stay signed in.** After sign-in, a session that isn't an active admin's (a worker, a member without the flag, a deactivated or unknown account) is signed out at once. The sign-in page then says "La console est réservée aux administrateurs." The session is also checked on each page load.
14. **Idle sign-out:** `consoleIdleLimit = Duration(minutes: 30)`, in `lib/console/console_config.dart`. Any pointer or key event resets the timer. On expiry the console signs out and the sign-in page says "Déconnecté après 30 minutes sans activité."
15. **Network errors on the web.** `lib/sync/server_errors.dart` stops importing `dart:io`. Socket and HTTP exceptions are recognised through a conditional import (`network_errors_stub.dart` / `network_errors_io.dart`), so the phone behaves as before and the web build compiles.
16. **The browser's device id:** a UUIDv7 stored under `dobo_device_id` in `SharedPreferences` (local storage on the web), made on first use.
17. **The phone after founding leaves.** The Welcome screen keeps three buttons. The `/welcome/create` route, `CreateAssociationScreen`, the sync screen's offer, `AccountRepository.createAssociation` and the `planned_*` meta keys all go, with their ARB keys and tests. A server build whose sign-in hits `no_site` keeps its message.
18. **Desktop layouts.**
    - A `NavigationRail` on the left: Association, Groupes, Membres, Personnes. At its foot: the language switch (fr/mg, saved on the admin's own member row) and "Se déconnecter".
    - Pages hold a title, a primary button and a `DataTable`. Create, edit and reset happen in dialogs.
    - Deactivating and reactivating ask for confirmation.
    - The content is at most 1 100 px wide.
19. **Deploy by hand.**
    - Build with `flutter build web -t lib/main_web.dart --release --dart-define-from-file=env/prod.json`.
    - Deploy with `npx wrangler pages deploy build/web --project-name dobo-console`.
    - `docs/deploy.md` gets a "Web console" section (first-time `wrangler login` and `wrangler pages project create`), the `FOUNDING_CODE` secret step, `supabase functions deploy found-association reset-secret`, and a rewritten "First use": found on the web with the code; sign-ups are never opened.

## Global Constraints

- The phone stays offline-first: nothing on the phone except creating an account, resetting a secret and signing in needs the network. The schema is unchanged on the phone (`schemaVersion` stays 6); the server gets one new migration.
- `lib/domain/` imports neither Flutter nor Drift (`test/domain/purity_test.dart`).
- Nothing reachable from `lib/main_web.dart` imports `dart:io`, `package:drift`, `package:drift_flutter`, `package:path_provider`, `package:image_picker`, `package:flutter_image_compress`, `package:share_plus`, `package:file_picker` or `package:printing` (enforced from Task 4).
- Every string comes from the ARB files, with every key in both `app_fr.arb` and `app_mg.arb`. New Malagasy texts are drafts, and `docs/mg-review.csv` is regenerated (Task 9). Phone touch targets stay ≥ 56 dp.
- Ids are UUIDv7 made on the client. Timestamps are UTC. Dates display `dd/mm/yyyy`.
- Workers' PINs are exactly 6 digits; members' passwords are 8 characters or more; worker usernames match `^[a-z0-9._-]{3,30}$`.
- No money anywhere.
- At the end of each task: `flutter analyze` has no issues. `flutter test` and `TZ=UTC flutter test` pass. From Task 1 on, `supabase test db` passes; from Task 2 on, `tool/server_test.sh` passes. From Task 4 on, `flutter build web -t lib/main_web.dart` succeeds.
- Commits use a conventional prefix and end with the `Co-Authored-By` line. Branch: `feat/m9-web-console` from `main`.

## Review Focus

1. **A founding answer lost on the network:** the retry finishes the founding instead of saying "login taken", and creates no second association. The real retry is tested against the server in Task 5; the page's reuse of its planned ids in Task 6.
2. **The last admin removes their own flag or deactivates themselves in the console:** the server refuses with `last_admin`, the console says why, and the table still shows them as admin. Test in Task 8.
3. **An admin of another association calls `reset-secret` with a member id of this one:** `404 no_member`, and the password is unchanged (the old one still signs in). Test in Task 2.
4. **A worker or a plain member signs in to the console:** they are signed out at once with the admins-only message, and no admin page ever renders. Test in Task 5.
5. **Two founding attempts at once with the same code** (a double click, or two people): exactly one association is created, and the other attempt gets `bad_code` with its login removed. Test in Task 2.

---

### Task 1: Server schema for founding and renaming

**Files:**
- Create: `supabase/migrations/20261114000001_founding.sql`, `supabase/tests/founding_test.sql`
- Modify: `supabase/tests/roles_test.sql` (drop its `create_association` checks, around lines 200–235; any fixture that used it inserts rows directly or calls `found_association`)

**Interfaces:**
- Produces:
  - table `founding_codes_spent (code_hash text primary key, association_id uuid not null references associations (id), spent_at timestamptz not null default now())`, with RLS on and no policies;
  - `found_association(p_code_hash text, p_user_id uuid, p_email text, p_association_id uuid, p_association_name text, p_group_id uuid, p_group_name text, p_site_id uuid, p_site_name text, p_location_note text, p_member_id uuid, p_person_id uuid, p_member_name text, p_locale text, p_device_id uuid) returns void`, `security definer`, executable by `service_role` only. It raises `code_spent` when the hash is already spent (the primary key also catches a race) and `association_exists`. It inserts, in this order: association; group; site; person (name = member name, active); member (`role 'member'`, `is_admin true`, `login = p_email`, `user_id = p_user_id`, `person_id = p_person_id`, `group_id = p_group_id`); spent code. Every `entered_by` is `p_member_id`; every `created_at_device` and `updated_at_device` is `now()`.
  - policy `admin_rename` on `associations` for update, `id = my_association() and is_admin()` on both sides, with `revoke update on associations from anon, authenticated; grant update (name) on associations to authenticated;`
  - `drop function create_association(uuid, text, uuid, text, uuid, text, text, uuid);`

- [ ] **Step 1: Write the failing pgTAP tests** in `founding_test.sql`:
  - `found_association` as `service_role` creates one row in each of `associations`, `groups`, `sites`, `people`, `members`, and each synced row has a `server_seq`;
  - the founder's member row has `is_admin`, `active`, `person_id = p_person_id` and `user_id = p_user_id`;
  - the same `p_code_hash` again raises `code_spent` and adds no association;
  - `authenticated` and `anon` can't execute `found_association` (`throws_ok` with `42501`);
  - an admin of the association can update `associations.name`; a plain member's update changes nothing; an admin updating `id` is refused (`42501`);
  - `create_association` no longer exists (`hasnt_function`).
- [ ] **Step 2:** `supabase db reset && supabase test db`. Expected: `founding_test.sql` fails (function missing).
- [ ] **Step 3: Write the migration** described in Interfaces, and update `roles_test.sql`.
- [ ] **Step 4:** `supabase db reset && supabase test db`. Expected: all pass.
- [ ] **Step 5: Commit** `feat(server): founding transaction, spent codes and association rename`.

### Task 2: Edge functions: found-association, reset-secret, CORS

**Files:**
- Create:
  - `supabase/functions/_shared/http.ts`: `corsHeaders`, `reply(status, body)`, `fail(status, error)`, `preflight(req): Response | null`, `callerMember(req): Promise<Member | null>` (moved from `create-account`);
  - `supabase/functions/found-association/index.ts`;
  - `supabase/functions/reset-secret/index.ts`;
  - `supabase/functions/.env.example`;
  - `test/server/found_association_test.dart`, `test/server/reset_secret_test.dart`.
- Modify:
  - `supabase/functions/create-account/index.ts` (use `_shared/http.ts`, answer `OPTIONS`);
  - `.gitignore` (`supabase/functions/.env`);
  - `supabase/config.toml` (`[auth] enable_signup = false`);
  - `tool/server_test.sh` (export `FOUNDING_CODE` from `supabase/functions/.env`);
  - `test/server/server_env.dart` (add `foundingCode`, `foundAssociation`, `serviceClient`; remove `signedUpClient`);
  - `test/server/create_account_test.dart`, `test/server/sync_e2e_test.dart` (found through the fixture).

**Interfaces:**
- `POST found-association`, no session needed. Body:
  `{code, email, password, founderName, associationName, groupName, siteName, locationNote?, associationId, groupId, siteId, memberId, personId, deviceId}`.
  - Validation: every id is a UUID; names are non-empty after trim; the email matches `^[^@\s]+@[^@\s]+$` and is lowercased; the password is ≥ 8 characters.
  - Answers:
    - `400 bad_request`, `bad_login`, `bad_secret`;
    - `403 bad_code` (wrong, unset or spent code);
    - `409 login_taken`;
    - `200 {memberId}`.
  - The login is deleted again when `found_association` fails.
- `POST reset-secret`, admin session. Body `{memberId, secret}`. Answers `403 not_admin`, `404 no_member`, `400 bad_secret`, `200 {}`.
- `ServerEnv`:
  - `String get foundingCode` (from env `FOUNDING_CODE`);
  - `SupabaseClient serviceClient()`;
  - `Future<FoundedAssociation> foundAssociation({String? email, String password = 'motdepasse1'})`: creates a confirmed login with the admin API, calls `found_association` with fresh ids and a random code hash, and returns the founder's ids and a signed-in client.
  - `FoundedAssociation`: `{associationId, groupId, siteId, memberId, personId, email, password, SupabaseClient client}`.

- [ ] **Step 1: Write the failing server tests.**
  - `found_association_test.dart` (setUp: `psql $SUPABASE_DB_URL -c "delete from founding_codes_spent where code_hash = encode(sha256(convert_to('<code>','UTF8')),'hex')"`):
    - `founding with the code creates an admin who signs in and sees the site`;
    - `the same code again is refused with bad_code and leaves no login` (signing in with the second email fails);
    - `a wrong code is refused with bad_code`;
    - `an email already in use is refused with login_taken`;
    - `two foundings at once with one code make one association` (`Future.wait` of two calls with different emails: one `200`, one `403 bad_code`, one new `associations` row);
    - `OPTIONS answers 204 with the CORS headers` (plain `http` request).
  - `reset_secret_test.dart`:
    - `an admin resets a worker's PIN: the new one signs in, the old one no longer does`;
    - `a 5-digit PIN is refused with bad_secret`;
    - `a member's password under 8 characters is refused with bad_secret`;
    - `a plain member gets not_admin`;
    - `an admin of another association gets no_member and the password is unchanged`.
- [ ] **Step 2:** `tool/server_test.sh test/server/found_association_test.dart test/server/reset_secret_test.dart`. Expected: FAIL (functions missing).
- [ ] **Step 3: Write `_shared/http.ts`, the two functions and the `create-account` refactor; switch the fixtures; turn off local sign-ups.** Run `supabase stop && supabase start`, then `supabase functions serve` with the new `.env`.
- [ ] **Step 4:** `tool/server_test.sh`. Expected: all server tests pass, the old ones included.
- [ ] **Step 5: Commit** `feat(server): founding with a code, password and PIN reset, CORS on functions`.

### Task 3: Phone: founding removed, reset added

**Files:**
- Create: `lib/domain/accounts.dart`, `test/domain/accounts_test.dart`
- Delete: `lib/features/account/create_association_screen.dart` and its tests
- Modify:
  - `lib/sync/auth_gateway.dart` (remove `signUp` and `createAssociation`; add `resetSecret`);
  - `lib/sync/supabase_auth_gateway.dart`;
  - `test/sync/fake_auth_gateway.dart`;
  - `lib/db/repositories/account_repository.dart` (remove `createAssociation` and the `planned_*` keys);
  - `lib/db/repositories/member_repository.dart` (add `resetSecret`);
  - `lib/features/account/welcome_screen.dart`;
  - `lib/features/sync/sync_screen.dart` (remove the offer near line 110);
  - `lib/router.dart` (remove `/welcome/create`);
  - `lib/features/admin/member_form_screen.dart` (use `accounts.dart`; add the reset button and dialog);
  - `lib/l10n/app_fr.arb` and `app_mg.arb` (remove the founding keys; add the reset keys);
  - `test/db/account_repository_test.dart`, `test/features/admin/admin_test.dart`;
  - `integration_test/m4_sync_test.dart` (the founder part: see Step 3).

**Interfaces:**
- `lib/domain/accounts.dart`:
  - `const minPasswordLength = 8; const pinLength = 6;`
  - `String? accountProblem({required MemberRole role, required String login, required String secret})`: `'bad_login'`, `'bad_secret'` or null, with the server's rules (worker: username regex and `^\d{6}$`; member: email regex and ≥ 8);
  - `String? secretProblem({required MemberRole role, required String secret})`.
- `AuthGateway.resetSecret({required String memberId, required String secret}) → Future<void>`: throws `AuthFailed(code)` with the function's error code; no network becomes `SyncOffline`.
- `MemberRepository.resetSecret(String memberId, String secret) → Future<void>`.

- [ ] **Step 1: Write the failing tests.**
  - `accounts_test.dart`:
    - a worker with `rakoto` and `123456` is ok; `ra` gives `bad_login`; `12345`, `1234567` and `12a456` give `bad_secret`;
    - a member with `a@b.mg` and `motdepasse` is ok; `ab.mg` gives `bad_login`; `court` gives `bad_secret`;
    - logins are checked lowercased.
  - `admin_test.dart`:
    - `an admin resets a worker's PIN from the member page` (the fake records `('m1', '654321')`; a green "Code PIN changé" appears);
    - `a reset with no network says so and keeps the dialog open`.
  - In the Welcome screen's existing test file (`grep -rl WelcomeScreen test`): `welcome offers sign-in, worker sign-in and backup only` (no `welcomeCreate` key).
- [ ] **Step 2:** `flutter test test/domain/accounts_test.dart test/features/admin` and the Welcome test file. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Remove the founding code paths and their now-unused ARB keys from both ARB files, then run `flutter gen-l10n`.
  - In `m4_sync_test.dart`, the founder part founds over HTTP with `found-association`, using `--dart-define=FOUNDING_CODE`. It then signs in through the member login screen and creates the pond, the worker's account and the stocking as before. The doc comment at the top says to clear the local spent code first (the `psql` line from Task 2) and to pass `FOUNDING_CODE`.
- [ ] **Step 4:** `flutter analyze && flutter test && TZ=UTC flutter test && tool/server_test.sh`. Expected: all pass.
- [ ] **Step 5: Commit** `feat(account): phones no longer found associations; admins reset a password or PIN`.

### Task 4: Web target, console shell and the import guard

**Files:**
- Create:
  - `web/` (`flutter create --platforms=web --project-name dobo .`; then set `web/index.html` `<title>` and `web/manifest.json` `name` to "Dobo — console");
  - `lib/main_web.dart`;
  - `lib/console/console_app.dart`, `lib/console/console_router.dart`, `lib/console/console_shell.dart`, `lib/console/console_config.dart`;
  - `lib/sync/network_errors_stub.dart`, `lib/sync/network_errors_io.dart`;
  - `test/console/web_safe_imports_test.dart`, `test/console/console_shell_test.dart`.
- Modify: `lib/sync/server_errors.dart`, `pubspec.yaml` (`shared_preferences` as a direct dependency).

**Interfaces:**
- `bool isIoNetworkError(Object e)`: false in the stub; `SocketException || HttpException` in the io version. `server_errors.dart` imports `'network_errors_stub.dart' if (dart.library.io) 'network_errors_io.dart'`. `guardServer` keeps its behaviour on the phone.
- `class ConsoleApp extends ConsumerWidget`: `MaterialApp.router` with the app's localization delegates (the Malagasy fallbacks first, as in `lib/app.dart`), `supportedLocales` fr and mg, and the locale from `consoleLocaleProvider`.
- `final consoleRouterProvider = Provider<GoRouter>(...)`, with the routes from Decision 12 and placeholder pages for now. The admin pages sit in a `ShellRoute` whose builder is `ConsoleShell(child:)`.
- `ConsoleShell({required Widget child})`: the `NavigationRail` from Decision 18. The rail items have keys `navAssociation`, `navGroups`, `navMembers`, `navPeople`; the sign-out button has key `consoleSignOut`.
- `const consoleIdleLimit = Duration(minutes: 30);`

- [ ] **Step 1: Write the failing tests.**
  - `web_safe_imports_test.dart`: `nothing reachable from main_web.dart imports phone-only code`. It parses `import` and `export` lines from `lib/main_web.dart`, following `package:dobo/` and relative URIs (for a conditional import, only the default URI). It fails naming the chain to any file importing a URI in the Global Constraints list.
  - `console_shell_test.dart`: `the shell shows the four sections and sign-out`; `tapping Membres shows the members page` (placeholder text).
- [ ] **Step 2:** `flutter test test/console`. Expected: FAIL.
- [ ] **Step 3: Implement** the web target, `main_web.dart` (`Supabase.initialize` when `serverConfigured`, then `ProviderScope(child: ConsoleApp())`), the shell and router, and the `server_errors.dart` split.
- [ ] **Step 4:** `flutter analyze && flutter test && flutter build web -t lib/main_web.dart`. Expected: pass, and `build/web/index.html` exists. Also run `flutter test test/sync` to confirm `guardServer` is unchanged on the VM.
- [ ] **Step 5: Commit** `feat(console): web target, console shell and a guard against phone-only imports`.

### Task 5: Console data layer, sign-in and the session rules

**Files:**
- Create:
  - `lib/console/data/console_api.dart` (interface and row types);
  - `lib/console/data/supabase_console_api.dart`;
  - `lib/console/data/browser_device.dart`;
  - `lib/console/console_providers.dart`;
  - `lib/console/pages/sign_in_page.dart`;
  - `lib/console/idle_guard.dart`;
  - `test/console/fake_console_api.dart`, `test/console/sign_in_test.dart`, `test/console/idle_guard_test.dart`, `test/server/console_api_test.dart`.

**Interfaces:**
- Rows, each with `fromJson(Map<String, Object?>)`, `copyWith` and the full server row `raw`:
  - `GroupRow {id, name}`;
  - `MemberRow {id, name, groupId, personId, role (MemberRole), isAdmin, isSales, active, locale, login}`;
  - `PersonRow {id, name, phone, note, active}`.
- `ConsoleMe {memberId, associationId, associationName, name, role, isAdmin, active, locale}`.
- `Founding {code, email, password, founderName, associationName, groupName, siteName, locationNote, associationId, groupId, siteId, memberId, personId}`, plus `Founding.planned(...)`, which makes the ids with `newId()` and `accountPersonId`.
- `abstract interface class ConsoleApi`:
  - `bool get hasSession`;
  - `Future<void> signIn(String email, String password)`, `Future<void> signOut()`;
  - `Future<ConsoleMe> me()`: throws `AuthFailed('no_member')`;
  - `Future<void> foundAssociation(Founding f)`: Decision 3; signed in afterwards;
  - `Future<void> renameAssociation(String name)`;
  - `Future<List<GroupRow>> groups()`, `Future<void> saveGroup(GroupRow g, {bool isNew = false})`;
  - `Future<List<MemberRow>> members()`, `Future<void> saveMember(MemberRow m)`;
  - `Future<void> createAccount(NewAccount a)`: Decision 8;
  - `Future<void> resetSecret(String memberId, String secret)`;
  - `Future<List<PersonRow>> people()`, `Future<void> savePerson(PersonRow p, {bool isNew = false})`.
- `class ConsoleWriteFailed implements Exception { final String code; }`.
- `Future<String> browserDeviceId(SharedPreferences prefs)`.
- Providers:
  - `consoleApiProvider`;
  - `consoleMeProvider` (`FutureProvider<ConsoleMe?>`, null when signed out);
  - `groupsProvider`, `membersProvider`, `peopleProvider` (`FutureProvider`, invalidated after writes);
  - `consoleLocaleProvider`.
- `IdleGuard({required Widget child, required VoidCallback onIdle, Duration limit = consoleIdleLimit})`.
- `SignInPage({String? notice})`; notice codes `admins_only`, `idle`.

- [ ] **Step 1: Write the failing tests.**
  - `sign_in_test.dart` (with `FakeConsoleApi`):
    - `an admin signs in and lands on Membres`;
    - `a worker who signs in is signed out with the admins-only message` (`fake.signedOut == true`; no `navMembers` in the tree);
    - `a member without the admin flag is signed out with the admins-only message`;
    - `a wrong password says so and stays on the page`;
    - `no network says so`.
  - `idle_guard_test.dart`:
    - `30 minutes without input calls onIdle once`;
    - `a tap at 29 minutes restarts the count` (`onIdle` not called at 30 minutes, called at 59);
    - `after idle the sign-in page shows the idle notice`.
  - `console_api_test.dart` (tag `server`, using `ServerEnv.foundAssociation`):
    - `me() returns the founder as an active admin with the association name`;
    - `saveGroup(isNew) then groups() lists it, and a phone pull sees it with server_seq` (via `SupabaseSyncApi.pull('groups', afterSeq: 0, limit: 100)`);
    - `renaming a group keeps the old name in reference_history` (psql);
    - `saveMember turning off the last admin's flag throws ConsoleWriteFailed('last_admin')`;
    - `createAccount pushes the account's person first` (a `people` row with id `accountPersonId(memberId)` and the member's `person_id` equal to it);
    - `renameAssociation changes associations.name`;
    - `foundAssociation called twice with the same Founding succeeds both times and makes one association` (the second call gets `login_taken` from the function, signs in and finds its own association; clear the spent code with `psql` first, as in Task 2);
    - `foundAssociation with an email another association uses throws AuthFailed('login_taken') and ends signed out`.
- [ ] **Step 2:** `flutter test test/console` and `tool/server_test.sh test/server/console_api_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** the API (Decision 7), the providers, the sign-in page with the session rules from Decision 13 (in the router redirect and after sign-in), and `IdleGuard`, wrapped around the router in `ConsoleApp`.
- [ ] **Step 4:** Run the Step 2 commands again, plus `flutter build web -t lib/main_web.dart`. Expected: pass.
- [ ] **Step 5: Commit** `feat(console): server data layer, admin sign-in and idle sign-out`.

### Task 6: Founding page

**Files:**
- Create: `lib/console/pages/found_page.dart`, `test/console/found_page_test.dart`
- Modify: `test/console/fake_console_api.dart`, the ARB files

**Interfaces:**
- `FoundPage()`, route `/fonder`. Fields: founding code, association name, first group name, your name, email, password, password again, site name, location note (optional). It keeps one `Founding.planned` in its state.
- The sign-in page has a small "Fonder une association" link to `/fonder`.

- [ ] **Step 1: Write the failing tests:**
  - `founding with every field calls the API once and lands on Membres`;
  - `a short password or a mismatch blocks the button with the reason`;
  - `bad_code says the code is wrong or already used`;
  - `login_taken says the email is already in use`;
  - `a retry after no network sends the same planned ids`: the fake's first call throws `SyncOffline`; tapping again lands on Membres, and both calls carried the same `associationId`, `memberId` and `personId`;
  - `the location note is optional`.
- [ ] **Step 2:** `flutter test test/console/found_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** the page; validation uses `lib/domain/accounts.dart`.
- [ ] **Step 4:** `flutter test test/console && flutter build web -t lib/main_web.dart`. Expected: pass.
- [ ] **Step 5: Commit** `feat(console): founding page`.

### Task 7: Association, groups and people pages

**Files:**
- Create: `lib/console/pages/association_page.dart`, `lib/console/pages/groups_page.dart`, `lib/console/pages/people_page.dart`, and their tests under `test/console/`
- Modify: `lib/console/console_shell.dart` (the language switch saves through `saveMember` on the admin's own row and sets `consoleLocaleProvider`), the ARB files

**Interfaces:**
- `AssociationPage`: the name with a "Renommer" dialog.
- `GroupsPage`: a table of names, plus "Nouveau groupe" and "Renommer" dialogs.
- `PeoplePage`: a table of name, phone, note and active, with "Nouvelle personne" and "Modifier" dialogs (name required; phone and note optional; active switch).
- Nothing is deleted.

- [ ] **Step 1: Write the failing tests** (with the fake):
  - `renaming the association shows the new name`;
  - `a new group appears in the table`;
  - `renaming a group to blank is refused`;
  - `a new person appears; editing keeps their id`;
  - `a write with no network shows the offline message and keeps the dialog open with what was typed`;
  - `switching to mg saves it on the admin's own member row and relabels the menu` (the fake's member row has `locale == 'mg'`; the rail shows the Malagasy label for Membres).
- [ ] **Step 2:** `flutter test test/console`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** `flutter test test/console && flutter build web -t lib/main_web.dart`. Expected: pass.
- [ ] **Step 5: Commit** `feat(console): association, groups and people pages`.

### Task 8: Members page: create, edit, deactivate, reset

**Files:**
- Create: `lib/console/pages/members_page.dart`, `lib/console/pages/member_dialogs.dart`, `test/console/members_page_test.dart`
- Modify: the ARB files

**Interfaces:**
- `MembersPage`: a table with name, group, role (Membre/Ouvrier), admin, sales, active, language and login. The row actions are Modifier, Nouveau mot de passe / Nouveau code PIN, and Désactiver / Réactiver. "Nouveau compte" sits at the top.
- `NewAccountDialog`: name, role, login (email or username, with the label following the role), password or PIN (twice), group, admin, sales and language (default `mg` for a worker, `fr` for a member, as SPEC §9). It keeps one `memberId` across retries.
- `EditMemberDialog`: name, group, admin, sales, language. The role and login can't be edited, as on the phone.
- `ResetSecretDialog`: the new secret, twice.

- [ ] **Step 1: Write the failing tests** (with the fake):
  - `a new worker account is created with a PIN and shows in the table`;
  - `the worker's language defaults to mg, a member's to fr`;
  - `a 5-digit PIN blocks the button`;
  - `login_taken keeps the dialog open; the retry sends the same memberId`;
  - `removing the last admin's flag shows the last-admin message and the table still shows them admin`;
  - `deactivating asks first, then shows the member inactive`;
  - `resetting a PIN calls the API with the member and the new PIN and says done`.
- [ ] **Step 2:** `flutter test test/console/members_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** `flutter test test/console && flutter build web -t lib/main_web.dart`. Expected: pass.
- [ ] **Step 5: Commit** `feat(console): members page with accounts, deactivation and reset`.

### Task 9: Malagasy, docs and the walk-through

**Files:**
- Create: `test/server/console_e2e_test.dart`
- Modify:
  - `lib/l10n/app_mg.arb` (drafts for every new key);
  - `docs/mg-review.csv` (`dart run tool/mg_review.dart export`);
  - `docs/deploy.md`: the local `.env` and the spent-code reset line; `FOUNDING_CODE` on the hosted project; deploying the two new functions; a "Web console" section (build, `wrangler` first time and each time, running it locally with `flutter run -d chrome -t lib/main_web.dart --dart-define-from-file=env/host.json`); "First use" rewritten for web founding;
  - `README.md` (one paragraph on the console and where deploy.md covers it).

- [ ] **Step 1: Write the walk-through test** `console_e2e_test.dart` (tag `server`). This one goes through the real edge function: first clear the spent code with `psql`, then:
  1. `SupabaseConsoleApi.foundAssociation` with `env.foundingCode`;
  2. create a worker account (`rakoto<stamp>`, PIN `123456`) and a group "Branche 2";
  3. reset the worker's PIN to `654321`;
  4. on a phone, an in-memory Drift with `AccountRepository` over a real `SupabaseAuthGateway`, as in `sync_e2e_test.dart`: signing in as the worker with `123456` fails, and with `654321` succeeds;
  5. one sync later, the phone holds the site, both groups, the founder's and the worker's people, and the worker's member row.
- [ ] **Step 2:** `tool/server_test.sh test/server/console_e2e_test.dart`. Expected: PASS. (Any failure here is a bug in Tasks 2–8; fix it there.)
- [ ] **Step 3: Malagasy and docs.** Write the drafts, regenerate the CSV, and update `deploy.md` and `README.md`. Expected: the Malagasy completeness test passes.
- [ ] **Step 4: Browser check.** Run `flutter run -d chrome -t lib/main_web.dart --dart-define-from-file=env/host.json` against the local stack, with sign-ups off and `supabase functions serve` running. Then:
  - found an association;
  - create a worker;
  - rename a group;
  - reset the PIN;
  - switch to Malagasy;
  - sign out.

  Then sign the emulator in as that worker (`env/local.json`) and see the worker home. Note the result in the commit body.
- [ ] **Step 5: Final checks:** `flutter analyze && flutter test && TZ=UTC flutter test && supabase test db && tool/server_test.sh && flutter build web -t lib/main_web.dart --release && flutter build apk --debug`. Expected: all pass.
- [ ] **Step 6: Commit** `docs: web console deploy, Malagasy drafts and the M9 walk-through`.
