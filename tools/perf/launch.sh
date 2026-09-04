#!/usr/bin/env bash
# Cold-launch the profile build and print a host-reachable VM Service URI.
# Deterministic: own forward on a fixed port, token read from logcat.
set -euo pipefail

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
DEVICE="${PLEZY_DEVICE:-192.168.1.7:5555}"
PKG=com.edde746.plezy
HOST_PORT="${PLEZY_VM_PORT:-9223}"

a() { "$ADB" -s "$DEVICE" "$@"; }

a shell input keyevent 224 >/dev/null 2>&1 || true
a shell am force-stop "$PKG" >/dev/null 2>&1 || true
sleep 2
a logcat -c
a shell input keyevent 224 >/dev/null 2>&1 || true

# --ez enable-dart-profiling: FlutterShellArgs reads it from the intent, which
# `am start` must supply explicitly (only `flutter run` passes it for us).
a shell am start -W -S --ez enable-dart-profiling true -n "$PKG/$PKG.MainActivity" >/dev/null 2>&1

LINE=""
for _ in $(seq 1 40); do
  LINE=$(a logcat -d 2>/dev/null | grep -o 'The Dart VM service is listening on http://127.0.0.1:[0-9]*/[^ ]*' | tail -1 || true)
  [ -n "$LINE" ] && break
  sleep 1
done
[ -n "$LINE" ] || { echo "VM service never published" >&2; exit 1; }

URI="${LINE##* }"                     # http://127.0.0.1:PORT/TOKEN/
DEV_PORT=$(echo "$URI" | sed -E 's#.*127\.0\.0\.1:([0-9]+)/.*#\1#')
TOKEN=$(echo "$URI" | sed -E 's#.*127\.0\.0\.1:[0-9]+/##')

a forward --remove "tcp:$HOST_PORT" >/dev/null 2>&1 || true
a forward "tcp:$HOST_PORT" "tcp:$DEV_PORT" >/dev/null

# Let the app reach its settled home screen before anyone measures it.
sleep "${PLEZY_SETTLE:-14}"
a shell input keyevent 224 >/dev/null 2>&1 || true

echo "http://127.0.0.1:$HOST_PORT/$TOKEN"
