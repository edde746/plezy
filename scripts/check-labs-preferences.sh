#!/usr/bin/env bash
set -euo pipefail

official_ref=${1:?usage: check-labs-preferences.sh <official-tag>}
registry=${2:-tool/labs_preferences.txt}

if [[ ! -f "$registry" ]]; then
  echo "Missing Labs preference registry: $registry" >&2
  exit 1
fi

official_settings=$(git show "$official_ref:lib/services/settings_service.dart")
failures=0

while IFS='|' read -r key value_type migration; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  if grep -Fq "'$key'" <<<"$official_settings" && [[ -z "$migration" ]]; then
    echo "Official Plezy now owns preference '$key' ($value_type), but no compatibility decision is registered." >&2
    failures=$((failures + 1))
  fi
done < "$registry"

if (( failures > 0 )); then
  echo "Add a migration identifier or 'compatible' in the third registry column before releasing." >&2
  exit 1
fi

echo "Labs preference compatibility check passed for $official_ref"
