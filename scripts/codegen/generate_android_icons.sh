#!/usr/bin/env bash
# Keep Android monochrome, notification, adaptive and legacy artwork in sync.
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$script_dir/generate_brand_assets.py" "$@"
