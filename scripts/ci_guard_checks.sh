#!/usr/bin/env bash
# Single source of truth for workflow/script guards, shared by CI and
# scripts/ci_checks.sh. Regression tests use a glob so new test_checkers are
# picked up automatically; checkers requiring Bun or built packages run in
# their owning jobs as well.
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for checker in \
  scripts/checks/check_build_workflow.py \
  scripts/checks/check_apple_spm_locks.py \
  scripts/checks/check_tvos_test_wiring.py \
  scripts/checks/check_shrinker_rules.py \
  scripts/checks/verify_runtime_inputs.py \
  scripts/checks/check_workflow_security.py \
  scripts/checks/check_workflow_action_pins.py \
  scripts/checks/check_container_image_pins.py \
  scripts/checks/check_update_packages_workflow.py \
  scripts/checks/check_linux_package_deps.py \
  scripts/checks/check_windows_installer.py \
  scripts/checks/check_windows_msix.py; do
  python3 "$checker"
done

for guard_test in scripts/test_*.py scripts/*/test_*.py; do
  python3 "$guard_test"
done
