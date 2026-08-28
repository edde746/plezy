#!/usr/bin/env bash
set -euo pipefail

mapfile -t conflicts < <(git diff --name-only --diff-filter=U)

if (( ${#conflicts[@]} == 0 )); then
  echo "No merge conflicts need generated-file resolution."
  exit 0
fi

unsupported=()
for path in "${conflicts[@]}"; do
  if [[ ! "$path" =~ ^lib/i18n/strings(_[A-Za-z0-9]+)?\.g\.dart$ ]]; then
    unsupported+=("$path")
  fi
done

if (( ${#unsupported[@]} > 0 )); then
  echo "Automatic resolution is limited to generated translation files." >&2
  printf 'Unsupported conflict: %s\n' "${unsupported[@]}" >&2
  exit 1
fi

flutter pub get --enforce-lockfile --no-example
scripts/prepare-labs-translations.py
dart run slang
git add -- lib/i18n/strings*.g.dart

if git diff --name-only --diff-filter=U | grep -q .; then
  echo "Generated translation conflicts remain after regeneration." >&2
  exit 1
fi

echo "Regenerated and resolved ${#conflicts[@]} translation file conflict(s)."
