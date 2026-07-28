#!/usr/bin/env bash
# Workflow and script regression guards.
#
# Single source of truth for the guard roster, shared by the "Verify workflow
# and script guards" step in .github/workflows/ci.yml and section 4 of
# scripts/ci_checks.sh. The checkers are named explicitly because a few of them
# belong to other jobs (check_bun_audit.py needs Bun, check_codegen.py runs via
# codegen.sh), but their regression tests are discovered by glob so a newly
# added scripts/test_*.py is picked up automatically instead of having to be
# remembered in two places.
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for checker in \
  scripts/check_build_workflow.py \
  scripts/check_apple_spm_locks.py \
  scripts/check_tvos_test_wiring.py \
  scripts/check_shrinker_rules.py \
  scripts/verify_runtime_inputs.py \
  scripts/check_workflow_security.py \
  scripts/check_workflow_action_pins.py \
  scripts/check_container_image_pins.py \
  scripts/check_update_packages_workflow.py; do
  python3 "$checker"
done

for guard_test in scripts/test_*.py; do
  python3 "$guard_test"
done
