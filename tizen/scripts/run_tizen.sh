#!/usr/bin/env bash
# Run the app on a connected Tizen device for development.
#
# Usage:
#   ./tizen/scripts/run_tizen.sh                          # release mode, auto-detect device
#   ./tizen/scripts/run_tizen.sh --debug                  # debug mode, auto-detect device
#   ./tizen/scripts/run_tizen.sh -d <device-ip>           # release mode, connect device first via sdb
#   ./tizen/scripts/run_tizen.sh -d <device-ip> --debug   # debug mode, connect device first via sdb
#
# -d triggers an sdb connect before launching, use it when the device is not already connected.
# flutter-tizen auto-detects a connected device when -d is omitted.
# All extra arguments are forwarded to flutter-tizen run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Resolve sdb: prefer PATH, fall back to the default Tizen Studio location.
SDB="sdb"
if ! command -v sdb &>/dev/null; then
	if [[ -x "$HOME/tizen-studio/tools/sdb" ]]; then
		SDB="$HOME/tizen-studio/tools/sdb"
	else
		echo "Warning: sdb not found on PATH or at ~/tizen-studio/tools/sdb; skipping connect step. Please connect manually" >&2
		SDB=""
	fi
fi

# Sync tizen-manifest.xml version from pubspec.yaml (e.g. "2.2.0+100" -> "2.2.0").
PUBSPEC_VERSION="$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version:[[:space:]]*//' | sed 's/+.*//' | tr -d '[:space:]')"
if [[ -n "$PUBSPEC_VERSION" ]]; then
	sed -i "s/\(<manifest[^>]* version=\"\)[^\"]*\"/\1$PUBSPEC_VERSION\"/" "$REPO_ROOT/tizen/tizen-manifest.xml"
fi

MODE="--release"
DEVICE_IP=""
EXTRA_ARGS=()
i=1
while [[ $i -le $# ]]; do
	arg="${!i}"
	if [[ "$arg" == "--debug" ]]; then
		MODE="--debug"
	elif [[ "$arg" == "-d" ]]; then
		i=$((i + 1))
		DEVICE_IP="${!i}"
		EXTRA_ARGS+=("-d" "$DEVICE_IP")
	else
		EXTRA_ARGS+=("$arg")
	fi
	i=$((i + 1))
done

# Connect the device via SDB before handing off to flutter-tizen.
# Strip any existing port so we always connect on the SDB default (26101).
if [[ -n "$SDB" && -n "$DEVICE_IP" ]]; then
	IP_ONLY="${DEVICE_IP%%:*}"
	echo "Connecting to $IP_ONLY via SDB..."
	"$SDB" connect "$IP_ONLY" || true
fi

flutter-tizen run \
	$MODE \
	--dart-define=TIZEN_BUILD=true \
	"${EXTRA_ARGS[@]}"
