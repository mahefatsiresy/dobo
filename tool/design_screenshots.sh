#!/usr/bin/env bash
# Screenshots of the redesigned screens (docs/design.md) on a phone or an
# emulator, from the demo farm (tool/design_demo.dart), in French and in
# Malagasy. They land in build/screenshots/.
#
#   tool/design_screenshots.sh DEVICE [PAGE…]   # DEVICE from `adb devices`
#
# PAGE is `list` (the ponds list), a demo pond code (E1, E2, P1…),
# `worker` (the worker home), `log-E1` (a pond's daily log), `alerts`,
# `visit-start` (the Visit tab before a visit), `visit` (one under way),
# `reports` (the Reports tab), `report` (a published report), or for
# step 7 `more`, `batches`, `batch`, `batch-closed`, `feed`, `sales`,
# `transfer` or `sale`, or for step 7b `transcription`, `paper`, `prep`,
# `sync`, `account`, `admin`, `members`, `member`, `settings` or `exports`;
# by default `list E1 E2 P1`.
#
# The demo build replaces the app on the device, signed with the same debug
# key, so the device's own records stay; a later `flutter run` puts the
# normal app back. It installs from a pushed file (`pm install`): some
# phones (realme) drop USB during a streamed `adb install`.
set -euo pipefail
device=${1:?usage: tool/design_screenshots.sh DEVICE [PAGE…]}
shift
pages=("$@")
[ ${#pages[@]} -eq 0 ] && pages=(list E1 E2 P1)
out=build/screenshots
apk=build/app/outputs/flutter-apk/app-debug.apk
mkdir -p "$out"
on() { adb -s "$device" "$@"; }

size=$(on shell wm size | tail -1 | sed 's/.*: //' | tr -d '\r')
w=${size%x*}
h=${size#*x}
swipe() { on shell input swipe $((w / 2)) "$1" $((w / 2)) "$2" 300; }

for page in "${pages[@]}"; do
  for locale in fr mg; do
    flutter build apk --debug -t tool/design_demo.dart \
      --dart-define=DEMO_LOCALE="$locale" --dart-define=DEMO_PAGE="$page"
    on push "$apk" /data/local/tmp/dobo-demo.apk >/dev/null
    on shell pm install -r -t /data/local/tmp/dobo-demo.apk
    on shell rm /data/local/tmp/dobo-demo.apk
    on shell am force-stop mg.dobo.dobo
    on shell monkey -p mg.dobo.dobo -c android.intent.category.LAUNCHER 1 \
      >/dev/null
    sleep 12
    on exec-out screencap -p >"$out/${page}_${locale}_top.png"
    swipe $((h * 3 / 4)) $((h / 5))
    swipe $((h * 3 / 4)) $((h / 5))
    sleep 2
    on exec-out screencap -p >"$out/${page}_${locale}_bottom.png"
  done
done
ls "$out"
