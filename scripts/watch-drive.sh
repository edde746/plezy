#!/usr/bin/env bash
# Build, install, and auto-drive the Plezy Watch app on simulator with full log capture.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WATCH_UDID="${WATCH_UDID:-8A13A0F7-C4D1-4337-98FA-70DDECFDEA0B}"
LOG="/tmp/plezy-watch-drive.log"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"

echo "==> Building…"
cd "$ROOT/ios"
xcodebuild -scheme "PlezyWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)" \
  build -quiet

APP=$(find "$DERIVED"/Runner-* -name "PlezyWatch Watch App.app" -path "*Debug-watchsimulator*" ! -path "*Index.noindex*" | head -1)
echo "==> App: $APP"

xcrun simctl boot "$WATCH_UDID" 2>/dev/null || true

echo "==> Starting log stream → $LOG"
rm -f "$LOG"
/usr/bin/log stream --predicate 'subsystem == "com.edde746.plezy.watch"' --style compact > "$LOG" 2>&1 &
LOGPID=$!
trap 'kill $LOGPID 2>/dev/null || true' EXIT
sleep 1

echo "==> Installing & launching with PLEZY_INSTRUMENT_DRIVE=1"
xcrun simctl terminate "$WATCH_UDID" com.edde746.plezy.watchkitapp 2>/dev/null || true
xcrun simctl install "$WATCH_UDID" "$APP"
SIMCTL_CHILD_PLEZY_INSTRUMENT_DRIVE=1 xcrun simctl launch "$WATCH_UDID" com.edde746.plezy.watchkitapp

echo "==> Driving (12s)…"
sleep 1.5
xcrun simctl io "$WATCH_UDID" screenshot /tmp/plezy-drive-home.png
sleep 10
xcrun simctl io "$WATCH_UDID" screenshot /tmp/plezy-drive-final.png

kill $LOGPID 2>/dev/null || true
trap - EXIT

echo ""
echo "==> Screenshots: /tmp/plezy-drive-home.png /tmp/plezy-drive-final.png"
echo "==> Log ($LOG):"
rg "ms \[" "$LOG" || true
