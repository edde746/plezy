#!/usr/bin/env bash
# Build, install, and auto-drive Plezy on physical watch + phone.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WATCH_DEVICE="${WATCH_DEVICE:-Dangerwatch}"
PHONE_DEVICE="${PHONE_DEVICE:-Dangerphone}"
BUNDLE_ID="com.edde746.plezy.watchkitapp"
PHONE_BUNDLE="com.edde746.plezy"
DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
LOG="/tmp/plezy-watch-device.log"
DRIVE_SECS="${DRIVE_SECS:-45}"
INSTRUMENT_DRIVE="${PLEZY_INSTRUMENT_DRIVE:-1}"
WATCH_WAIT_SECS="${WATCH_WAIT_SECS:-900}"
WATCH_POLL_SECS="${WATCH_POLL_SECS:-10}"
WATCH_LAUNCH_WAIT_SECS="${WATCH_LAUNCH_WAIT_SECS:-900}"

watch_device_state() {
  xcrun devicectl list devices 2>&1 | rg "^${WATCH_DEVICE}[[:space:]]" | awk '{print $4}' || true
}

wait_for_watch_online() {
  local label="${1:-online}"
  local max="$WATCH_WAIT_SECS"
  local interval="$WATCH_POLL_SECS"
  local elapsed=0
  while (( elapsed < max )); do
    local state
    state="$(watch_device_state)"
    if [[ "$state" == "connected" ]]; then
      echo "==> $WATCH_DEVICE $label (connected)"
      return 0
    fi
    echo "==> Waiting for $WATCH_DEVICE to be connected ($label) — state=${state:-not found}, ${elapsed}s / ${max}s"
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  echo "ERROR: $WATCH_DEVICE not connected after ${max}s" >&2
  return 1
}

launch_watch_app() {
  local max="$WATCH_LAUNCH_WAIT_SECS"
  local interval="$WATCH_POLL_SECS"
  local elapsed=0
  local output=""

  while (( elapsed < max )); do
    if [[ "$INSTRUMENT_DRIVE" == "1" ]]; then
      ENV_JSON='{"PLEZY_INSTRUMENT_DRIVE":"1"}'
      if output="$(xcrun devicectl device process launch --device "$WATCH_DEVICE" \
        --environment-variables "$ENV_JSON" \
        --console "$BUNDLE_ID" 2>&1)"; then
        printf '%s\n' "$output"
        return 0
      fi
    elif output="$(xcrun devicectl device process launch --device "$WATCH_DEVICE" "$BUNDLE_ID" 2>&1)"; then
      printf '%s\n' "$output"
      return 0
    fi

    if printf '%s' "$output" | rg -q "Locked|device is locked|passcode locked"; then
      echo "==> $WATCH_DEVICE locked — unlock it (wake + passcode). Retrying in ${interval}s (${elapsed}s / ${max}s)"
    elif printf '%s' "$output" | rg -qi "unavailable|not connected|not found"; then
      echo "==> $WATCH_DEVICE unavailable — waiting for connection (${elapsed}s / ${max}s)"
      wait_for_watch_online "for launch" || true
    else
      echo "==> Launch failed, retrying in ${interval}s:"
      printf '%s\n' "$output" | tail -5
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "ERROR: could not launch $BUNDLE_ID on $WATCH_DEVICE after ${max}s" >&2
  printf '%s\n' "$output" >&2
  return 1
}

wait_for_watch_online "before build"

echo "==> Building watch for $WATCH_DEVICE..."
cd "$ROOT/ios"
xcodebuild -scheme "PlezyWatch Watch App" \
  -destination "platform=watchOS,name=$WATCH_DEVICE" \
  -allowProvisioningUpdates build -quiet

APP=$(find "$DERIVED"/Runner-* -name "PlezyWatch Watch App.app" -path "*Debug-watchos*" ! -path "*Index.noindex*" | head -1)
wait_for_watch_online "before install"
echo "==> Installing $APP"
xcrun devicectl device install app --device "$WATCH_DEVICE" "$APP"

echo "==> Launching iPhone app ($PHONE_BUNDLE) for credentials..."
xcrun devicectl device process launch --device "$PHONE_DEVICE" "$PHONE_BUNDLE" 2>&1 || true
sleep 3

echo "==> Starting Mac log stream -> $LOG"
rm -f "$LOG"
/usr/bin/log stream --predicate 'subsystem == "com.edde746.plezy.watch"' --style compact > "$LOG" 2>&1 &
LOGPID=$!
trap 'kill $LOGPID 2>/dev/null || true' EXIT
sleep 1

wait_for_watch_online "before launch"
echo "==> Launching watch with instrument drive (${DRIVE_SECS}s)..."
CONSOLE_LOG="/tmp/plezy-watch-console.log"
rm -f "$CONSOLE_LOG"
if [[ "$INSTRUMENT_DRIVE" == "1" ]]; then
  (
    launch_watch_app 2>&1 | tee "$CONSOLE_LOG"
  ) &
  CONSOLEPID=$!
else
  launch_watch_app || true
  CONSOLEPID=""
fi

echo "==> Driving (${DRIVE_SECS}s)..."
sleep "$DRIVE_SECS"

[[ -n "${CONSOLEPID:-}" ]] && kill "$CONSOLEPID" 2>/dev/null || true

kill $LOGPID 2>/dev/null || true
trap - EXIT

echo ""
echo "==> Instrument log ($LOG + $CONSOLE_LOG):"
if [[ -f "$CONSOLE_LOG" ]] && rg -q "ms \[" "$CONSOLE_LOG" 2>/dev/null; then
  rg "ms \[" "$CONSOLE_LOG"
elif rg -q "ms \[" "$LOG" 2>/dev/null; then
  rg "ms \[" "$LOG"
else
  echo "(no structured logs captured)"
  tail -40 "$CONSOLE_LOG" 2>/dev/null || tail -40 "$LOG" 2>/dev/null || true
fi

echo ""
echo "==> Drive summary:"
rg "InstrumentDriver|transcode|Ready to play|isPlaying|playback confirmed|FAILED|TIMEOUT|DONE|artist radio|resolveStreamUrl" "$LOG" "$CONSOLE_LOG" 2>/dev/null | tail -60 || true
