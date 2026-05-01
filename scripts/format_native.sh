#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

MODE="check"
case "${1:---check}" in
  --check) MODE="check" ;;
  --fix|--write) MODE="fix" ;;
  -h|--help)
    echo "Usage: scripts/format_native.sh [--check|--fix]"
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    echo "Usage: scripts/format_native.sh [--check|--fix]" >&2
    exit 2
    ;;
esac

KTLINT_VERSION="${KTLINT_VERSION:-1.5.0}"
KTLINT_BIN="$ROOT/.dart_tool/native-format/ktlint-$KTLINT_VERSION"

has_command() {
  command -v "$1" >/dev/null 2>&1
}

run_clang_format() {
  if has_command xcrun && xcrun --find clang-format >/dev/null 2>&1; then
    xcrun clang-format "$@"
  elif has_command clang-format; then
    clang-format "$@"
  else
    echo "clang-format not found. Install clang-format or Xcode command line tools." >&2
    return 127
  fi
}

run_swift_format() {
  if has_command xcrun && xcrun --find swift-format >/dev/null 2>&1; then
    xcrun swift-format "$@"
  elif has_command swift-format; then
    swift-format "$@"
  elif has_command swift && swift format --help >/dev/null 2>&1; then
    swift format "$@"
  else
    echo "swift-format not found. Install Swift 6+, swift-format, or Xcode 16+." >&2
    return 127
  fi
}

ensure_ktlint() {
  if [ -x "$KTLINT_BIN" ]; then
    return 0
  fi
  if ! has_command curl; then
    echo "curl not found. Install curl to download ktlint." >&2
    return 127
  fi
  if ! has_command java; then
    echo "java not found. Install JDK 17+ to run ktlint." >&2
    return 127
  fi

  mkdir -p "$(dirname "$KTLINT_BIN")"
  curl -fsSL "https://github.com/pinterest/ktlint/releases/download/$KTLINT_VERSION/ktlint" -o "$KTLINT_BIN"
  chmod +x "$KTLINT_BIN"
}

append_native_files() {
  while IFS= read -r -d '' file; do
    case "$file" in
      android/app/src/main/cpp/include/*) continue ;;
      android/app/src/main/java/io/flutter/plugins/*) continue ;;
      ios/Flutter/*|macos/Flutter/*|tvos/Flutter/*) continue ;;
      linux/flutter/*|windows/flutter/*) continue ;;
      tvos/Runner/Plugins/*) continue ;;
      */GeneratedPluginRegistrant.*|*/generated_plugin_registrant.*) continue ;;
    esac

    case "$file" in
      *.kt|*.kts) ktlint_files+=("$file") ;;
      *.swift) swift_files+=("$file") ;;
      *.c|*.cc|*.cpp|*.h|*.hpp|*.m|*.mm) clang_files+=("$file") ;;
    esac
  done < <(git ls-files -z -- "$@")
}

ktlint_files=()
swift_files=()
clang_files=()

append_native_files \
  'android/**/*.kt' 'android/**/*.kts' \
  'ios/**/*.swift' 'macos/**/*.swift' 'tvos/**/*.swift' 'shared/**/*.swift' \
  'android/**/*.[ch]' 'android/**/*.cc' 'android/**/*.cpp' 'android/**/*.hpp' \
  'ios/**/*.[hm]' 'ios/**/*.mm' \
  'macos/**/*.[hm]' 'macos/**/*.mm' \
  'tvos/**/*.[hm]' 'tvos/**/*.mm' \
  'linux/**/*.[ch]' 'linux/**/*.cc' 'linux/**/*.cpp' 'linux/**/*.hpp' \
  'windows/**/*.[ch]' 'windows/**/*.cc' 'windows/**/*.cpp' 'windows/**/*.hpp' \
  'shared/**/*.[ch]' 'shared/**/*.cc' 'shared/**/*.cpp' 'shared/**/*.hpp'

FAILED=0

if [ "${#ktlint_files[@]}" -gt 0 ]; then
  ensure_ktlint
  if [ "$MODE" = "fix" ]; then
    "$KTLINT_BIN" -F "${ktlint_files[@]}"
  else
    "$KTLINT_BIN" "${ktlint_files[@]}" || FAILED=1
  fi
else
  echo "No Kotlin files found."
fi

if [ "${#swift_files[@]}" -gt 0 ]; then
  if [ "$MODE" = "fix" ]; then
    run_swift_format format --configuration "$ROOT/.swift-format" --in-place "${swift_files[@]}"
  else
    swift_failed=0
    for file in "${swift_files[@]}"; do
      tmp="$(mktemp)"
      run_swift_format format --configuration "$ROOT/.swift-format" "$file" >"$tmp"
      if ! cmp -s "$file" "$tmp"; then
        if [ "$swift_failed" -eq 0 ]; then
          echo "Swift files need formatting:"
        fi
        echo "  $file"
        swift_failed=1
      fi
      rm -f "$tmp"
    done
    if [ "$swift_failed" -ne 0 ]; then
      FAILED=1
    fi
  fi
else
  echo "No Swift files found."
fi

if [ "${#clang_files[@]}" -gt 0 ]; then
  if [ "$MODE" = "fix" ]; then
    run_clang_format -i "${clang_files[@]}"
  else
    run_clang_format --dry-run --Werror "${clang_files[@]}" || FAILED=1
  fi
else
  echo "No C/C++/Obj-C files found."
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Native formatting issues found. Run: scripts/format_native.sh --fix" >&2
  exit 1
fi

if [ "$MODE" = "check" ]; then
  echo "Native formatting passed."
else
  echo "Native formatting applied."
fi
