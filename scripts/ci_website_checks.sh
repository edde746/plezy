#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/website"

bun install --frozen-lockfile
bun test
bun run check
bun run build
python3 "$ROOT_DIR/scripts/test_check_bun_audit.py"
bun run audit
