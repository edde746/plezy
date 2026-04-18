#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

if [ -t 1 ]; then
  BOLD=$'\e[1m'; RED=$'\e[31m'; GRN=$'\e[32m'; DIM=$'\e[2m'; RST=$'\e[0m'
else
  BOLD=""; RED=""; GRN=""; DIM=""; RST=""
fi
section() { printf "\n%s==> %s%s\n" "$BOLD" "$1" "$RST"; }
ok()   { printf "  %sPASS%s  %s\n" "$GRN" "$RST" "$1"; }
fail() { printf "  %sFAIL%s  %s\n" "$RED" "$RST" "$1"; }
skip() { printf "  %sSKIP%s  %s\n" "$DIM" "$RST" "$1"; }

if ! command -v flutter >/dev/null 2>&1 || ! command -v dart >/dev/null 2>&1; then
  fail "flutter/dart not in PATH"
  echo "  Install Flutter: https://docs.flutter.dev/get-started/install"
  echo "  Bypass temporarily: SKIP_HOOKS=1 git commit ..."
  exit 1
fi

have_dart_code_linter() {
  [ -f "$ROOT/.dart_tool/package_config.json" ] && \
    grep -q '"name": *"dart_code_linter"' "$ROOT/.dart_tool/package_config.json" 2>/dev/null
}

FAILED=0

# 1. dart format (mirrors ci.yml "Verify formatting")
section "dart format"
files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(
  find lib $([ -d test ] && echo test) \
    -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" \
    -type f -print0 2>/dev/null
)
if [ ${#files[@]} -eq 0 ]; then
  skip "no dart files"
else
  out="$(mktemp)"
  if dart format --output=none --set-exit-if-changed "${files[@]}" >"$out" 2>&1; then
    ok "${#files[@]} file(s) correctly formatted"
  else
    fail "formatting issues"
    sed 's/^/    /' "$out"
    FAILED=1
  fi
  rm -f "$out"
fi

# 2. flutter analyze (mirrors ci.yml "Analyze code")
section "flutter analyze"
out="$(mktemp)"
flutter analyze >"$out" 2>&1 || true
if grep -q "error •" "$out"; then
  fail "errors"
  grep -E "error •|warning •" "$out" | sed 's/^/    /'
  FAILED=1
elif grep -q "warning •" "$out"; then
  fail "warnings (treated as failure, matching CI)"
  grep "warning •" "$out" | sed 's/^/    /'
  FAILED=1
else
  ok "no errors or warnings"
fi
rm -f "$out"

# 3. Unused code (mirrors ci.yml "Check for unused code")
section "dart_code_linter: unused code"
if ! have_dart_code_linter; then
  skip "dart_code_linter unresolved — run 'flutter pub get'"
else
  out="$(mktemp)"
  dart run dart_code_linter:metrics check-unused-code lib >"$out" 2>&1 || true
  if grep -qi "no unused code found" "$out"; then
    ok "none"
  else
    fail "unused code detected:"
    sed 's/^/    /' "$out"
    FAILED=1
  fi
  rm -f "$out"
fi

# 4. Unused files (mirrors ci.yml "Check for unused files")
section "dart_code_linter: unused files"
if ! have_dart_code_linter; then
  skip "dart_code_linter unresolved — run 'flutter pub get'"
else
  out="$(mktemp)"
  dart run dart_code_linter:metrics check-unused-files lib >"$out" 2>&1 || true
  if grep -qi "no unused files found" "$out"; then
    ok "none"
  else
    fail "unused files detected:"
    sed 's/^/    /' "$out"
    FAILED=1
  fi
  rm -f "$out"
fi

if [ "$FAILED" -ne 0 ]; then
  printf "\n%sOne or more checks failed.%s Bypass with SKIP_HOOKS=1 (or --no-verify).\n" "$RED" "$RST"
  exit 1
fi
printf "\n%sAll checks passed.%s\n" "$GRN" "$RST"
