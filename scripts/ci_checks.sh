#!/usr/bin/env bash
set -uo pipefail

# Hook-invoked Flutter commands inherit GIT_* variables and can misreport the SDK
# version; clear them so hooks and direct invocations behave identically.
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_PREFIX

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

section "codegen freshness"
out="$(mktemp)"
if scripts/codegen.sh --check >"$out" 2>&1; then
  ok "generated files are current"
else
  fail "generated files are stale"
  sed 's/^/    /' "$out"
  FAILED=1
fi
rm -f "$out"

section "translation hygiene"
if python3 scripts/clean_translations.py --check --strict; then
  ok "locale files normalized and no unused keys found"
else
  fail "translation files need cleanup or contain unused keys"
  FAILED=1
fi

section "hardcoded UI strings"
if python3 scripts/check_hardcoded_strings.py; then
  ok "user-facing strings use the translation layer"
else
  fail "hardcoded user-facing English strings found"
  FAILED=1
fi

section "workflow and script guards"
if bash scripts/ci_guard_checks.sh; then
  ok "workflow and script guards passed"
else
  fail "workflow or script guard failed"
  FAILED=1
fi

section "icon consistency"
if dart run scripts/check_icon_consistency.dart; then
  ok "production icons use AppIcon and rounded Symbols"
else
  fail "icon consistency violations found"
  FAILED=1
fi

section "native format"
out="$(mktemp)"
if scripts/format_native.sh --check >"$out" 2>&1; then
  ok "native files correctly formatted"
else
  fail "native formatting check failed"
  sed 's/^/    /' "$out"
  FAILED=1
fi
rm -f "$out"

section "Dart analyzer"
if dart run scripts/check_analyzer.dart; then
  ok "no unapproved diagnostics"
else
  fail "analyzer errors, warnings, unexpected infos, or tool failure"
  FAILED=1
fi

section "dart_code_linter: unused code"
if ! have_dart_code_linter; then
  skip "dart_code_linter unresolved — run 'flutter pub get'"
else
  out="$(mktemp)"
  flutter pub run dart_code_linter:metrics check-unused-code lib >"$out" 2>&1 || true
  if grep -qi "no unused code found" "$out"; then
    ok "none"
  else
    fail "unused code detected:"
    sed 's/^/    /' "$out"
    FAILED=1
  fi
  rm -f "$out"
fi

section "dart_code_linter: unused files"
if ! have_dart_code_linter; then
  skip "dart_code_linter unresolved — run 'flutter pub get'"
else
  out="$(mktemp)"
  flutter pub run dart_code_linter:metrics check-unused-files lib >"$out" 2>&1 || true
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
