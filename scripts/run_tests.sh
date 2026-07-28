#!/usr/bin/env bash
set -uo pipefail

# Run the Flutter test suite with a concurrency that matches the host.
#
# `flutter test` defaults to ceil(numCPUs / 2), which leaves half the machine
# idle. That default is a poor fit here because roughly three quarters of this
# suite's cost is per-file Dart kernel compilation rather than test execution
# (436 test files, each its own isolate), and compilation scales with cores.
#
# Measured on an 8-core host, full suite:
#   -j 4 (the default)  190s
#   -j 6                168s
#   -j 8                136s
#   -j 12               165s
#
# One job per core wins; oversubscribing regresses. So scale to the core count
# instead of hard-coding a number that would oversubscribe smaller CI runners.
#
# Any arguments are forwarded to `flutter test`, and an explicit -j/--concurrency
# still overrides the computed value.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Overridable so scripts/test_run_tests.py can point the detector at fixtures.
: "${PLEZY_CGROUP_ROOT:=/sys/fs/cgroup}"

# Cores this process may actually use.
#
# Three limits can each be the binding one, and a container can hit any subset
# of them: a generous CPU quota paired with a narrow cpuset is as common as the
# reverse. Taking whichever is discovered first would oversubscribe whenever a
# different one binds, so collect them all and use the smallest.
#
#   cgroup v2 quota   cpu.max ("<quota> <period>", or "max" when unlimited)
#   cgroup v1 quota   cpu.cfs_quota_us / cpu.cfs_period_us (-1 when unlimited)
#   affinity/cpuset   reported by nproc, which honours sched_getaffinity
online_cpus() {
  if command -v nproc >/dev/null 2>&1; then
    nproc 2>/dev/null && return
  fi
  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null && return
  fi
  getconf _NPROCESSORS_ONLN 2>/dev/null
}

# ceil(quota / period), skipped unless both are positive integers.
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

  # Nothing readable anywhere: prefer a conservative guess over the host count.
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

# Sourced by the tests to exercise the detector; only a direct run continues.
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
