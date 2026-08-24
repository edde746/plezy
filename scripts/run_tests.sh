#!/usr/bin/env bash
set -uo pipefail

# Match Flutter test concurrency to the host. Kernel compilation dominates this
# suite, and one job per available core outperformed the default on CI hosts.
# Explicit -j/--concurrency arguments are forwarded unchanged.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Overridable for scripts/test_run_tests.py fixtures.
: "${PLEZY_CGROUP_ROOT:=/sys/fs/cgroup}"

# Use the smallest available limit: cgroup quota, legacy quota, or affinity.
online_cpus() {
  if command -v nproc >/dev/null 2>&1; then
    nproc 2>/dev/null && return
  fi
  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null && return
  fi
  getconf _NPROCESSORS_ONLN 2>/dev/null
}

# Return ceil(quota / period) for positive numeric values.
quota_cpus() {
  local quota="$1" period="$2"
  case "$quota$period" in
    '' | *[!0-9]*) return 1 ;;
  esac
  [ "$period" -gt 0 ] || return 1
  [ "$quota" -gt 0 ] || return 1
  echo $(((quota + period - 1) / period))
}

detect_cpus() {
  local limits=() value quota period

  value="$(online_cpus)"
  case "$value" in
    '' | *[!0-9]*) ;;
    *) limits+=("$value") ;;
  esac

  if [ -r "$PLEZY_CGROUP_ROOT/cpu.max" ]; then
    read -r quota period <"$PLEZY_CGROUP_ROOT/cpu.max" || true
    if value="$(quota_cpus "${quota:-}" "${period:-}")"; then
      limits+=("$value")
    fi
  fi

  if [ -r "$PLEZY_CGROUP_ROOT/cpu/cpu.cfs_quota_us" ] &&
    [ -r "$PLEZY_CGROUP_ROOT/cpu/cpu.cfs_period_us" ]; then
    read -r quota <"$PLEZY_CGROUP_ROOT/cpu/cpu.cfs_quota_us" || true
    read -r period <"$PLEZY_CGROUP_ROOT/cpu/cpu.cfs_period_us" || true
    if value="$(quota_cpus "${quota:-}" "${period:-}")"; then
      limits+=("$value")
    fi
  fi

  # Nothing readable: prefer a conservative default.
  if [ "${#limits[@]}" -eq 0 ]; then
    echo 4
    return
  fi

  local smallest="${limits[0]}"
  for value in "${limits[@]}"; do
    [ "$value" -lt "$smallest" ] && smallest="$value"
  done
  [ "$smallest" -lt 1 ] && smallest=1
  echo "$smallest"
}

# Tests source this file to exercise the detector.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
  return 0
fi

cd "$ROOT"

for arg in "$@"; do
  case "$arg" in
    -j | --concurrency | -j=* | --concurrency=*)
      exec flutter test "$@"
      ;;
  esac
done

CPUS="$(detect_cpus)"

echo "==> flutter test -j $CPUS ${*:-}"
exec flutter test -j "$CPUS" "$@"
