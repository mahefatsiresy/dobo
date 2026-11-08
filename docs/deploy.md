# Server: local development and the hosted project

The app syncs with a Supabase project (SPEC §7). The schema, row-level
security and the `create-account` function live in `supabase/`. A build
reads the server address from `--dart-define-from-file=env/<name>.json`.
A build without one runs fully offline and sets the phone up locally, as
before M4.

## Local development (Fedora, podman)

```bash
systemctl --user start podman.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
supabase start                     # first run downloads the images
supabase functions serve &         # serves create-account
supabase test db                   # pgTAP: tables, roles, sync_push
tool/server_test.sh                # Dart tests tagged `server`
```

- SELinux blocks the edge runtime from reading the bind-mounted function
  folder. Label it with `chcon -Rt container_file_t supabase/functions`.
  `restorecon -R supabase/functions` undoes it. A file git writes anew (a
  checkout or merge that adds it) loses the label: when `create-account`
  answers 503 and the edge runtime logs "failed to determine entrypoint",
  run the `chcon` again.
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
  three parts at the top of the file.

## The hosted project (once)

1. Create a project on supabase.com. Choose a region near Madagascar, for
   example `eu-central` or `ap-south`.
2. Under Authentication → Sign In / Providers → Email, turn **off**
   "Confirm email": the founder signs up from the app, and admins create
   every other account. Keep the minimum password length at **6**, because
   worker PINs are 6 digits.
3. From this folder:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push                         # the migrations in supabase/migrations
   supabase functions deploy create-account
   ```

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

## First use

On the founder's phone, choose "Créer l'association". A phone that already
holds records keeps them: its association, site and records become the
server's. The founder then creates everyone else's account under Plus →
Administration → Membres: members get an email and password, workers a
username and PIN. Each person signs in once with a network connection, and
the phone works offline from then on.

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
