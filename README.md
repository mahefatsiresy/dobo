# Dobo

Offline-first Android app for a family association in Madagascar that raises
Nile tilapia in ponds. It replaces the paper production log and builds the
visit report. A web console lets admins found and manage the association. See `docs/SPEC.md` (features) and `docs/DOMAIN.md` (farming
rules).

## Run the app

Without server settings the app runs fully offline: it sets up a local site
and never syncs.

```bash
flutter run
```

With the server, pass its address and key from a file in `env/` (gitignored;
`env/example.json` shows the shape):

| Where the app runs | File | Server address |
|---|---|---|
| Android emulator | `env/local.json` | `http://10.0.2.2:54321` (the host, seen from the emulator) |
| Real phone on the same Wi-Fi | `env/device.json` | `http://<laptop LAN IP>:54321` (check with `ip -4 addr`) |
| Tools on the host | `env/host.json` | `http://127.0.0.1:54321` |

```bash
flutter run --dart-define-from-file=env/local.json                 # emulator
flutter run -d <phone-id> --dart-define-from-file=env/device.json  # phone (flutter devices)
```

The local server is plain HTTP, which only debug builds allow (`flutter run`
is one). Release builds use the hosted HTTPS project: see `docs/deploy.md`.

An emulator left in airplane mode by a walk-through can't reach the server.
Turn its network back on:

```bash
adb shell settings put global airplane_mode_on 0
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
adb shell svc wifi enable
adb shell svc data enable
```

## Web console

Admins found and manage the association from a web console built from the
same code (SPEC F16): founding with the founding code, groups, members and
workers, people, password and PIN reset. It is online only. Run it against
the local server in Chromium:

```bash
flutter run -d chrome -t lib/main_web.dart --dart-define-from-file=env/host.json
```

Building and hosting on Cloudflare Pages are in `docs/deploy.md`.

### The founding code

The association is founded once, in the console ("Fonder une
association"), with a founding code. The code is a server secret, spent by
the first founding that uses it. No phone can found an association.

- **Locally** the code is `dobo-local-founding`
  (`cp supabase/functions/.env.example supabase/functions/.env`, once).
  To found again, make it usable again:

  ```bash
  psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -c 'truncate founding_codes_spent'
  ```

- **On the hosted project**, make one and set it before the founder opens
  the console:

  ```bash
  CODE=$(openssl rand -hex 12); echo "Founding code: $CODE"
  supabase secrets set FOUNDING_CODE="$CODE"
  ```

  Write it down: it can't be read back. Hand it to the founder privately,
  with the console's address. A wrong, spent or unset code gets "Code de
  fondation faux ou déjà utilisé". Lost or leaked before use: run the two
  lines again. The rest (after founding, another association) is in
  `docs/deploy.md`, "The founding code".

## Local server

Supabase runs locally on podman. Start it, then read its URLs and keys:

```bash
systemctl --user start podman.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
supabase start
supabase status
```

- Studio (tables, SQL, accounts): http://127.0.0.1:54323
- Database: `psql postgresql://postgres:postgres@127.0.0.1:54322/postgres`

Setup details, SELinux and the hosted project are in `docs/deploy.md`.

## Tests

```bash
flutter test                 # unit, repository and widget tests
TZ=UTC flutter test          # the same under UTC (farm dates must not shift)
tool/server_test.sh          # against the local Supabase stack
flutter test integration_test/m5_guidance_test.dart -d <device>  # on a device
```

The look (`docs/design.md`) is pinned by golden images under
`test/**/goldens/`. A deliberate change of look regenerates them:
`flutter test --update-goldens <test file>`; look at the new PNGs before
committing. Screenshots of the redesigned screens on a phone or emulator,
from a demo farm in memory (the device's own records are untouched), in
French and Malagasy, land in `build/screenshots/`:

```bash
tool/design_screenshots.sh <device>   # keep the phone unlocked and awake
```

## Malagasy review

Every string has a Malagasy text in `lib/l10n/app_mg.arb`. The texts are
Claude's drafts until a Malagasy speaker reviews them, in
`docs/mg-review.csv` (one row per string: key, description, French,
Malagasy, ok).

1. `dart run tool/mg_review.dart export` refreshes the sheet from the ARB
   files. It keeps the `ok` marks, and clears a mark whose French text has
   changed since.
2. Open the sheet in LibreOffice or Google Sheets, with `;` as the separator
   and UTF-8. Correct the `mg` column and write `ok` in the last column once
   a row reads right. Save it as CSV with the same separator.
3. `dart run tool/mg_review.dart import`, then `flutter gen-l10n`.

Conventions: everyday Malagasy over loanwords (*trondro* fish, *sakafo*
feed, *dobo* pond, *maty* deaths, *andiany* batch). Units, codes and
numbers stay as they are. Text in braces (`{count}`, `{date}`) is filled in
by the app and must stay as it is; `test/l10n/mg_complete_test.dart` fails
if one goes missing.

## Field test

`docs/field-test.md` is the protocol for trying the worker screens and the
paper sheet on the farm, and what to change afterwards.
