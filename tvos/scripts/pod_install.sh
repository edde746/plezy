#!/usr/bin/env bash
# Runs `pod install` for the tvOS target with UTF-8 locale forced — CocoaPods
# 1.16 on Ruby 4.0 crashes with Encoding::CompatibilityError when LANG/LC_ALL
# are unset or non-UTF-8.

set -euo pipefail

TVOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TVOS_DIR"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

exec pod install "$@"
