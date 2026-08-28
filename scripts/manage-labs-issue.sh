#!/usr/bin/env bash
set -euo pipefail

action=${1:?usage: manage-labs-issue.sh <failure|success> <labs-tag> [stage] [details]}
tag=${2:?usage: manage-labs-issue.sh <failure|success> <labs-tag> [stage] [details]}
stage=${3:-}
details=${4:-}
repository=${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}
run_url=${GITHUB_RUN_URL:-${GITHUB_SERVER_URL:-https://github.com}/$repository/actions}
title="Plezy Labs automation blocked for $tag"

issues=$(gh issue list --repo "$repository" --state all --limit 100 --json number,title,state)
number=$(jq -r --arg title "$title" '[.[] | select(.title == $title)] | first | .number // empty' <<<"$issues")
state=$(jq -r --arg title "$title" '[.[] | select(.title == $title)] | first | .state // empty' <<<"$issues")

if [[ "$action" == "success" ]]; then
  if [[ -n "$number" && "$state" == "OPEN" ]]; then
    gh issue comment "$number" --repo "$repository" --body "Automation succeeded for $tag. Closing this issue. Run: $run_url"
    gh issue close "$number" --repo "$repository" --reason completed
  fi
  exit 0
fi

if [[ "$action" != "failure" ]]; then
  echo "Unknown action: $action" >&2
  exit 2
fi

gh label create labs-automation \
  --repo "$repository" \
  --color B60205 \
  --description "Plezy Labs automation requires attention" \
  --force

body=$(mktemp)
trap 'rm -f "$body"' EXIT
{
  echo "Plezy Labs could not complete **$tag**."
  echo
  echo "- Failed stage: \`$stage\`"
  echo "- Workflow run: $run_url"
  echo "- Result: no release was published"
  echo
  echo "### Details"
  echo
  if [[ -n "$details" ]]; then
    echo '```text'
    echo "$details"
    echo '```'
  else
    echo "Inspect the workflow log for the failing command."
  fi
  echo
  echo "Fix the incompatibility, then rerun the Plezy Labs workflow manually. Repeated watcher attempts update this issue instead of creating duplicates."
} >"$body"

if [[ -z "$number" ]]; then
  gh issue create \
    --repo "$repository" \
    --title "$title" \
    --label labs-automation \
    --body-file "$body"
else
  if [[ "$state" == "CLOSED" ]]; then
    gh issue reopen "$number" --repo "$repository"
  fi
  gh issue edit "$number" --repo "$repository" --add-label labs-automation --body-file "$body"
  gh issue comment "$number" --repo "$repository" --body "Automation failed again during \`$stage\`. Updated from $run_url"
fi
