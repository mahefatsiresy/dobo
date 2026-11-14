# Server: local development and the hosted project

The app syncs with a Supabase project (SPEC §7). The schema, row-level
security and the edge functions (`create-account`, `found-association`,
`reset-secret`) live in `supabase/`. A build reads the server address from
`--dart-define-from-file=env/<name>.json`. A phone build without one runs
fully offline and sets the phone up locally, as before M4.

The association is founded in the web console (SPEC F16), never on a
phone. The console is a Flutter Web build of the same code
(`lib/main_web.dart`), hosted as static files on Cloudflare Pages.

## Local development (Fedora, podman)

```bash
systemctl --user start podman.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
cp supabase/functions/.env.example supabase/functions/.env   # once
supabase start                     # first run downloads the images
supabase functions serve &         # serves the three functions
supabase test db                   # pgTAP: tables, roles, sync_push, founding
tool/server_test.sh                # Dart tests tagged `server`
```

- `supabase/functions/.env` (gitignored) holds the local founding code,
  `FOUNDING_CODE=dobo-local-founding`. A code is spent by the first
  founding that uses it. To found again locally (the M4 walk-through, the
  console by hand), make it usable again:
  `psql "$(supabase status -o env | sed -n 's/^DB_URL=//p' | tr -d '"')" -c 'truncate founding_codes_spent'`.
  The server tests do this themselves.
- Sign-ups are off locally too (`supabase/config.toml`), as on the hosted
  project. Accounts come only from the functions.

- SELinux blocks the edge runtime from reading the bind-mounted function
  folder. Label it with `chcon -Rt container_file_t supabase/functions`.
  `restorecon -R supabase/functions` undoes it. A file git writes anew (a
  checkout or merge that adds it) loses the label: when `create-account`
  answers 503 and the edge runtime logs "failed to determine entrypoint",
  run the `chcon` again. `supabase db reset` wipes the local database.
- If `supabase start` stops with "failed to copy secret file into
  container" after the analytics container crashes ("Failed to detect IP
  version for DB_HOSTNAME"), start without analytics and Studio:
  `supabase start -x vector,logflare,studio`. The tests don't need them.
- `env/local.json` points the Android emulator at the host
  (`http://10.0.2.2:54321`). `env/host.json` is for tools on the host. Both
  hold the local anon key from `supabase status` and are gitignored.
  `env/example.json` shows the shape.
- Run the app against it:
  `flutter run --dart-define-from-file=env/local.json`.
- The local server is plain HTTP. Android 9+ refuses that by default, so
  the debug manifest (`android/app/src/debug/AndroidManifest.xml`) allows
  it for debug builds only. The hosted project is HTTPS, so release builds
  never need it.
- On a real phone on the same Wi-Fi, use the laptop's address instead:
  `env/device.json` with `"SUPABASE_URL": "http://<laptop LAN IP>:54321"`
  (gitignored), then `flutter run -d <phone> --dart-define-from-file=env/device.json`.
- To cut and restore an emulator's network, run `adb root` once, then
  `adb shell svc wifi disable|enable` and `adb shell svc data disable|enable`.
- The M4 walk-through (`integration_test/m4_sync_test.dart`) explains its
  three parts at the top of the file. Its founder part founds through
  `found-association`: pass `--dart-define=FOUNDING_CODE=dobo-local-founding`.
- Run the console against the local server in Chromium:
  `flutter run -d chrome -t lib/main_web.dart --dart-define-from-file=env/host.json`.

## The hosted project (once)

1. Create a project on supabase.com. Choose a region near Madagascar, for
   example `eu-central` or `ap-south`.
2. Under Authentication → Sign In / Providers:
   - turn **off** "Allow new users to sign up". Every account, the
     founder's included, is made by an edge function through the admin
     API, which works with sign-ups off. The anon key is inside every APK
     and the console, so open sign-ups would let anyone make an account;
   - keep the minimum password length at **6**, because worker PINs are 6
     digits.
3. From this folder:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push                         # the migrations in supabase/migrations
   CODE=$(openssl rand -hex 12); echo "Founding code: $CODE"
   supabase secrets set FOUNDING_CODE="$CODE"
   supabase functions deploy create-account found-association reset-secret
   ```

   Note the founding code it prints: the dashboard and `supabase secrets
   list` show only a digest of it. Give it to the founder with the
   console's address. It works for one founding only; to found another
   association some day, set a new one the same way.

4. Create `env/prod.json` (gitignored):

   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_ANON_KEY": "<publishable or anon key from Project Settings → API>"
   }
   ```

5. Create the release key, once (next section), then build the app for
   the phones:

   ```bash
   flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json
   ```

   Install `app-arm64-v8a-release.apk` (or `armeabi-v7a` on older phones).

## The release key

Android installs a new version over the old one only when both are signed
with the same key. A phone given a version signed with another key has to
uninstall the app first, and uninstalling deletes every record not yet sent
to the server. So every APK that goes on a farm phone is signed with one
key, made once and kept forever. A release build stops with an error when
the key is missing; it never falls back to the debug key.

1. Make the key, outside this folder (the keystore must never be
   committed):

   ```bash
   mkdir -p ~/dobo-release
   keytool -genkeypair -v -keystore ~/dobo-release/dobo-release.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias dobo
   ```

   `keytool` asks for a password and a name; the name can be the
   association's. Use one password for both the store and the key.

2. Create `android/key.properties` (gitignored):

   ```properties
   storeFile=/home/<you>/dobo-release/dobo-release.jks
   storePassword=<password>
   keyAlias=dobo
   keyPassword=<password>
   ```

3. **Back up the keystore and its password now**, in two places off this
   laptop (a USB stick kept by another family member, and an encrypted
   cloud folder or password manager). If the key is lost, the next version
   can't be installed over the phones' app, and each phone would have to
   send every record, uninstall and sign in again.

4. Check a build is signed with it:

   ```bash
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

   The certificate's SHA-256 matches
   `keytool -list -v -keystore ~/dobo-release/dobo-release.jks`.

Each new version raises the number after `+` in `pubspec.yaml`'s `version`
(e.g. `1.0.0+1` to `1.0.1+2`); Android refuses to install a lower one.

## The web console

A static site: build it, then upload `build/web` to Cloudflare Pages
(free plan). Node is needed for `npx`.

Once:

```bash
npx wrangler login
npx wrangler pages project create dobo-console --production-branch main
```

Each time the console changes:

```bash
flutter build web -t lib/main_web.dart --release --dart-define-from-file=env/prod.json
npx wrangler pages deploy build/web --project-name dobo-console --branch main
```

It is served at `https://dobo-console.pages.dev` (a custom domain can be
added later in the Cloudflare dashboard, with no change here). The pages
use `#` addresses (`/#/membres`), so no rewrite rule is needed. Only
active admins can stay signed in; 30 minutes without use signs out.

## First use

1. **Found the association** in the console: open its address, choose
   "Fonder une association", and fill in the founding code, the
   association, the first branch, your name, email and password, and the
   site. You are its first admin, and the console opens the members page.

2. In the console (Membres) or on a phone (Plus → Administration →
   Membres), create everyone else's account: members get an email and
   password, workers a username and PIN. No email is sent; hand the
   password or PIN over in person. Each person signs in once with a
   network connection, and the phone works offline from then on. A
   forgotten password or PIN is replaced from the same page ("Nouveau
   mot de passe" / "Nouveau code PIN").

3. **Name a second admin** among the members (tick "admin" when creating
   the account, or later on the member's page). An admin who loses their
   phone or forgets their password can then be helped by the other. The
   server never lets the last active admin lose the flag or be deactivated.

A worker's phone has no way out of the worker home. To take it back, an
admin long-presses the title on the worker home and signs in with their
email and password. The worker's records must all be sent first, so this
needs the network.

## Changing the schema later

Add a new file in `supabase/migrations/`. Never edit a migration that has
already been pushed. Run `supabase db reset` and `supabase test db` locally,
then `supabase db push`. A column added to a synced table must be added to
the Drift table too, with a schema bump (CLAUDE.md).
`test/server/schema_parity_test.dart` fails until both sides match.
