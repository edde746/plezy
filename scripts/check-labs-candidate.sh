#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage: $0 OFFICIAL_TAG" >&2
  exit 2
fi

OFFICIAL_TAG=$1
ROOT=$(git rev-parse --show-toplevel)
CANDIDATE_LOG=$(mktemp)
BASELINE_LOG=$(mktemp)
BASELINE_ROOT=$(mktemp -d)
BASELINE_WORKTREE="$BASELINE_ROOT/official"

cleanup() {
  git -C "$ROOT" worktree remove --force "$BASELINE_WORKTREE" >/dev/null 2>&1 || true
  rmdir "$BASELINE_ROOT" >/dev/null 2>&1 || true
  rm -f "$CANDIDATE_LOG" "$BASELINE_LOG"
}
trap cleanup EXIT

has_known_analyzer_crash() {
  local log=$1
  grep -Fq "An error occurred while executing an analyzer plugin: Null check operator used on a null value" "$log" &&
    grep -Fq "CommentReferenceResolver._resolveSimpleIdentifier" "$log" &&
    grep -Fq "Analyzer check failed: unexpected stderr output (exit 2)" "$log"
}

normalized_diagnostics() {
  local log=$1
  local root=$2
  grep -E '^(ERROR|WARNING|INFO)\|' "$log" | sed "s|$root/|<root>/|g" || true
}

has_only_unchanged_upstream_format_drift() {
  local log=$1
  local official_tag=$2
  local failure_count
  local path
  local paths=()

  failure_count=$(grep -c '^  FAIL  ' "$log" || true)
  [[ $failure_count -eq 1 ]] || return 1
  grep -Fq '  FAIL  formatting issues' "$log" || return 1

  while IFS= read -r path; do
    [[ -n "$path" ]] && paths+=("$path")
  done < <(sed -n 's/^    Changed //p' "$log")
  [[ ${#paths[@]} -gt 0 ]] || return 1

  for path in "${paths[@]}"; do
    [[ -f "$ROOT/$path" ]] || return 1
    git -C "$ROOT" diff --quiet "$official_tag" HEAD -- "$path" || return 1
  done
}

has_known_upstream_maestro_contract_failure() {
  local log=$1
  local official_tag=$2
  local path
  local paths=(
    scripts/maestro/test_maestro_flow_contracts.py
    .maestro/regression_flows/05_tv_next_episode_back.yaml
  )

  [[ $(grep -Ec '^(ERROR|FAIL): ' "$log" || true) -eq 1 ]] || return 1
  grep -Fq 'ERROR: test_tv_next_episode_dismissal_has_platform_specific_controls' "$log" || return 1
  grep -Fq 'StopIteration' "$log" || return 1

  for path in "${paths[@]}"; do
    git -C "$ROOT" diff --quiet "$official_tag" HEAD -- "$path" || return 1
  done
}

has_only_unchanged_upstream_unused_code() {
  local log=$1
  local official_tag=$2
  local path
  local paths=()

  while IFS= read -r path; do
    [[ -n "$path" ]] && paths+=("$path")
  done < <(
    sed -n \
      '/^==> dart_code_linter: unused code$/,/^==> dart_code_linter: unused files$/s/^    \([^[:space:]].*\.dart\):$/\1/p' \
      "$log"
  )
  [[ ${#paths[@]} -gt 0 ]] || return 1

  for path in "${paths[@]}"; do
    [[ -f "$ROOT/$path" ]] || return 1
    git -C "$ROOT" diff --quiet "$official_tag" HEAD -- "$path" || return 1
  done
}

set +e
scripts/ci_checks.sh 2>&1 | tee "$CANDIDATE_LOG"
CANDIDATE_STATUS=${PIPESTATUS[0]}
set -e

if [[ $CANDIDATE_STATUS -eq 0 ]]; then
  exit 0
fi

if has_only_unchanged_upstream_format_drift "$CANDIDATE_LOG" "$OFFICIAL_TAG"; then
  echo "::warning::Official $OFFICIAL_TAG contains the only files reported by the formatter; accepting unchanged upstream format drift."
  exit 0
fi

FAILURE_COUNT=$(grep -c '^  FAIL  ' "$CANDIDATE_LOG" || true)
ACCEPTED_FAILURES=0
if grep -Fq '  FAIL  workflow or script guard failed' "$CANDIDATE_LOG" &&
  has_known_upstream_maestro_contract_failure "$CANDIDATE_LOG" "$OFFICIAL_TAG"; then
  echo "::warning::Official $OFFICIAL_TAG contains the unchanged failing Maestro next-episode contract; accepting the upstream baseline failure."
  ACCEPTED_FAILURES=$((ACCEPTED_FAILURES + 1))
fi
if grep -Fq '  FAIL  unused code detected:' "$CANDIDATE_LOG" &&
  has_only_unchanged_upstream_unused_code "$CANDIDATE_LOG" "$OFFICIAL_TAG"; then
  echo "::warning::Official $OFFICIAL_TAG contains every reported unused-code path unchanged; accepting the upstream baseline failure."
  ACCEPTED_FAILURES=$((ACCEPTED_FAILURES + 1))
fi
if [[ $ACCEPTED_FAILURES -eq $FAILURE_COUNT ]]; then
  exit 0
fi

if [[ $FAILURE_COUNT -ne 1 ]] ||
  ! grep -Fq '  FAIL  analyzer errors, warnings, unexpected infos, or tool failure' "$CANDIDATE_LOG" ||
  ! has_known_analyzer_crash "$CANDIDATE_LOG"; then
  echo "Labs candidate failed checks for a reason other than the known upstream analyzer crash." >&2
  exit "$CANDIDATE_STATUS"
fi

echo "Candidate hit the known analyzer crash; reproducing it on official $OFFICIAL_TAG."
git -C "$ROOT" worktree add --detach "$BASELINE_WORKTREE" "$OFFICIAL_TAG"
(
  cd "$BASELINE_WORKTREE"
  flutter pub get
  (cd packages/saf_util && flutter pub get)
  dart run scripts/checks/check_analyzer.dart
) 2>&1 | tee "$BASELINE_LOG" || BASELINE_STATUS=${PIPESTATUS[0]}
BASELINE_STATUS=${BASELINE_STATUS:-0}

if [[ $BASELINE_STATUS -eq 0 ]]; then
  echo "Official $OFFICIAL_TAG unexpectedly passed analyzer validation, so the candidate crash cannot be accepted." >&2
  exit "$CANDIDATE_STATUS"
fi

if ! diff -u \
  <(normalized_diagnostics "$BASELINE_LOG" "$BASELINE_WORKTREE") \
  <(normalized_diagnostics "$CANDIDATE_LOG" "$ROOT"); then
  echo "Labs candidate analyzer diagnostics differ from official $OFFICIAL_TAG." >&2
  exit "$CANDIDATE_STATUS"
fi

if has_known_analyzer_crash "$BASELINE_LOG"; then
  echo "::warning::Official $OFFICIAL_TAG reproduces the same analyzer-plugin crash and diagnostics; accepting the upstream baseline failure."
elif grep -Eq '^Analyzer check failed: unexpected (ERROR|WARNING|INFO) diagnostic:' "$BASELINE_LOG"; then
  echo "::warning::Official $OFFICIAL_TAG emitted identical diagnostics without reproducing the nondeterministic analyzer-plugin crash; accepting the upstream baseline failure."
else
  echo "Official $OFFICIAL_TAG failed analyzer validation for an unexpected reason." >&2
  exit "$CANDIDATE_STATUS"
fi
