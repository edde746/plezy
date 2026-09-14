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

KTLINT_VERSION="1.5.0"
KTLINT_SHA256="a16be01dcc480aab2f55f444b620142152f66e31564b3b9376506d624c28a2ad"
KTLINT_URL="https://github.com/ktlint/ktlint/releases/download/$KTLINT_VERSION/ktlint"
KTLINT_BIN="$ROOT/.dart_tool/native-format/ktlint-$KTLINT_VERSION"
KTLINT_TMP=""
JAVA_BIN_DIR=""

cleanup() {
  if [ -n "$KTLINT_TMP" ]; then
    rm -f -- "$KTLINT_TMP"
  fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
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

java_diagnostic() {
  echo "A working JDK 17+ is required for Kotlin formatting. Set JAVA_HOME to a JDK 17+ installation or put java on PATH." >&2
}

resolve_java() {
  local candidate output version major
  if [ -n "${JAVA_HOME:-}" ]; then
    candidate="$JAVA_HOME/bin/java"
  else
    candidate="$(command -v java 2>/dev/null || true)"
  fi
  if [ -z "$candidate" ] || [ ! -x "$candidate" ]; then
    java_diagnostic
    return 127
  fi
  if [[ "$candidate" != /* ]]; then
    candidate="$PWD/$candidate"
  fi
  if ! output="$("$candidate" -version 2>&1)"; then
    java_diagnostic
    return 127
  fi
  if [[ "$output" =~ version[[:space:]]+\"([^\"]+)\" ]]; then
    version="${BASH_REMATCH[1]}"
  else
    java_diagnostic
    return 127
  fi
  if [[ "$version" =~ ^1\.([0-9]+)([._-]|$) ]]; then
    major="${BASH_REMATCH[1]}"
  elif [[ "$version" =~ ^([0-9]+)([._-]|$) ]]; then
    major="${BASH_REMATCH[1]}"
  else
    java_diagnostic
    return 127
  fi
  if ((major < 17)); then
    java_diagnostic
    return 127
  fi
  JAVA_BIN_DIR="${candidate%/*}"
}

sha256_file() {
  local output
  if has_command shasum; then
    output="$(shasum -a 256 "$1")" || {
      echo "Failed to calculate the ktlint SHA-256 digest with shasum." >&2
      return 2
    }
  elif has_command sha256sum; then
    output="$(sha256sum "$1")" || {
      echo "Failed to calculate the ktlint SHA-256 digest with sha256sum." >&2
      return 2
    }
  else
    echo "A SHA-256 tool is required to verify ktlint (shasum or sha256sum)." >&2
    return 127
  fi
  printf '%s\n' "${output%%[[:space:]]*}"
}

verify_ktlint() {
  local digest
  digest="$(sha256_file "$1")" || return $?
  [[ "$digest" =~ ^[0-9a-f]{64}$ ]] && [ "$digest" = "$KTLINT_SHA256" ]
}

ensure_ktlint() {
  local status
  if ! has_command shasum && ! has_command sha256sum; then
    echo "A SHA-256 tool is required to verify ktlint (shasum or sha256sum)." >&2
    return 127
  fi
  if [ -f "$KTLINT_BIN" ]; then
    if verify_ktlint "$KTLINT_BIN"; then
      chmod +x "$KTLINT_BIN"
      return 0
    else
      status=$?
      if [ "$status" -ne 1 ]; then
        return "$status"
      fi
    fi
  fi
  if ! has_command curl; then
    echo "curl not found. Install curl to download ktlint." >&2
    return 127
  fi

  mkdir -p "$(dirname "$KTLINT_BIN")"
  KTLINT_TMP="$(mktemp "$(dirname "$KTLINT_BIN")/.ktlint-$KTLINT_VERSION.XXXXXX")"
  if ! curl -fsSL "$KTLINT_URL" -o "$KTLINT_TMP"; then
    echo "Failed to download ktlint $KTLINT_VERSION." >&2
    return 1
  fi
  if verify_ktlint "$KTLINT_TMP"; then
    :
  else
    status=$?
    if [ "$status" -eq 1 ]; then
      echo "Downloaded ktlint $KTLINT_VERSION failed SHA-256 verification." >&2
    fi
    return "$status"
  fi
  chmod +x "$KTLINT_TMP"
  mv -f "$KTLINT_TMP" "$KTLINT_BIN"
  KTLINT_TMP=""
}

run_ktlint() {
  PATH="$JAVA_BIN_DIR:$PATH" "$KTLINT_BIN" "$@"
}

append_native_files() {
  while IFS= read -r -d '' file; do
    case "$file" in
      android/app/src/main/cpp/include/*) continue ;;
      android/libmpv/src/main/cpp/include/*) continue ;;
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
  resolve_java
  ensure_ktlint
  if [ "$MODE" = "fix" ]; then
    run_ktlint -F "${ktlint_files[@]}"
  else
    run_ktlint "${ktlint_files[@]}" || FAILED=1
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
