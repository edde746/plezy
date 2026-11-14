#!/usr/bin/env bash
# Stream Plezy Watch instrument logs.
#
# Simulator:
#   ./scripts/watch-log-stream.sh
#
# Physical watch (paired, logs via unified logging when connected):
#   ./scripts/watch-log-stream.sh device
#   Or use Xcode → Devices → Dangerwatch → Open Console
#
# Format: +NNNNNNms [category] message
# Categories: lifecycle, ui, navigation, state, action, playback, plex, connectivity, recent, timing

set -euo pipefail

TARGET="${1:-simulator}"
PREDICATE='subsystem == "com.edde746.plezy.watch"'

if [[ "$TARGET" == "device" ]]; then
  echo "Streaming from unified log (physical watch logs appear when paired)…"
  echo "Tip: filter Console.app by subsystem: com.edde746.plezy.watch"
  /usr/bin/log stream --predicate "$PREDICATE" --style compact
else
  echo "Streaming from watch simulator…"
  /usr/bin/log stream --predicate "$PREDICATE" --style compact
fi
