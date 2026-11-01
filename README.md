# Dobo

Offline-first Android app for a family association in Madagascar that raises
Nile tilapia in ponds. It replaces the paper production log and builds the
visit report. See `docs/SPEC.md` (features) and `docs/DOMAIN.md` (farming
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
