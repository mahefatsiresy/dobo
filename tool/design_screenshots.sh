#!/usr/bin/env bash
# Screenshots of the redesigned screens (docs/design.md) on a phone or an
# emulator, from the demo farm (tool/design_demo.dart), in French and in
# Malagasy. They land in build/screenshots/.
#
#   tool/design_screenshots.sh DEVICE      # DEVICE from `adb devices`
#
# The demo build replaces the app on the device, signed with the same debug
# key, so the device's own records stay; a later `flutter run` puts the
# normal app back. It installs from a pushed file (`pm install`): some
# phones (realme) drop USB during a streamed `adb install`.
set -euo pipefail
device=${1:?usage: tool/design_screenshots.sh DEVICE}
out=build/screenshots
apk=build/app/outputs/flutter-apk/app-debug.apk
mkdir -p "$out"
on() { adb -s "$device" "$@"; }

size=$(on shell wm size | tail -1 | sed 's/.*: //' | tr -d '\r')
w=${size%x*}
h=${size#*x}
swipe() { on shell input swipe $((w / 2)) "$1" $((w / 2)) "$2" 300; }

for locale in fr mg; do
  flutter build apk --debug -t tool/design_demo.dart \
    --dart-define=DEMO_LOCALE="$locale"
  on push "$apk" /data/local/tmp/dobo-demo.apk >/dev/null
  on shell pm install -r -t /data/local/tmp/dobo-demo.apk
  on shell rm /data/local/tmp/dobo-demo.apk
  on shell am force-stop mg.dobo.dobo
  on shell monkey -p mg.dobo.dobo -c android.intent.category.LAUNCHER 1 \
    >/dev/null
  sleep 10
  on exec-out screencap -p >"$out/ponds_${locale}_top.png"
  swipe $((h * 3 / 4)) $((h / 5))
  swipe $((h * 3 / 4)) $((h / 5))
  sleep 2
  on exec-out screencap -p >"$out/ponds_${locale}_bottom.png"
done
ls "$out"
